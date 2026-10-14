#!/bin/bash
# Run this on broken hosts .100 .101 .120 .161 .178
echo "Fixing docker on $HOSTNAME"
rm -f /etc/systemd/system/docker.service.d/tcp.conf
rmdir /etc/systemd/system/docker.service.d 2>/dev/null || true
systemctl daemon-reload
systemctl restart docker
docker ps
