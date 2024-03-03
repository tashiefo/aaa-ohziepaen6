#!/bin/bash
#apt update
#apt install -y systemd-resolved

# Point to Google's DNS server
sed -i -e 's/#DNS=/DNS=8.8.8.8/' /etc/systemd/resolved.conf

service systemd-resolved restart
