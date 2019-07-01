FROM alpine:3.7

MAINTAINER Manish Kumar <rishimanish123@gmail.com>

#install postgres client
RUN apk update \
 && apk add --no-cache --virtual .build-deps \
 postgresql-client

# disable default crontab
COPY backup.sh /backup
RUN chmod +x /backup

COPY crontab /var/spool/cron/crontabs/root

ENTRYPOINT ["crond", "-f", "-l", "2"]

