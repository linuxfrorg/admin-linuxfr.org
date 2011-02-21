#!/bin/bash

. "conf.sh"
# sauvegarde sql journalière
mysqldump ${DATABASE} | gzip > ${BACKUP_DIR}/linuxfr-daily.dump.gz
mysqldump -F mysql | gzip > ${BACKUP_DIR}/mysql-daily.dump.gz
gzip -c /var/lib/redis/dump.rdb > ${BACKUP_DIR}/redis.rdb.gz

# génération des logs
#TODO ${SCRIPTS_DIR}/make-stats.sh

# compression des logs
#TODO xz ${WEBLOGS_DIR}/$(date +%Y/%m/%d -d yesterday)/combined.log
#TODO xz ${WEBLOGS_DIR}/$(date +%Y/%m/%d -d yesterday)/error.log
