FROM docker:latest

RUN apk add --no-cache bash lftp



COPY backup-client.sh /usr/local/bin/backup-client.sh



# Create the log file to be able to run tail

RUN touch /var/log/backup.log



# Run the command on container startup

CMD ["/usr/local/bin/backup-client.sh"]
