#!/bin/sh
#
# Installer of Kibrary  Kensuke Konishi
#

if [ "$(readlink /bin/sh)" != "dash" ];then
  set -o posix
fi

readonly install_version='0.2.5'
readonly KIBIN_URL='https://bit.ly/31FkTrh'
readonly DEFAULT_KIBRARY_HOME="$HOME/Kibrary"
readonly logdir="$(mktemp -d)"
readonly logfile="$logdir/kinst.log"
readonly errfile="$logdir/kinst.err"
readonly gitbin='https://kensuke1984.github.io/bin'

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
    pwd -P
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
  mv "$logdir" "$KIBRARY_HOME/log"
}

__download_kibin(){
  jar_tmp=$(mktemp)
  if [ $downloader = "curl" ]; then
    curl -sL -o "$jar_tmp" "$KIBIN_URL"
  else
    wget -q -O "$jar_tmp" "$KIBIN_URL"
  fi
  __md5 "$jar_tmp" >>"$logfile"
  version=$(java -cp "$jar_tmp" -Djava.awt.headless=true io.github.kensuke1984.kibrary.About 2>&1 >/dev/null | head -1 | awk '{print $2}')
  mv "$jar_tmp" "kibrary-$version.jar"
}

__unexpected_exit(){
  printf '%s (%s)\n' "$2" "$1"| tee -a "$errfile"
  __mvlog
  exit $1
}

touch "$logfile" "$errfile"
echo "###install.sh stdout $install_version" >>"$logfile"
echo "###install.sh stderr $install_version" >>"$errfile"
echo "PATH=$PATH" >>"$logfile"

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

echo "KIBRARY_HOME=$KIBRARY_HOME" >>"$logfile"

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
(cd bin && __download_kibin || __unexpected_exit 31 "Could not download \\e[3mKibrary\\e[m.")
__mvlog

exit 0



