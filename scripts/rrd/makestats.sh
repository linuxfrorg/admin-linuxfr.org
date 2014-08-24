#!/bin/bash

. "conf.sh"

export LANG=fr_FR.UTF-8
export LC_ALL=fr_FR.UTF-8

GREEN="#579d1c"
ORANGE="#ff420e"

DATE="$(date +%Y/%m/%d)"

rrdtool update ${SCRIPTS_DIR}/rrd/loadavg.rrd `awk '{printf "N:%s:%s:%s",$1,$2,$3}' /proc/loadavg` 

rrdtool graph -w 800 -h 260 -a PNG ${GRAPHS_DIR}/load.png \
	--title="Charge serveur quotidienne / LinuxFr.org (${DATE})" \
	DEF:avg1=${SCRIPTS_DIR}/rrd/loadavg.rrd:avg1:AVERAGE \
	DEF:avg5=${SCRIPTS_DIR}/rrd/loadavg.rrd:avg5:AVERAGE \
	DEF:avg15=${SCRIPTS_DIR}/rrd/loadavg.rrd:avg15:AVERAGE \
	AREA:avg1${GREEN}:"avg 1" \
	LINE1:avg1#000000 \
	GPRINT:avg1:MIN:"Min\: %lf%s" \
	GPRINT:avg1:AVERAGE:"Moy\: %lf%s" \
	GPRINT:avg1:MAX:"Max\: %lf%s" \
	GPRINT:avg1:LAST:"Dernier\: %lf%s" > /dev/null

rrdtool graph -w 800 -h 260 -a PNG ${GRAPHS_DIR}/load-week.png \
	--start -604800 --title="Charge serveur hebdomadaire / LinuxFr.org (${DATE})" \
	DEF:avg1=${SCRIPTS_DIR}/rrd/loadavg.rrd:avg1:AVERAGE \
	DEF:avg5=${SCRIPTS_DIR}/rrd/loadavg.rrd:avg5:AVERAGE \
	DEF:avg15=${SCRIPTS_DIR}/rrd/loadavg.rrd:avg15:AVERAGE \
	AREA:avg1${GREEN}:"avg 1" \
	LINE1:avg1#000000 \
	GPRINT:avg1:MIN:"Min\: %lf%s" \
	GPRINT:avg1:AVERAGE:"Moy\: %lf%s" \
	GPRINT:avg1:MAX:"Max\: %lf%s" \
	GPRINT:avg1:LAST:"Dernier\: %lf%s" > /dev/null

rrdtool graph -w 800 -h 260 -a PNG ${GRAPHS_DIR}/load-month.png \
	--start -2678400 --title="Charge serveur mensuelle / LinuxFr.org (${DATE})" \
	DEF:avg1=${SCRIPTS_DIR}/rrd/loadavg.rrd:avg1:AVERAGE \
	DEF:avg5=${SCRIPTS_DIR}/rrd/loadavg.rrd:avg5:AVERAGE \
	DEF:avg15=${SCRIPTS_DIR}/rrd/loadavg.rrd:avg15:AVERAGE \
	AREA:avg1${GREEN}:"avg 1" \
	LINE1:avg1#000000 \
	GPRINT:avg1:MIN:"Min\: %lf%s" \
	GPRINT:avg1:AVERAGE:"Moy\: %lf%s" \
	GPRINT:avg1:MAX:"Max\: %lf%s" \
	GPRINT:avg1:LAST:"Dernier\: %lf%s" > /dev/null

rrdtool graph -w 800 -h 260 -a PNG ${GRAPHS_DIR}/load-semestre.png \
	--start -16070400 --title="Charge serveur semestrielle / LinuxFr.org (${DATE})" \
	DEF:avg1=${SCRIPTS_DIR}/rrd/loadavg.rrd:avg1:AVERAGE \
	DEF:avg5=${SCRIPTS_DIR}/rrd/loadavg.rrd:avg5:AVERAGE \
	DEF:avg15=${SCRIPTS_DIR}/rrd/loadavg.rrd:avg15:AVERAGE \
	AREA:avg1${GREEN}:"avg 1" \
	LINE1:avg1#000000 \
	GPRINT:avg1:MIN:"Min\: %lf%s" \
	GPRINT:avg1:AVERAGE:"Moy\: %lf%s" \
	GPRINT:avg1:MAX:"Max\: %lf%s" \
	GPRINT:avg1:LAST:"Dernier\: %lf%s" > /dev/null

rrdtool graph -w 800 -h 260 -a PNG ${GRAPHS_DIR}/load-yearly.png \
	--start -32140800 --title="Charge serveur annuelle / LinuxFr.org (${DATE})" \
	DEF:avg1=${SCRIPTS_DIR}/rrd/loadavg.rrd:avg1:AVERAGE \
	DEF:avg5=${SCRIPTS_DIR}/rrd/loadavg.rrd:avg5:AVERAGE \
	DEF:avg15=${SCRIPTS_DIR}/rrd/loadavg.rrd:avg15:AVERAGE \
	AREA:avg1${GREEN}:"avg 1" \
	LINE1:avg1#000000 \
	GPRINT:avg1:MIN:"Min\: %lf%s" \
	GPRINT:avg1:AVERAGE:"Moy\: %lf%s" \
	GPRINT:avg1:MAX:"Max\: %lf%s" \
	GPRINT:avg1:LAST:"Dernier\: %lf%s" > /dev/null

