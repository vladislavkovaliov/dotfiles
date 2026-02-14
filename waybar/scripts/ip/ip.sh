#!/usr/bin/env bash

active_conn_info=$(nmcli -t -f DEVICE,TYPE,STATE dev status | grep ":connected" | head -n1)

device=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5; exit}')

if [ -z "$device" ]; then
  echo "{\"text\":\"No network\",\"class\":\"disconnected\"}"
  
  exit 0
fi

ip_addr=$(ip -4 addr show "$device" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

echo "{\"text\":\"$device: $ip_addr\",\"class\":\"connected\"}"

