#!/bin/sh

MIKROTIK_USER="admin"
MIKROTIK_PASS="123"
MIKROTIK_IP="192.168.9.11"

expect << EOF
spawn telnet $MIKROTIK_IP
expect "login:"
send "$MIKROTIK_USER\r"
expect "Password:"
send "$MIKROTIK_PASS\r"
expect ">"
send "/interface dhcp-client add interface=ether1 disabled=no\r"
expect ">"
send "/interface address add address=192.168.200.1/24 interface=ether2\r"
expect ">"
send "/ip pool add name=dhcp_pool ranges=192.168.200.10-192.168.200.100\r"
expect ">"
send "/ip dhcp-server add name=dhcp1 interface=ether2 address-pool=dhcp_pool disabled=no\r"
expect ">"
send "/ip dhcp-server network add address=192.168.200.0/24 gateway=192.168.200.1\r"
expect ">"
send "/ip route add gateway=192.168.9.1\r"
expect ">"
send "exit\r"
expect eof
EOF
