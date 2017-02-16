#!/usr/bin/env bash
# Maybe debugged with -d parameter

. "./lxc-conf.sh"

if [ "-d" = "$1" ]; then debug=1 ; fi

check_process() {
	local server="$1"
	local printname="$2"
	local uid="$3"
	local pname="$4"
	local servername
	local pids
	if [ -z "$server" ] ; then
		servername="host"
		pids="$(ps -u "$uid" -eo pid,args,cgroup|grep "$pname"|grep -vE ":/lxc/|grep"|cut -d' ' -f1)"
	else
		servername="container ${server}"
		pids="$(lxc-attach -n $server -- pgrep -u "$uid" -f "$pname")"
	fi
	if [ $? -eq 0 ] ; then
		test -n "${debug}" && printf "[OK] %s process %s (%s) user %s pid(s) %s\n" "$servername" "$printname" "$pname" "$uid" "$pids"
	else
		printf "[FAIL] %s missing process %s (%s) user %s pid(s) %s\n" "$servername" "$printname" "$pname" "$uid" "$pids"
		failure=1
		return 1
	fi
}

check_socket() {
	local server="$1"
	local servername
	local netstat
	if [ -z "$server" ] ; then
		servername="host"
		filtername="netstat_filter"
		netstat="netstat_output"
	else
		servername="container ${server}"
		filtername="${server}_netstat_filter"
		netstat="${server}_netstat_output"
	fi
	local printname="$2"
	local proto="$3"
	local localaddress="$4"
	local foreignaddress="$5"
	local state="$6"
	local expectednb="${7}"
	local expectedmax="${8:-0}"
	local filter="^${proto} .* ${localaddress}  *${foreignaddress} *${state} "
	eval $filtername="\${$filtername}\${$filtername:+|}\${filter}"
	nb=$(printf "%s" "${!netstat}"|grep -cE "${filter}")
	if [ -n "$expectednb" ] ; then
		if [ "$nb" -ne "$expectednb" ] ; then
			printf "[FAIL] %s %s: %s %s %s %s count %s (expect %s)\n" "$servername" "$printname" "$proto" "$localaddress" "$foreignaddress" "$state" "$nb" "$expectednb"
			failure=1
			return 1
		else
			test -n "${debug}" && printf "[OK] %s %s: %s %s %s %s count %s (expect %s)\n" "$servername" "$printname" "$proto" "$localaddress" "$foreignaddress" "$state" "$nb" "$expectednb"
			return 0
		fi
	else
		if [ "$nb" -gt "$expectedmax" ] ; then
			printf "[FAIL] %s %s: %s %s %s %s count %s (max %s)\n" "$servername" "$printname" "$proto" "$localaddress" "$foreignaddress" "$state" "$nb" "$expectedmax"
			failure=1
			return 1
		else
			test -n "${debug}" && printf "[OK] %s %s: %s %s %s %s count %s (max %s)\n" "$servername" "$printname" "$proto" "$localaddress" "$foreignaddress" "$state" "$nb" "$expectedmax"
			return 0
		fi
	fi
}

check_unknown_socket() {
	local server="$1"
	if [ -z "$server" ] ; then
		servername="host"
		filtername="netstat_filter"
		netstat="netstat_output"
	else
		servername="container ${server}"
		filtername="${server}_netstat_filter"
		netstat="${server}_netstat_output"
	fi
	local notfiltered="$(printf "%s" "${!netstat}"|grep -Ev "${!filtername}")"
	if [ -n "${notfiltered}" ] ; then
		printf "Unfiltered socket(s) on %s:\n%s\n" "$servername" "${notfiltered}"
		failure=1
		return 1
	fi
}

failure=0
not_listening="(CLOSE_WAIT|CLOSING|ESTABLISHED|FIN_WAIT[12]|LAST_ACK|SYN_RECV|SYN_SENT|TIME_WAIT)"

declared_lxc_containers="alpha main prod"
lxc_containers="$(lxc-ls --active|sort|xargs)"

if [ "${lxc_containers}" != "${declared_lxc_containers}" ] ; then
	printf "[WARN] LXC containers: %s - Checked containers: %s\n" "$lxc_containers" "$declared_lxc_containers"
fi
default_filter="^Active Internet connections|^Proto"

