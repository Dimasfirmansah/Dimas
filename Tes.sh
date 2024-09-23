#!/bin/bash

set -e

# Fungsi untuk menampilkan pesan sukses
print_success() {
    echo -e "\e[32m[SUCCESS]\e[0m $1"
}

# Fungsi untuk menampilkan pesan error
print_error() {
    echo -e "\e[31m[ERROR]\e[0m $1"
}

# Fungsi untuk menampilkan pesan peringatan
print_warning() {
    echo -e "\e[33m[WARNING]\e[0m $1"
}

# Memperkenalkan diri
print_success "Selamat datang! Script ini dirancang oleh Dimas. Melanjutkan proses setup..."

# Menambahkan repository lokal Kartolo
print_success "Menambahkan repository lokal Kartolo..."
{
    cat <<EOF | sudo tee /etc/apt/sources.list
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-updates main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-security main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-backports main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-proposed main restricted universe multiverse
EOF
} &> /dev/null

print_success "Memperbarui daftar paket..."
sudo apt update &> /dev/null

print_success "Menginstal ISC DHCP Server, IPTables, dan iptables-persistent..."
sudo apt install -y isc-dhcp-server iptables iptables-persistent &> /dev/null

print_success "Mengonfigurasi DHCP server..."
{
    cat <<EOF | sudo tee /etc/dhcp/dhcpd.conf
subnet 192.168.9.0 netmask 255.255.255.0 {
    range 192.168.9.10 192.168.9.100;
    option routers 192.168.9.1;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
}
EOF
} &> /dev/null

print_success "Mengonfigurasi interface DHCP server..."
sudo sed -i 's/^INTERFACESv4=.*/INTERFACESv4="enp0s8"/' /etc/default/isc-dhcp-server

print_success "Mengonfigurasi IP statis untuk internal network..."
{
    cat <<EOF | sudo tee /etc/netplan/50-cloud-init.yaml
network:
  version: 2
  ethernets:
    enp0s3:
     dhcp4: true
    enp0s8:
      addresses:
        - 192.168.9.1/24
      dhcp4: no
EOF
} &> /dev/null

print_success "Menerapkan konfigurasi netplan..."
sudo netplan apply &> /dev/null

# Restart DHCP server
print_success "Merestart DHCP server menggunakan /etc/init.d/isc-dhcp-server..."
sudo /etc/init.d/isc-dhcp-server restart &> /dev/null 

# Mengaktifkan IP forwarding dan mengonfigurasi IPTables
print_success "Mengaktifkan IP forwarding dan mengonfigurasi IPTables..."
{
    sudo sysctl -w net.ipv4.ip_forward=1
    echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
    sudo iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
} &> /dev/null

print_success "Menyimpan aturan IPTables..."
sudo netfilter-persistent save &> /dev/null

print_success "Setup selesai! Terima kasih telah menggunakan script ini. Script ini dibuat dengan hati oleh Dimas."
