#!/bin/bash

LC_ALL=C

GPG_RUFFY="--encrypt-key 97FE3CFD"
GPG_LUKHAS="--encrypt-key 12A22DAB"
GPG_NONO="--encrypt-key CE5B6885"
GPG_KEYS="${GPG_RUFFY} ${GPG_NONO} ${GPG_LUKHAS}"

BACKUP_ZONE="scp://backupgruik@zobe.linuxfr.org//data/backup/gruik_duplicity"
BACKUP_LOG="/var/log/backup_gruik.log"

touch ${BACKUP_LOG}

duplicity remove-all-but-n-full 1 --force ${BACKUP_ZONE} >> ${BACKUP_LOG}

PASSPHRASE=  duplicity ${GPG_KEYS} --exclude /proc --exclude /dev --exclude /sys --exclude /var/run --exclude /var/lock --exclude /cgroup --volsize 1000 --full-if-older-than $(date -d '21 days ago'  '+%Y/%m/%d') / ${BACKUP_ZONE} >> ${BACKUP_LOG}

# old version with rsync+ssh
#ionice -c3 rsync --size-only --numeric-ids --delete-before -avHz -e ssh \
#--exclude=/proc --exclude=/dev --exclude=/sys \
#--exclude=/var/lib/vservers/*/dev --exclude=/var/lib/vservers/*/proc \
#--exclude=/var/lib/vservers/*/var/cache/apt/archives \
#--exclude=/data/web/linuxfr.org/htdocs/templeet/cache \
#--exclude=/data/web/linuxfr.org/htdocs/template/rdf \
#/ root@zobe.linuxfr.org:/data/backup/gruik > /var/log/backup_gruik.log
