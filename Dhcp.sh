#!/bin/bash

set -e

# Fungsi untuk menampilkan pesan dengan warna hijau
print_success() {
    dialog --title "Success" --msgbox "$1" 6 50
}

# Fungsi untuk menampilkan pesan dengan warna merah
print_error() {
    dialog --title "Error" --msgbox "$1" 6 50
}

# Fungsi untuk menampilkan pesan dengan warna kuning
print_warning() {
    dialog --title "Warning" --msgbox "$1" 6 50
}

# Fungsi untuk konfirmasi pengguna
confirm_action() {
    dialog --title "Confirm" --yesno "$1" 6 50
}

# Memperkenalkan diri
dialog --title "Script by Dimas" --msgbox "Selamat datang! Script ini dirancang oleh Dimas.\n\nTekan OK untuk melanjutkan." 6 50

# Menambahkan repository lokal Kartolo
print_success "Menambahkan repository lokal Kartolo..."
cat <<EOF | sudo tee /etc/apt/sources.list
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-updates main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-security main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-backports main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-proposed main restricted universe multiverse
EOF

print_success "Memperbarui daftar paket..."
sudo apt update

print_success "Menginstal ISC DHCP Server, IPTables, dan iptables-persistent..."
sudo apt install -y isc-dhcp-server iptables iptables-persistent

print_success "Mengonfigurasi DHCP server..."
cat <<EOF | sudo tee /etc/dhcp/dhcpd.conf
subnet 192.168.9.0 netmask 255.255.255.0 {
    range 192.168.9.10 192.168.9.100;
    option routers 192.168.9.1;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
}
EOF

print_success "Mengonfigurasi interface DHCP server..."
sudo sed -i 's/^INTERFACESv4=.*/INTERFACESv4="enp0s8"/' /etc/default/isc-dhcp-server

print_success "Mengonfigurasi IP statis untuk internal network..."
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

print_success "Menerapkan konfigurasi netplan..."
sudo netplan apply

# Restart DHCP server
print_success "Merestart DHCP server menggunakan /etc/init.d/isc-dhcp-server..."
sudo /etc/init.d/isc-dhcp-server restart 

# Mengaktifkan IP forwarding dan mengonfigurasi IPTables
print_success "Mengaktifkan IP forwarding dan mengonfigurasi IPTables..."
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE

print_success "Menyimpan aturan IPTables..."
sudo netfilter-persistent save

print_success "Setup selesai! Terima kasih telah menggunakan script ini. Script ini dibuat dengan hati oleh Dimas."
