#!/bin/bash

. "conf.sh"

export LANG=fr_FR.UTF-8
export LC_ALL=fr_FR.UTF-8

GREEN="#579d1c"
ORANGE="#ff420e"

DATE="$(date +%Y/%m/%d)"

RRD_COMMON="--width 800 --height 260 --imgformat PNG"

# CPU loadavg

XML="${SCRIPTS_DIR}/rrd/loadavg.xml"
RRD="${SCRIPTS_DIR}/rrd/loadavg.rrd"

if [ ! -f "${RRD}" ] ; then
	rrdtool restore "${XML}" "${RRD}"
fi

rrdtool update ${RRD} $(awk '{printf "N:%s:%s:%s",$1,$2,$3}' /proc/loadavg)

function graph_load() {
	rrdtool graph ${RRD_COMMON} ${GRAPHS_DIR}/$1 \
		${3:+--start }$3 --title="Charge serveur $2 / LinuxFr.org (${DATE})" \
		DEF:avg1=${RRD}:avg1:AVERAGE \
		DEF:avg5=${RRD}:avg5:AVERAGE \
		DEF:avg15=${RRD}:avg15:AVERAGE \
		AREA:avg1${GREEN}:"avg 1" \
		LINE1:avg1#000000 \
		GPRINT:avg1:MIN:"Min\: %lf%s" \
		GPRINT:avg1:AVERAGE:"Moy\: %lf%s" \
		GPRINT:avg1:MAX:"Max\: %lf%s" \
		GPRINT:avg1:LAST:"Dernier\: %lf%s" > /dev/null
}

graph_load "load.png" "quotidienne"
graph_load "load-week.png" "hebdomadaire" "-604800"
graph_load "load-month.png" "mensuelle" "-2678400"
graph_load "load-semestre.png" "semestrielle" "-16070400"
graph_load "load-yearly.png" "annuelle" "-32140800"

# Network

XML="${SCRIPTS_DIR}/rrd/network.xml"
IFACES="$(ip -family link -oneline addr|awk '{print $2}'|sed 's/:$//'|sort -u)"

for iface in ${IFACES} ; do
	RRD="${SCRIPTS_DIR}/rrd/network-${iface}.rrd"
	if [ ! -f "${RRD}" ] ; then
		rrdtool restore "${XML}" "${RRD}"
	fi
	rrdtool update ${RRD} $(sed "/^ *${iface}:/!d;s%^ *${iface}:%%" /proc/net/dev|awk '{printf "N:%s:%s",$1,$9}')

	function graph_net() {
		IFACE_NAMEX="IFACE_${iface}"
		rrdtool graph ${RRD_COMMON} ${GRAPHS_DIR}/network-${iface}-$1.png \
			${3:+--start }$3 --title="Interface ${!IFACE_NAMEX:-${iface}} $2/ LinuxFr.org (${DATE})" \
			-v "bits" \
			DEF:inoctets=${RRD}:input:AVERAGE \
			DEF:outoctets=${RRD}:output:AVERAGE \
			CDEF:a=inoctets,-8,* \
			CDEF:b=outoctets,8,* \
			AREA:b${GREEN}:"Trafic sortant en bits" \
			LINE1:b#000000 \
			GPRINT:b:AVERAGE:"Moy\: %.2lf%s" \
			GPRINT:b:MAX:"Max\: %.2lf%s" \
			GPRINT:b:LAST:"Dernier\: %.2lf%s" \
			AREA:a${ORANGE}:"Trafic entrant en bits" \
			LINE1:a#000000 \
			GPRINT:a:AVERAGE:"Moy\: %.2lf%s" \
			GPRINT:a:MIN:"Max\\: %.2lf%s" \
			GPRINT:a:LAST:"Dernier\: %.2lf%s" > /dev/null
	}

	graph_net "day" "quotidienne" "-86400"
	graph_net "week" "hebdomadaire" "-604800"
	graph_net "month" "mensuelle" "-2678400"
	graph_net "semestre" "semestrielle" "-16070400"
	graph_net "yearly" "annuelle" "-32140800"
done

#Memoire

XML="${SCRIPTS_DIR}/rrd/meminfo.xml"
RRD="${SCRIPTS_DIR}/rrd/meminfo.rrd"

if [ ! -f "${RRD}" ] ; then
	rrdtool restore "${XML}" "${RRD}"
fi

rrdtool update ${RRD} $(free -m|sed '/^Mem:/!d;s%Mem:%%'|awk '{printf "N:%s:%s:%s:%s:%s",$2,$3,$4,$5,$6}')

