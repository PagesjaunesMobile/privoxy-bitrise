#!/bin/bash

proxy_url="127.0.0.1"
proxy_port="8142"
privoxy_logfile="/usr/local/var/log/privoxy/logfile"
local_path=$( cd $( dirname "${BASH_SOURCE[0]}" ) && pwd )
privoxy_configfile="${local_path}/privoxy_configfile"

# Configs
echo ""
echo "========== Configs =========="
echo "proxy: ${proxy_url}:${proxy_port}"
echo "logfile: ${privoxy_logfile}"
echo "privoxy_configfile: ${privoxy_configfile}"
if [[ -n "${privoxy_debug_mode}" ]]; then
	echo "privoxy_debug_mode: ${privoxy_debug_mode}"
fi
echo "============================="
echo ""

if [[ "${privoxy_debug_mode}" = true ]]; then
	set -x
fi

# curl -O https://raw.githubusercontent.com/mackoj/privoxy-bitrise/master/privoxy_configfile

if [[ "${privoxy_debug_mode}" = true ]]; then
	ls
	networksetup -listallnetworkservices
fi

# install privoxy
brew install privoxy

# configure privoxy
ln -sfv /usr/local/opt/privoxy/*.plist ~/Library/LaunchAgents
privoxy_bin=$(/usr/libexec/PlistBuddy -c "Print:ProgramArguments:0" ~/Library/LaunchAgents/homebrew.mxcl.privoxy.plist)

# setup the proxy on OSX
sudo networksetup -setwebproxy "Ethernet" ${proxy_url} ${proxy_port}
eval "${privoxy_bin} ${privoxy_configfile}"

#verifing if privoxy is working properly
privoxy_state=1
is_privoxy_working=$(ps aux | grep privoxy | grep -v grep | wc -l | awk '{print $1}')
if [[ ${is_privoxy_working} > 0 ]]; then
	privoxy_state=0
fi


if [[ "${privoxy_debug_mode}" = true ]]; then
	set +x
fi

# debug stuff
open https://raw.githubusercontent.com/mackoj/privoxy-bitrise/master/privoxy_configfile

# output all the logs
export PRIVOXY_LOG=${privoxy_logfile}
echo ""
echo "========== Outputs =========="
echo "PRIVOXY_LOG: ${PRIVOXY_LOG}"
echo "============================="
echo ""

exit ${privoxy_state}
