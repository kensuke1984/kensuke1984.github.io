#!/bin/sh
#set -e
set -o posix

#Emulates readlink -f hoge
__readlink_f (){
  TARGET_FILE=$1
  if [ "$(echo "$TARGET_FILE" | cut -c 1-2)" = "~/" ]; then
    TARGET_FILE=$HOME/${TARGET_FILE#\~/}
  fi
  while [ "$TARGET_FILE" != "" ]; do
      cd "$(dirname "$TARGET_FILE")" || exit 60
      FILENAME="$(basename "$TARGET_FILE")"
      TARGET_FILE="$(readlink "$FILENAME")"
  done
  if [ "$FILENAME" = "." ]; then
    echo "$(pwd -P)"
  else
    echo "$(pwd -P)/$FILENAME"
  fi
}

readonly DEFAULT_KIBRARY_HOME="$HOME"/Kibrary

printf "Where would you like to install Kibrary? (%s) " "$DEFAULT_KIBRARY_HOME"
read -r KIBRARY_HOME </dev/tty

if [ -z "$KIBRARY_HOME" ]; then
  KIBRARY_HOME="$DEFAULT_KIBRARY_HOME"
fi

if command -v curl >/dev/null 2>&1; then
  downloader=curl
elif command -v wget >/dev/null 2>&1; then
  downloader=wget
else
  printf "No downloader is found. Install \\e[31mGNU Wget\\e[m (\\e[4mhttps://www.gnu.org/software/wget/\\e[m) or \\e[31mcurl\\e[m (\\e[4mhttps://curl.haxx.se/\\e[m), otherwise please download the latest Kibrary manually.\\n"
  exit 3
fi

KIBRARY_HOME="$(__readlink_f "$KIBRARY_HOME")"
printf "Installing in %s ... ok? (y/N) " "$KIBRARY_HOME"
read -r yn </dev/tty
case "$yn" in [yY]*)  ;; *) echo "Cancelled." ; exit ;; esac
while getopts f OPT
do
  case $OPT in
    "f" ) readonly FLG_F="TRUE" ;; 
    *) printf "Invalid options detected.\n"
      exit 250 ;;
  esac
done

if [ -n "$FLG_F" ]; then
  rm -rf "$KIBRARY_HOME"
fi

githubio='https://kensuke1984.github.io'
gitbin="$githubio/bin"
if [ ! -e "$KIBRARY_HOME" ]; then
  if ! mkdir -p "$KIBRARY_HOME" >/dev/null 2>&1; then
    echo "Could not create $KIBRARY_HOME"
    return 2>/dev/null
    exit 1 
  fi
else
  printf "%s already exists. If you want to do a clean install, please add an option \\e[4;31m-f\\e[m as below:\\n" "$KIBRARY_HOME" 
  if [ "$downloader" = "curl" ]; then
    echo "curl -s $githubio/bin/install.sh | /bin/sh -s -- -f"
  else
    echo "wget -q -O - $githubio/bin/install.sh | /bin/sh -s -- -f"
  fi
  return 2>/dev/null
  exit 2
fi

cd "$KIBRARY_HOME" || (echo "Could not cd to $KIBRARY_HOME. Install failure."; exit 1)
mkdir bin share
export KIBRARY_HOME

#catalog
cd share
piac_html="https://www.dropbox.com/s/l0w1abpfgn1ze38/piac.tar?dl=1"
catalog_tar=$(mktemp)
mv "$catalog_tar" "$catalog_tar".tar
catalog_tar="$catalog_tar.tar"
if [ $downloader = "curl" ]; then
  curl -sL -o "$catalog_tar" "$piac_html"
else
  wget -q -O "$catalog_tar" "$piac_html"
fi
tar xf "$catalog_tar"
cd ..

#bin
if [ $downloader = "curl" ]; then
  curl -s -o bin/javaCheck "$gitbin"/javaCheck
  curl -s -o bin/javaInstall "$gitbin"/javaInstall
  curl -s -o bin/anisotime "$gitbin"/anisotime
  curl -s -o bin/javaCheck.jar "$gitbin"/javaCheck.jar
  curl -s -o bin/.kibraryrc "$gitbin"/kibraryrc
  curl -s -o bin/kibrary_property "$gitbin"/kibrary_property
  curl -s -o bin/kibrary_operation "$gitbin"/kibrary_operation
  curl -s -o bin/oracle_javase_url "$gitbin"/oracle_javase_url
