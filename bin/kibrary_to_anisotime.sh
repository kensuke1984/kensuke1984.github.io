#!/bin/sh

k2a_version='0.0.2'
cwd=$(pwd)
file="$(readlink -f $1)"
name="anisotime-1.3.7.jar"
test -f "$file" || exit 71
test -f "$name" && exit 2
dir=$(mktemp -d)
cd "$dir" || exit 1
jar xf "$file"
sed -i 's/kibrary.About/anisotime.ANISOtime/' META-INF/MANIFEST.MF
jar cmf META-INF/MANIFEST.MF "$name" ./*
mv "$name" "$cwd"
rm -rf "$dir"
