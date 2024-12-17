#!/bin/bash

set -e

GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}██   ██  █████  ██   ██ ██      ██ ██     ████████ ███████  █████  ███    ███ ${NC}"
echo -e "${GREEN}██  ██  ██   ██ ██   ██ ██      ██ ██        ██    ██      ██   ██ ████  ████ ${NC}"
echo -e "${GREEN}█████   ███████ ███████ ██      ██ ██        ██    █████   ███████ ██ ████ ██ ${NC}"
echo -e "${GREEN}██  ██  ██   ██ ██   ██ ██ ██   ██ ██        ██    ██      ██   ██ ██  ██  ██ ${NC}"
echo -e "${GREEN}██   ██ ██   ██ ██   ██ ██  █████  ██        ██    ███████ ██   ██ ██      ██ ${NC}"                                                       

echo -e "${GREEN}- Dimas Firmansah${NC}"
echo -e "${GREEN}- Gilar Bimo Tio Altan${NC}"
echo -e "${GREEN}- Jenar Adi Raditya${NC}"
echo -e "${GREEN}- Muhammad Khosy Pahala${NC}"
echo -e "${GREEN}- Rafi Ilham Muzaki${NC}"
echo -e "${GREEN}- Zein Aljundi${NC}"

set -e

# Inisialisasi awal ...
# Menambah Repositori Kartolo
cat <<EOF | sudo tee /etc/apt/sources.list
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-updates main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-security main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-backports main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-proposed main restricted universe multiverse
EOF

sudo apt update
sudo apt install isc-dhcp-server -y
sudo apt install expect -y
sudo DEBIAN_FRONTEND=noninteractive apt install -y iptables-persistent
sudo ufw allow 30014/tcp
sudo ufw allow 30015/tcp
sudo ufw allow from 192.168.42.128 to any port 30014
sudo ufw allow from 192.168.42.128 to any port 30015
sudo ufw reload

# Konfigurasi Pada Netplan
echo "Mengkonfigurasi netplan..."
cat <<EOF | sudo tee /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: true
    eth1:
      dhcp4: no
  vlans:
     eth1.10:
       id: 10
       link: eth1
       addresses: [192.168.8.1/24]
EOF

sudo netplan apply

# Konfigurasi DHCP Server
echo "Menyiapkan konfigurasi DHCP server..."
cat <<EOL | sudo tee /etc/dhcp/dhcpd.conf
# Konfigurasi subnet untuk VLAN 10
subnet 192.168.8.0 netmask 255.255.255.0 {
    range 192.168.8.2 192.168.8.200;
    option routers 192.168.8.1;
    option subnet-mask 255.255.255.0;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
    default-lease-time 600;
    max-lease-time 7200;
}

EOL

echo -e "${GREEN}██   ██  █████  ██   ██ ██      ██ ██     ████████ ███████  █████  ███    ███ ${NC}"
echo -e "${GREEN}██  ██  ██   ██ ██   ██ ██      ██ ██        ██    ██      ██   ██ ████  ████ ${NC}"
echo -e "${GREEN}█████   ███████ ███████ ██      ██ ██        ██    █████   ███████ ██ ████ ██ ${NC}"
echo -e "${GREEN}██  ██  ██   ██ ██   ██ ██ ██   ██ ██        ██    ██      ██   ██ ██  ██  ██ ${NC}"
echo -e "${GREEN}██   ██ ██   ██ ██   ██ ██  █████  ██        ██    ███████ ██   ██ ██      ██ ${NC}"                                                       

echo -e "${GREEN}- Dimas Firmansah${NC}"
echo -e "${GREEN}- Gilar Bimo Tio Altan${NC}"
echo -e "${GREEN}- Jenar Adi Raditya${NC}"
echo -e "${GREEN}- Muhammad Khosy Pahala${NC}"
echo -e "${GREEN}- Rafi Ilham Muzaki${NC}"
echo -e "${GREEN}- Zein Aljundi${NC}"