# Common or at least shared
for server in "" ${declared_lxc_containers}
do
	username="${server}_username"
	username="${!username}"
	if [ -z "${username}" ] ; then username="missingvar" ; fi

	if [ -z "${server}" ] ; then
		netstat_output="$(netstat -putan)"
		netstat_filter="${default_filter}"
	else
		eval ${server}_netstat_output="\$(lxc-attach -n $server -- netstat -putan)"
		eval ${server}_netstat_filter="\${default_filter}"
	fi

	check_process "$server" "sshd"       "root"  "/usr/sbin/sshd"
	check_socket  "$server" "sshd"       "tcp"   "0.0.0.0:22"         "0.0.0.0:\*"        "LISTEN"         1
	check_socket  "$server" "sshd"       "tcp"   "127.0.0.1:601[0-4]" "0.0.0.0:\*"        "LISTEN"         "" 5
	if [ -z "${server}" ] ; then
		check_socket "" "sshd"       "tcp6"  ":::22"              ":::\*"             "LISTEN"         1
		check_socket "" "sshd"       "tcp6"  "::1:601[0-4]"       ":::\*"             "LISTEN"         "" 5
	fi
	check_socket  "$server" "sshd"       "tcp"   "[0-9.]*:22"         "[0-9.:]*"          "$not_listening" "" 24

	check_process "$server" "ntpd"       "ntp"   "/usr/sbin/ntpd"
	check_socket  "$server" "ntpd IPv4"  "udp"   "[0-9.]*:123"     "0.0.0.0:\*"        ""               3
	if [ -z "${server}" ] ; then ntp_conn=6; else ntp_conn=3; fi
	check_socket  "$server" "ntpd IPv6"  "udp6"  "[0-9a-f:]*:123"  ":::\*"             ""               ${ntp_conn}

	check_process "$server" "crond"      "root"  "/usr/sbin/cron"

	check_process "$server" "rsyslogd"   "root"  "rsyslogd"

	if [ -z "${server}" ] ; then
		check_socket  "$server" "dnsmasq" "tcp"  "[0-9.]*:53"    "0.0.0.0:\*" "LISTEN" 1
		check_socket  "$server" "dnsmasq" "tcp6" "[0-9a-f:]*:53" ":::\*"      "LISTEN" 1
		check_socket  "$server" "dnsmasq" "udp"  "0.0.0.0:67"    "0.0.0.0:\*" ""       1
		check_socket  "$server" "dnsmasq" "udp6" "[0-9a-f:]*:53" ":::\*"      ""       1
	fi
	check_socket  "$server" "dns"        "udp"   "[0-9.:]*"        "[0-9.]*:53"        ""               "" 10
	check_socket  "$server" "dns"        "tcp"   "[0-9.:]*"        "[0-9.]*:53"        ""               "" 5

	postfix_conn="${server}_postfix_conn"
	postfix_conn="${!postfix_conn}"
	check_process "$server" "postfix master"  "root"  "postfix/master"
	check_socket  "$server" "postfix master"  "tcp"   "[0-9.:]*"         "[0-9.]*:25"        "$not_listening" "" ${postfix_conn:-3}

	if [ "${server}" = "main" ] ; then
		check_socket "$server" "postfix master"   "tcp"  "0.0.0.0:25"      "0.0.0.0:\*"        "LISTEN"         1
		check_socket "$server" "postfix master"   "tcp6" ":::25"           ":::\*"             "LISTEN"         1
		check_socket "$server" "postfix smtpd"    "tcp"  "[0-9.:]*"        "[0-9.]*:25"        "$not_listening" "" ${postfix_conn}
		check_socket "$server" "postfix smtpd"    "tcp"  "[0-9.]*:25"      "[0-9.:]*"          "$not_listening" "" ${postfix_conn}
	else
		check_socket "$server" "postfix master"   "tcp"  "127.0.0.1:25"     "0.0.0.0:\*"        "LISTEN"         1
		check_socket "$server" "postfix master"   "tcp6" "::1:25"           ":::\*"             "LISTEN"         1
	fi

	if [ "${server}" = "prod" ] || [ "${server}" = "alpha" ] || [ "${server}" = "main" ] ; then
		check_process "$server" "mysqld"     "mysql" "mysqld"
		check_socket  "$server" "mysqld"     "tcp"   "127.0.0.1:3306"  "0.0.0.0:\*"        "LISTEN"         1
	fi

	if [ "${server}" = "prod" ] || [ "${server}" = "alpha" ] ; then
		nginx_conn="${server}_nginx_conn"
		check_process "$server" "nginx"   "root" "master process"
		check_socket  "$server" "nginx"   "tcp"  "0.0.0.0:(80|443)" "0.0.0.0:\*"        "LISTEN"         2
		check_socket  "$server" "nginx"   "tcp"  "[0-9.]*:(80|443)" "[0-9.:]*"          "$not_listening" "" ${!nginx_conn}
	elif [ "${server}" = "main" ] ; then
		httpd_conn="${server}_httpd_conn"
		check_process "$server" "apache2" "www-data" "apache2"
		check_socket  "$server" "apache2" "tcp6"     ":::443"           ":::\*"             "LISTEN"         1
		check_socket  "$server" "apache2" "tcp"      "[0-9.]*:443"      "[0-9.:]*"          "$not_listening" "" ${!httpd_conn}
		check_socket  "$server" "apache2" "tcp6"     "[0-9.]*:443"      "[0-9.:]*"          "$not_listening" "" ${!httpd_conn}
	fi

	if [ "${server}" = "prod" ] || [ "${server}" = "alpha" ] ; then
		svgtex_conn="${server}_svgtex_conn"
		check_process "$server" "redis"  "redis"       "redis-server"
		check_process "$server" "svgtex" "${username}" "phantomjs"
		check_socket  "$server" "svgtex" "tcp"         "127.0.0.1:16000"  "0.0.0.0:\*"        "LISTEN"         1
		check_socket  "$server" "svgtex" "tcp"         "127.0.0.1:16000"  "127.0.0.1:[0-9]*"  "$not_listening" "" ${!svgtex_conn}

		epub_conn="${server}_epub_conn"
		check_process "$server" "epub-LinuxFr.org" "${username}" "epub-LinuxFr.org"
		check_socket  "$server" "epub-LinuxFr.org" "tcp"  "127.0.0.1:9000"   "0.0.0.0:\*"        "LISTEN"         1
		check_socket  "$server" "epub-LinuxFr.org" "tcp"  "127.0.0.1:9000"   "[0-9.:]*"          "$not_listening" "" ${!epub_conn}

		img_conn="${server}_img_conn"
		check_process "$server" "img"              "${username}" "img-LinuxFr.org"
		check_socket  "$server" "img-LinuxFr.org"  "tcp"  "127.0.0.1:8000"   "0.0.0.0:\*"        "LISTEN"         1
		check_socket  "$server" "img-LinuxFr.org"  "tcp"  "127.0.0.1:8000"   "[0-9.:]*"          "$not_listening" "" ${!img_conn}
		check_socket  "$server" "img-LinuxFr.org"  "tcp"  "[0-9:]*"          "[0-9.]*:(80|443|5281)"  "SYN_SENT"       "" 10
		check_socket  "$server" "img-LinuxFr.org"  "tcp"  "[0-9:]*"          "[0-9.]*:5281"      "$not_listening" "" ${!img_conn} #ugly fix for :5281

		check_process "$server" "rails"            "${username}" "unicorn master"

		redis_conn="${server}_redis_conn"
		check_socket  "$server" "redis-server"     "tcp"  "127.0.0.1:6379"   "0.0.0.0:\*"        "LISTEN"         1
		check_socket  "$server" "redis-server"     "tcp"  "127.0.0.1:6379"   "[0-9.:]*"          "$not_listening" "" ${!redis_conn}

		check_socket  "$server" "git"              "tcp"  "[0-9:]*"          "[0-9.]*:9418"      "$not_listening" "" 1
	fi
