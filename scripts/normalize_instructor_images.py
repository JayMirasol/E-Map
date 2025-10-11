#!/usr/bin/env python3
"""
Normalize instructor image filenames and update assets/data/instructor_photos.json.

Usage:
  # Dry run (shows planned renames and JSON changes)
  python3 scripts/normalize_instructor_images.py --dry-run

  # Do the changes
  python3 scripts/normalize_instructor_images.py --apply

Notes:
- Expects project structure:
  assets/images/instructors/
  assets/data/instructor_photos.json

- Backups:
  - instructor_photos.json -> instructor_photos.json.bak.YYYYMMDD_HHMMSS
"""
from __future__ import annotations
import argparse
import json
import os
import re
import shutil
from datetime import datetime
from pathlib import Path
from typing import Dict, Tuple

INSTRUCTORS_DIR = Path("assets/images/instructors")
PHOTOS_JSON = Path("assets/data/instructor_photos.json")


def normalize_filename(name: str) -> str:
    """
    Normalize a filename (without path) to: lowercase, letters/numbers + underscores.
    Keeps extension.
    """
    name = name.strip()
    stem, ext = os.path.splitext(name)
    # replace sequences of whitespace and separators with underscore
    stem = re.sub(r"[ \t\-]+", "_", stem)
    # remove characters that are not alnum or underscore
    stem = re.sub(r"[^0-9A-Za-z_]", "", stem)
    # collapse multiple underscores
    stem = re.sub(r"_+", "_", stem)
    stem = stem.strip("_").lower()
    if stem == "":
        stem = "img"
    return f"{stem}{ext.lower()}"


def unique_name(target_dir: Path, filename: str) -> str:
    """
    Ensure filename is unique in target_dir by adding suffix if needed.
    """
    candidate = target_dir / filename
    if not candidate.exists():
        return filename
    stem, ext = os.path.splitext(filename)
    i = 1
    while True:
        candidate_name = f"{stem}_{i}{ext}"
        if not (target_dir / candidate_name).exists():
            return candidate_name
        i += 1


def load_photos_json(path: Path) -> Dict[str, str]:
    if not path.exists():
        return {}
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def backup_file(path: Path) -> Path:
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup = path.with_suffix(path.suffix + f".bak.{ts}")
    shutil.copy2(path, backup)
    return backup


def main(dry_run: bool):
    print("Normalize instructor images script")
    print(f" - instructors dir: {INSTRUCTORS_DIR}")
    print(f" - photos json:    {PHOTOS_JSON}")
    if not INSTRUCTORS_DIR.exists():
        print("ERROR: instructors directory not found. Aborting.")
        return
    photos = load_photos_json(PHOTOS_JSON)
    # Map current file basenames -> normalized target name (planned)
    planned_renames: Dict[Path, Path] = {}
    # Build a set of existing filenames in folder
    existing_files = sorted([p for p in INSTRUCTORS_DIR.iterdir() if p.is_file()])
    existing_names = {p.name for p in existing_files}

    # 1) For each file in folder, compute its normalized filename
    used_targets = set()  # to avoid duplicate normalized names
    for p in existing_files:
        new_name = normalize_filename(p.name)
        if new_name in used_targets:
            new_name = unique_name(INSTRUCTORS_DIR, new_name)
        used_targets.add(new_name)
        target = INSTRUCTORS_DIR / new_name
        if p.name != new_name:
            planned_renames[p] = target

    # 2) For entries in photos JSON whose value points to assets/images/instructors/..., ensure we map to correct normalized name
    updated_photos: Dict[str, str] = {}
    for instr, path in photos.items():
        # if path is remote or not under instructors dir, leave as-is
        if not isinstance(path, str):
            updated_photos[instr] = path
            continue
        if not path.startswith("assets/images/instructors/"):
            updated_photos[instr] = path
            continue
        filename = os.path.basename(path)
        # If file will be renamed, compute new path
        # Find matching planned rename by original filename
        matched = None
        for src, tgt in planned_renames.items():
            if src.name == filename:
                matched = tgt.name
                break
        # If not scheduled to rename but file exists unchanged, we may still normalize its name
        if matched is None:
            normalized = normalize_filename(filename)
            if normalized != filename and (INSTRUCTORS_DIR / normalized).exists():
                matched = normalized
            elif normalized != filename and normalized in used_targets:
                # maybe the normalized target exists or will exist; prefer normalized
                matched = normalized
            else:
                # keep original (maybe remote path or non-existent)
                matched = filename
        updated_photos[instr] = f"assets/images/instructors/{matched}"

    # 3) Also add entries for any files in folder not referenced in JSON (optional)
    # We'll add mapping key derived from filename (title-cased) only for files not referenced.
    referenced_files = {os.path.basename(v) for v in updated_photos.values() if isinstance(v, str) and v.startswith("assets/images/instructors/")}
    for p in existing_files:
        if p.name in referenced_files:
            continue
        # derive label: replace underscores with spaces, strip extension, title case
        base = os.path.splitext(p.name)[0]
        label = re.sub(r"[_]+", " ", base).strip().title()
        # avoid overwriting existing instructor keys
        key = label
        i = 1
        while key in updated_photos:
            key = f"{label} {i}"
            i += 1
        updated_photos[key] = f"assets/images/instructors/{p.name}"

    # Show planned actions
    print("\nPlanned file renames:")
    if not planned_renames:
        print("  (no file renames needed)")
    else:
        for src, tgt in planned_renames.items():
            print(f"  {src.name} -> {tgt.name}")

    print("\nUpdated instructor_photos.json entries (sample 20):")
    cnt = 0
    for k, v in updated_photos.items():
        print(f'  "{k}": "{v}"')
        cnt += 1
        if cnt >= 20:
            break
    if len(updated_photos) > 20:
        print(f"  ... and {len(updated_photos)-20} more entries")

    if dry_run:
        print("\nDry run complete. No files changed.")
        return

    # APPLY changes
    # 1) Rename files
    if planned_renames:
        print("\nApplying file renames...")
        for src, tgt in planned_renames.items():
            try:
                print(f"  Renaming {src.name} -> {tgt.name}")
                src.replace(tgt)
            except Exception as e:
                print(f"  FAILED to rename {src} -> {tgt}: {e}")

    # 2) Backup and write updated JSON
    if PHOTOS_JSON.exists():
        bkp = backup_file(PHOTOS_JSON)
        print(f"\nBacked up {PHOTOS_JSON} -> {bkp}")
    else:
        # ensure parent dir exists
        PHOTOS_JSON.parent.mkdir(parents=True, exist_ok=True)
        print(f"\nCreating new {PHOTOS_JSON}")

    with open(PHOTOS_JSON, "w", encoding="utf-8") as f:
        json.dump(updated_photos, f, indent=2, ensure_ascii=False)
    print(f"Wrote updated {PHOTOS_JSON} ({len(updated_photos)} entries)")

    print("\nDone. Please run:\n  flutter clean\n  flutter pub get\nand then rebuild your app to ensure assets are bundled.")


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description="Normalize instructor image filenames and update JSON")
    ap.add_argument("--dry-run", action="store_true", help="Do not modify files; only print actions")
    ap.add_argument("--apply", action="store_true", help="Apply changes (rename files and update JSON)")
    args = ap.parse_args()
    if args.dry_run and args.apply:
        print("Use either --dry-run OR --apply, not both.")
    else:
        main(dry_run=not args.apply)
