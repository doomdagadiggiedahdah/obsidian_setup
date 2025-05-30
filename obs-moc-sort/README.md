# Obsidian MOC Auto-Updater

Automatically appends new notes to matching MOC (Map of Content) files based on filename prefixes.

## Quick Setup

```bash
chmod +x install.sh
./install.sh
```

The installer will prompt for your Obsidian vault path and User name set up the systemd service. eg in your terminal:
`[I] mat@fantasyFlamingo ~/D/obsidian_setup (main)>` "mat" is my username

## How it works

Create an MOC file for your project, like `balloons - moc`
Then whenever you make a file with the `balloons` prefix, it'll be automatically sorted to your MOC file.


## Management

- View logs: `sudo journalctl -u obsidian-moc.service -f`
- Stop service: `sudo systemctl stop obsidian-moc.service`
- Restart: `sudo systemctl restart obsidian-moc.service`