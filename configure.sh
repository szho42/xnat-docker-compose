#!/usr/bin/env bash

# Change to the directory where the configure file is
pushd $(dirname $0)

if [ -f '.env' ]; then
    # Load previously saved configuration variables
    source .env
else
    echo "Creating "$(pwd)/.env" to store configuration variables"
fi

if [ -z "$SITE" ]; then
    read -p 'Please enter domain name: ' SITE
else
    echo "Loaded saved value for SITE=$SITE"
fi

if [ -z "$DATA_DIR" ]; then
    read -p 'Please enter primary data directory, i.e. SHOULD BE BACKED UP!! (DATA_DIR):' DATA_DIR
else
    echo "Loaded saved value for DATA_DIR=$DATA_DIR"
fi

if [ -z "$APP_DIR" ]; then
    read -p 'Please enter "app" directory in which to store plugins, caches and logs, i.e. can be ephemeral (APP_DIR): :' APP_DIR
else
    echo "Loaded saved value for APP_DIR=$APP_DIR"
fi

if [ -z "$BACKUP_DIR" ]; then
    read -p 'Please enter postgres backup directory (BACKUP_DIR) :' BACKUP_DIR
else
    echo "Loaded saved value for BACKUP_DIR=$BACKUP_DIR"
fi

if [ -z "$TIMEZONE" ]; then
    read -p 'Please enter time-zone for server, e.g. Australia/Melbourne (TIMEZONE):' TIMEZONE
else
    echo "Loaded saved value for TIMEZONE=$TIMEZONE"
fi

if [ -z "$LOCALE" ]; then
    read -p 'Please enter locale for server, e.g. en_AU (LOCALE):' LOCALE
else
    echo "Loaded saved value for LOCALE=$LOCALE"
fi

echo "---"
echo "Writing configuration variables to $(pwd)/.env"
echo "---"
echo "\

SITE=$SITE
DATA_DIR=$DATA_DIR
APP_DIR=$APP_DIR
TIMEZONE=$TIMEZONE
LOCALE=$LOCALE" | tee .env.copy
echo "---"

echo "---"
echo "Making required data and app directories"
echo "---"

# Make all required sub-directories if they aren't present
read -p "Is it okay to make required sub-directories in $DATA_DIR and $APP_DIR (quit otherwise) [y/N]:" DIR_OKAY

if [ "$DIR_OKAY" == 'y' ]; then
    mkdir -p ./webapps
    mkdir -p ./plugins
    mkdir -p ./config/auth
    mkdir -p ./logs/xnat
    mkdir -p ./logs/tomcat
    mkdir -p $APP_DIR/pipeline
    mkdir -p $APP_DIR/build
    mkdir -p $APP_DIR/cache
    mkdir -p $APP_DIR/ftp
    mkdir -p $APP_DIR/prearchive
    mkdir -p $DATA_DIR/archive
else
    echo "Terminating configuration of XNAT docker compose"
    exit
fi

# Return to original directory
popd;

# From add_plugins.sh

#wget --quiet --no-cookies https://gitlab.erc.monash.edu.au/mbi-image/xnat-non-dicom-upload-plugin/builds/1251/artifacts/file/out/artifacts/non-dicom-uploader/non-dicom-uploader.jar -O ./plugins/non-dicom-uploader.jar

#docker pull manishkumr/xnat-qc-pipeline
