#!/bin/bash

SERVICE_NAME="easybackup"
SERVICE_DESCRIPTION="EasyBackup Service"
SERVICE_DOCUMENTATION="https://github.com/YOUR_USERNAME/EasyBackup"
MAIN_BASH_PATH="backup.sh"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

cat > $SERVICE_FILE <<EOT
[Unit]
Description=$SERVICE_DESCRIPTION
Documentation=$SERVICE_DOCUMENTATION
After=network.target

[Service]
WorkingDirectory=/opt/EasyBackup
Type=simple
User=root
ExecStart=/bin/bash $MAIN_BASH_PATH -c /opt/EasyBackup/config.json
RestartSec=5
Restart=on-failure
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOT

systemctl daemon-reload
systemctl enable $SERVICE_NAME.service
systemctl start $SERVICE_NAME.service

echo "Service file created at: $SERVICE_FILE"
