FROM tomcat:7-jre8-alpine

MAINTAINER Tom Close <tom.g.close@gmail.com>

#ARG LOCALE

RUN apk add --no-cache postgresql-client vim tzdata

# Set locales
#RUN locale-gen $LOCALE.UTF-8
#ENV LANG $LOCALE.UTF-8
#ENV LANGUAGE $LOCALE.UTF-8
#ENV LC_ALL $LOCALE.UTF-8

# Make directories required for XNAT
RUN mkdir -p /data/xnat/home/config
RUN mkdir -p /data/xnat/home/work
RUN mkdir -p /data/xnat/archive
RUN mkdir -p /data/xnat/prearchive
RUN mkdir -p /data/xnat/build
RUN mkdir -p /data/xnat/cache
RUN mkdir -p /data/xnat/ftp
RUN mkdir -p /data/xnat/pipeline

EXPOSE 8080
EXPOSE 8009
RUN rm -rf $CATALINA_HOME/webapps
VOLUME "$CATALINA_HOME/webapps"

# Launch Tomcat
CMD ["/usr/local/tomcat/bin/catalina.sh", "run"]
