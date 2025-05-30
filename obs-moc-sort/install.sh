#!/bin/bash

# Obsidian MOC Updater Installation Script

echo "Installing Obsidian MOC Auto-Updater..."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "Don't run this as root. Run as your regular user."
   exit 1
fi

# Check if uv is installed
if ! command -v uv &> /dev/null; then
    echo "Error: uv is not installed. Please install uv first:"
    echo "curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi

# Check if already installed
if systemctl is-active --quiet obsidian-moc.service; then
    echo "Service is already running. Stopping for reinstall..."
    sudo systemctl stop obsidian-moc.service
fi

# Get user info
read -p "Enter your username: " USERNAME
if [[ -z "$USERNAME" ]]; then
    echo "Error: Username cannot be empty"
    exit 1
fi

# Get vault path
read -p "Enter path to your Obsidian vault: " VAULT_PATH

if [[ ! -d "$VAULT_PATH" ]]; then
    echo "Error: Vault path doesn't exist: $VAULT_PATH"
    exit 1
fi

# Validate it's an Obsidian vault (has .obsidian folder)
if [[ ! -d "$VAULT_PATH/.obsidian" ]]; then
    echo "Warning: $VAULT_PATH doesn't appear to be an Obsidian vault (no .obsidian folder found)"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create virtual environment with uv
echo "Setting up virtual environment with uv..."
if [[ ! -d ".venv" ]]; then
    uv venv
fi

# Install dependencies
echo "Installing Python dependencies..."
uv sync

# Make script executable
chmod +x obsidian_moc_updater.py

# Create logs directory
mkdir -p logs

# Update service file with correct vault path - use a more robust approach
CURRENT_DIR=$(pwd)
cp obsidian-moc.service obsidian-moc.service.tmp
sed -i "s|User=.*|User=$USERNAME|g" obsidian-moc.service.tmp
sed -i "s|Environment=OBSIDIAN_VAULT=.*|Environment=OBSIDIAN_VAULT=$VAULT_PATH|g" obsidian-moc.service.tmp
sed -i "s|WorkingDirectory=.*|WorkingDirectory=$CURRENT_DIR|g" obsidian-moc.service.tmp
sed -i "s|Environment=PATH=.*|Environment=PATH=$CURRENT_DIR/.venv/bin:/usr/bin:/bin|g" obsidian-moc.service.tmp
sed -i "s|ExecStart=.*|ExecStart=$CURRENT_DIR/.venv/bin/python $CURRENT_DIR/obsidian_moc_updater.py|g" obsidian-moc.service.tmp

# Copy service file to systemd
echo "Installing systemd service..."
sudo cp obsidian-moc.service.tmp /etc/systemd/system/obsidian-moc.service
rm obsidian-moc.service.tmp

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