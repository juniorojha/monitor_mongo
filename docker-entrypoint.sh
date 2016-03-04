#!/bin/bash
set -e

# Setup mongodb-mms-agent
if [ ! "$MMS_API_KEY" ]; then
    {
        echo 'error: MMS_API_KEY was not specified'
        echo 'try something like: docker run -e MMS_API_KEY=... ...'
        echo '(see https://mms.mongodb.com/settings/monitoring-agent for your mmsApiKey)'
        echo
    } >&2
    exit 1
fi

config_tmp="$(mktemp)"
cat /etc/mongodb-mms/monitoring-agent.config > "$config_tmp"

set_config() {
    key="$1"
    value="$2"
    sed_escaped_value="$(echo "$value" | sed 's/[\/&]/\\&/g')"
    sed -ri "s/^($key)[ ]*=.*$/\1 = $sed_escaped_value/" "$config_tmp"
}

set_config mmsApiKey "$MMS_API_KEY"

cat "$config_tmp" > /etc/mongodb-mms/monitoring-agent.config
rm "$config_tmp"

# Setup munin-node
config_tmp="$(mktemp)"
cat /etc/munin/munin-node.conf "$config_tmp"

# allow interface address ...
echo $(ip route get 8.8.8.8|head -n 1 |awk '{print "allow ^"$7"$"}'|sed 's@\.@\\.@g') >> "$config_tmp"

cat "$config_tmp" > /etc/munin/munin-node.conf
rm "$config_tmp"

exec "$@"
