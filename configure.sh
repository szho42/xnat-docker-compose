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

if [ -z "$CINDER_DIR" ]; then
    read -p 'Please enter "cinder" directory, i.e. can be ephemeral (CINDER_DIR): :' CINDER_DIR
else
    echo "Loaded saved value for CINDER_DIR=$CINDER_DIR"
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
echo "Making required data and cinder directories"
echo "---"

# Make all required sub-directories if they aren't present
read -p "Is it okay to make required sub-directories in $DATA_DIR and $CINDER (quit otherwise) [y/N]:" DIR_OKAY

if [ "$DIR_OKAY" == 'y' ]; then
    mkdir -p $CINDER_DIR/webapps
    mkdir -p $CINDER_DIR/plugins
    mkdir -p $CINDER_DIR/auth
    mkdir -p $CINDER_DIR/logs/xnat
    mkdir -p $CINDER_DIR/logs/tomcat
    mkdir -p $CINDER_DIR/pipeline
    mkdir -p $CINDER_DIR/build
    mkdir -p $DATA_DIR/archive
    mkdir -p $DATA_DIR/prearchive
    mkdir -p $DATA_DIR/cache
    mkdir -p $DATA_DIR/ftp
else
    echo "Terminating configuration of XNAT docker compose"
    exit
fi


echo "---"
echo "Writing configuration variables to $(pwd)/.env"
echo "---"
echo "\
SITE=$SITE
DATA_DIR=$DATA_DIR
CINDER_DIR=$CINDER_DIR
TIMEZONE=$TIMEZONE
LOCALE=$LOCALE" | tee .env.copy
echo "---"

# Return to original directory
popd;

