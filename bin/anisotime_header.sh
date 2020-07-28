#!/bin/sh
#v0.0.5

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

get_version (){
  java -cp "$1" -Djava.awt.headless=true io.github.kensuke1984.anisotime.About | head -1 | awk '{print $2}'
}

anisotime_url='https://bit.ly/2XI9KT7'

update (){
  tmpfile="$(mktemp)"
  kibin="$(dirname "$(__readlink_f "$0")")"
  if command -v wget >/dev/null 2>&1; then
    wget -q -O "$tmpfile" "$anisotime_url"
  elif command -v curl >/dev/null 2>&1; then
    curl -sL -o "$tmpfile" "$anisotime_url"
  else
    return
  fi
  cloud_version=$(get_version "$tmpfile")
  local_version=$(get_version "$0")
  if [ "$local_version" \< "$cloud_version" ]; then
    mv -f "$0" "$kibin/.anisotime_$local_version"
    mv "$tmpfile" "$kibin/anisotime"
    chmod +x "$kibin/anisotime"
    printf '%s is updated.\n' "$kibin/anisotime" 1>&2
  else
    rm "$tmpfile"
  fi
}

java -cp "$0" io.github.kensuke1984.anisotime.ANISOtime "$@"
update &
exit $?

