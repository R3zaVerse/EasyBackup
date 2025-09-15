# EasyBackup

EasyBackup sends compressed backups of selected files or directories to Telegram and Discord.

## Usage

### Step 1
Install dependencies:
```bash
apt install tar curl jq -y
```
Clone the project and change directory:
```bash
cd /opt
git clone "https://github.com/M03ED/EasyBackup.git"
cd /opt/EasyBackup
```

### Step 2
Configure `config.json` with your paths and credentials:
```json
{
    "backup_dir": "/tmp/backup",
    "backup_interval_time": 60,
    "telegram": {
        "bot_token": "your-telegram-bot-token",
        "chat_id": "your-chat-id"
    },
    "discord": {
        "backup_url": "your-discord-webhook-url"
    },
    "paths": [
        "/path/to/important/file",
        "/path/to/important/directory"
    ]
}
```

### Step 3
Install the service:
```bash
sudo bash install_service.sh
```

Backups will be sent to Telegram and Discord at the interval specified.
To view logs:
```bash
journalctl -xeu easybackup.service
```
