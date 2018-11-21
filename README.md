# backup-client

in the docker-compose-yml use 
 
```yaml
  backup_client:
    image: 'mxl125/backup-client:latest'
    deploy:
      mode: 'global'
    environment:
      - FTP_SERVER ip of ftp-server to send backups to
      - FTP_USER userid for ftp loging
      - FTP_PASSWD passwd for ftp loging
      - SLEEP_INIT how long to sleep waiting for containers to fully start (i.e. 3m)
      - SLEEP how long to sleep before taking another backups (i.e. 60m)
      - LOG_SIZE  nbr of lines to keep in logs (i.e. 10000)
      - USED_PERCENTAGE_THRESHOLD when disk space % > threshold send email
      - FROM email of sender
      - TO email to receive notification when disk space % > threshold
      - SMTP_USER gmail user (without @gmail.com) 
      - SMTP_PASS   gmail password

    volumes:
      - '/var/run/docker.sock:/var/run/docker.sock'
      - '/etc:/usr/local/data'
      - 'backup_client-log:/var/log'

  backup-server:
    see the mxl125/backup-server image doc

```

Thanks to:
  http://www.debianadmin.com/how-to-sendemail-from-the-command-line-using-a-gmail-account-and-others.html
  https://github.com/vivekyad4v/docker-cron-sendEmail-shell-scripts
  
