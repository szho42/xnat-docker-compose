#!/usr/bin/env bash
# This script configures authentication providers for the XNAT docker-compose configuration
#
# Author: Tom Close (tom.g.close@gmail.com)

set -e

if [ -f 'config' ]; then
    source config
else
    echo "Please run 'configure.sh' before 'configure-auth.sh'"
    exit
fi

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
 

if [ -z "$AAF_AUTH" ]; then
    read -p 'Would you like to configure Australian Access Federation (AAF) authentication [y/N]: ' AAF_AUTH
    if [ -z "$AAF_AUTH" ]; then
        AAF_AUTH=N
    else
        # Convert to upper case
        AAF_AUTH=$(echo "$AAF_AUTH" | tr '[:lower:]' '[:upper:]')
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


echo ""
echo "---------------------------------------------------------------"
echo " Configuring properties files and downloading required plugins"
echo "---------------------------------------------------------------"

LDAP_AUTH_PLUGIN_VER=1.0.0
OPENID_AUTH_PLUGIN_VER=1.0.0
OPENID_AUTH_PLUGIN_RELEASE=20190409.122010-10


# Move existing properties files if present

if [ -f ./auth/openid-provider.properties ]; then 
    NEW_LOC=$(pwd)/auth/openid-provider.properties.$(date +"%Y-%m-%d-%H-%M-%S")
    echo "Found existing openid-provider.properties file, moving to $NEW_LOC to disable"
    mv ./auth/openid-provider.properties $NEW_LOC
fi


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

    echo "\
# xnat-openid-auth-plugin: openid-provider.properties
#
# Needs to be 'openid'
auth.method=openid
type=openid
provider.id=openid
visible=true
auto.enabled=true
auto.verified=true
# Name displayed in the UI
name=OpenID Authentication Provider
# Toggle username & password login visibility
disableUsernamePasswordLogin=false
# Site URL - the main domain, needed to build the pre-established URL below.
siteUrl=https://$SITE
preEstablishedRedirUri=/openid-login
# List of providers that appear on the login page, see options below." > ./auth/openid-provider.properties

    if [ "$AAF_AUTH" == 'Y' ]; then
        if [ "$GOOGLE_AUTH" == 'Y' ]; then
            echo "enabled=aaf,google" >> ./auth/openid-provider.properties
        else
            echo "enabled=aaf" >> ./auth/openid-provider.properties
        fi
    else
        echo "enabled=google" >> ./auth/openid-provider.properties
    fi

    if [ "$AAF_AUTH" == 'Y' ]; then
        if [ -z "$AAF_CLIENT_ID" ]; then
            echo "No saved AAF client ID. A client ID + secret can be obtained by email AAF at support@aaf.edu.au with:"
            echo "    1. Your Redirect URL (This must be HTTPS based): e.g. xnat.myuni.edu/openid-login"
            echo "    2. A descriptive name for your service: e.g MyUni's XNAT Repository"
            echo "    3. Your organisation name (Must be an AAF subscriber): e.g. MyUni University"
            echo "    4. An indication of if your service is being used for developing/testing purposes or if it is a "
            echo "       production ready service: e.g. Production"
            echo ""

            read -p 'Please enter AAF client ID: ' AAF_CLIENT_ID
        else
            echo "Loaded saved value for AAF_CLIENT_ID=$AAF_CLIENT_ID"
        fi

        if [ -z "$AAF_CLIENT_SECRET" ]; then
            read -p 'Please enter AAF client secret: ' AAF_CLIENT_SECRET
        else
            echo "Loaded saved value for AAF_CLIENT_SECRET=$AAF_CLIENT_SECRET"
        fi

        if [ -z "$AAF_DEV" ]; then
            read -p 'Connect to test AAF federation (as opposed to production) [y/N]?: ' AAF_DEV
            if [ -z "$AAF_DEV" ]; then
                AAF_DEV=N
            else
                # Convert to upper case
                AAF_DEV=$(echo "$AAF_DEV" | tr '[:lower:]' '[:upper:]')
            fi
        else
            echo "Loaded saved value for AAF_DEV=$AAF_DEV"
        fi

        if [ "$AAF_DEV" == 'Y' ]; then
            AAF_SERVER=central.test.aaf.edu.au
        else
            AAF_SERVER=central.aaf.edu.au
        fi

        echo "\
# AAF authentication
openid.aaf.clientId=$AAF_CLIENT_ID
openid.aaf.clientSecret=$AAF_CLIENT_SECRET
openid.aaf.accessTokenUri=https://$AAF_SERVER/providers/op/token
openid.aaf.userAuthUri=https://$AAF_SERVER/providers/op/authorize
openid.aaf.scopes=openid,profile,email
openid.aaf.link=<p>To sign-in using your AAF credentials, please click on the button below.</p><p><a href="/openid-login?providerId=aaf"><img src="/images/aaf_service_223x54.png" /></a></p>
# Flag that sets if we should be checking email domains
openid.aaf.shouldFilterEmailDomains=false
# Domains below are allowed to login, only checked when 'shouldFilterEmailDomains' is true
openid.aaf.allowedEmailDomains=
# Flag to force the user creation process, normally this should be set to true
openid.aaf.forceUserCreate=true
# Flag to set the enabled property of new users, set to false to allow admins to manually enable users before allowing logins, set to true to allow access right away
openid.aaf.userAutoEnabled=true
# Flag to set the verified property of new users
openid.aaf.userAutoVerified=true
# Property names to use when creating users
openid.aaf.emailProperty=email
openid.aaf.givenNameProperty=name
openid.aaf.familyNameProperty=deliberately_unknown_property" >> ./auth/openid-provider.properties 

    fi
     
    if [ "$GOOGLE_AUTH" == 'Y' ]; then

        if [ -z "$GOOGLE_CLIENT_ID" ]; then
            echo "No saved Google client ID. A client ID + secret can be obtained from "
            echo "https://developers.google.com/identity/protocols/OpenIDConnect"
            echo "via the console.developers.google.com developer console. Ensure you create"
            echo "the new credentials with the \"Authorised redirect URI\" == https://$SITE/openid-login"
            echo ""

            read -p 'Please enter Google client ID: ' GOOGLE_CLIENT_ID
        else
            echo "Loaded saved value for GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID"
        fi

        if [ -z "$GOOGLE_CLIENT_SECRET" ]; then
            read -p 'Please enter Google client secret: ' GOOGLE_CLIENT_SECRET
        else
            echo "Loaded saved value for GOOGLE_CLIENT_SECRET=$GOOGLE_CLIENT_SECRET"
        fi

        echo "\
openid.google.clientId=$GOOGLE_CLIENT_ID
openid.google.clientSecret=$GOOGLE_CLIENT_SECRET
openid.google.accessTokenUri=https://www.googleapis.com/oauth2/v3/token
openid.google.userAuthUri=https://accounts.google.com/o/oauth2/auth
openid.google.scopes=openid,profile,email
openid.google.link=<p>To sign-in using your Google credentials, please click on the button below.</p></p><p><a href="/openid-login?providerId=google"> <img src="/images/btn_google_signin_dark_normal_web.png" /> </a></p>
# Flag that sets if we should be checking email domains
openid.google.shouldFilterEmailDomains=false
# Flag to force the user creation process, normally this should be set to false
openid.google.forceUserCreate=true
# Flag to set the enabled property of new users, set to false to allow admins to manually enable users before allowing logins, set to true to allow access right away
openid.google.userAutoEnabled=false
# Flag to set the verified property of new users
openid.google.userAutoVerified=false
# Property names to use when creating users
openid.google.emailProperty=email
openid.google.givenNameProperty=given_name
openid.google.familyNameProperty=family_name" >> ./auth/openid-provider.properties

    fi

    # Restrict access to provider properties to protect username/secrets
    chmod 600 ./auth/openid-provider.properties

