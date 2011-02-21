#!/bin/bash

. "conf.sh"

# We backup the MySQL database
mysqldump ${DATABASE} | gzip > ${BACKUP_DIR}/linuxfr-weekly.dump.gz
mysqldump -F mysql | gzip > ${BACKUP_DIR}/mysql-weekly.dump.gz
gzip -c /var/lib/redis/dump.rdb > ${BACKUP_DIR}/redis-weekly.rdb.gz

# We flush the logs
#mysqladmin flush-logs
