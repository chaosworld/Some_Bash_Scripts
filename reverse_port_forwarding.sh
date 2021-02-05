/bin/bash
# Setup reverse port forwarding
# local NAT service <----> public IP
 
# set below variables accordingly
SERVER="xxx.xxx.xx.xx"
USER="non-privilidge-user"
remoteaddr="0.0.0.0"
remote_listen_port="6022"
localaddr="127.0.0.1"
# localaddr="`/sbin/ifconfig eth0 | \
#	    grep -o 'inet addr:[^[:space:]]*' | cut -d':' -f2`"
OPTION_R_ARG="$remoteaddr:$remote_listen_port:$localaddr:22" 
 
HOST_LISTEN_PORT="`echo $OPTION_R_ARG | cut -d':' -f2`"
 
DESC="`sed -n '2,6p' $0 | sed \"s/# *//\"`"
Usage ()
{
	        echo -e "$DESC\n\nUsage: sh $0 [--restart]>\n"\
			>&2
		exit 2
}
 
NOT_RESTART=${NOT_RESTART-1}
while test -n "$1"; do
	case "$1" in
	--restart)
		NOT_RESTART=0
		;;
	-h)
		Usage
		;;
	*)
		echo "$0: $1: Unknown option" >&2
		exit 2
		;;
	esac
	shift
done
 
 
# argu: $rpf_rule $rpf_listen_port $ssh_server $ssh_user $not_restart
reverse_port_forwarding()
{
	SSH_PORT="${SSH_PORT-22}"
	rpf_rule="$1"
	rpf_listen_port="$2"
	ssh_server="$3"
	ssh_user="$4"
	not_restart="$5"
	cmd="ssh -p $SSH_PORT -fN -R $rpf_rule $ssh_user@$ssh_server"
	netcat -v -z -n -w 1 $ssh_server $rpf_listen_port
	# ps aux | grep -v grep | grep "$cmd"
	port_scan_ret="$?"
	[ $not_restart -eq 1 -a $port_scan_ret -eq 0 ] || {
		[ $not_restart -eq 1 ] || echo "Restart $rpf_rule .."
		pid="`ps aux | grep -v grep | \
		      grep \"$cmd\" | awk '{print $2}'`"
		[ -z $pid ] || { 
			echo "Killing '$cmd' .."
			kill -9 $pid
		}
		echo "Start $rpf_rule"
		$cmd
	}
}
 
date
 

sleep 1

# reverse proxy for SSH service, so local SSH service can be connected through 'ssh -p $HOST_LISTEN_PORT user@$SERVER'
reverse_port_forwarding $OPTION_R_ARG $HOST_LISTEN_PORT $SERVER $USER $NOT_RESTART

sleep 1
# for owncloud
reverse_port_forwarding 0.0.0.0:8443:127.0.0.1:443 8443 $SERVER $USER $NOT_RESTART
# owncloud port to hkhost
curl  https://$SERVER/ 2>&1 | grep "couldn't connect to host" -q && {
    SSH_PORT=2022 reverse_port_forwarding 127.0.0.1:8443:127.0.0.1:443 8443 $SERVER $USER 0
} || {
	echo "owncloud from $SERVER is alive .."
}

exit
