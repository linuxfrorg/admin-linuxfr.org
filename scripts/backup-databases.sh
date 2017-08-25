#!/bin/sh
# Managed by Ansible, do not edit by hand

period="$1"
case "$period" in
  daily)
    flush=""
    continue
  ;;
  weekly)
    flush="yep"
    continue
  ;;
  *)
    echo "Unknown backup period"
    exit 1
  ;;
esac

umask 066
mysqldump "linuxfr_production" | gzip > /data/prod/backup/linuxfr-${period}.dump.gz
mysqldump -F mysql --events | gzip > /data/prod/backup/mysql-${period}.dump.gz
gzip -c /var/lib/redis/dump.rdb > /data/prod/backup/redis-${period}.rdb.gz

if [ -n "$flush" ] ; then
  mysql "linuxfr_production" -e "FLUSH QUERY CACHE;" > /dev/null
  #mysqladmin flush-logs
fi
