#!/bin/bash
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

if [ $FLG_F ]; then
  rm -rf $KIBRARY_DIR
fi

if [ ! -e $KIBRARY_DIR ]; then
  mkdir -p $KIBRARY_BIN
  if [ $? -ne 0 ]; then
    echo "Could not create $installDir"
    return 2>/dev/null
    exit 1 
  fi
else
  printf "%s already exists. If you want to do a clean install, please add an option \e[4;31m-f\e[m as below\n" $KIBRARY_DIR 
  echo "curl -s http://kensuke1984.github.io/bin/install.sh | /bin/sh -s -- -f"
  echo "or" 
  echo "wget -q -O - http://kensuke1984.github.io/bin/install.sh | /bin/sh -s -- -f"
  return 2>/dev/null
  exit 2
fi

cd $KIBRARY_DIR

#bin
wget -q -P $KIBRARY_BIN http://kensuke1984.github.io/bin/javaCheck && chmod +x $KIBRARY_BIN/javaCheck
wget -q -P $KIBRARY_BIN http://kensuke1984.github.io/bin/anisotime && chmod +x $KIBRARY_BIN/anisotime
wget -q -P $KIBRARY_BIN http://kensuke1984.github.io/bin/javaCheck.jar && chmod +x $KIBRARY_BIN/javaCheck.jar


$KIBRARY_BIN/javaCheck 
if [ $? -ne 0 ]; then
  echo "Installation failed."
  return 2>/dev/null
  exit 1
fi

#Build Kibrary
echo "Kibrary is in $KIBRARY_DIR"
wget -q http://kensuke1984.github.io/gradlew.tar
tar xf gradlew.tar
./gradlew -q >/dev/null
./gradlew -q build

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

if echo $SHELL | grep -qE 'bash|zsh' ; then
  echo source $KIBRARY_BIN/init_bash.sh
elif echo $SHELL | grep -qE 'tcsh' ; then
  echo source $KIBRARY_BIN/init_tcsh.sh 
else
  echo Please add $KIBRARY_BIN in PATH.
fi
#source $KIBRARY_BIN/init_bash.sh 2>/dev/null || source $KIBRARY_BIN/init_tcsh.sh 2>/dev/null
#return 2> /dev/null
exit 0









