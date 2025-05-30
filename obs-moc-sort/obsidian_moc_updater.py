#!/usr/bin/env python3
"""
Obsidian MOC Auto-Updater Daemon

Watches for new .md files and appends them to matching MOC files.
"""

import os
import sys
import time
import logging
from pathlib import Path

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler('/tmp/obsidian-moc.log')
    ]
)
logger = logging.getLogger(__name__)

try:
    from watchdog.observers import Observer
    from watchdog.events import FileSystemEventHandler
except ImportError:
    logger.error("watchdog not installed. Install with: pip install watchdog")
    sys.exit(1)


class MOCUpdater(FileSystemEventHandler):
    def __init__(self, vault_path):
        self.vault_path = Path(vault_path)
        
    def on_created(self, event):
        if not event.is_directory and event.src_path.endswith('.md'):
            logger.info(f"New markdown file detected: {event.src_path}")
            self.update_moc(Path(event.src_path))
    
    def on_moved(self, event):
        if not event.is_directory and event.dest_path.endswith('.md'):
            logger.info(f"Markdown file renamed: {event.src_path} -> {event.dest_path}")
            self.update_moc(Path(event.dest_path))
    
    def update_moc(self, note_path):
        note_name = note_path.stem
        
        # Extract prefix (before first " - ")
        if ' - ' not in note_name:
            logger.debug(f"No prefix found in: {note_name}")
            return
            
        prefix = note_name.split(' - ')[0]
        logger.info(f"Processing note '{note_name}' with prefix '{prefix}'")
        
        # Find MOC file
        moc_file = self.find_moc(prefix)
        if not moc_file:
            logger.info(f"No MOC file found for prefix: {prefix}")
            return
            
        # Add link to MOC
        link = f"- [[{note_name}]]"
        
        with open(moc_file, 'r') as f:
            content = f.read()
            
        if link not in content:
            with open(moc_file, 'a') as f:
                f.write(f"\n{link}")
            logger.info(f"✅ Added '{note_name}' to MOC: {moc_file.name}")
        else:
            logger.info(f"Link already exists in {moc_file.name}")
                
    def find_moc(self, prefix):
        """Find MOC file for given prefix."""
        for md_file in self.vault_path.rglob("*.md"):
            name = md_file.stem
            if (name.endswith(" - MOC") or name.endswith(" - moc") or 
                name.startswith(f"(({prefix} - MOC))") or
                name.startswith(f"(({prefix} - moc))")):
                if prefix in name:
                    return md_file
        return None


def main():
    vault_path = sys.argv[1] if len(sys.argv) > 1 else os.environ.get('OBSIDIAN_VAULT')
    
    if not vault_path or not os.path.exists(vault_path):
        logger.error("Error: Valid vault path required")
        sys.exit(1)
    
    logger.info(f"Starting MOC updater for vault: {vault_path}")
    
    handler = MOCUpdater(vault_path)
    observer = Observer()
    observer.schedule(handler, vault_path, recursive=True)
    observer.start()
    
    logger.info("File watcher started. Monitoring for new .md files...")
    
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        logger.info("Stopping file watcher...")
        observer.stop()
    
    observer.join()
    logger.info("File watcher stopped.")


if __name__ == "__main__":
    main()