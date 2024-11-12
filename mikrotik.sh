#!/bin/bash

# Set variables
MIKROTIK_USER="admin"
MIKROTIK_PASS="123"
MIKROTIK_IP="192.168.9.10"

# Telnet login and configuration
echo "$MIKROTIK_PASS" | telnet $MIKROTIK_IP << EOF
/interface dhcp-client add interface=ether1 disabled=no
/interface address add address=192.168.200.1/24 interface=ether2
/interface dhcp-server add name=dhcp1 interface=ether2 address-pool=dhcp_pool disabled=no
/ip pool add name=dhcp_pool ranges=192.168.200.10-192.168.200.100
/ip dhcp-server network add address=192.168.200.0/24 gateway=192.168.200.1
/ip route add gateway=192.168.9.1
EOF

echo "MikroTik configuration completed."