#!/bin/sh
#set -e
set -o posix

readonly KIBRARY_HOME="$HOME"/.Kibrary
readonly KIBRARY_BIN="$KIBRARY_HOME"/bin
readonly KIBRARY_SHARE="$KIBRARY_HOME"/share


while getopts f OPT
do
  case $OPT in
    "f" ) readonly FLG_F="TRUE" ;; 
  esac
done

if which curl >/dev/null 2>&1; then
  downloader=curl
elif which wget >/dev/null 2>&1; then
  downloader=wget
else
  printf "No downloader is found. Install \\e[31mGNU Wget\\e[m (\\e[4mhttps://www.gnu.org/software/wget/\\e[m) or \\e[31mcurl\\e[m (\\e[4mhttps://curl.haxx.se/\\e[m), otherwise please download the latest Kibrary manually.\\n"
  exit 3
fi

if [ $FLG_F ]; then
  rm -rf "$KIBRARY_HOME"
fi

githubio='https://kensuke1984.github.io'
gitbin="$githubio/bin"
if [ ! -e "$KIBRARY_HOME" ]; then
  mkdir -p "$KIBRARY_BIN"
  mkdir "$KIBRARY_SHARE"
  if [ $? -ne 0 ]; then
    echo "Could not create $KIBRARY_HOME"
    return 2>/dev/null
    exit 1 
  fi
else
  printf "%s already exists. If you want to do a clean install, please add an option \\e[4;31m-f\\e[m as below:\\n" "$KIBRARY_HOME" 
  if [ $downloader = "curl" ]; then
    echo "curl -s $githubio/bin/install.sh | /bin/sh -s -- -f"
  else
    echo "wget -q -O - $githubio/bin/install.sh | /bin/sh -s -- -f"
  fi
  return 2>/dev/null
  exit 2
fi

cd "$KIBRARY_HOME" || (echo "Could not cd to $KIBRARY_HOME. Install failure."; exit 1)

#bin
if [ $downloader = "curl" ]; then
  curl -s -o "$KIBRARY_BIN"/javaCheck "$gitbin"/javaCheck
  curl -s -o "$KIBRARY_BIN"/javaInstall "$gitbin"/javaInstall
  curl -s -o "$KIBRARY_BIN"/anisotime "$gitbin"/anisotime
  curl -s -o "$KIBRARY_BIN"/javaCheck.jar "$gitbin"/javaCheck.jar
  curl -s -o "$KIBRARY_BIN"/.kibraryrc "$gitbin"/kibraryrc
  curl -s -o "$KIBRARY_BIN"/kibrary_property "$gitbin"/kibrary_property
  curl -s -o "$KIBRARY_BIN"/kibrary_operation "$gitbin"/kibrary_operation
  curl -s -o "$KIBRARY_BIN"/oracle_javase_url "$gitbin"/oracle_javase_url
else
  wget -q -P "$KIBRARY_BIN" "$gitbin"/javaCheck
  wget -q -P "$KIBRARY_BIN" "$gitbin"/javaInstall
  wget -q -P "$KIBRARY_BIN" "$gitbin"/anisotime
  wget -q -P "$KIBRARY_BIN" "$gitbin"/javaCheck.jar
  wget -q -P "$KIBRARY_BIN" "$gitbin"/kibrary_property
  wget -q -P "$KIBRARY_BIN" "$gitbin"/kibrary_operation
  wget -q -P "$KIBRARY_BIN" "$gitbin"/oracle_javase_url
  wget -q -O "$KIBRARY_BIN"/.kibraryrc "$gitbin"/kibraryrc
fi

chmod +x "$KIBRARY_BIN/javaCheck"
chmod +x "$KIBRARY_BIN/javaInstall"
chmod +x "$KIBRARY_BIN/anisotime"
chmod +x "$KIBRARY_BIN/javaCheck.jar"
chmod +x "$KIBRARY_BIN/kibrary_property"
chmod +x "$KIBRARY_BIN/kibrary_operation"
chmod +x "$KIBRARY_BIN/oracle_javase_url"

if ! "$KIBRARY_BIN"/javaCheck -r >/dev/null 2>&1; then
  if ! "${KIBRARY_BIN}/javaInstall" -f >/dev/null 2>&1; then
    echo "Java is not found and cannot be installed. ANISOtime installation cancelled."
    exit 1
  fi
fi

if ! "$KIBRARY_BIN"/javaCheck >/dev/null 2>&1; then
  if ! "${KIBRARY_BIN}/javaInstall" -f >/dev/null 2>&1; then
    echo "Due to a failure of building Kibrary, downloading the latest binary release.";
    if [ $downloader = "curl" ]; then
      curl -s -o "$KIBRARY_BIN/kibrary-latest.jar" "$gitbin"/kibrary-latest.jar
    else
      wget -q -P "$KIBRARY_BIN" "$gitbin"/kibrary-latest.jar
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
./gradlew --no-daemon -q build 2>/dev/null 

if [ $? -eq 0 ]; then
  mv build/libs/kibrary*jar "$KIBRARY_BIN" 
else
  echo "Due to a failure of building Kibrary, downloading the latest binary release.";
  if [ $downloader = "curl" ]; then
    curl -s -o "$KIBRARY_BIN/kibrary-latest.jar" "$githubio"/kibrary-latest.jar
  else
    wget -q -P "$KIBRARY_BIN" "$githubio"/kibrary-latest.jar
  fi
fi 

readonly KIBRARY=$(ls "$KIBRARY_BIN"/kib*jar)

#bash
cat <<EOF >"$KIBRARY_BIN"/init_bash.sh
##classpath
export CLASSPATH=\$CLASSPATH:$KIBRARY
export PATH=\$PATH:$KIBRARY_BIN
if [ -e "${KIBRARY_HOME}"/java/latest/bin ];then
  export PATH="${KIBRARY_HOME}"/java/latest/bin:\$PATH
  export JAVA_HOME="${KIBRARY_HOME}"/java/latest
fi
EOF

#tcsh
cat <<EOF >"$KIBRARY_BIN"/init_tcsh.sh
##classpath
set opt_set = \$?nonomatch
set nonomatch
if ! \$?CLASSPATH then
  setenv CLASSPATH $KIBRARY
else
  setenv CLASSPATH \${CLASSPATH}:$KIBRARY
endif
setenv PATH \${PATH}:$KIBRARY_BIN
if (\$opt_set == 0) then
  unset nonomatch
endif
EOF

echo Copy and paste the below line to setup PATH and CLASSPATH.

if echo "$SHELL" | grep -qE 'bash|zsh'; then
  echo "source $KIBRARY_BIN/init_bash.sh"
elif echo "$SHELL" | grep -qE 'tcsh'; then
  echo "source $KIBRARY_BIN/init_tcsh.sh" 
else
  echo "Please add $KIBRARY_BIN in PATH."
fi
#source $KIBRARY_BIN/init_bash.sh 2>/dev/null || source $KIBRARY_BIN/init_tcsh.sh 2>/dev/null
#return 2> /dev/null
exit 0









