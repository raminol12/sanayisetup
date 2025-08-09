#!/bin/bash

set -e

# دریافت اطلاعات لازم از کاربر
read -p "Enter Foreign IP address: " foreign_ip
read -p "Enter Iran IP address: " iran_ip
read -p "Enter SSH port number: " ssh_port

# پاک کردن کامل محتویات /etc/rc.local و نوشتن محتوای جدید
sudo bash -c "cat > /etc/rc.local" <<EOF
#! /bin/bash
ip tunnel add 6to4_iran mode sit remote $foreign_ip local $iran_ip

ip -6 addr add 2002:a00:100::1/64 dev 6to4_iran

ip link set 6to4_iran mtu 1480

ip link set 6to4_iran up

ip -6 tunnel add GRE6Tun_iran mode ip6gre remote 2002:a00:100::2 local 2002:a00:100::1

ip addr add 10.10.187.1/30 dev GRE6Tun_iran

ip link set GRE6Tun_iran mtu 1436

ip link set GRE6Tun_iran up

sysctl net.ipv4.ip_forward=1

iptables -t nat -A PREROUTING -p tcp --dport $ssh_port -j DNAT --to-destination 10.10.187.1

iptables -t nat -A PREROUTING -j DNAT --to-destination 10.10.187.2

iptables -t nat -A POSTROUTING -j MASQUERADE

exit 0
EOF

# دادن مجوز اجرا به /etc/rc.local
sudo chmod +x /etc/rc.local

echo "/etc/rc.local updated and executable permission set."
