#!/bin/bash

. "conf.sh"
# sauvegarde sql journalière
mysqldump ${DATABASE} | gzip > ${BACKUP_DIR}/linuxfr-daily.dump.gz
mysqldump -F mysql | gzip > ${BACKUP_DIR}/mysql-daily.dump.gz
gzip -c /var/lib/redis/dump.rdb > ${BACKUP_DIR}/redis.rdb.gz

