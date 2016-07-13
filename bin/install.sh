#!/bin/sh
#set -e

wget http://kensuke1984.github.io/gradlew.tar
tar xf gradlew.tar
./gradlew
./gradlew build

installDir=$HOME/.Kibrary
binDir=$installDir/bin
rm -rf $installDir

if [ ! -e $installDir ]; then
mkdir -p $binDir 
if [ $? -ne 0 ]; then
 echo "Could not create $installDir"
  exit 1 
fi
else
 echo  "$installDir already exists"
exit 2
fi
from="build/libs"

file=$(ls $from/kibrary*jar | sed "s/build\/libs\///")
mv $from/$file $binDir
mv javaCheck anisotime $binDir

#bash
cat <<EOF > $binDir/init_bash.sh
##classpath
export CLASSPATH=\$CLASSPATH:$binDir/$file
export PATH=\$PATH:$binDir
EOF

#tcsh
cat <<EOF > $binDir/init_tcsh.sh
##classpath
if ! \$?CLASSPATH then
    setenv CLASSPATH $binDir/$file
else
setenv CLASSPATH \${CLASSPATH}:$binDir/$file
endif
setenv PATH \${PATH}:$binDir
exit 0
EOF

exit 0









