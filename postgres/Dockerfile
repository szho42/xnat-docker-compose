FROM postgres:9.4-alpine

COPY XNAT.sql /docker-entrypoint-initdb.d/

#for logging to a volume
RUN mkdir /logs
RUN chown postgres:postgres /logs
