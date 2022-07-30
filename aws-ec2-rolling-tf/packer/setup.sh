#!/bin/bash

set -eux -o pipefail

sudo sed -i '/^SELINUX=/cSELINUX=disabled' /etc/selinux/config
sudo setenforce 0

sudo tee /etc/sysctl.d/ipv6-disable.conf <<EOS
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOS

sudo systemctl disable --now firewalld.service
sudo systemctl disable --now iptables.service

sudo dnf -y install httpd
sudo systemctl enable httpd
echo ok | sudo tee /var/www/html/index.html
