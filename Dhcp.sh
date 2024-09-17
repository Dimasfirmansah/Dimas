#!/bin/bash

# Mengatur repository lokal Kartolo
echo "Menambahkan repository lokal Kartolo..."
sudo tee /etc/apt/sources.list <<EOF
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-updates main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-security main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-backports main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-proposed main restricted universe multiverse
EOF

# Update paket
echo "Memperbarui paket..."
sudo apt update

# Instal paket yang diperlukan
echo "Menginstal ISC DHCP Server dan IPTables..."
sudo apt install -y isc-dhcp-server iptables

# Konfigurasi DHCP server
echo "Mengonfigurasi DHCP server..."
sudo tee /etc/dhcp/dhcpd.conf <<EOF
subnet 192.168.9.0 netmask 255.255.255.0 {
    range 192.168.9.10 192.168.9.100;
    option routers 192.168.9.1;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
}
EOF

# Mengonfigurasi interface DHCP server
echo "Mengonfigurasi interface DHCP server..."
sudo sed -i 's/^INTERFACESv4=.*/INTERFACESv4="enp0s8"/' /etc/default/isc-dhcp-server

# Mengatur IP statis untuk internal network
echo "Mengonfigurasi IP statis untuk internal network..."
sudo tee /etc/netplan/01-netcfg.yaml <<EOF
network:
  version: 2
  ethernets:
    enp0s8:
      addresses:
        - 192.168.9.1/24
      dhcp4: no
EOF

# Terapkan konfigurasi netplan
echo "Menerapkan konfigurasi netplan..."
sudo netplan apply

# Mengaktifkan IP forwarding dan menambahkan aturan IPTables
echo "Mengonfigurasi IP forwarding dan IPTables..."
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo iptables -t nat -A POSTROUTING -o enp0s0 -j MASQUERADE
sudo iptables -A FORWARD -i enp0s8 -o enp0s0 -j ACCEPT
sudo iptables -A FORWARD -i enp0s0 -o enp0s8 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Simpan aturan IPTables
sudo iptables-save | sudo tee /etc/iptables/rules.v4

# Mulai dan aktifkan DHCP server
echo "Memulai dan mengaktifkan DHCP server..."
sudo systemctl restart isc-dhcp-server
sudo systemctl enable isc-dhcp-server

echo "Setup selesai!"
