#!/bin/bash

# Obsidian MOC Updater Installation Script

echo "Installing Obsidian MOC Auto-Updater..."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "Don't run this as root. Run as your regular user."
   exit 1
fi

# Get vault path
read -p "Enter path to your Obsidian vault: " VAULT_PATH

if [[ ! -d "$VAULT_PATH" ]]; then
    echo "Error: Vault path doesn't exist: $VAULT_PATH"
    exit 1
fi

# Create virtual environment with uv
echo "Setting up virtual environment with uv..."
if [[ ! -d ".venv" ]]; then
    uv venv
fi

# Install dependencies
echo "Installing Python dependencies..."
uv sync

# Update service file with correct vault path
sed -i "s|/path/to/your/obsidian/vault|$VAULT_PATH|g" obsidian-moc.service

# Copy service file to systemd
echo "Installing systemd service..."
sudo cp obsidian-moc.service /etc/systemd/system/

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable obsidian-moc.service
sudo systemctl start obsidian-moc.service

echo "Installation complete!"
echo "Service status:"
sudo systemctl status obsidian-moc.service --no-pager

echo ""
echo "To check logs: sudo journalctl -u obsidian-moc.service -f"
echo "To stop: sudo systemctl stop obsidian-moc.service"
echo "To disable: sudo systemctl disable obsidian-moc.service"