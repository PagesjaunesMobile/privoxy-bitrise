#!/bin/bash

proxy_url="127.0.0.1"
proxy_port="8142"
privoxy_logfile="/usr/local/var/log/privoxy/logfile"
privoxy_configfile="privoxy_configfile"

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

brew install privoxy
ln -sfv /usr/local/opt/privoxy/*.plist ~/Library/LaunchAgents
privoxy_bin=$(/usr/libexec/PlistBuddy -c "Print:ProgramArguments:0" ~/Library/LaunchAgents/homebrew.mxcl.privoxy.plist)
# privoxy_config=$(/usr/libexec/PlistBuddy -c "Print:ProgramArguments:2" ~/Desktop/homebrew.mxcl.privoxy.plist)
if [[ "${fauxpas_debug_mode}" = true ]]; then
	networksetup -listallnetworkservices
fi
sudo networksetup -setwebproxy "Ethernet 1" ${proxy_url} ${proxy_port}
eval "${privoxy_bin} ${privoxy_configfile}"

if [[ "${fauxpas_debug_mode}" = true ]]; then
	set +x
fi

export PRIVOXY_LOG=${privoxy_logfile}

echo ""
echo "========== Outputs =========="
echo "PRIVOXY_LOG: ${PRIVOXY_LOG}"
echo "============================="
echo ""

exit 0
