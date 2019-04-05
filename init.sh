#!/usr/bin/env bash

pushd $(dirname $0)

if [ -f '.env' ]; then
    echo "Please create a '.env' file in the root of the repository with " \
         "site-specific values for SITE, CINDER_DIR, DATA_DIR, TIMEZONE " \
         "and LOCALE (see example-env file for example)"j
    exit
fi

source .env
echo $CINDER_DIR

for e in $(cat .env); do
    export $e;
done

popd;

