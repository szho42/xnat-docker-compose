# Dockerized XNAT
Use this repository to quickly deploy an [XNAT](https://xnat.org/) instance on [docker](https://www.docker.com/).

## Introduction

This repository contains files to bootstrap XNAT deployment. The build creates five containers:

- **[Tomcat](http://tomcat.apache.org/) + XNAT**: The XNAT web application
- [**Postgres**](https://www.postgresql.org/): The XNAT database
- [**nginx**](https://www.nginx.com/): Web proxy sitting in front of XNAT
- [**cAdvisor**](https://github.com/google/cadvisor/): Gathers statistics about all the other containers
- [**Prometheus**](https://prometheus.io/): Monitoring and alerts

## Prerequisites

A POSIX-based (i.e. Unix, Linux or OSX) system (or virtual machine) with the following ports open on its firewall

* 80 (http)    - to all IPs users will access your XNAT from (typically all IPs, i.e. 0.0.0.0/0)
* 443 (https)  -       "          "          "          "          "          "          "
* 8104 (DICOM) - to the IPs of devices you will send DICOMs to XNAT DICOM receiver from

The latest versions of the following packages

* [docker](https://www.docker.com/)
* [docker-compose](http://docs.docker.com/compose) (which is installed along with docker if you download it from their site)
* [openssl](https://www.openssl.org/) (required to generated SSL certificate signing request)


Sudo (administrator) access. On Linux systems you will need to run Docker with sudo by default. To avoid
having to do this you can add sudo privileges to Docker using the command

```
sudo usermod -aG docker ${USER}
```

NOTE Please ensure that your docker's "/var/lib/docker" directory is on a volume with sufficient space to hold
all the built containers + any pipeline containers you may want to install as part of the container service
(>100 GB recommended)

NB: You will need to log out and in again afterwards

## Usage


1. Clone the [xnat-docker-compose](https://github.com/MonashBI/xnat-docker-compose) repository AND cd to directory

```
$ git clone https://github.com/MonashBI/xnat-docker-compose
$ cd xnat-docker-compose
```

NOTE that all subsequent commands should be run from the repository root directory

2. Try-out "Demo" XNAT instance (optional)

If you just want to check out XNAT and don't want to bother with SSL certs, locations for securely storing the
imaging data, and the like at this point you can perform basic configuration with 

```
./configure-basic.sh
```

which will prompt you for the XNAT version you want to use (1.7.5.3 is the most recent at the time of writing)
perform the most basic configuration such as download the XNAT WAR file and create directories to store logs.

After that you can bring up the demo instance with

```
docker-compose -f docker-compose.yml up -d
```

which will build the required docker images and launch them. During initialisation
XNAT will create all SQL tables so the process can take several minutes. You can view the progress of the
start up process with 

```
docker-compose -f docker-compose.yml logs -f xnat-web
```

You should now be able to navigate the demo XNAT instance by going to http://your-host and log in using username
'admin' and password 'admin'. 

NOTE that this demo XNAT instance is NOT suitable for production use as image data will be stored in the Tomcat
container (i.e. is ephemeral) and it doesn't use SSL. 

After you have finished exploring the demo you can bring it down agin with

```
docker-compose -f docker-compose.yml down
```

3. Configure XNAT for production

To configure XNAT for production use you should run

```
./configure.sh
```

which will ask for storage locations for imaging data, caches, XNAT's SQL database and backups (in addition to the basic
config from previous step).  It will also ask you to provide SSL certificates for the SSL configuration. If you don't
already have appropriate certificates then it can generate an appropriate certificate-signing-request for you to
send to your provider. Once your provider has issued the certificates then rerun the `configure.sh` script to install
the certificate in the correct location

NOTE that the certificate must in PEM format including the full chain back to a root certificate, i.e. pasted in order within
the same file starting from site-cert, then intermediates and finally root. If only the final certificate is provided
(i.e. not the full chain), then access to the site via the web UI will likely still work (for well known providers at least)
but REST API access won't.

All configuration variables are stored in the './.env' file, which is symlinked to './config' for convenience. You can
edit most of the saved variables directly in there if they change at a later date and they will be picked up by docker-compose.
The only exception is the site name, which is also used in the ./nginx/nginx.ssl.conf, and will need to be edited in there
as well (or rerun the `configure.sh` script)

4. Bring up the XNAT instance

Once you have installed your SSL certificates in `./certs` then you are ready to bring up a production XNAT instance with

```
docker-compose up -d
```

As with the demo instance, during initialisation XNAT will create all SQL tables so the process can take several minutes.
You can view the progress of the start up process with 

```
docker-compose logs -f xnat-web
```

Once the initialisation is complete you should be able to navigate the demo XNAT instance by going to http://your-host and log
in using username 'admin' and password 'admin' (BE SURE TO CHANGE THIS IN THE ADMIN SETTINGS!!). The first time you login
you will be greeted by an initial configuration page with which you should change the Site ID and the Administrator
email address. It is important to leave all other settings the same except the Miscellaneous Settings at the bottom,
which you are free to change as desired.

Additional administration settings (including changing the 'admin' user password) can be configured from the 'Administer' menu item.

5. Configure advanced authentication options

By default user authentication is peformed against user passwords stored in XNAT's Postgres DB. While these passwords are
salted it is recommended to use an external provider to authenticate your users for security.

XNAT supports authentication by external providers via LDAP (e.g. university-wide authentication) and OpenID Connect
(e.g. Australian Access Federation and Google). In order to get this to work you will need to register your service
with the authentication provider, which typically involves them assessing your instance and checking that is suitable
(i.e. uses SSL). So you will need to have your instance up and running with SSL first before you can configure external
authentication providers.

To objtain credentials from AAF email support@aaf.edu.au with the following details:

    1. Your Redirect URL (This must be HTTPS based): e.g. xnat.myuni.edu/openid-login
    2. A descriptive name for your service: e.g MyUni's XNAT Repository
    3. Your organisation name (Must be an AAF subscriber): e.g. MyUni University
    4. An indication of if your service is being used for developing/testing purposes or if it is a
       production ready service: e.g. Production

To obtain credentials from Google visit https://developers.google.com/identity/protocols/OpenIDConnect
via the console.developers.google.com developer console. Just ensure you set
"Authorised redirect URI" == https://$SITE/openid-login.

Once you have the credentials you require, run

```
./configure-auth.sh
```

This will prompt you whether you want to enable LDAP, AAF, and/or Google authentication, and generate basic "properties" files
in the './auth' directory. After running this script you can edit these files to customise the authentication methods.

NOTE Please ensure that all the information in the properties files are correct before restarting your XNAT instance
otherwise it will error. You can rename any unfinished providers so they don't end with 'provider.properties'
to disable them.

Once the authentication has been properly configured restart the `xnat-web` container

```
docker-compose restart xnat-web
```

and then login to the Admin UI and edit the list of enabled providers (comma delimited),
e.g. "Enabled Authentication Providers": localdb,ldap1,google-openid, and restart again

6. Customisations (optional)

The default configuration is sufficient to run the deployment. However, the following files can be modified if you really want to
fine-tune the configuration.  Although this typically won't be neccessary and you are on your own from then on! ;)

    - **docker-compose.yml**: How the different containers are deployed.
    - **postgres/XNAT.sql**: Database configuration. Mainly used to customize the database user or password. See [Configuring PostgreSQL for XNAT](https://wiki.xnat.org/documentation/getting-started-with-xnat-1-7/installing-xnat-1-7/configuring-postgresql-for-xnat).
    - **tomcat/server.xml**: Configures the Tomcat server that runs the XNAT web application
    - **tomcat/xnat-conf.properties**: Configures the XNAT web application, primarily to connect to the Postgres DB
    - **tomcat/tomcat-users.xml**: [Tomcat manager](https://tomcat.apache.org/tomcat-7.0-doc/manager-howto.html) settings.
    - **tomcat/xnat-conf.properties**: XNAT database configuration properties. There is a default version
    - **prometheus/prometheus.yaml**: Prometheus configuration


## Setup postgres backup
Postgres backups are scheduled to run at 0300 hrs everyday but can be configures by modifying crontab file environment
under backup directory.

```
0 3 * * *  /backup
```

The `xnat-backup` service is configured to create nighly backups under `backups` directory, but can be configured by
overriding this value in `docker-compose.override.yml` file.

```
xnat-backup:
       volumes:
          - $BACKUP_DIR:/backups
```

## Troubleshooting


### Get a shell in a running container
To list all containers and to get container id run

```
docker ps
```

You can also grab the name and put it into ane environment variable:


```
$ NAME=$(docker ps -aqf "name=xnatdockercompose_xnat-web")
$ echo $NAME
42d07bc7710b
```

To get into a running container

```
docker exec -it <container ID> bash
docker exec -it $NAME bash
```

### Read logs

Tomcat and XNAT logs are stored in directories outside the container at `<XNAT-DOCKER-COMPOSE-REPO-ROOT>/logs`


### Controlling Instances

#### Stop Instances
Bring all the instances down (this will bring down all container and remove all the images) by running

```
docker-compose down --rmi all
```

#### Bring up instances
This will bring all instances up again. The `-d` means "detached" so you won't see any output to the terminal.

```
docker-compose up -d
```


## Monitoring

- Browse to http://localhost:9090/graph

     To view a graph of total cpu usage for each container (nginx/tomcat/postgres.cAdvisor/Prometheus) execute the
     following query in the query box `container_cpu_usage_seconds_total{container_label_com_docker_compose_project="xnatdocker"}`

- Browse to http://localhost:8082/docker/

     Docker containers running on this host are listed under Subcontainers

     Click on any subcontainer to view its metrics
