#!/bin/bash
# Log all output for troubleshooting
exec > /var/log/setup_dvwa.log 2>&1

# Update package index and install Docker
apt-get update -y
apt-get install -y docker.io

# Enable Docker to start on boot and start the service now
systemctl enable docker
systemctl start docker

# Pull the DVWA image and run it on port 80 in the background
docker run --name dvwa -d -p 80:80 --restart unless-stopped vulnerables/web-dvwa