# Reseau
rrdtool update ${SCRIPTS_DIR}/rrd/network-eth.rrd `sed '/eth0/!d;s%eth0:%%' /proc/net/dev|awk '{printf "N:%s:%s",$1,$9}'`

# Daily Graph
rrdtool graph ${GRAPHS_DIR}/network-eth-day.png --start -86400 \
	--title="Stats réseau LinuxFr.org (${DATE})" -v "bits" -a PNG -u=512000 \
	DEF:inoctets=${SCRIPTS_DIR}/rrd/network-eth.rrd:input:AVERAGE \
	DEF:outoctets=${SCRIPTS_DIR}/rrd/network-eth.rrd:output:AVERAGE \
	CDEF:a=inoctets,8,* \
	CDEF:b=outoctets,8,* \
	AREA:b${GREEN}:"Trafic sortant en bits" \
	LINE1:b#000000 \
	GPRINT:b:AVERAGE:"Moy\: %.2lf%s" \
	GPRINT:b:MAX:"Max\: %.2lf%s" \
	GPRINT:b:LAST:"Dernier\: %.2lf%s" \
	AREA:a${ORANGE}:"Trafic entrant en bits" \
	LINE1:a#000000 \
	GPRINT:a:AVERAGE:"Moy\: %.2lf%s" \
	GPRINT:a:MAX:"Max\: %.2lf%s" \
	GPRINT:a:LAST:"Dernier\: %.2lf%s" \
	-w 800 -h 260 > /dev/null

#Memoire
rrdtool update ${SCRIPTS_DIR}/rrd/meminfo.rrd `free -m|sed '/^Mem:/!d;s%Mem:%%'|awk '{printf "N:%s:%s:%s:%s:%s",$2,$3,$4,$5,$6}'`

# Daily Graph
rrdtool graph ${GRAPHS_DIR}/meminfo.png --start -86400 \
	--title="Stats mémoire LinuxFr.org (${DATE})" -v "GiB" -a PNG  \
	DEF:used=${SCRIPTS_DIR}/rrd/meminfo.rrd:used:AVERAGE \
	CDEF:g_used=used,1024,/ \
	AREA:g_used#ffd320:"Used" \
	DEF:free=${SCRIPTS_DIR}/rrd/meminfo.rrd:free:AVERAGE \
	CDEF:g_free=free,1024,/ \
	STACK:g_free${GREEN}:"Free" \
	DEF:cached=${SCRIPTS_DIR}/rrd/meminfo.rrd:cached:AVERAGE \
	CDEF:g_cached=cached,1024,/ \
	AREA:g_cached${ORANGE}:"Cached" \
	DEF:shared=${SCRIPTS_DIR}/rrd/meminfo.rrd:shared:AVERAGE \
	CDEF:g_shared=shared,1024,/ \
	AREA:g_shared#7e0021:"Shared" \
	DEF:buffers=${SCRIPTS_DIR}/rrd/meminfo.rrd:buffers:AVERAGE \
	CDEF:g_buffers=buffers,1024,/ \
	AREA:g_buffers#004586:"Buffers" \
	LINE1:g_used#000000 \
	CDEF:free_stacked=g_free,g_used,+ \
	LINE1:free_stacked#000000 \
	LINE1:g_cached#000000 \
	LINE1:g_buffers#000000 \
	LINE1:g_shared#000000 \
	-w 800 -h 260 > /dev/null

if [ ! -r "${GRAPHS_DIR}/index.html" ] ; then
	cat > "${GRAPHS_DIR}/index.html" <<EOF
<!DOCTYPE html>
<html lang="fr">
<head>
<title>Statistiques LinuxFr.org</title>
<meta charset="utf-8">
</head>

<body>

<h2 id="load">Charge serveur <a href="#load" class="anchor">¶</a></h2>

<img src="load.png" alt="Charge serveur quotidienne" /><br/>

<img src="load-week.png" alt="Charge serveur hebdomadaire" /><br/>

<img src="load-month.png" alt="Charge serveur mensuelle" /><br/>

<img src="load-semestre.png" alt="Charge serveur semestrielle" /><br/>

<img src="load-yearly.png" alt="Charge serveur annuelle" /><br/>

<h2 id="memory">Mémoire <a href="#memory" class="anchor">¶</a></h2>

<img src="meminfo.png" alt="Stats mémoire" /><br/>

<h2 id="network">Réseau <a href="#network" class="anchor">¶</a></h2>

<img src="network-eth-day.png" alt="Stats réseau" /><br/>

</body>

</html>
EOF
fi
