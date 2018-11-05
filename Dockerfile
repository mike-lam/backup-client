FROM docker:latest

RUN apk add --no-cache bash lftp

COPY backup-server.sh /usr/local/bin/backup-client.sh
COPY backup-process.sh /usr/local/bin/backup-process.sh
COPY backup-run-one.sh  /usr/local/bin/backup-run-one.sh

RUN wget https://launchpad.net/run-one/+download/run-one_1.17.orig.tar.gz && tar -zxvpf run-one_1.17.orig.tar.gz && rm run-one_1.17.orig.tar.gz


# Create the log file to be able to run tail
RUN touch /var/log/backup.log

# Run the command on container startup
CMD ["/usr/local/bin/backup-client.sh"]
