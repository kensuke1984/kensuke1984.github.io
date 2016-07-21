#!/bin/bash
#set -e

readonly KIBRARY_DIR=$HOME/.Kibrary
readonly KIBRARY_BIN=$KIBRARY_DIR/bin

while getopts f OPT
do
  case $OPT in
    "f" ) readonly FLG_F="TRUE" 
  esac
done

if [ $FLG_F ]; then
  rm -rf $KIBRARY_DIR
fi

if [ ! -e $KIBRARY_DIR ]; then
  mkdir -p $KIBRARY_BIN
  if [ $? -ne 0 ]; then
    echo "Could not create $installDir"
    exit 1 
  fi
else
  echo  "$KIBRARY_DIR already exists. If you want to do a clean install, please add an option -f"
  exit 2
fi

cd $KIBRARY_DIR

#bin
wget -P $KIBRARY_BIN http://kensuke1984.github.io/bin/javaCheck && chmod +x $KIBRARY_BIN/javaCheck
wget -P $KIBRARY_BIN http://kensuke1984.github.io/bin/anisotime && chmod +x $KIBRARY_BIN/anisotime
wget -P $KIBRARY_BIN http://kensuke1984.github.io/bin/javaCheck.jar && chmod +x $KIBRARY_BIN/javaCheck.jar


$KIBRARY_BIN/javaCheck 
if [ $? -ne 0 ]; then
  exit 1
fi

#Build Kibrary
echo "Downloading build scripts in $KIBRARY_DIR"
wget http://kensuke1984.github.io/gradlew.tar
tar xf gradlew.tar
./gradlew
./gradlew build

mv build/libs/kibrary*jar $KIBRARY_BIN

#bash
cat <<EOF >$KIBRARY_BIN/init_bash.sh
##classpath
export CLASSPATH=\$CLASSPATH:$KIBRARY_BIN/$file
export PATH=\$PATH:$KIBRARY_BIN
EOF

#tcsh
cat <<EOF >$KIBRARY_BIN/init_tcsh.sh
##classpath
if ! \$?CLASSPATH then
    setenv CLASSPATH $KIBRARY_BIN/$file
else
setenv CLASSPATH \${CLASSPATH}:$KIBRARY_BIN/$file
endif
setenv PATH \${PATH}:$KIBRARY_BIN
exit 0
EOF

source $KIBRARY_BIN/init_bash.sh 2>/dev/null || source $KIBRARY_BIN/init_tcsh.sh 2>/dev/null

#exit 0









