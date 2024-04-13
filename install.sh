#!/bin/bash

gum style \
  --border normal --margin "1" --padding "1 2" --border-foreground 212 \
  "SecureSync installation script"

SFTP_GROUP=$(gum input --placeholder "Enter sftp group name")
USERNAME=$(gum input --placeholder "Enter sftp user username")

gum confirm "Create '$USERNAME' user and '$SFTP_GROUP' group?" || exit 1

gum log --level info "Creating group '$USERNAME'"
groupadd "$SFTP_GROUP"

gum log --level info "Creating user '$USERNAME'"
useradd -g "$SFTP_GROUP" "$USERNAME"

gum log --level info "Adding password for the user '$USERNAME'"
while ! passwd "$USERNAME"
do
  echo "Try again"
done

SFTP_ROOT_DIR="/data/$USERNAME"
SFTP_UPLOADS_DIR="$SFTP_ROOT_DIR/uploads/"

gum log --level info "Creating sftp user directory '$SFTP_UPLOADS_DIR'"
mkdir -p "$SFTP_UPLOADS_DIR"
chown root:"$SFTP_GROUP" "$SFTP_ROOT_DIR"
chown "$USERNAME":"$SFTP_GROUP" "$SFTP_UPLOADS_DIR"

SSHD_CONFIG_PATH=/etc/ssh/sshd_config
gum log --level info "Configuring ssh"

if ! grep -q "$SFTP_GROUP" "$SSHD_CONFIG_PATH"; then
cat >> "$SSHD_CONFIG_PATH" << EOF
Match Group $SFTP_GROUP 
  ChrootDirectory /data/%u
  ForceCommand internal-sftp
EOF
fi

gum log --level info "Restarting and enabling sshd service"
systemctl restart sshd.service
systemctl enable sshd.service
systemctl status sshd.service

gum log --level info "Creating FRP configuration"
FRP_CONFIG_DIR="/home/$USERNAME/.config/frp"
echo $FRP_CONFIG_DIR
mkdir -p "$FRP_CONFIG_DIR"
FRP_CONFIG="$FRP_CONFIG_DIR/frp.toml"
echo $FRP_CONFIG
touch $FRP_CONFIG

SERVER_ADDR=$(gum input --placeholder "Enter your proxy server public IP address")
SERVER_PORT=$(gum input --placeholder "Enter port that is used for communication between this sftp server and proxy server.")
REMOTE_PORT=$(gum input --placeholder "Enter port that is used for communication between proxy server and mobile application.")

cat > "$FRP_CONFIG" << EOF
serverAddr = "$SERVER_ADDR"
serverPort = $SERVER_PORT

[[proxies]]
name = "ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = $REMOTE_PORT
EOF

cat > /etc/systemd/system/frp.service << EOF
[Unit]
Description=FRP Service
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=$USERNAME
ExecStart=/usr/bin/bash -c "frpc -c $FRP_CONFIG"

[Install]
WantedBy=multi-user.target
EOF

gum log --level info "Starting and enabling frp service"
systemctl daemon-reload
systemctl restart frp.service
systemctl enable frp.service
systemctl status frp.service
