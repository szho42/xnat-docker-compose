FROM postgres:9.4-alpine

LABEL maintainer="Manish Kumar <rishimanish123@gmail.com>"

# Set timezone
ARG TIMEZONE
RUN apk update && apk add --no-cache --virtual .build-deps tzdata && \
    ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && \
    echo $TIMEZONE > /etc/timezone && \
    apk del .build-deps && rm -rf /var/cache/apk/*
ENV TZ $TIMEZONE

COPY XNAT.sql /docker-entrypoint-initdb.d/
