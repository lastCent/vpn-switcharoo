#!/bin/bash

# What is this?
# A: A quick little helper-script for switching up Mullvad-VPN connections.
#    Generates a config file for a (random) tunneled connection and applies it.
#    Requires sudo or root, since bringing interfaces up/down is no small task.

# Default Config
# -----------------------------------------------------------------------------

# Where am I?
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

# What is the server-list file name?
SERVERLIST="eu-servers.txt"

# Determine primary server (first connection)
PrimaryS="no1"

# Determine secondary server (destination)

# TODO: FUNCTIONALIZE, and call only once 
SecondaryLine="$(shuf -n 1 $SCRIPTPATH/$SERVERLIST)"
SecondaryS="$(echo "$SecondaryLine" | cut --fields=1 | cut --fields=1 --delimiter='-')"
SecondaryP="$(echo "$SecondaryLine" | cut --fields=6 )"

# Auto-update wireguard server list TODO
# Format: Name Country City PublicKey Socks5Name MultihopPort

# All flags set by arguments
# -----------------------------------------------------------------------------
DISP_HELP=false
NO_KILL=false
BRING_DOWN=false
BRING_DOWN_NK=false 

# Interpret flags and arguments 
# -----------------------------------------------------------------------------

# TODO: Regex check input?
while test $# -gt 0; do
	case "$1" in 
		"-h" | "--help" )
			DISP_HELP=true
			shift
			;;
		"-o" | "--origin" )
			# Set specific origin server
			shift 
			if test $# -gt 0; then
				PrimaryS="$#"
			else 
				echo "Origin flag given, but no server specified"
				exit 1
			fi
			shift
			;;
		"-t" | "--target" )
			shift
			# Set specific target
			if test $# -gt 1; then
				SecondaryS="$#"
				shift
				SecondaryP="$#"
				shift
			else
				echo "Incorrect number of targets. Need [Server Port]."
				exit 1
			fi
			;;	
		"-s" | "--servers" )
			# Make use of specific server list
			shift 
			if test $# -gt 0; then
				SERVERLIST="$#"
				shift
			else 
				echo "Server list flag given, but not file name specified"
				exit 1
			fi
			;;
		"-d" | "--down" )
			shift
			# Just take down the current interface 
			BRING_DOWN=true	
			;;

		"-D" | "--Down" )
			shift
			# Take down current interface, and disable kill switch
			BRING_DOWN_NK=true
			;;
		"-n" | "--nokill" )
			shift
			# Skip adding the kill switch
			NO_KILL=true
			;;
		*)
		
			echo "Unknown argument passed!"
			break
			;;
	esac
done


# Functions
# ------------------------------------------------------------------------------

# The file name of the config 
ConfFile() {
	FILE="/etc/wireguard/mullvad-$PrimaryS$SecondaryS.conf"
	echo -e "$FILE"
}

#Get current interface
InterfaceName() {
	INTERFACE="$(sudo wg show | grep 'interface' | cut --fields=2 --delimiter=' ')"
	echo -e "$INTERFACE"
}

# Create new conf file
CreateConf() {
	CONFFILE=$(ConfFile)
	sudo sh -c "umask 077; sed 's/^Endpoint.*/Endpoint = $PrimaryS-wireguard.mullvad.net:$SecondaryP/' /etc/wireguard/mullvad-$SecondaryS.conf > $CONFFILE"
	AddKillSwitch
}

# Add kill-switch
AddKillSwitch() {
	CONFFILE=$(ConfFile)
	if [ "$NO_KILL" == false ]; then
		sed -i '/\[Peer\]/i \
PostUp  =  iptables -I OUTPUT ! -o %i -m mark ! --mark $(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT && ip6tables -I OUTPUT ! -o %i -m mark ! --mark $(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT \
PreDown = iptables -D OUTPUT ! -o %i -m mark ! --mark $(wg show  %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT && ip6tables -D OUTPUT ! -o %i -m mark ! --mark $(wg show  %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT ' "$CONFFILE"
	fi
}

# Take down current interface if one is up
TearDown() {
	IF_NAME=$(InterfaceName)
	if [ "$IF_NAME" != "" ]; then
		sudo wg-quick down "$IF_NAME"
	fi
	# TODO: Kill switch override
}

# Enable this interface
BringUp() {
	sudo wg-quick up "mullvad-$PrimaryS$SecondaryS"
}

# Display help and options
PrintHelp() {
if [ "$DISP_HELP" == true ]; then
	echo "A quick vpn config generator and deployer"
	echo "Designed for use with Wireguard and Mullvad VPN"
	echo "switcharoo [options] "
	echo "Options:"
	echo "	-h / --help: Display this help page"
	echo "	-o / --origin [xyn]: Manually specify tunnel origin. Defaults to no1"
	echo "	-t / --target [xyn]: Manually specify tunnel endpoint. Default is random."
	echo "	-s / --servers [list.txt] : Manually specify server list. Defaults to eu-servers.txt"
	echo "	-d / --down: Just take down whatever the current interface is."
	echo "	-D / --Down: Same as -d, but also override an active kill-switch."
	echo "	-n / --nokill: Skip adding the kill-switch."
	exit 0
fi
}

# Execute
# ------------------------------------------------------------------------------

# Provide aid if needed
PrintHelp
# Create new config file
CreateConf
# Remove old interface
TearDown
# Bring new interface up
BringUp

exit 0 