fi

#####################################
# LDAP authentication configuration #
#####################################

if [ "$LDAP_AUTH" == 'Y' ]; then
    # Download plugin
    if [ ! -f ./plugins/ldap-auth-plugin.jar ]; then
        echo "Downloading LDAP authentication plugin"
        pushd downloads
        wget https://bitbucket.org/xnatx/ldap-auth-plugin/downloads/xnat-ldap-auth-plugin-$LDAP_AUTH_PLUGIN_VER.jar
        popd
        mv ./downloads/xnat-ldap-auth-plugin-$LDAP_AUTH_PLUGIN_VER.jar ./plugins/ldap-auth-plugin.jar
    else
        echo "Skipping download of LDAP auth plugin as it is already present at $(pwd)/plugins/ldap-auth-plugin.jar"
    fi

    # Set up properties file
    if [ ! -f ./auth/ldap-provider.properties ]; then 
        echo "Copying LDAP authentication properties file template to '$(pwd)/auth/ldap-provider-properties'"
        echo "NOTE you will need to customise it to include appropriate values according to your organisation's LDS for: "
        echo "    1. address (address of LDS service)"
        echo "    2. userdn (account with admin access to view all accounts)"
        echo "    3. password"
        echo "    4. search.base (root of directory where users are stored)"
        echo "    5. search.filter (the attribute that the username is stored in)"
        echo "BEFORE you restart your XNAT instance otherwise it will error on startup!"
        echo ""

        echo "\
name=My University LDS
provider.id=ldap1
auth.method=ldap
address=ldaps://lds.myuni.edu:636/dc=myuni,dc=edu
userdn=uid=myroleaccount,ou=users,dc=myuni,dc=edu
password=myroleaccountpassword
search.base=ou=users
search.filter=(uid={0})
auto.enabled=true
auto.verified=true
visible=true" > ./auth/ldap-provider.properties

        # Restrict access to provider properties
        chmod 600 ./auth/ldap-provider.properties

     else
        echo "Using existing LDAP authentication providers file at $(pwd)/auth/ldap-provider.properties,"
     fi
else
    if [ -f ./auth/ldap1-provider.properties ]; then 
        NEW_LOC=$(pwd)/auth/ldap1-provider.properties.$(date +"%Y-%m-%d-%H-%M-%S")
        echo "Found ldap1-provider.properties file when LDAP_AUTH is disabled, moving to $NEW_LOC to disable"
        mv ./auth/ldap1-provider.properties $NEW_LOC
    fi
fi


echo ""
echo "------------------"
echo "Auth Configuration"
echo "------------------"
echo "\
AAF_AUTH=$AAF_AUTH
AAF_CLIENT_ID=$AAF_CLIENT_ID
AAF_CLIENT_SECRET=$AAF_CLIENT_SECRET
AAF_DEV=$AAF_DEV
GOOGLE_AUTH=$GOOGLE_AUTH
GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET=$GOOGLE_CLIENT_SECRET
LDAP_AUTH=$LDAP_AUTH" | tee config-auth

# Restrict permissions to config_auth as it contains connection secrets
chmod 600 config_auth
