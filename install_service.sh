#!/bin/bash

SERVICE_NAME="sql-backup"
SERVICE_DESCRIPTION="M03ED SQL Backup Service"
SERVICE_DOCUMENTATION="https://github.com/M03ED/sql_backup"
MAIN_BASH_PATH="backup.sh"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

# Create the service file
cat > $SERVICE_FILE <<EOF
[Unit]
Description=$SERVICE_DESCRIPTION
Documentation=$SERVICE_DOCUMENTATION
After=network.target

[Service]
WorkingDirectory=/opt/sql_backup
Type=simple
User=root
ExecStart=/bin/bash $MAIN_BASH_PATH -c /opt/sql_backup/config.json
RestartSec=5
Restart=on-failure
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable $SERVICE_NAME.service
systemctl start $SERVICE_NAME.service

echo "Service file created at: $SERVICE_FILE"
