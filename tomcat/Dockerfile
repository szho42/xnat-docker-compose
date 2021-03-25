FROM tomcat:7.0.108-jdk8-openjdk-buster

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
ENV TZ $TIMEZONE
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
# Launch Tomcat
CMD ["/usr/local/tomcat/bin/catalina.sh", "run"]