else
  wget -q -P bin "$gitbin"/javaCheck
  wget -q -P bin "$gitbin"/javaInstall
  wget -q -P bin "$gitbin"/anisotime
  wget -q -P bin "$gitbin"/javaCheck.jar
  wget -q -P bin "$gitbin"/kibrary_property
  wget -q -P bin "$gitbin"/kibrary_operation
  wget -q -P bin "$gitbin"/oracle_javase_url
  wget -q -O bin/.kibraryrc "$gitbin"/kibraryrc
fi

chmod +x "bin/javaCheck"
chmod +x "bin/javaInstall"
chmod +x "bin/anisotime"
chmod +x "bin/javaCheck.jar"
chmod +x "bin/kibrary_property"
chmod +x "bin/kibrary_operation"
chmod +x "bin/oracle_javase_url"

if ! bin/javaCheck -r >/dev/null 2>&1; then
  if ! "bin/javaInstall" -f >/dev/null 2>&1; then
    echo "Java is not found and cannot be installed. ANISOtime installation cancelled."
    exit 1
  fi
fi

if ! bin/javaCheck >/dev/null 2>&1; then
  if ! "bin/javaInstall" -f >/dev/null 2>&1; then
    echo "Due to a failure of building Kibrary, downloading the latest binary release.";
    if [ $downloader = "curl" ]; then
      curl -s -o "bin/kibrary-latest.jar" "$gitbin"/kibrary-latest.jar
    else
      wget -q -P bin "$gitbin"/kibrary-latest.jar
    fi
    exit 1
  fi
  export JAVA_HOME="${KIBRARY_HOME}/java/latest"
fi

#Build Kibrary
echo "Kibrary is in $KIBRARY_HOME"
if [ $downloader = "curl" ]; then
  curl -s -o gradlew.tar "$githubio"/gradlew.tar
else
  wget -q "$githubio"/gradlew.tar
fi
tar xf gradlew.tar
./gradlew --no-daemon -q >/dev/null

if ./gradlew --no-daemon -q build 2>/dev/null; then
  mv build/libs/kibrary*jar bin 
else
  echo "Due to a failure of building Kibrary, downloading the latest binary release.";
  if [ $downloader = "curl" ]; then
    curl -s -o "bin/kibrary-latest.jar" "$gitbin"/kibrary-latest.jar
  else
    wget -q -P bin "$gitbin"/kibrary-latest.jar
  fi
fi 

readonly KIBRARY=$(__readlink_f bin/kib*jar)

exit 0
###########ANCIENT
#bash
cat <<EOF >"$KIBRARY_HOME/bin/init_bash.sh"
if [ -z "\$KIBRARY_HOME" ]; then
  echo "KIBRARY_HOME is not set."
  export KIBRARY_HOME=\$(dirname \$(__readlink_f "\$(dirname \$0)"))
  printf "KIBRARY_HOME is now %s\n" "\$KIBRARY_HOME"
#  return 71
fi
##classpath
#export CLASSPATH=\$CLASSPATH:$KIBRARY
export PATH=\$PATH:\${KIBRARY_HOME}/bin
if [ -e \${KIBRARY_HOME}/java/latest/bin ];then
  export PATH=\${KIBRARY_HOME}/java/latest/bin:\$PATH
  export JAVA_HOME=\${KIBRARY_HOME}/java/latest
fi
EOF

#tcsh
cat <<EOF >"$KIBRARY_HOME/bin/init_tcsh.sh"
##classpath
set opt_set = \$?nonomatch
set nonomatch
#if ! \$?CLASSPATH then
#  setenv CLASSPATH $KIBRARY
#else
#  setenv CLASSPATH \${CLASSPATH}:$KIBRARY
#endif
setenv PATH \${PATH}:$KIBRARY_HOME/bin
if (\$opt_set == 0) then
  unset nonomatch
endif
EOF

echo Copy and paste the below line to setup PATH and CLASSPATH.

if echo "$SHELL" | grep -qE 'bash|zsh'; then
  echo "source $KIBRARY_HOME/bin/init_bash.sh"
elif echo "$SHELL" | grep -qE 'tcsh'; then
  echo "source $KIBRARY_HOME/bin/init_tcsh.sh" 
else
  echo "Please add $KIBRARY_HOME/bin in PATH."
fi
#source $KIBRARY_BIN/init_bash.sh 2>/dev/null || source $KIBRARY_BIN/init_tcsh.sh 2>/dev/null
#return 2> /dev/null
exit 0



