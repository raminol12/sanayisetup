#!/bin/bash

set -e

echo "Updating and upgrading the system..."
sudo apt update && sudo apt -y upgrade

echo "Installing 3x-ui..."
echo -e "y\n2112" | bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)

read -p "Do you want to create the tunnel? (y for yes, n for no): " tunnel_answer

if [[ "$tunnel_answer" == "y" || "$tunnel_answer" == "Y" ]]; then
    read -p "Please enter the Iran IP address: " iran_ip
    
    foreign_ip=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
    
    if [ -z "$foreign_ip" ]; then
        echo "Error: Could not detect server IP. Please enter it manually:"
        read -p "Server IP: " foreign_ip
    fi

    echo "Detected server IP: $foreign_ip"

    sudo bash -c "cat > /etc/rc.local" <<EOF
#! /bin/bash
ip tunnel add 6to4_Forign mode sit remote $iran_ip local $foreign_ip

ip -6 addr add 2002:a00:100::2/64 dev 6to4_Forign

ip link set 6to4_Forign mtu 1480

ip link set 6to4_Forign up

ip -6 tunnel add GRE6Tun_Forign mode ip6gre remote 2002:a00:100::1 local 2002:a00:100::2

ip addr add 10.10.187.2/30 dev GRE6Tun_Forign

ip link set GRE6Tun_Forign mtu 1436

ip link set GRE6Tun_Forign up

exit 0
EOF

    sudo chmod +x /etc/rc.local

    echo "/etc/rc.local has been updated and made executable."
else
    echo "Tunnel creation canceled."
fi

echo "Changing root password to Ramin1280y..."
echo "root:Ramin1280y" | sudo chpasswd

echo "Rebooting the server now..."
sudo reboot
