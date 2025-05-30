# obsidian moc auto-updater

automatically manages moc (map of content) files by adding/removing note links based on filename prefixes.

## quick setup

```bash
chmod +x install.sh
./install.sh
```

the installer will prompt for your obsidian vault path and user name set up the systemd service. eg in your terminal:
`[i] jeff@your_computer_name ~/d/obsidian_setup (main)>` "jeff" is my username

## how it works

**auto-add:** create `project - moc.md`, then any `project - task.md` gets automatically linked  
**auto-remove:** delete a note and its link disappears from the moc instantly  
**smart caching:** builds a memory cache of all moc files for lightning-fast lookups


## management

- view logs: `sudo journalctl -u obsidian-moc.service -f`
- stop service: `sudo systemctl stop obsidian-moc.service`
- restart: `sudo systemctl restart obsidian-moc.service`
