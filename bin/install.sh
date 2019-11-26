#!/bin/sh
#set -e
set -o posix

install_version='0.1.1'

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

touch $logfile $errfile
echo "###install.sh stdout $install_version" >>$logfile
echo "###install.sh stderr $install_version" >>$errfile
echo "PATH=$PATH" >>$logfile

printf "Where would you like to install Kibrary? (%s) " "$DEFAULT_KIBRARY_HOME"
read -r KIBRARY_HOME </dev/tty

if [ -z "$KIBRARY_HOME" ]; then
  KIBRARY_HOME="$DEFAULT_KIBRARY_HOME"
fi

if command -v curl >/dev/null 2>>"$errfile"; then
  downloader=curl
elif command -v wget >/dev/null 2>>"$errfile"; then
  downloader=wget
else
  printf "No downloader is found. Install \\e[31mGNU Wget\\e[m (\\e[4mhttps://www.gnu.org/software/wget/\\e[m) or \\e[31mcurl\\e[m (\\e[4mhttps://curl.haxx.se/\\e[m), otherwise please download the latest Kibrary manually. (3)\\n" | tee -a "$errfile"
  exit 3
fi
echo "downloader=$downloader" >>"$logfile"

KIBRARY_HOME="$(__readlink_f "$KIBRARY_HOME")"
printf "Installing in %s ... ok? (y/N) " "$KIBRARY_HOME"
read -r yn </dev/tty
case "$yn" in [yY]*)  ;; *) echo "Installation cancelled."; exit ;; esac

echo "KIBRARY_HOME=$KIBRARY_HOME" >>$logfile

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
piac_html="https://bit.ly/2rnhOMS"
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
#  curl -s -o bin/.kibraryrc "$gitbin"/kibraryrc
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
#  wget -q -O bin/.kibraryrc "$gitbin"/kibraryrc
fi

chmod +x "bin/javaCheck"
chmod +x "bin/javaInstall"
chmod +x "bin/anisotime"
chmod +x "bin/javaCheck.jar"
chmod +x "bin/kibrary_property"
chmod +x "bin/kibrary_operation"
chmod +x "bin/oracle_javase_url"

if [ -z "$JAVA" ];then
  JAVA='java'
  echo "JAVA is set to be 'java'. ($(command -v java))" >>$logfile
else
  echo "JAVA=$JAVA ($(command -v $JAVA)) " >>$logfile
fi

if [ -z "$JAVAC" ];then
  JAVAC='javac'
  echo "JAVAC is set to be 'javac' ($(command -v javac))" >>$logfile
else
  echo "JAVAC=$JAVAC ($(command -v $JAVAC))" >>$logfile
fi
export JAVA JAVAC

./bin/javaCheck -v >>"$logfile" 2>>"$errfile"

bin/javaCheck -r >>"$logfile" 2>>"$errfile"
if [ $? -ge 20 ] ; then
  echo "Java is not found. ANISOtime installation cancelled. (71)" | tee -a "$errfile"
  exit 71
fi

bin/javaCheck >>"$logfile" 2>>"$errfile"
if [ $? -ge 20 ] ; then
  echo "Because you do not have a Java compiler installed, downloading the latest binary release. (81)" | tee -a "$errfile"
  kibin='http://bit.ly/37wxazr'
  kibpath='bin/kibrary-0.4.5.jar'
  if [ $downloader = "curl" ]; then
    curl -sL -o "$kibpath" "$kibin"
  else
    wget -q -O "$kibpath" "$gitbin"/kibrary-latest.jar
  fi
  exit 81
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
    curl -sL -o "bin/kibrary-latest.jar" "$gitbin"/kibrary-latest.jar 2>>"$errfile"
  else
    wget -q -P bin "$gitbin"/kibrary-latest.jar 2>>"$errfile"
  fi
fi 

readonly KIBRARY=$(__readlink_f bin/kib*jar)

mv "$logfile" "$errfile" "$KIBRARY_HOME"

exit 0