# Konfigurasi DDHCP Server
echo "Menyiapkan konfigurasi DDHCP server..."
cat <<EOL | sudo tee /etc/default/isc-dhcp-server
INTERFACESv4="eth1.10"
EOL

# Mengaktifkan IP forwarding dan mengonfigurasi IPTables
echo "Mengaktifkan IP forwarding dan mengonfigurasi IPTables..."
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A OUTPUT -p tcp --dport 30014 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 30015 -j ACCEPT

echo "Restart DHCP Server..."
sudo systemctl restart isc-dhcp-server

sudo ip route add 192.168.200.0/24 via 192.168.8.2

echo "Konfigurasi Ubuntu Selesai"

#!/bin/bash

{
    sleep 1
    echo "enable"
    sleep 1
    echo "configure terminal"
    sleep 1
    echo "int e0/1"
    sleep 1
    echo "sw mo acc"
    sleep 1
    echo "sw acc vl 10"
    sleep 1
    echo "exit"
    sleep 1
    echo "interface e0/0"
    sleep 1
    echo "sw tr encap do"
    sleep 1
    echo "sw mo tr"
    sleep 1
    echo "exit"
    sleep 1
} | telnet 192.168.42.128 30014

sleep 2

# Memastikan script keluar dengan kode status yang benar
if [ $? -eq 0 ]; then
    echo "Konfigurasi CISCO berhasil diterapkan."
else
    echo "Terjadi kesalahan saat menerapkan konfigurasi."
fi

#!/bin/bash

expect << EOF

spawn telnet 192.168.42.128 30015
expect "Mikrotik Login:"
send "admin\r"

expect "Password:"
send "\r"

expect ">"
send "n"

expect "new password"
send "123\r"

expect "repeat new password"
send "123\r"

expect ">"
send "/ip address add address=192.168.200.1/24 interface=ether2\r"

expect ">"
send "/ip address add address=192.168.8.2/24 interface=ether1\r"

expect ">"
send "/ip pool add name=dhcp_pool ranges=192.168.200.2-192.168.200.200\r"

expect ">"
send "/ip dhcp-server add name=dhcp1 interface=ether2 address-pool=dhcp_pool\r"

expect ">"
send "/ip dhcp-server network add address=192.168.200.0/24 gateway=192.168.200.1 dns-server=8.8.8.8\r"

expect ">"
send "/ip dhcp-server enable dhcp1\r"

expect ">"
send "/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade\r"

expect ">"
send "/ip route add gateway=192.168.8.1\r"

expect eof

EOF

sudo systemctl restart isc-dhcp-server
sudo systemctl restart isc-dhcp-server
sudo systemctl restart isc-dhcp-server


echo -e "${GREEN}██   ██  █████  ██   ██ ██      ██ ██     ████████ ███████  █████  ███    ███ ${NC}"
echo -e "${GREEN}██  ██  ██   ██ ██   ██ ██      ██ ██        ██    ██      ██   ██ ████  ████ ${NC}"
echo -e "${GREEN}█████   ███████ ███████ ██      ██ ██        ██    █████   ███████ ██ ████ ██ ${NC}"
echo -e "${GREEN}██  ██  ██   ██ ██   ██ ██ ██   ██ ██        ██    ██      ██   ██ ██  ██  ██ ${NC}"
echo -e "${GREEN}██   ██ ██   ██ ██   ██ ██  █████  ██        ██    ███████ ██   ██ ██      ██ ${NC}"                                                       

echo -e "${GREEN}- Dimas Firmansah${NC}"
echo -e "${GREEN}- Gilar Bimo Tio Altan${NC}"
echo -e "${GREEN}- Jenar Adi Raditya${NC}"
echo -e "${GREEN}- Muhammad Khosy Pahala${NC}"
echo -e "${GREEN}- Rafi Ilham Muzaki${NC}"
echo -e "${GREEN}- Zein Aljundi${NC}"