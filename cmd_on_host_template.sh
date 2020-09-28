#!/bin/bash
# Distribute tool template
# Usage: hostlist="host1 host2.." sh $0 [--yes|-y]

hostlist="${hostlist-}"
CONFIRM=${CONFIRM-}

SSHPORT="${SSHPORT-22}"
SSHUSER="${SSHUSER-root}"

DESC="`sed -n '2,3p' $0 | sed \"s/# *//\"`"
Usage ()
{
	echo -e "$DESC\n\n" \
		>&2
	exit 2
}

while test -n "$1"; do
        case "$1" in
        --yes|-y)
		CONFIRM="Yes"
		;;
	--help|-h)
		Usage
		;;
	*)
		echo "$1: Unknown option" >&2
		exit 2
		;;
	esac
	shift
done

[ -n "$hostlist" ] || {
	echo "hostlist is not defined" >&2
	exit 2
}

[ -n "$CONFIRM" ] ||  read -p "Input 'Yes' if you want to proceed: " CONFIRM
[ "$CONFIRM" == "Yes" ] || {
        echo "Only 'Yes' allow to continue, exit.." >&2
        exit 2
}

# distribute something to host
for host in $hostlist; do
	# do something
	ssh -f -p$SSHPORT  $SSHUSER@$host \
		":; \
		" || echo "$0: ssh $SSHUSER@$host: Failed" 
	
	usleep 500000
done
