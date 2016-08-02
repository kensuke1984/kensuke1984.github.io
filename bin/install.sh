#!/bin/sh
#set -e
set -o posix

readonly KIBRARY_DIR=$HOME/.Kibrary
readonly KIBRARY_BIN=$KIBRARY_DIR/bin

while getopts f OPT
do
  case $OPT in
    "f" ) readonly FLG_F="TRUE" 
  esac
done



if which wget >&/dev/null; then
  downloader=wget
elif which curl >&/dev/null; then
  downloader=curl
else
  printf "No downloader is found. Install \e[31mGNU Wget\e[m (\e[4mhttps://www.gnu.org/software/wget/\e[m) or \e[31mcurl\e[m (\e[4mhttps://curl.haxx.se/\e[m), otherwise please download the latest Kibrary manually.\n"
  exit 3
fi





if [ $FLG_F ]; then
  rm -rf "$KIBRARY_DIR"
fi

if [ ! -e "$KIBRARY_DIR" ]; then
  mkdir -p "$KIBRARY_BIN"
  if [ $? -ne 0 ]; then
    echo "Could not create $KIBRARY_DIR"
    return 2>/dev/null
    exit 1 
  fi
else
  printf "%s already exists. If you want to do a clean install, please add an option \e[4;31m-f\e[m as below:\n" "$KIBRARY_DIR" 
  if [ $downloader = "curl" ]; then
    echo "curl -s http://kensuke1984.github.io/bin/install.sh | /bin/sh -s -- -f"
  else
    echo "wget -q -O - http://kensuke1984.github.io/bin/install.sh | /bin/sh -s -- -f"
  fi
  return 2>/dev/null
  exit 2
fi

cd "$KIBRARY_DIR" || (echo "Could not cd to $KIBRARY_DIR. Install failure."; exit 1)

#bin
if [ $downloader = "curl" ]; then
  curl -s -o "$KIBRARY_BIN/javaCheck" https://kensuke1984.github.io/bin/javaCheck
  curl -s -o "$KIBRARY_BIN/anisotime" https://kensuke1984.github.io/bin/anisotime
  curl -s -o "$KIBRARY_BIN/javaCheck.jar" https://kensuke1984.github.io/bin/javaCheck.jar
else
  wget -q -P "$KIBRARY_BIN" https://kensuke1984.github.io/bin/javaCheck
  wget -q -P "$KIBRARY_BIN" https://kensuke1984.github.io/bin/anisotime
  wget -q -P "$KIBRARY_BIN" https://kensuke1984.github.io/bin/javaCheck.jar
fi

chmod +x "$KIBRARY_BIN/javaCheck"
chmod +x "$KIBRARY_BIN/anisotime"
chmod +x "$KIBRARY_BIN/javaCheck.jar"

"$KIBRARY_BIN"/javaCheck 
if [ $? -ne 0 ]; then
  echo "Installation failed."
  return 2>/dev/null
  exit 1
fi

#Build Kibrary
echo "Kibrary is in $KIBRARY_DIR"
if [ $downloader = "curl" ]; then
  curl -s -o gradlew.tar https://kensuke1984.github.io/gradlew.tar
else
  wget -q https://kensuke1984.github.io/gradlew.tar
fi
tar xf gradlew.tar
./gradlew -q >/dev/null
./gradlew -q build 2>/dev/null 

if [ $? -eq 0 ]; then
  mv build/libs/kibrary*jar "$KIBRARY_BIN" 
else
  echo "Due to a failure of building Kibrary, downloading the latest binary release.";
  if [ $downloader = "curl" ]; then
    curl -s -o "$KIBRARY_BIN/kibrary-latest.jar" https://kensuke1984.github.io/kibrary-latest.jar
  else
    wget -q -P "$KIBRARY_BIN" https://kensuke1984.github.io/kibrary-latest.jar
  fi
fi 

readonly KIBRARY=$(ls "$KIBRARY_BIN"/kib*jar)

#bash
cat <<EOF >"$KIBRARY_BIN"/init_bash.sh
##classpath
export CLASSPATH=\$CLASSPATH:$KIBRARY
export PATH=\$PATH:$KIBRARY_BIN
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

echo Copy and paste it to setup PATH and CLASSPATH.

if echo "$SHELL" | grep -qE 'bash|zsh' ; then
  echo "source $KIBRARY_BIN/init_bash.sh"
elif echo "$SHELL" | grep -qE 'tcsh' ; then
  echo "source $KIBRARY_BIN/init_tcsh.sh" 
else
  echo "Please add $KIBRARY_BIN in PATH."
fi
#source $KIBRARY_BIN/init_bash.sh 2>/dev/null || source $KIBRARY_BIN/init_tcsh.sh 2>/dev/null
#return 2> /dev/null
if [ $downloader = "curl" ]; then
    curl -s -o "$KIBRARY_BIN"/.kibraryrc https://kensuke1984.github.io/bin/kibraryrc
  else
    wget -q -O "$KIBRARY_BIN"/.kibraryrc https://kensuke1984.github.io/bin/kibraryrc
fi
exit 0









