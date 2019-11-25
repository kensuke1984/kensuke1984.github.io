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
readonly logfile=$(pwd)/kinst.log
readonly errfile=$(pwd)/kinst.err

printf "Where would you like to install Kibrary? (%s) " "$DEFAULT_KIBRARY_HOME"
read -r KIBRARY_HOME </dev/tty

if [ -z "$KIBRARY_HOME" ]; then
  KIBRARY_HOME="$DEFAULT_KIBRARY_HOME"
fi

echo KIBRARY_HOME=$KIBRARY_HOME >>$logfile

if command -v curl >>"$logfile" 2>>"$errfile"; then
  downloader=curl
elif command -v wget >>"$logfile" 2>>"$errfile"; then
  downloader=wget
else
  printf "No downloader is found. Install \\e[31mGNU Wget\\e[m (\\e[4mhttps://www.gnu.org/software/wget/\\e[m) or \\e[31mcurl\\e[m (\\e[4mhttps://curl.haxx.se/\\e[m), otherwise please download the latest Kibrary manually. (3)\\n" | tee -a "$errfile"
  exit 3
fi

echo downloader="$downloader" >>"$logfile"
KIBRARY_HOME="$(__readlink_f "$KIBRARY_HOME")"
printf "Installing in %s ... ok? (y/N) " "$KIBRARY_HOME"
read -r yn </dev/tty
case "$yn" in [yY]*)  ;; *) echo "Installation cancelled."; exit ;; esac

githubio='https://kensuke1984.github.io'
gitbin="$githubio/bin"
if [ ! -e "$KIBRARY_HOME" ]; then
  if ! mkdir -p "$KIBRARY_HOME" >>"$logfile" 2>>"$errfile"; then
    echo "Could not create $KIBRARY_HOME. (1)" | tee -a "$errfile"
    exit 1 
  fi
else
  printf "%s exists. Do you want to \\e[4;31mremove\\e[m it and continue? (y/N)\\n" "$KIBRARY_HOME"
  read -r yn </dev/tty
  case "$yn" in [yY]*)  ;; *) echo "Installation cancelled." ; exit 2;; esac
  rm -rf "$KIBRARY_HOME"
  mkdir "$KIBRARY_HOME"
fi

cd "$KIBRARY_HOME" || (echo "Could not cd to $KIBRARY_HOME. Install failure. (1)" | tee -a "$errfile"; exit 1)
mkdir bin share
export KIBRARY_HOME

#catalog
#piac_html="https://www.dropbox.com/s/l0w1abpfgn1ze38/piac.tar?dl=1"
piac_html="https://www.dropbox.com/s/dadsqhe47wnfe2k/piac.zip?dl=1"
catalog_zip=$(mktemp)
mv "$catalog_zip" "$catalog_zip".zip
catalog_zip="$catalog_zip.zip"
if [ $downloader = "curl" ]; then
  curl -sL -o "$catalog_zip" "$piac_html"
else
  wget -q -O "$catalog_zip" "$piac_html"
fi
(cd share; unzip -q "$catalog_zip")
rm "$catalog_zip"

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

if ! bin/javaCheck -r >>"$logfile" 2>>"$errfile"; then
  if ! "bin/javaInstall" -f >>"$logfile" 2>>"$errfile"; then
    echo "Java is not found and cannot be installed. ANISOtime installation cancelled. (71)" | tee -a "$errfile"
    exit 71
  fi
fi

if ! bin/javaCheck >>"$logfile" 2>>"$errfile"; then
  if ! "bin/javaInstall" -f >>"$logfile" 2>>"$errfile"; then
    echo "Due to a failure of building Kibrary, downloading the latest binary release. (81)" | tee -a "$errfile"
    if [ $downloader = "curl" ]; then
      curl -s -o "bin/kibrary-latest.jar" "$gitbin"/kibrary-latest.jar
    else
      wget -q -P bin "$gitbin"/kibrary-latest.jar
    fi
    exit 81
  fi
  export JAVA_HOME="${KIBRARY_HOME}/java/latest"
fi

#Build Kibrary
echo "Kibrary is in $KIBRARY_HOME" | tee -a "$logfile"
if [ $downloader = "curl" ]; then
  curl -s -o gradlew.tar "$githubio"/gradlew.tar
else
  wget -q "$githubio"/gradlew.tar
fi
tar xf gradlew.tar
./gradlew -q --no-daemon >/dev/null 2>&1

if ./gradlew -q --no-daemon build >/dev/null 2>&1; then
  mv build/libs/kibrary*jar bin 
else
  echo "Due to a failure of building Kibrary, downloading the latest binary release." | tee -a "$errfile"
  if [ $downloader = "curl" ]; then
    curl -# -o "bin/kibrary-latest.jar" "$gitbin"/kibrary-latest.jar 2>>"$errfile"
  else
    wget -P bin "$gitbin"/kibrary-latest.jar 2>>"$errfile"
  fi
fi 

readonly KIBRARY=$(__readlink_f bin/kib*jar)

mv "$logfile" "$errfile" "$KIBRARY_HOME"

exit 0
###########ANCIENT
#bash
cat <<EOF >"$KIBRARY_HOME/bin/init_bash.sh"
if [ -z "\$KIBRARY_HOME" ]; then
  echo "KIBRARY_HOME is not set."
  export KIBRARY_HOME=\$(dirname \$(__readlink_f "\$(dirname \$0)"))
  printf "KIBRARY_HOME is now %s\n" "\$KIBRARY_HOME"
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



