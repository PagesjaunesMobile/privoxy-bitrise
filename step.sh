#!/bin/bash

# defining the same proxy setting as in the config file
privoxy_logfile="/usr/local/var/log/privoxy/logfile"
proxy_url=$(ifconfig en0 | grep inet | grep -v inet6 | awk '{print $2}')
proxy_port="8242"

# local_path=$( cd $( dirname "${BASH_SOURCE[0]}" ) && pwd )
# privoxy_configfile="${local_path}/privoxy_configfile"
privoxy_configfile="${PWD}/privoxy_configfile_tmp"

# configure privoxy
ln -sf /usr/local/opt/privoxy/*.plist ~/Library/LaunchAgents
privoxy_bin=$(/usr/libexec/PlistBuddy -c "Print:ProgramArguments:0" ~/Library/LaunchAgents/homebrew.mxcl.privoxy.plist)


# Configs
echo ""
echo "========== Configs =========="
echo "proxy: ${proxy_url}:${proxy_port}"
echo "logfile: ${privoxy_logfile}"
echo "privoxy_configfile: ${privoxy_configfile}"
echo "privoxy_bin: ${privoxy_bin}"
echo "privoxy_webproxy_networkservice: ${privoxy_webproxy_networkservice}"
if [[ -n "${privoxy_debug_mode}" ]]; then
	echo "privoxy_debug_mode: ${privoxy_debug_mode}"
fi
echo "============================="
echo ""

if [[ "${privoxy_debug_mode}" = true ]]; then
	set -x
fi

# Ugly workaroud
curl https://raw.githubusercontent.com/mackoj/privoxy-bitrise/master/privoxy_configfile -o privoxy_configfile_tmp

set -x
eval "sed -i 's/__IP__/${proxy_url}/g' \"${privoxy_configfile}\""
eval "sed -i 's/__PORT__/${proxy_port}/g' \"${privoxy_configfile}\""
set +x

if [[ "${privoxy_debug_mode}" = true ]]; then
	ls
	networksetup -listallnetworkservices
fi

# setup the proxy on OSX
sudo networksetup -setwebproxy "${privoxy_webproxy_networkservice}" ${proxy_url} ${proxy_port}
eval "${privoxy_bin} ${privoxy_configfile}"

# enable the proxy more broadly
export http_proxy=http://${proxy_url}:${proxy_port}/
envman add --key http_proxy --value "http://${proxy_url}:${proxy_port}/"

#verifing if privoxy is working properly
if [[ "${privoxy_debug_mode}" = true ]]; then
	ps aux | grep privoxy | grep -v grep
fi
privoxy_state=1
is_privoxy_working=$(ps aux | grep privoxy | grep -v grep | wc -l | awk '{print $1}')
if [[ ${is_privoxy_working} > 0 ]]; then
	privoxy_state=0
fi


if [[ "${privoxy_debug_mode}" = true ]]; then
	set +x
fi

# output all the logs
export PRIVOXY_LOG=${privoxy_logfile}
envman add --key PRIVOXY_LOG --value ${privoxy_logfile}

echo ""
echo "========== Outputs =========="
echo "PRIVOXY_LOG: ${PRIVOXY_LOG}"
echo "============================="
echo ""

exit ${privoxy_state}
