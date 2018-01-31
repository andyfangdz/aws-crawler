#!/usr/bin/env bash

# build.sh - packages lambda source code w/ dependencies

set +ex

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd $DIR

virtualenv_path=$DIR/tmp/env

mkdir -p tmp
rm -rf build/* || mkdir -p build

cp src/* build

pushd build
    virtualenv $virtualenv_path
    source $virtualenv_path/bin/activate
    pip install -r reqiurements.txt
    cp -r $virtualenv_path/lib/python3.6/site-packages/* .
popd

rm -rf $DIR/tmp
