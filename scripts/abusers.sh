#!/bin/sh

. "./conf.sh"

now=$(date +%s)
IPS_FILE="ips.txt"
IPDATES_FILE="ipdates.txt"
IPDATES_FILE_TMP="ipdates.txt.tmp"
IPDATES_TEMPLATE="${LINUXFR_DIR}/${USERNAME}/production/current/tmp/abusers.txt"
LOGS_FILE="${WEBLOGS_DIR}/${USERNAME}/access.log"

update_ipdates_file() {
for i in $1 
do
	if grep " $i " ${IPDATES_FILE} > /dev/null 2>&1
	then
		sed -i "s@^.* $i .*\$@$now $i $(dig -x $i +short|xargs)@" ${IPDATES_FILE}
	else
		echo "$now $i $(dig -x $i +short|xargs)" >> ${IPDATES_FILE}
	fi
done

# Drop people from blacklist after 24h
test -f ${IPDATES_FILE} && mv ${IPDATES_FILE} ${IPDATES_FILE_TMP}
test -f ${IPDATES_FILE_TMP} && cat ${IPDATES_FILE_TMP} | while read l
do
	d=$(echo $l | cut -f1 -d" ")
	i=$(echo $l | cut -f2 -d" ")
	if [ $now -le $((d+3600*24)) ]
	then
		echo "$l" >> ${IPDATES_FILE}
	fi
done
rm -f "${IPDATES_FILE_TMP}"
test -f ${IPDATES_FILE} && cut -f2 -d" " < ${IPDATES_FILE} > ${IPS_FILE}
}

if [ -r "${LOGS_FILE}" ]; then
# Trop de fois la même URL
ips=$(tail -n 100000 ${LOGS_FILE}| sed -n "s/^\([^-]*\)-.*\[.*\][^\"]*\"\([^\"]*\)\".*$/\1 \2/p" | sort | uniq -c | awk '{if($1>1200) {print $2}}')
update_ipdates_file ${ips} 

# Trop de fois la même IP source
ips=$(tail -n 100000 ${LOGS_FILE}| sed -n "s/^\([^-]*\).*$/\1/p" | sort | uniq -c | awk '{if($1>2500) {print $2}}')
update_ipdates_file ${ips}
fi

# Template pour affichage côté web
> ${IPDATES_TEMPLATE}
test -f ${IPDATES_FILE} && cat "${IPDATES_FILE}"|while read d i n ;
do
  echo $(date +"%d/%m %H:%M" -d "1970/01/01 + $d seconds") " $i $n" >> ${IPDATES_TEMPLATE}
done