function graph_mem() {
        rrdtool graph ${RRD_COMMON} ${GRAPHS_DIR}/$1 \
                ${3:+--start }$3 --title="Mémoire $2 / LinuxFr.org (${DATE})" \
		-v "GiB" \
		DEF:used=${RRD}:used:AVERAGE \
		CDEF:g_used=used,1024,/ \
		AREA:g_used#ffd320:"Used" \
		DEF:free=${RRD}:free:AVERAGE \
		CDEF:g_free=free,1024,/ \
		STACK:g_free${GREEN}:"Free" \
		DEF:cached=${RRD}:cached:AVERAGE \
		CDEF:g_cached=cached,1024,/ \
		AREA:g_cached${ORANGE}:"Cached" \
		DEF:shared=${RRD}:shared:AVERAGE \
		CDEF:g_shared=shared,1024,/ \
		AREA:g_shared#7e0021:"Shared" \
		DEF:buffers=${RRD}:buffers:AVERAGE \
		CDEF:g_buffers=buffers,1024,/ \
		AREA:g_buffers#004586:"Buffers" \
		LINE1:g_used#000000 \
		CDEF:free_stacked=g_free,g_used,+ \
		LINE1:free_stacked#000000 \
		LINE1:g_cached#000000 \
		LINE1:g_buffers#000000 \
		LINE1:g_shared#000000 > /dev/null
}

graph_mem "meminfo.png" "quotidienne" "-86400"
graph_mem "meminfo-week.png" "hebdomadaire" "-604800"
graph_mem "meminfo-month.png" "mensuelle" "-2678400"
graph_mem "meminfo-semestre.png" "semestrielle" "-16070400"
graph_mem "meminfo-yearly.png" "annuelle" "-32140800"

# Index page
if [ ! -r "${GRAPHS_DIR}/index.html" ] ; then
	IFACE_HTML=
	for iface in ${IFACES} ; do
		IFACE_NAMEX="IFACE_${iface}"
		IFACE_NAME="${!IFACE_NAMEX:-${iface}}"
		IFACE_LIST="${IFACE_LIST}\
<li><a href=\"#iface${iface}\">Interface ${IFACE_NAME}</a></li>"
		IFACE_HTML="${IFACE_HTML}\
<h3 id=\"iface${iface}\">Interface ${IFACE_NAME} <a href=\"#iface${iface}\" class=\"anchor\">¶</a>&nbsp;<a href=\"#top\">^</a></h3>
<img src=\"network-${iface}-day.png\" alt=\"Stats réseau ${IFACE_NAME} quotidienne\" /><br/>
<img src=\"network-${iface}-week.png\" alt=\"Stats réseau ${IFACE_NAME} hebdomadaire\" /><br/>
<img src=\"network-${iface}-month.png\" alt=\"Stats réseau ${IFACE_NAME} mensuelle\" /><br/>
<img src=\"network-${iface}-semestre.png\" alt=\"Stats réseau ${IFACE_NAME} semestrielle\" /><br/>
<img src=\"network-${iface}-yearly.png\" alt=\"Stats réseau ${IFACE_NAME} annuelle\" /><br/>"
	done

	cat > "${GRAPHS_DIR}/index.html" <<EOF
<!DOCTYPE html>
<html lang="fr">
<head>
<title>Statistiques LinuxFr.org</title>
<meta charset="utf-8">
</head>

<body>

<h2 id="top">Sommaire</h2>
<ul>
<li><a href="#load">Charge serveur</a></li>
<li><a href="#memory">Mémoire</a></li>
<li><a href="#network">Réseau</a>
	<ul>
	${IFACE_LIST}
	</ul>
</li>
</ul>

<h2 id="load">Charge serveur <a href="#load" class="anchor">¶</a>&nbsp;<a href="#top">^</a></h2>

<img id="load-day" src="load.png" alt="Charge serveur quotidienne" /><br/>

<img id="load-week" src="load-week.png" alt="Charge serveur hebdomadaire" /><br/>

<img id="load-month" src="load-month.png" alt="Charge serveur mensuelle" /><br/>

<img id="load-semestre" src="load-semestre.png" alt="Charge serveur semestrielle" /><br/>

<img id="load-yearly" src="load-yearly.png" alt="Charge serveur annuelle" /><br/>

<h2 id="memory">Mémoire <a href="#memory" class="anchor">¶</a>&nbsp;<a href="#top">^</a></h2>

<img src="meminfo.png" alt="Mémoire quotidienne" /><br/>

<img src="meminfo-week.png" alt="Mémoire hebdomadaire" /><br/>

<img src="meminfo-month.png" alt="Mémoire mensuelle" /><br/>

<img src="meminfo-semestre.png" alt="Mémoire semestrielle" /><br/>

<img src="meminfo-yearly.png" alt="Mémoire annuelle" /><br/>

<h2 id="network">Réseau <a href="#network" class="anchor">¶</a>&nbsp;<a href="#top">^</a></h2>

${IFACE_HTML}

</body>

</html>
EOF
fi
