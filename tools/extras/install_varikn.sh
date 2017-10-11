#!/bin/bash

# Copyright 2017  Peter Smit
# Apache 2.0

set -u
set -e


# Make sure we are in the tools/ directory.
if [ `basename $PWD` == extras ]; then
  cd ..
fi

! [ `basename $PWD` == tools ] && \
  echo "You must call this script from the tools/ directory" && exit 1;

echo Downloading and installing VariKN 
if [ ! -x ./variKN ]; then
    git clone https://github.com/vsiivola/variKN.git || exit 1;
fi
pushd variKN
git pull

mkdir -p build
pushd build
cmake ..
make || exit 1
echo Done making VariKN tools 

popd
popd

(
  [ -z ${VARIKN+x} ] && \
    echo "export VARIKN=$PWD/variKN" && \
    echo "export PATH=\${PATH}:\${VARIKN}/build/bin"
) >> env.sh
