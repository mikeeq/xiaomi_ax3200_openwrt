#!/usr/bin/env bash

RUN_PATH=$PWD
SCRIPT_PATH=${SCRIPT_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

echo "===]> Info: RUN_PATH=$RUN_PATH"
echo "===]> Info: SCRIPT_PATH=$SCRIPT_PATH"

[ -x "$(command -v jq)" ] || echo "===]> Exit: Install jq!"

STOK="${STOK:-}"
ROUTER_IP="${ROUTER_IP:-192.168.31.1}"

echo "===]> Info: STOK=$STOK"
echo "===]> Info: ROUTER_IP=$ROUTER_IP"

echo "===]> Info: Printing device information..."

curl -sLk http://$ROUTER_IP/cgi-bin/luci/api/xqsystem/fac_info | jq
curl -sLk http://$ROUTER_IP/cgi-bin/luci/api/xqsystem/bdata | jq .

TELNET_PASSWORD=$(python3 password.py $(curl -sLk http://$ROUTER_IP/cgi-bin/luci/api/xqsystem/bdata | jq -r .SN))

echo
echo "===]> Info: telnet $ROUTER_IP"
echo "===]> Info: TELNET_USER=root"
echo "===]> Info: TELNET_PASSWORD=$TELNET_PASSWORD"
