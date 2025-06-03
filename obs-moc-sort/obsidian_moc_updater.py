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
        self.moc_cache = {}  # prefix -> Path mapping
        self._build_moc_cache()
        
    def on_created(self, event):
        if not event.is_directory and event.src_path.endswith('.md'):
            file_path = Path(event.src_path)
            logger.info(f"New markdown file detected: {event.src_path}")
            
            # Check if this is a new MOC file and update cache
            if self._is_moc_file(file_path):
                self._update_moc_cache_entry(file_path)
                logger.info(f"New MOC file added to cache: {file_path.name}")
            
            self.update_moc(file_path)
    
    def on_moved(self, event):
        if not event.is_directory and event.dest_path.endswith('.md'):
            dest_path = Path(event.dest_path)
            logger.info(f"Markdown file renamed: {event.src_path} -> {event.dest_path}")
            
            # Check if the renamed file is now a MOC file and update cache
            if self._is_moc_file(dest_path):
                self._update_moc_cache_entry(dest_path)
                logger.info(f"New MOC file added to cache: {dest_path.name}")
            
            self.update_moc(dest_path)
    
    def on_deleted(self, event):
        if not event.is_directory and event.src_path.endswith('.md'):
            file_path = Path(event.src_path)
            note_name = file_path.stem
            logger.info(f"Markdown file deleted: {event.src_path}")
            
            # Skip if it was a MOC file - remove from cache
            if self._is_moc_file(file_path):
                self._remove_from_cache(file_path)
                logger.info(f"MOC file removed from cache: {note_name}")
                return
            
            # Remove link from MOC file if it was a regular note
            if ' - ' in note_name:
                prefix = note_name.split(' - ')[0]
                self.remove_from_moc(note_name, prefix)
    
    def update_moc(self, note_path):
        note_name = note_path.stem
        
        # Skip if this file is itself a MOC file
        if self._is_moc_file(note_path):
            logger.debug(f"Skipping MOC file: {note_name}")
            return
        
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
            
        # Check for existing link (with or without .md extension)
        link_without_ext = f"- [[{note_name.replace('.md', '')}]]"
        if link not in content and link_without_ext not in content:
            with open(moc_file, 'a') as f:
                f.write(f"\n{link}")
            logger.info(f"✅ Added '{note_name}' to MOC: {moc_file.name}")
        else:
            logger.info(f"Link already exists in {moc_file.name}")
                
    def find_moc(self, prefix):
        """Find MOC file for given prefix using cache."""
        # Check cache first
        if prefix in self.moc_cache:
            moc_file = self.moc_cache[prefix]
            if moc_file.exists():
                return moc_file
            else:
                # File was deleted, remove from cache
                del self.moc_cache[prefix]
        
        # Cache miss - file not found
        return None
    
    def _build_moc_cache(self):
        """Build cache of all MOC files in the vault."""
        logger.info("Building MOC file cache...")
        self.moc_cache.clear()
        
        for md_file in self.vault_path.rglob("*.md"):
            if self._is_moc_file(md_file):
                self._update_moc_cache_entry(md_file)
        
        logger.info(f"Found {len(self.moc_cache)} MOC files: {list(self.moc_cache.keys())}")
    
    def _is_moc_file(self, file_path):
        """Check if a file is a MOC file based on naming patterns."""
        name = file_path.stem
        return (name.endswith(" - MOC") or name.endswith(" - moc") or 
                name.endswith(" - MOC)") or name.endswith(" - moc)") or
                "MOC" in name.upper())
    
    def _update_moc_cache_entry(self, moc_file):
        """Extract prefix from MOC file and add to cache."""
        name = moc_file.stem
        
        # Extract prefix from different MOC naming patterns
        if name.endswith(" - MOC") or name.endswith(" - moc"):
            prefix = name.rsplit(" - ", 1)[0]
        elif name.startswith("((") and (name.endswith(" - MOC))") or name.endswith(" - moc))")):
            # Handle ((prefix - MOC)) pattern
            prefix = name[2:].rsplit(" - ", 1)[0]
        else:
            # For other MOC patterns, try to extract meaningful prefix
            if " - " in name:
                prefix = name.split(" - ")[0]
            else:
                prefix = name.replace(" MOC", "").replace(" moc", "").strip()
        
        if prefix:
            self.moc_cache[prefix] = moc_file
            logger.debug(f"Cached MOC: '{prefix}' -> {moc_file.name}")
    
    def _remove_from_cache(self, moc_file):
        """Remove a MOC file from cache."""
        # Find and remove the cache entry for this file
        to_remove = [prefix for prefix, path in self.moc_cache.items() if path == moc_file]
        for prefix in to_remove:
            del self.moc_cache[prefix]
            logger.debug(f"Removed from cache: '{prefix}'")
    
    def remove_from_moc(self, note_name, prefix):
        """Remove a note link from its MOC file."""
        moc_file = self.find_moc(prefix)
        if not moc_file:
            logger.debug(f"No MOC file found for deleted note: {note_name}")
            return
        
        link_to_remove = f"- [[{note_name}]]"
        
        try:
            with open(moc_file, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            # Filter out the link line
            original_count = len(lines)
            lines = [line for line in lines if line.strip() != link_to_remove]
            
            if len(lines) < original_count:
                # Write back the file without the deleted link
                with open(moc_file, 'w', encoding='utf-8') as f:
                    f.writelines(lines)
                logger.info(f"🗑️ Removed '{note_name}' from MOC: {moc_file.name}")
            else:
                logger.debug(f"Link not found in MOC for: {note_name}")
                
        except Exception as e:
            logger.error(f"Error removing link from MOC {moc_file.name}: {e}")


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