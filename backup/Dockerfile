FROM alpine:3.14

LABEL maintainer="Manish Kumar <rishimanish123@gmail.com>"

#install postgres client and set timezone
ARG TIMEZONE
RUN apk update \
    && apk add postgresql-client tzdata && \
    ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && \
    echo $TIMEZONE > /etc/timezone && \
    apk del .build-deps
ENV TZ $TIMEZONE

# disable default crontab
COPY backup.sh /backup
RUN chmod +x /backup

COPY crontab /var/spool/cron/crontabs/root

ENTRYPOINT ["crond", "-f", "-l", "2"]

