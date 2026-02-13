#!/usr/bin/env bash

active_conn_info=$(nmcli -t -f DEVICE,TYPE,STATE dev status | grep ":connected" | head -n1)

if [ -z "$active_conn_info" ]; then
  echo "{\"text\":\"No network\",\"class\":\"disconnected\"}"
 
  exit 0
fi

device=$(echo "$active_conn_info" | cut -d: -f1)

type=$(echo "$active_conn_info" | cut -d: -f2)


ip_addr=$(ip -4 addr show "$device" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

echo "{\"text\":\"$type: $ip_addr\",\"class\":\"connected\"}"

