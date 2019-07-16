#!/usr/bin/env bash
# This scripts configures the XNAT docker compose repository to store image and DB data in external mounts
# and SSL certificates for HTTPS
#
# Author: Tom Close (tom.close@monash.edu)

set -e

source ./configure-basic.sh

# Change to the directory where the configure file is
pushd $(dirname $0)

echo ""
echo "-------------------------------------"
echo " Configuring local DB authentication"
echo "-------------------------------------"

mkdir -p ./auth

if [ ! -f ./auth/localdb-provider.properties ]; then
    echo "\
name=Database
provider.id=localdb
auth.method=db
auto.enabled=false
auto.verified=false
visible=false" >  ./auth/localdb-provider.properties
fi


echo ""
echo "-----------------------------"
echo " Set Configuration variables"
echo "-----------------------------"

if [ -z "$SITE" ]; then
    read -p 'Please enter domain name (without protocol, e.g. myuni.edu.au): ' SITE
else
    echo "Loaded saved value for SITE=$SITE"
fi

# Replace instances of server name with value of site
sed "s/server_name SITE/server_name $SITE/g" ./nginx/nginx-ssl.conf.template > ./nginx/nginx-ssl.conf

if [ -z "$DATA_DIR" ]; then
    read -p 'Please enter location for primary data directory, i.e. SHOULD BE BACKED UP!! (DATA_DIR): ' DATA_DIR
else
    echo "Loaded saved value for DATA_DIR=$DATA_DIR"
fi

if [ ! -d $DATA_DIR ]; then
    echo "Error DATA_DIR doesn't exist!"
    exit
fi

if [ -z "$APP_DIR" ]; then
    read -p 'Please enter location of "cache" directory in which to store pre-archive, plugins, caches and logs, i.e. should be large enough to hold a number of large imaging sessions and be persistent (APP_DIR): ' APP_DIR
else
    echo "Loaded saved value for APP_DIR=$APP_DIR"
fi

if [ ! -d $APP_DIR ]; then
    echo "Error APP_DIR doesn't exist!"
    exit
fi

if [ -z "$DB_BACKUP_DIR" ]; then
    read -p "Please enter location for backups of XNAT's postgres DB (DB_BACKUP_DIR): " DB_BACKUP_DIR
else
    echo "Loaded saved value for DB_BACKUP_DIR=$DB_BACKUP_DIR"
fi

if [ ! -d $DB_BACKUP_DIR ]; then
    echo "Error DB_BACKUP_DIR doesn't exist!"
    exit
fi

if [ -z "$TIMEZONE" ]; then
    read -p 'Please enter time-zone for server, e.g. Australia/Melbourne (TIMEZONE): ' TIMEZONE
else
    echo "Loaded saved value for TIMEZONE=$TIMEZONE"
fi

if [ -z "$JVM_MEMGB" ]; then
    read -p 'Please enter amount of memory to allocate to the Java virtual machine that runs the XNAT application, typically most of the available memory leaving a 3-4 GB for the other containers and general purpose (JVM_MEMGB): ' JVM_MEMGB
else
    echo "Loaded saved value for JVM_MEMGB=$JVM_MEMGB"
fi

if [ -z "$JVM_MEMGB_INIT" ]; then
    # The amount of memory allocated to the JVM on startup
    # Half the max allocated memory or minimum of 1GB
    JVM_MEMGB_INIT=$(( $JVM_MEMGB / 2 ))
    JVM_MEMGB_INIT=$(( $JVM_MEMGB_INIT>1?$JVM_MEMGB_INIT:1 ))
    echo "Assuming a value of ${JVM_MEMGB_INIT}GB for the JVM initial memory (feel free to edit)"
else
    echo "Loaded saved value for JVM_MEMGB_INIT=$JVM_MEMGB_INIT"
fi

# Write environment variables to .env so they can be read in docker-compose*.yml
echo ""
echo "-------------"
echo "Configuration"
echo "-------------"
echo "\
SITE=$SITE
DATA_DIR=$DATA_DIR
APP_DIR=$APP_DIR
DB_BACKUP_DIR=$DB_BACKUP_DIR
XNAT_VER=$XNAT_VER
JVM_MEMGB=$JVM_MEMGB
JVM_MEMGB_INIT=$JVM_MEMGB_INIT
TIMEZONE=$TIMEZONE" | tee .env

mkdir -p $DATA_DIR/archive
mkdir -p $APP_DIR/pipeline
mkdir -p $APP_DIR/prearchive
mkdir -p $APP_DIR/build
mkdir -p $APP_DIR/cache
mkdir -p $APP_DIR/ftp
mkdir -p $APP_DIR/postgres

echo ""
echo "Wrote configuration variables to $(pwd)/.env (which is symlinked to '$(pwd)/config') "
echo "and made required sub-directories in $DATA_DIR and $APP_DIR"

echo ""
echo "-----------------------"
echo " Configuring SSL certs"
echo "-----------------------"

mkdir -p ./certs

if [ ! -f ./certs/key.key ]; then
    read -p 'Please enter path to SSL key (leave empty to generate + CSR): ' KEY_PATH
    if [ -z "$KEY_PATH" ]; then
        echo '---------------------------------------------------------------------------------------------------'
        echo "Generating certificate-signing-request. You will be asked for information about your organisation, "
        echo "which will be sent to users so they can verify your service."
        echo "NOTE! Please ensure that you enter the site-name saved in your configuration ('$SITE') "
        echo "for the fully-qualified domain name (FQDN), otherwise the nginx configuration will break"
        echo '---------------------------------------------------------------------------------------------------'
        echo '---------------------------------------------------------------------------------------------------'
        echo ''
        openssl req -new -newkey rsa:2048 -nodes -keyout ./certs/key.key -out ./certs/cert-sign-request.csr
        echo "SSL key and certificate signing request generated. Please provide $(pwd)/certs/cert-sign-request.csr "
        echo "to SSL provider and rerun this script when they have provided a certificate in PEM format including "
        echo "full chain to root certificate, pasted in sequence in the same file starting in order site-cert, "
        echo "intermediates, root"
    else
        cp $KEY_PATH ./certs/key.key
    fi
fi

if [ -f ./certs/key.key ] && [ ! -f ./certs/cert.crt ]; then
    read -p "Please enter path to SSL certificate provided for $(pwd)/certs/cert-sign-request.csr in PEM format including full chain to root certificate, pasted in sequence in the same file starting in order site-cert, intermediates, root (leave empty to quit this script): " CERT_PATH
    if [ ! -z CERT_PATH ]; then
        echo "No SSL certificate provided, quitting"
    else
        cp $CERT_PATH ./certs/cert.crt
    fi
fi

if [ -f ./certs/cert.crt ]; then
    echo "After brining up the docker composition use the following command to check that the client certs are "
    echo "installed properly. You should see a chain of certificates leading back to a root certificate:"
    echo ""
    echo "    openssl s_client -showcerts -connect $SITE:443"
    echo ""
fi

# Return to original directory
popd;
