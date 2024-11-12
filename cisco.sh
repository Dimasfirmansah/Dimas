# Remote Configuration for Cisco
echo "Configuring Cisco device..."
CISCO_USER="admin"
CISCO_PASS="123"
CISCO_IP="192.168.9.11"  # IP address of Cisco device in VLAN 10

sshpass -p "$CISCO_PASS" ssh -o StrictHostKeyChecking=no $CISCO_USER@$CISCO_IP << EOF
enable
configure terminal
interface ethernet 0/0
switchport mode trunk
exit
interface ethernet 0/1
switchport mode access
switchport access vlan 10
exit
end
EOF
echo "Cisco configuration completed."
