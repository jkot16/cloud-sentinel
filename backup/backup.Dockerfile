FROM amazonlinux:2

# Tools used for backup
RUN yum install -y \
    tar \
    gzip \
    curl \
    unzip \
    less \
    aws-cli && \
    yum clean all

# backup script
COPY backup/backup.sh /backup.sh

RUN chmod +x /backup.sh

# command for backup
ENTRYPOINT ["/backup.sh"]
