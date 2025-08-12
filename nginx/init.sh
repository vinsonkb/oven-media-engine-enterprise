#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Update package list and install git
sudo apt update
sudo apt install git -y

# Install and configure Docker
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
sudo chmod 666 /var/run/docker.sock
docker version

# Install Docker Compose
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -SL https://github.com/docker/compose/releases/download/v2.38.2/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
docker compose version

# Create SSH directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Prompt for key name
echo "Enter the name for your SSH key (e.g., id_rsa_github):"
read key_name

# Generate SSH key if it doesn't exist
if [ ! -f ~/.ssh/$key_name ]; then
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/$key_name -N ""
    chmod 600 ~/.ssh/$key_name
    chmod 644 ~/.ssh/$key_name.pub
fi

# Create or update SSH config file
CONFIG_FILE=~/.ssh/config
if [ ! -f $CONFIG_FILE ]; then
    touch $CONFIG_FILE
    chmod 600 $CONFIG_FILE
fi

# Check if GitHub configuration already exists
if grep -q "Host github.com" $CONFIG_FILE; then
    echo "GitHub configuration already exists in $CONFIG_FILE"
    echo "Current configuration:"
    grep -A 3 "Host github.com" $CONFIG_FILE
    echo "Would you like to update it? (y/n)"
    read update_choice
    if [ "$update_choice" != "y" ]; then
        echo "Keeping existing configuration"
        exit 0
    fi
    # Remove existing GitHub configuration
    sed -i '/Host github.com/,+3d' $CONFIG_FILE
fi

# Add GitHub configuration
cat << EOT >> $CONFIG_FILE
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/$key_name
EOT

echo "SSH configuration updated. Your public key is:"
cat ~/.ssh/$key_name.pub
echo
echo "Please add this public key to your GitHub account:"
echo "1. Go to https://github.com/settings/keys"
echo "2. Click 'New SSH key' or 'Add SSH key'"
echo "3. Give your key a descriptive title"
echo "4. Paste the above public key into the 'Key' field"
echo "5. Click 'Add SSH key'"