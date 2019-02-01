# vpn-switcharoo

## Purpose: Allow for quick cli-based switching around of vpn connections and tunneling functions

## Targets: Wireguard & Mullvad

## Usage: 
Note: This requires root permissions

switcheroo [options]

Options:
	-h / --help: Display this help page
	-o / --origin [xyn]: Manually specify tunnel origin. Defaults to no1"
	-t / --target [xyn]: Manually specify tunnel endpoint. Default is random."
	-s / --servers [list.txt] : Manually specify server list. Defaults to eu-servers.txt"
	-d / --down: Just take down whatever the current interface is."
	-D / --Down: Same as -d, but also override an active kill-switch."
	-n / --nokill: Skip adding the kill-switch."