done

#Specific

check_process "prod" "share"  "${prod_username}" "share-linuxfr"
check_process "prod" "board"  "${prod_username}" "board-linuxfr"

check_process "main" "clamav"        "clamav"    "freshclam"

check_process "main" "sympa"         "sympa"     "sympa.pl"
check_process "main" "sympa"         "sympa"     "task_manager.pl"
check_process "main" "sympa"         "sympa"     "bulk.pl"
check_process "main" "sympa"         "sympa"     "bounced.pl"
check_process "main" "sympa"         "sympa"     "archived.pl"
#started only at first access: check_process "main" "sympa"         "sympa"     "wwsympa.fcgi"

check_process "main" "cluebringer"   "110"       "cbpolicyd"
check_process "main" "cluebringer"   "110"       "cbpolicyd"
check_socket  "main" "cluebringer"   "tcp"       "127.0.0.1:10031"  "0.0.0.0:\*"        "LISTEN"         1
check_socket  "main" "cluebringer"   "tcp"       "127.0.0.1:10031"  "127.0.0.1:[0-9]*"  "$not_listening" "" ${main_cb_conn}
check_socket  "main" "cluebringer"   "tcp"       "127.0.0.1:[0-9]*" "127.0.0.1:10031"   "$not_listening" "" ${main_cb_conn}

check_process "main" "opendkim"      "opendkim"  "opendkim"
check_socket  "main" "opendkim"      "tcp"       "127.0.0.1:8891"   "0.0.0.0:\*"        "LISTEN"         1
check_socket  "main" "opendkim"      "tcp"       "127.0.0.1:[0-9]*" "127.0.0.1:8891"    "$not_listening" "" ${main_opendkim_conn}
check_socket  "main" "opendkim"      "tcp"       "127.0.0.1:8891"   "127.0.0.1:[0-9]*"  "$not_listening" "" ${main_opendkim_conn}
check_socket  "main" "opendkim"      "udp"       "0.0.0.0:[0-9]*"   "0.0.0.0:\*"        "$not_listening" "" ${main_opendkim_conn}

for server in "" ${declared_lxc_containers}
do
	check_unknown_socket ${server}
done

exit $failure
