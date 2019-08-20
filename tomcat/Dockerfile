FROM tomcat:7-jre8-alpine

LABEL maintainer="Tom Close <tom.g.close@gmail.com>"

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

# Set timezone
ARG TIMEZONE
RUN apk update && apk add --no-cache --virtual .build-deps tzdata && \
    ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && \
    echo $TIMEZONE > /etc/timezone && \
    apk del .build-deps && rm -rf /var/cache/apk/*
ENV TZ $TIMEZONE

# Launch Tomcat
CMD ["/usr/local/tomcat/bin/catalina.sh", "run"]
