#!/usr/bin/env bash
# This script configures authentication providers for the XNAT docker-compose configuration
#
# Author: Tom Close (tom.g.close@gmail.com)

set -e

if [ -f 'config-auth' ]; then
    # Load previously saved configuration variables
    source config-auth
else
    echo "No existing auth configuration found at '$(pwd)/config-auth'"
fi

echo ""
echo "--------------------------------------"
echo " Configuring Authentication Providers"
echo "--------------------------------------"


if [ -z "$LDAP_AUTH" ]; then
    read -p 'Would you like to configure LDAP authentication [y/N]: ' LDAP_AUTH
    if [ -z "$LDAP_AUTH" ]; then
        LDAP_AUTH=N
    else
        # Convert to upper case
        LDAP_AUTH=$(echo "$LDAP_AUTH" | tr '[:lower:]' '[:upper:]')
    fi
fi
 
if [ "$LDAP_AUTH" == 'Y' ]; then
    if [ ! -f ./auth/ldap1-provider.properties ]; then 
        cp ./example-auth-providers/ldap1-provider.properties ./auth
        echo "Copied template LDAP authentication providers file to $(pwd)/auth/ldap1-provider.properties,"
        echo "please edit it to match the LDS service of your organisation (NB: you may need to change the search.filter and search.base fields)"
     else
        echo "Using existing LDAP authentication providers file at $(pwd)/auth/ldap1-provider.properties,"
     fi
else
    if [ -f ./auth/ldap1-provider.properties ]; then 
        NEW_LOC=$(pwd)/auth/ldap1-provider.properties.$(date +"%Y-%m-%d-%H-%M-%S")
        echo "Found ldap1-provider.properties file when LDAP_AUTH is disabled, moving to $NEW_LOC to disable"
        mv ./auth/ldap1-provider.properties $NEW_LOC
    fi
fi

if [ -z "$AAF_AUTH" ]; then
    read -p 'Would you like to configure Australian Access Federation (AAF) authentication [y/N]: ' AAF_AUTH
    if [ -z "$AAF_AUTH" ]; then
        AAF_AUTH=N
    else
        # Convert to upper case
        AAF_AUTH=$(echo "$AAF_AUTH" | tr '[:lower:]' '[:upper:]')
    fi
fi

if [ "$AAF_AUTH" == 'Y' ]; then
    if [ ! -f ./auth/aaf-openid-provider.properties ]; then 
        cp ./example-auth-providers/aaf-openid-provider.properties ./auth
        echo "NOTE! Copied template AAF authentication providers file to $(pwd)/auth/aaf-openid-provider.properties,"
        echo "please edit it to include the 'clientId' and 'clientSecret' credentials you have obtained by emailing "
        echo "support@aaf.edu.au with:"
        echo "    1. Your Redirect URL (This must be HTTPS based): e.g. xnat.myuni.edu/openid-login"
        echo "    2. A descriptive name for your service: e.g MyUni's XNAT Repository"
        echo "    3. Your organisation name (Must be an AAF subscriber): e.g. MyUni University"
        echo "    4. An indication of if your service is being used for developing/testing purposes or if it is a "
        echo "       production ready service: e.g. Production"
     else
        echo "Using existing AAF authentication providers file at $(pwd)/auth/aaf-openid-provider.properties,"
     fi
else
    if [ -f ./auth/aaf-openid-provider.properties ]; then 
        NEW_LOC=$(pwd)/auth/aaf-openid-provider.properties.$(date +"%Y-%m-%d-%H-%M-%S")
        echo "Found aaf-openid-provider.properties file when AAF_AUTH is disabled, moving to $NEW_LOC to disable"
        mv ./auth/aaf-openid-provider.properties $NEW_LOC
    fi
fi


if [ -z "$GOOGLE_AUTH" ]; then
    read -p 'Would you like to configure Google authentication [y/N]: ' GOOGLE_AUTH
    if [ -z "$GOOGLE_AUTH" ]; then
        GOOGLE_AUTH=N
    else
        # Convert to upper case
        GOOGLE_AUTH=$(echo "$GOOGLE_AUTH" | tr '[:lower:]' '[:upper:]')
    fi
fi
 
if [ "$GOOGLE_AUTH" == 'Y' ]; then
    if [ ! -f ./auth/google-openid-provider.properties ]; then 
        cp ./example-auth-providers/google-openid-provider.properties ./auth
        echo "NOTE! Copied template Google authentication providers file to $(pwd)/auth/google-openid-provider.properties, please edit it to include the 'clientId' and 'clientSecret' credentials you have obtained from https://developers.google.com/identity/protocols/OpenIDConnect"
     else
        echo "Using existing GOOGLE authentication providers file at $(pwd)/auth/google-openid-provider.properties,"
     fi
else
    if [ -f ./auth/google-openid-provider.properties ]; then 
        NEW_LOC=$(pwd)/auth/google-openid-provider.properties.$(date +"%Y-%m-%d-%H-%M-%S")
        echo "Found google-openid-provider.properties file when GOOGLE_AUTH is disabled, moving to $NEW_LOC to disable"
        mv ./auth/google-openid-provider.properties $NEW_LOC
    fi
fi


echo ""
echo "---------------------------------------------"
echo " Downloading required authentication plugins"
echo "---------------------------------------------"

LDAP_AUTH_PLUGIN_VER=1.0.0
OPENID_AUTH_PLUGIN_VER=1.0.0
OPENID_AUTH_PLUGIN_RELEASE=20190409.122010-10

# OpenID auth plugin
if [ "$GOOGLE_AUTH" == 'Y' ] || [ "$AAF_AUTH" == 'Y' ]; then
    if [ ! -f ./plugins/openid-auth-plugin.jar ]; then
        echo "Downloading OpenID authentication plugin"
        pushd downloads
        wget http://dev.redboxresearchdata.com.au/nexus/service/local/repositories/snapshots/content/au/edu/qcif/xnat/openid/openid-auth-plugin/$OPENID_AUTH_PLUGIN_VER-SNAPSHOT/openid-auth-plugin-$OPENID_AUTH_PLUGIN_VER-$OPENID_AUTH_PLUGIN_RELEASE.jar
        popd
        mv ./downloads/openid-auth-plugin-$OPENID_AUTH_PLUGIN_VER-$OPENID_AUTH_PLUGIN_RELEASE.jar ./plugins/openid-auth-plugin.jar
    else
        echo "Skipping download of OpenID auth plugin as it is already present at $(pwd)/plugins/openid-auth-plugin.jar"
    fi
fi


# LDAP auth plugin
if [ "$LDAP_AUTH" == 'Y' ]; then
    if [ ! -f ./plugins/ldap-auth-plugin.jar ]; then
        echo "Downloading LDAP authentication plugin"
        pushd downloads
        wget https://bitbucket.org/xnatx/ldap-auth-plugin/downloads/xnat-ldap-auth-plugin-$LDAP_AUTH_PLUGIN_VER.jar
        popd
        mv ./downloads/xnat-ldap-auth-plugin-$LDAP_AUTH_PLUGIN_VER.jar ./plugins/ldap-auth-plugin.jar
    else
        echo "Skipping download of LDAP auth plugin as it is already present at $(pwd)/plugins/ldap-auth-plugin.jar"
    fi
fi

echo ""
echo "------------------"
echo "Auth Configuration"
echo "------------------"
echo "\
AAF_AUTH=$AAF_AUTH
GOOGLE_AUTH=$GOOGLE_AUTH
LDAP_AUTH=$LDAP_AUTH" | tee config-auth

