#!/usr/bin/env bash

set -e

# Change to the directory where the configure file is
pushd $(dirname $0)

echo "------------------------------------------"
echo "------------------------------------------"
echo " Docker-compose XNAT Configuration Script"
echo "------------------------------------------"
echo "------------------------------------------"
echo ""


if [ -f '.env' ]; then
    # Load previously saved configuration variables
    source .env
else
    echo "No existing configuration found at '$(pwd)/.env'"
fi

echo ""
echo "-----------------------------------------------"
echo " Configuring logs to be written at $(pwd)/logs"
echo "-----------------------------------------------"

mkdir -p ./logs/tomcat
mkdir -p ./logs/xnat
mkdir -p ./auth

echo ""
echo "---------------------------"
echo " Downloading XNAT WAR file"
echo "---------------------------"

mkdir -p ./webapps

if [ -z "$XNAT_VER" ]; then
    read -p 'Please enter version of XNAT to download and install [1.7.5.3] (XNAT_VER):' XNAT_VER
    if [ -z "$XNAT_VER" ]; then
        XNAT_VER=1.7.5.3
    fi
else
    echo "Loaded saved value for XNAT_VER=$XNAT_VER"
fi

# Download requested XNAT web version
mkdir -p downloads
WEBAPP_DOWNLOAD=./downloads/$XNAT_VER.war

if [ ! -f "$WEBAPP_DOWNLOAD" ]; then
    wget https://api.bitbucket.org/2.0/repositories/xnatdev/xnat-web/downloads/xnat-web-${XNAT_VER}.war 
    mv xnat-web-${XNAT_VER}.war $WEBAPP_DOWNLOAD
else
    echo "Skipping download of $WEBAPP_DOWNLOAD as it has already been downloaded"
fi

# Clear out existing webapps and add link to new webapp
sudo rm -r ./webapps
mkdir -p ./webapps
cp $WEBAPP_DOWNLOAD ./webapps/ROOT.war

echo "Moved v$XNAT_VER WAR file to '$(pwd)/webapps/ROOT.war', to upgrade to a later version of XNAT simply replace it with a new WAR file"
echo "NB: Configuration can be terminated at this stage if you only require a demo XNAT instance (i.e. one brought up by running 'docker-compose -f docker-compose.yml up -d')"

echo ""
echo "----------------------------"
echo " Downloading useful plugins"
echo "----------------------------"

mkdir -p ./plugins

CONTAINER_SERVICE_PLUGIN_VER=2.0.1
LDAP_AUTH_PLUGIN_VER=1.0.0
SIMPLE_UPLOAD_PLUGIN_VER=2.04

# Container service plugin
if [ ! -f ./plugins/container-service-plugin.jar ]; then
    echo "Downloading container service plugin"
    pushd downloads
    wget https://github.com/NrgXnat/container-service/releases/download/$CONTAINER_SERVICE_PLUGIN_VER/containers-$CONTAINER_SERVICE_PLUGIN_VER-fat.jar
    popd
    mv ./downloads/containers-$CONTAINER_SERVICE_PLUGIN_VER-fat.jar ./plugins/container-service-plugin.jar
fi


# LDAP auth plugin
if [ ! -f ./plugins/ldap-auth-plugin.jar ]; then
    echo "Downloading container service plugin"
    pushd downloads
    wget https://bitbucket.org/xnatx/ldap-auth-plugin/downloads/xnat-ldap-auth-plugin-$LDAP_AUTH_PLUGIN_VER.jar
    popd
    mv ./downloads/xnat-ldap-auth-plugin-$LDAP_AUTH_PLUGIN_VER.jar ./plugins/ldap-auth-plugin.jar
fi


# Non-DICOM uploaded plugin
if [ ! -f ./plugins/simple-upload-plugin.jar ]; then
    echo "Downloading simple upload plugin (for non-DICOM uploads)"
    pushd downloads
    # Need to fix up the version number of the plugin that is uploaded in the release
    wget https://github.com/MonashBI/xnat-simple-upload-plugin/releases/download/feature_release$SIMPLE_UPLOAD_PLUGIN_VER/xnat-simple-upload-plugin-2.0.0.jar
    popd
    mv ./downloads/xnat-simple-upload-plugin-2.0.0.jar ./plugins/simple-upload-plugin.jar
fi

# QC pipeline
docker pull manishkumr/xnat-qc-pipeline

echo "Downloaded plugins for the XNAT container service, simple file uploads, and LDAP authentication providers"

echo ""
echo "-------------------------"
echo " Configuration variables"
echo "-------------------------"

if [ -z "$SITE" ]; then
    read -p 'Please enter domain name: ' SITE
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

if [ -z "$LOCALE" ]; then
    read -p 'Please enter locale for server, e.g. en_AU (LOCALE): ' LOCALE
else
    echo "Loaded saved value for LOCALE=$LOCALE"
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

echo "Recording the following configuration:"
echo "\
SITE=$SITE
DATA_DIR=$DATA_DIR
APP_DIR=$APP_DIR
DB_BACKUP_DIR=$DB_BACKUP_DIR
XNAT_VER=$XNAT_VER
JVM_MEMGB=$JVM_MEMGB
JVM_MEMGB_INIT=$JVM_MEMGB_INIT
TIMEZONE=$TIMEZONE
LOCALE=$LOCALE" | tee .env

mkdir -p $DATA_DIR/archive
mkdir -p $APP_DIR/pipeline
mkdir -p $APP_DIR/prearchive
mkdir -p $APP_DIR/build
mkdir -p $APP_DIR/cache
mkdir -p $APP_DIR/ftp
mkdir -p $APP_DIR/postgres

echo ""
echo "Wrote configuration variables to $(pwd)/.env and made required sub-directories in $DATA_DIR and $APP_DIR"

echo ""
echo "-----------------------"
echo " Configuring SSL certs"
echo "-----------------------"

mkdir -p ./certs

if [ ! -f ./certs/key.key ]; then
    read -p 'Please enter path to SSL key (leave empty to generate + CSR): ' KEY_PATH
    if [ -z "$KEY_PATH" ]; then
        openssl req -new -newkey rsa:2048 -nodes -keyout ./certs/key.key -out ./certs/cert-sign-request.csr
        echo "SSL key and certificate signing request generated. Please provide $(pwd)/certs/cert-sign-request.csr to SSL provider and rerun this script when they have provided a certificate in PEM format including full chain to root certificate, pasted in sequence in the same file starting in order site-cert, intermediates, root"
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
    echo "After brining up the docker composition use the following command to check that the client certs are installed properly. You should see a chain of certificates leading back to a root certificate:"
    echo "openssl s_client -showcerts -connect $SITE:443"
fi

# Return to original directory
popd;
