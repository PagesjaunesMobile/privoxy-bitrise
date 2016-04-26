#!/bin/bash

privoxy_log_file="/usr/local/var/log/privoxy/logfile"
proxy_url=$(ifconfig en0 | grep inet | grep -v inet6 | awk '{print $2}')
proxy_port="8242"

ln -sf /usr/local/opt/privoxy/*.plist ~/Library/LaunchAgents
privoxy_bin=$(/usr/libexec/PlistBuddy -c "Print:ProgramArguments:0" ~/Library/LaunchAgents/homebrew.mxcl.privoxy.plist)

# local_path=$( cd $( dirname "${BASH_SOURCE[0]}" ) && pwd )
# privoxy_config_file="${local_path}/privoxy_config_file"
privoxy_config_file="${PWD}/privoxy_config_file_tmp"

# Configs
echo ""
echo "========== Configs =========="
echo "proxy: ${proxy_url}:${proxy_port}"
echo "logfile: ${privoxy_log_file}"
echo "privoxy_config_file: ${privoxy_config_file}"
echo "privoxy_bin: ${privoxy_bin}"
echo "networkservice: ${privoxy_webproxy_networkservice}"
if [[ -n "${privoxy_debug_mode}" ]]; then
	echo "privoxy_debug_mode: ${privoxy_debug_mode}"
fi
echo "============================="
echo ""

if [[ "${privoxy_debug_mode}" = true ]]; then
	set -x
fi

# Ugly workaroud
curl https://raw.githubusercontent.com/PagesjaunesMobile/privoxy-bitrise/master/privoxy_config_file -o ${privoxy_config_file}

sed -i '' -e "s/__IP__/${proxy_url}/g" ${privoxy_config_file}
sed -i '' -e "s/__PORT__/${proxy_port}/g" ${privoxy_config_file}

if [[ "${privoxy_debug_mode}" = true ]]; then
	ls
	networksetup -listallnetworkservices
fi

# setup the proxy on OSX
sudo networksetup -setwebproxy "${privoxy_webproxy_networkservice}" ${proxy_url} ${proxy_port}
eval "${privoxy_bin} ${privoxy_config_file}"

# enable the proxy more broadly
export http_proxy=http://${proxy_url}:${proxy_port}/
envman add --key http_proxy --value "http://${proxy_url}:${proxy_port}/"

#verifing if privoxy is working properly
ps aux | grep privoxy | grep -v grep

privoxy_state=1
is_privoxy_working=$(ps aux | grep privoxy | grep -v grep | wc -l | awk '{print $1}')
if [[ ${is_privoxy_working} > 0 ]]; then
	privoxy_state=0
fi

echo "privoxy_state: ${privoxy_state}"

if [[ "${privoxy_debug_mode}" = true ]]; then
	set +x
fi

# output all the logs
export PRIVOXY_LOG=${privoxy_log_file}
envman add --key PRIVOXY_LOG --value ${privoxy_log_file}

echo ""
echo "========== Outputs =========="
echo "PRIVOXY_LOG: ${PRIVOXY_LOG}"
echo "============================="
echo ""

sleep 3

exit ${privoxy_state}
