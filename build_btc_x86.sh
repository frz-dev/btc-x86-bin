#!/bin/bash

### DEFAULTS ###
BITCOIN_PATH='./'
BIN_PATH='./bin/'
BUILD_OPTIONS=""

function check_exit () {
    # "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo "ERROR: $1 failed ($status)" >&2
        exit $status
    fi
}

### ARGUMENTS PARSING ###
for i in "$@"
do
case $i in
    -btcdir=*|--bitcoin-dir=*)
      BITCOIN_PATH="${i#*=}"
      shift
    ;;
    -bindir=*|--binaries-dir=*)
      dir=${i#*=}
      if [[ "$dir" = /* ]]
        then BIN_PATH="$dir/"
        else BIN_PATH="$(pwd)/$dir/"
      fi
      shift
    ;;
    -v=*|--version=*)
      VERSION="${i#*=}"
      shift
    ;;
    *)
      BUILD_OPTIONS+=" $i"
      shift
    ;;
esac
done

### INSTALL BUILD REQUIREMENTS ###
sudo apt-get install build-essential libtool autotools-dev automake pkg-config bsdmainutils python3

### BUILD ###
cd $BITCOIN_PATH

if [ ! -z "${VERSION+x}" ]
then
  git fetch --all --tags --prune
  git checkout tags/v$VERSION
  check_exit "git checkout tags/v$VERSION"
  BIN_PATH+="/$VERSION/"
fi

./autogen.sh
check_exit "autogen.sh"

cd depends
make HOST=x86_64-linux-gnu
check_exit "make HOST=x86_64-linux-gnu"

cd ..
./configure --prefix=`pwd`/depends/x86_64-linux-gnu $BUILD_OPTIONS
check_exit "./configure --prefix=`pwd`/depends/x86_64-linux-gnu $BUILD_OPTIONS"

make
check_exit "make"

mkdir -p $BIN_PATH
cp src/bitcoind src/bitcoin-cli src/bitcoin-tx $BIN_PATH
cp src/qt/bitcoin-qt $BIN_PATH

if [ ! -z ${VERSION+x} ]
then git checkout master
     check_exit "git checkout master"
fi
