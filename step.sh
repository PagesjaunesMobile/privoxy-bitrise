#!/bin/bash

proxy_url="127.0.0.1"
proxy_port="8142"
privoxy_logfile="/usr/local/var/log/privoxy/logfile"
privoxy_configfile="${PWD}/privoxy_configfile"

# Configs
echo ""
echo "========== Configs =========="
echo "proxy: ${proxy_url}:${proxy_port}"
echo "logfile: ${privoxy_logfile}"
if [[ -n "${fauxpas_debug_mode}" ]]; then
	echo "fauxpas_debug_mode: ${fauxpas_debug_mode}"
fi
echo "============================="
echo ""

if [[ "${fauxpas_debug_mode}" = true ]]; then
	set -x
fi

curl -O https://raw.githubusercontent.com/mackoj/privoxy-bitrise/master/privoxy_configfile

if [[ "${fauxpas_debug_mode}" = true ]]; then
	ls
	networksetup -listallnetworkservices
fi

brew install privoxy
ln -sfv /usr/local/opt/privoxy/*.plist ~/Library/LaunchAgents
privoxy_bin=$(/usr/libexec/PlistBuddy -c "Print:ProgramArguments:0" ~/Library/LaunchAgents/homebrew.mxcl.privoxy.plist)
# privoxy_config=$(/usr/libexec/PlistBuddy -c "Print:ProgramArguments:2" ~/Desktop/homebrew.mxcl.privoxy.plist)

sudo networksetup -setwebproxy "Ethernet" ${proxy_url} ${proxy_port}
eval "${privoxy_bin} ${privoxy_configfile}"

privoxy_state=1

ps aux | grep privoxy | grep -v grep

is_privoxy_working=$(ps aux | grep privoxy | grep -v grep | wc -l | awk '{print $1}')
if [[ ${is_privoxy_working} > 0 ]]; then
	privoxy_state=0
fi

if [[ "${fauxpas_debug_mode}" = true ]]; then
	set +x
fi

sleep 5

open https://raw.githubusercontent.com/mackoj/privoxy-bitrise/master/privoxy_configfile

export PRIVOXY_LOG=${privoxy_logfile}

echo ""
echo "========== Outputs =========="
echo "PRIVOXY_LOG: ${PRIVOXY_LOG}"
echo "============================="
echo ""

exit ${privoxy_state}
