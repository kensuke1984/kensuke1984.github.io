#!/bin/sh

k2a_version='0.0.5'

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

__show_usage_exit (){
  printf 'Usage: %s /path/to/kibarary_jar\n' "$(basename "$0")"
  exit 1
}

if [ -z $1 ]; then
  __show_usage_exit
fi

cwd=$(pwd)
file="$(__readlink_f $1)"
if [ -d "$file" ]; then
  printf '%s is a directory.\n' "$file"
  __show_usage_exit
fi

if [ ! -f "$file" ]; then
  printf "%s does not exist.\n" "$file" 1>&2
  __show_usage_exit
fi

anisotime_version=$(java -cp "$file" -Djava.awt.headless=true io.github.kensuke1984.anisotime.About | head -1 | awk '{print $2}')
name="anisotime-${anisotime_version%.*}.jar"
if [ -f "$name" ]; then
  printf "%s already exists.\n" "$name" 1>&2
  exit 2
fi
dir=$(mktemp -d)
cd "$dir" || exit 1
jar xf "$file"
sed -i.bak 's/kibrary.About/anisotime.ANISOtime/' META-INF/MANIFEST.MF
jar cmf META-INF/MANIFEST.MF "$name" ./*
mv "$name" "$cwd"
rm -rf "$dir"
