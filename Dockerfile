FROM docker:latest

RUN apk update && \
    apk add ca-certificates wget perl perl-net-ssleay perl-io-socket-ssl && \
    apk add bash lftp && rm -rf /var/cache/apk/*

RUN wget http://caspian.dotconf.net/menu/Software/SendEmail/sendEmail-v1.56.tar.gz -P /tmp/ && \
    tar -xzvf /tmp/sendEmail-v1.56.tar.gz -C /tmp/ && \
    cp -a /tmp/sendEmail-v1.56/sendEmail /usr/local/bin && \
    sed -i "1906s/.*/if (\! IO::Socket::SSL->start_SSL(\$SERVER, SSL_version => \'SSLv23:\!SSLv2\', SSL_verify_mode => 0)) {/" /usr/local/bin/sendEmail && \
    rm -rf /tmp/sendEmail*

COPY backup-client.sh /usr/local/bin/backup-client.sh
COPY backup-process.sh /usr/local/bin/backup-process.sh
COPY backup-run-one.sh  /usr/local/bin/backup-run-one.sh
COPY diskusage.sh /usr/local/bin/diskusage.sh

RUN wget https://launchpad.net/run-one/trunk/1.17/+download/run-one_1.17.orig.tar.gz && tar -zxvpf run-one_1.17.orig.tar.gz && rm run-one_1.17.orig.tar.gz


# Create the log file to be able to run tail
RUN touch /var/log/backup.log
RUN touch /var/log/diskusage.log

# Run the command on container startup
CMD ["/usr/local/bin/backup-client.sh"]
