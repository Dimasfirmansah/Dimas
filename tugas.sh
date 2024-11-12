#!/bin/bash

# Configure local repository to Kartolo for Ubuntu 20.04
echo "Configuring local repository to Kartolo..."

# Setting up VLAN on eth1 using Netplan
echo "Configuring VLAN 10 on eth1 using Netplan..."

cat <<EOT > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: yes
    eth1:
      dhcp4: no
  vlans:
    eth1.10:
      id: 10
      link: eth1
      addresses:
        - 192.168.9.1/24
EOT

cat <<EOT > /etc/apt/sources.list
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-updates main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-security main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-backports main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-proposed main restricted universe multiverse
EOT

# Update repository
apt update

# Setting up VLAN and DHCP server on Ubuntu
echo "Configuring VLAN 10 on eth1 and setting up DHCP server..."

# Install DHCP server if not installed
apt install -y isc-dhcp-server

# Configure DHCP server
cat <<EOT > /etc/dhcp/dhcpd.conf
subnet 192.168.9.0 netmask 255.255.255.0 {
    range 192.168.9.10 192.168.9.100;
    option routers 192.168.9.1;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
}
EOT

# Specify the DHCP interface
echo 'INTERFACESv4="eth1.10"' > /etc/default/isc-dhcp-server

# Restart DHCP server
systemctl restart isc-dhcp-server
echo "DHCP server configured successfully."

# Enable IP forwarding
echo "Enabling IP forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward

# Configure iptables for internet sharing
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
echo "iptables configured for NAT."

# Configure route to MikroTik network
echo "Adding route to MikroTik network..."
ip route add 192.168.200.0/24 via 192.168.9.10  # Replace X with MikroTik's VLAN 10 IP

# Remote Configuration for Cisco
echo "Configuring Cisco device..."
CISCO_USER=""
CISCO_PASS=""
CISCO_IP="192.168.9.11"  # Replace with the IP address of the Cisco device in VLAN 10

sshpass -p "$CISCO_PASS" ssh -o StrictHostKeyChecking=no $CISCO_USER@$CISCO_IP << EOF
enable
configure terminal
interface fastEthernet 0/0
switchport mode trunk
exit
interface fastEthernet 0/1
switchport mode access
switchport access vlan 10
exit
end
EOF
echo "Cisco configuration completed."

# Remote Configuration for MikroTik
echo "Configuring MikroTik device..."
MIKROTIK_USER="admin"
MIKROTIK_PASS=""
MIKROTIK_IP="192.168.9.10"  # Replace Y with MikroTik's VLAN 10 IP

sshpass -p "$MIKROTIK_PASS" ssh -o StrictHostKeyChecking=no $MIKROTIK_USER@$MIKROTIK_IP << EOF
/ip dhcp-client add interface=ether1 disabled=no
/ip address add address=192.168.200.1/24 interface=ether2
/ip dhcp-server add name=dhcp1 interface=ether2 address-pool=dhcp_pool disabled=no
/ip pool add name=dhcp_pool ranges=192.168.200.10-192.168.200.100
/ip dhcp-server network add address=192.168.200.0/24 gateway=192.168.200.1
/ip route add dst-address=0.0.0.0/0 gateway=192.168.9.1
EOF
echo "MikroTik configuration completed."

echo "Automation complete."
saat creating vlan interface tolong settingkan di netplan