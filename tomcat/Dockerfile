FROM tomcat:7-jre8-alpine

MAINTAINER Tom Close <tom.g.close@gmail.com>

ARG LOCALE

RUN apk add --no-cache postgresql-client vim tzdata ca-certificates wget 

# Install language pack
RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.25-r0/glibc-2.25-r0.apk && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.25-r0/glibc-bin-2.25-r0.apk && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.25-r0/glibc-i18n-2.25-r0.apk && \
    apk add glibc-bin-2.25-r0.apk glibc-i18n-2.25-r0.apk glibc-2.25-r0.apk

# Iterate through all locales and install them
# Note that locale -a is not available in alpine linux, use `/usr/glibc-compat/bin/locale -a` instead
COPY ./locale.md /locale.md
RUN cat /locale.md | xargs -i /usr/glibc-compat/bin/localedef -i {} -f UTF-8 {}.UTF-8

# Set locales, NOT SUPPORTED by Alpine by default
ENV LANG $LOCALE.UTF-8
ENV LANGUAGE $LOCALE.UTF-8
ENV LC_ALL $LOCALE.UTF-8

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
