#!/bin/sh
# v0.0.8

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

parent=$(dirname "$(__readlink_f "$0")") 

java -cp "$0" io.github.kensuke1984.anisotime.ANISOtime "$@"

if [ $? -eq 55 ]; then
  mv "$parent/latest_anisotime" "$0"
  chmod +x "$0"
  java -cp "$0" io.github.kensuke1984.anisotime.ANISOtime "$@" & 
  exit 55
fi

exit $?

