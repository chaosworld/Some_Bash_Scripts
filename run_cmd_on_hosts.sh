#!/bin/bash
# This script executes commands on hosts.
#

NDEBUG=${NDEBUG-1}
debug()
{
        [ $NDEBUG -ne 0 ] || {
        	echo -e "$*" >&2
        }
}

# for ssh connection
PORT=${PORT-22}
USER=${USER-root}

workdir=`dirname $0`

DESC="`sed -n '2p' $0 | sed \"s/# *//\"`"

Usage ()
{
	echo -e "$DESC\n" \
		"\nUsage: echo \"host..\" | sh $0 \"<cmd1; cmd2; cmd3..>\"]\n"\
		>&2
	exit 2
}

while test -n "$1"; do
	case "$1" in
		--help|-h)
		Usage
		;;
		--debug|-d)
		NDEBUG=0
		;;
		*)
		# for unknow argument, print usage and exit
		[ "${1:0:1}" != "-" ] || Usage
		# otherwise, break and go ahead
		break
		;;
	esac
	shift
done

CMD="$*"
debug "CMD: $CMD"
# delete last option ';' character
CMD="`echo $CMD | sed 's/;[[:space:]]*$//'`"
debug "CMD: $CMD"
[ -z "$CMD" ] && Usage


# read hosts from stdin until ^D is pressed
while read -p "enter hosts (e.g. \`10.0.0.9 host2', Ctrl+D exit): " hostlist;
do
    debug "hostlist: $hostlist"
    # for each host
    for host in $hostlist; do
	debug "host: $host"
	tmplog="`basename $0 .sh`.`date +%s`.log"
	debug "tmplog: $tmplog"
        ssh -q -f -p$PORT $USER@$host \
	  "exec 6>&1; exec > ${tmplog}; \
           echo -e \"\n--- $host ---\"; \
	   $CMD ; \
	   exec 1>&6 6>&-; \
	   cat ${tmplog}; \
	   rm -f ${tmplog}; \
	  " || echo "$0: ssh -p$PORT $USER@$host: Failed" >&2 &
    done
done
