#!/bin/bash

LC_ALL=C

GPG_RUFFY="--encrypt-key 618D63E9"
GPG_LUKHAS="--encrypt-key D87E3219"
GPG_NONO="--encrypt-key 3BB7675F"
GPG_KEYS="${GPG_RUFFY} ${GPG_NONO} ${GPG_LUKHAS}"
export PASSPHRASE=

BACKUP_ZONE="scp://backupgruik@zobe.linuxfr.org//data/backup/gruik_duplicity"
BACKUP_LOG="/var/log/backup_gruik.log"
BACKUP_LOG_TMP=$(mktemp)
BACKUP_EXCLUDE="--exclude /proc --exclude /dev --exclude /sys --exclude /var/run --exclude /var/lock --exclude /cgroup --exclude **/var/cache/apt/archives/** --exclude /root/old_not_backupped"

MAILDEST="root@linuxfr.org"
DATE=$(date +%Y%m%d)
MAILSUBJECT="Duplicity log: $1 backup - date: ${DATE}"
NB_FULLBACKUP_TO_KEEP=2

LOGPART="|& tee ${BACKUP_LOG_TMP} &>> ${BACKUP_LOG}"

touch ${BACKUP_LOG}

usage()
{
  echo "Usage: $0 [full|incremental|clean]"
  echo "To restore, need private key and password"
  echo "  $0 restore [--time date_to_restore] file_to_restore directory_where_to_restore gpg_dir_with_private_key"
  exit 1
}

# While paramiko 1.15.1 not available in Ubuntu LTS, use pexpect backend instead
# https://github.com/paramiko/paramiko/issues/423

# $1 == incr or full
duplicity_backup()
{
  echo "Start $1 backup job at $(date)" | tee -a ${BACKUP_LOG_TMP} >> ${BACKUP_LOG}
  duplicity $1 ${GPG_KEYS} ${BACKUP_EXCLUDE} --ssh-backend pexpect --volsize 1000 / ${BACKUP_ZONE} |& tee -a ${BACKUP_LOG_TMP} &>> ${BACKUP_LOG}
}

duplicity_clean()
{
  echo "Start cleaning backups at $(date)" | tee -a ${BACKUP_LOG_TMP} >> ${BACKUP_LOG}
  duplicity remove-all-but-n-full ${NB_FULLBACKUP_TO_KEEP} --force --ssh-backend pexpect ${GPG_KEYS} ${BACKUP_ZONE} |& tee -a ${BACKUP_LOG_TMP} &>> ${BACKUP_LOG}
  duplicity clean --force --ssh-backend pexpect --extra-clean ${GPG_KEYS} ${BACKUP_ZONE} |& tee -a ${BACKUP_LOG_TMP} &>> ${BACKUP_LOG}
}

case "$1" in
  incremental)
    duplicity_backup incr
  ;;
  full)
    duplicity_backup full
    duplicity_clean
  ;;
  restore)
    if [[ $# -ne 4 ]] && [[ $# -ne 6 ]]
    then
      usage
    fi
    if [[ $2 == "--time" ]]
    then
      TIME="$2 $3"
      shift 2
    fi
    echo "Start restoring at $(date) file $2 into $3 ${TIME:+with }${TIME} (not logged)"
    unset PASSPHRASE
    GNUPGHOME=$4 duplicity restore ${GPG_KEYS} ${TIME} --ssh-backend pexpect --file-to-restore "$2" ${BACKUP_ZONE} "$3"
    RET=$?
    echo "End restoring at $(date) (not logged)"
    exit $?
  ;;
  clean)
    duplicity_clean
  ;;
  *)
    usage
  ;;
esac

# No private GPG keys available so don't try to verify backup
#echo "Starting verify backup at $(date)" >> ${BACKUP_LOG}
#duplicity verify ${GPG_KEYS} -vn ${BACKUP_ZONE} / &>> ${BACKUP_LOG}

duplicity collection-status --ssh-backend pexpect ${BACKUP_ZONE} |& tee -a ${BACKUP_LOG_TMP} &>> ${BACKUP_LOG}

echo "Job finished at $(date)" |& tee -a ${BACKUP_LOG_TMP} &>> ${BACKUP_LOG}

mail -s "${MAILSUBJECT}" "${MAILDEST}" < ${BACKUP_LOG_TMP}
rm ${BACKUP_LOG_TMP}

# old basic version with duplicity
#duplicity remove-all-but-n-full 1 --force ${BACKUP_ZONE} >> ${BACKUP_LOG}
#PASSPHRASE=  duplicity ${GPG_KEYS} --exclude /proc --exclude /dev --exclude /sys --exclude /var/run --exclude /var/lock --exclude /cgroup --volsize 1000 --full-if-older-than $(date -d '21 days ago'  '+%Y/%m/%d') / ${BACKUP_ZONE} >> ${BACKUP_LOG}

# old old version with rsync+ssh
#ionice -c3 rsync --size-only --numeric-ids --delete-before -avHz -e ssh \
#--exclude=/proc --exclude=/dev --exclude=/sys \
#--exclude=/var/lib/vservers/*/dev --exclude=/var/lib/vservers/*/proc \
#--exclude=/var/lib/vservers/*/var/cache/apt/archives \
#--exclude=/data/web/linuxfr.org/htdocs/templeet/cache \
#--exclude=/data/web/linuxfr.org/htdocs/template/rdf \
#/ root@zobe.linuxfr.org:/data/backup/gruik > /var/log/backup_gruik.log
