#!/usr/bin/env bash
# This script runs the most basic part of the XNAT docker compose configuration,
# which is required to run a demo XNAT instance with 'docker-compose -f docker-compose.yml up -d'
#
# Author: Tom Close (tom.close@monash.edu)

set -e

# Change to the directory where the configure file is
pushd $(dirname $0)

echo ""
echo "##########################################"
echo " Docker-compose XNAT Configuration Script"
echo "##########################################"
echo ""


if [ -f '.env' ]; then
    # Load previously saved configuration variables
    source .env
else
    echo "No existing configuration found at '$(pwd)/.env'"
fi

echo ""
echo "------------------------------------------------------------"
echo " Configuring log directories in $(pwd)/logs"
echo "------------------------------------------------------------"

mkdir -p ./logs/tomcat
mkdir -p ./logs/xnat

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
echo ""

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

echo ""
echo "----------------------------"
echo " Downloading useful plugins"
echo "----------------------------"

mkdir -p ./plugins

CONTAINER_SERVICE_PLUGIN_VER=2.0.1
SIMPLE_UPLOAD_PLUGIN_VER=2.04

# Container service plugin
if [ ! -f ./plugins/container-service-plugin.jar ]; then
    echo "Downloading container service plugin"
    pushd downloads
    wget https://github.com/NrgXnat/container-service/releases/download/$CONTAINER_SERVICE_PLUGIN_VER/containers-$CONTAINER_SERVICE_PLUGIN_VER-fat.jar
    popd
    mv ./downloads/containers-$CONTAINER_SERVICE_PLUGIN_VER-fat.jar ./plugins/container-service-plugin.jar
else
    echo "Skipping download of the Container Service plugin as it is already present at $(pwd)/plugins/container-service-plugin.jar"
fi


# Non-DICOM uploaded plugin
if [ ! -f ./plugins/simple-upload-plugin.jar ]; then
    echo "Downloading simple upload plugin (for non-DICOM uploads)"
    pushd downloads
    # Need to fix up the version number of the plugin that is uploaded in the release
    wget https://github.com/MonashBI/xnat-simple-upload-plugin/releases/download/feature_release$SIMPLE_UPLOAD_PLUGIN_VER/xnat-simple-upload-plugin-2.0.0.jar
    popd
    mv ./downloads/xnat-simple-upload-plugin-2.0.0.jar ./plugins/simple-upload-plugin.jar
else
    echo "Skipping download of the \"simple upload\" plugin as it is already present at $(pwd)/plugins/simple-upload-plugin.jar"
fi

# QC pipeline
# docker pull manishkumr/xnat-qc-pipeline

if [ ! "$FULL_CONFIG" ]; then
    echo ""
    echo "-------------"
    echo "Configuration"
    echo "-------------"
    echo "\
XNAT_VER=$XNAT_VER
JVM_MEMGB=$JVM_MEMGB
JVM_MEMGB_INIT=$JVM_MEMGB_INIT
TIMEZONE=$TIMEZONE
LOCALE=$LOCALE" | tee .env
fi

popd
