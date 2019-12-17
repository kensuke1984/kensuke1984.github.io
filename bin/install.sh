#!/bin/sh
#
# Installer of Kibrary  Kensuke Konishi
#

if [ "$(readlink /bin/sh)" != "dash" ];then
  set -o posix
fi

readonly install_version='0.2.0'
readonly KIBIN_URL='https://bit.ly/37wxazr'
readonly kibrary_jar='kibrary-0.4.5.jar'
readonly KIBRARY_MASTER_ZIP='https://bit.ly/2qY5J0O'
readonly DEFAULT_KIBRARY_HOME="$HOME/Kibrary"
readonly logfile="$(pwd)/kinst.log"
readonly errfile="$(pwd)/kinst.err"
readonly githubio='https://kensuke1984.github.io'
readonly gitbin="$githubio/bin"

#Emulates readlink -f hoge
__readlink_f (){
  TARGET_FILE=$1
  if [ "$(echo "$TARGET_FILE" | cut -c 1-2)" = "~/" ]; then
    TARGET_FILE=$HOME/${TARGET_FILE#\~/}
  fi
  while [ "$TARGET_FILE" != "" ];
  do
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

__md5 (){
  if command -v md5sum >/dev/null 2>&1; then
    md5sum "$@" >>"$logfile"
  elif command -v md5 >/dev/null 2>&1; then
    md5 "$@" >>"$logfile"
  fi
}

__mvlog(){
  mv "$logfile" "$errfile" "$KIBRARY_HOME"
}

__download_kibin(){
  if [ $downloader = "curl" ]; then
    curl -sL -o "$kibrary_jar" "$KIBIN_URL"
  else
    wget -q -O "$kibrary_jar" "$KIBIN_URL"
  fi
  __md5 "$kibrary_jar" >>"$logfile"
}

__unexpected_exit(){
  printf "$2 ($1)\n" | tee -a "$errfile"
  __mvlog
  exit $1
}

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
  __unexpected_exit 3 "No downloader is found. Install \\e[31mGNU Wget\\e[m (\\e[4mhttps://www.gnu.org/software/wget/\\e[m) or \\e[31mcurl\\e[m (\\e[4mhttps://curl.haxx.se/\\e[m), otherwise please download the latest Kibrary manually."
fi 

echo "downloader=$downloader" >>"$logfile"

KIBRARY_HOME="$(__readlink_f "$KIBRARY_HOME")"
printf "Installing in %s ... ok? (y/N) " "$KIBRARY_HOME"
read -r yn </dev/tty
case "$yn" in [yY]*)  ;; *) __unexpected_exit 1 "Installation cancelled.";; esac

echo "KIBRARY_HOME=$KIBRARY_HOME" >>$logfile

if [ ! -e "$KIBRARY_HOME" ]; then
  if ! mkdir -p "$KIBRARY_HOME" >>"$logfile" 2>>"$errfile"; then
    __unexpected_exit 1 "Could not create $KIBRARY_HOME."
  fi
else
  printf "%s exists. Do you want to \\e[4;31mremove\\e[m it and continue? (y/N)\\n" "$KIBRARY_HOME"
  read -r yn </dev/tty
  case "$yn" in [yY]*)  ;; *) __unexpected_exit 2 "Installation cancelled.";; esac
  rm -rf "$KIBRARY_HOME"
  mkdir "$KIBRARY_HOME"
fi

cd "$KIBRARY_HOME" || __unexpected_exit 3 "Could not cd to $KIBRARY_HOME. Installation failure."
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
(cd share && unzip -q "$catalog_zip" || __unexpected_exit 69 "Could not cd to share.")
rm "$catalog_zip"
__md5 share/*.cat

#bin
for binfile in anisotime readlink_f.sh kibrary_property kibrary_operation
do
  if [ $downloader = "curl" ]; then
    curl -s -o "bin/$binfile" "$gitbin/$binfile"
  else
    wget -q -P bin "$gitbin/$binfile"
  fi
  __md5 "bin/$binfile"
  chmod +x "bin/$binfile"
done
(cd bin && __download_kibin || __unexpected_exit 31 "Could not download the Kibrary.")
__mvlog

exit 0



