#!/bin/bash
set -e -o pipefail

INSTALL_DIR=/tmp
PUBLIC_IP=$(curl -s https://checkip.amazonaws.com)

sudo apt-get update

git clone https://github.com/pivpn/pivpn.git /usr/local/src/pivpn

curl -L https://install.pivpn.io > $INSTALL_DIR/install.sh
sudo chmod +x $INSTALL_DIR/install.sh

echo """IPv4dev=ens5
install_user=ubuntu
VPN=wireguard
pivpnNET=10.6.0.0
subnetClass=24
ALLOWED_IPS="0.0.0.0/0"
pivpnPORT=51820
pivpnHOST=$${PUBLIC_IP}
pivpnPERSISTENTKEEPALIVE=25
USING_UFW=0
pivpnPROTO=udp
pivpnDNS1=8.8.8.8
pivpnDNS2=8.8.4.4
TWO_POINT_FOUR=1
pivpnENCRYPT=256
USE_PREDEFINED_DH_PARAM=1
INPUT_CHAIN_EDITED=0
FORWARD_CHAIN_EDITED=0
pivpnDEV=tun0
UNATTUPG=1""" > $INSTALL_DIR/options.conf

sudo $INSTALL_DIR/install.sh --unattended $INSTALL_DIR/options.conf

pivpn add --name="aws-$${PUBLIC_IP}"
chown -R ubuntu: /home/ubuntu/configs

sudo reboot
