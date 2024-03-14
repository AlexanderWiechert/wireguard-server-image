#!/usr/bin/env bash

set -e

echo "GENERATE SERVER PRIVATE KEY"
wg genkey | sudo tee /etc/wireguard/private.key &&\
chmod go= /etc/wireguard/private.key &&\
cat /etc/wireguard/private.key | wg pubkey | sudo tee /etc/wireguard/public.key

echo "CREATE SERVER CONFIG"
PRIV=$(cat /etc/wireguard/private.key)
cat <<EOF > /etc/wireguard/wg0.conf
[Interface]
Address = 10.16.0.1
ListenPort = 51820
PrivateKey $PRIV
SaveConfig = true
PostUp = iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
PostUp = ip6tables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
PreDown = ufw route delete allow in on wg0 out on eth0
PreDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
PreDown = ip6tables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

EOF

echo "CREATE 1. CLIENT PRIVATE KEY"
wg genkey |tee /etc/wireguard/iphone.key |wg pubkey |tee /etc/wireguard/iphone.key.pub

echo "UPDATE SERVER CONFIG"
CPRIV=$(cat /etc/wireguard/iphone.key.pub)
cat <<EOF >> /etc/wireguard/wg0.conf
[Peer]
PublicKey = $CPRIV
AllowedIPs = 10.16.0.10/32
EOF

echo "CREATE 1. CLIENT CONFIG"
CPRIV=$(cat /etc/wireguard/iphone.key.pub)
cat <<EOF > /etc/wireguard/iphone.conf
[Interface]
PrivateKey = $CPRIV
Address = 10.16.0.10/24
DNS = 1.1.1.1
[Peer]
PublicKey = $PRIV
AllowedIPs = 10.16.0.0/24
Endpoint = vpn0.elastic2ls.com:51820
EOF

echo "GENERATE QR CODE"
qrencode  < /etc/wireguard/iphone.conf -o /etc/wireguard/iphone-qr.png

bash