#!/bin/sh

rl_f_version='0.0.1'

#Emulates readlink -f hoge
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

