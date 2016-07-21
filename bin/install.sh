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
    return 2> /dev/null
    exit 1 
  fi
else
  echo  "$KIBRARY_DIR already exists. If you want to do a clean install, please add an option -f as below"
  echo  "/bin/bash <(curl http://kensuke1984.github.io/bin/install.sh) -f"
  return 2> /dev/null
  exit 2
fi

cd $KIBRARY_DIR

#bin
wget -P $KIBRARY_BIN http://kensuke1984.github.io/bin/javaCheck && chmod +x $KIBRARY_BIN/javaCheck
wget -P $KIBRARY_BIN http://kensuke1984.github.io/bin/anisotime && chmod +x $KIBRARY_BIN/anisotime
wget -P $KIBRARY_BIN http://kensuke1984.github.io/bin/javaCheck.jar && chmod +x $KIBRARY_BIN/javaCheck.jar


$KIBRARY_BIN/javaCheck 
if [ $? -ne 0 ]; then
  return 2> /dev/null
  exit 1
fi

#Build Kibrary
echo "Downloading build scripts in $KIBRARY_DIR"
wget http://kensuke1984.github.io/gradlew.tar
tar xf gradlew.tar
./gradlew
./gradlew build

mv build/libs/kibrary*jar $KIBRARY_BIN

readonly KIBRARY=$(ls $KIBRARY_BIN/kib*jar)

#bash
cat <<EOF >$KIBRARY_BIN/init_bash.sh
##classpath
export CLASSPATH=\$CLASSPATH:$KIBRARY
export PATH=\$PATH:$KIBRARY_BIN
EOF

#tcsh
cat <<EOF >$KIBRARY_BIN/init_tcsh.sh
##classpath
if ! \$?CLASSPATH then
    setenv CLASSPATH $KIBRARY
else
setenv CLASSPATH \${CLASSPATH}:$KIBRARY
endif
setenv PATH \${PATH}:$KIBRARY_BIN
EOF

echo Please run $KIBRARY_BIN/init_bash.sh or $KIBRARY_BIN/init_tcsh.sh to add Kibrary in PATH.
#source $KIBRARY_BIN/init_bash.sh 2>/dev/null || source $KIBRARY_BIN/init_tcsh.sh 2>/dev/null
#return 2> /dev/null
exit 0









