# Theme Switcher - Architecture Documentation

> **Version:** 2.0.0  
> **Last Updated:** December 2024  
> **Author:** Nalindu Ashirwada

Welcome, contributor! This document explains how the Theme Switcher script is organized and how you can extend it.

---

## Table of Contents

1. [Overview](#overview)
2. [Design Principles](#design-principles)
3. [Architecture Diagram](#architecture-diagram)
4. [Layer-by-Layer Breakdown](#layer-by-layer-breakdown)
5. [Directory Structure](#directory-structure)
6. [How to Extend](#how-to-extend)
7. [Testing Guidelines](#testing-guidelines)

---

## Overview

Theme Switcher is a Bash script that manages Linux desktop themes (GTK, cursors, icons, wallpapers) from gnome-look.org. It provides:

- **Interactive Mode**: Pretty menus to select theme packages
- **CLI Mode**: Command-line flags for automation/scripting
- **History**: Restore previous theme configurations
- **Caching**: Downloaded themes are stored locally to avoid re-downloading

### Original vs Refactored

| Original Script | Refactored Script |
|-----------------|-------------------|
| Monolithic design | Modular, layered design |
| GNOME-only | Desktop Environment Adapters |
| Mixed responsibilities | Single Responsibility |
| Hard to test | Testable functions |
| Global state | Dependency injection |

---

## Design Principles

### 1. Single Responsibility Principle (SRP)
Each function does **ONE thing** well.

```bash
# Good: Separate functions for each task
download_theme_file()    # Only downloads
extract_theme_archive()  # Only extracts
install_gtk_theme()      # Only installs
apply_gtk_theme()        # Only applies
```

### 2. Open/Closed Principle
- **Open** for extension (add new DE adapters)
- **Closed** for modification (don't change existing adapters)

### 3. Adapter Pattern
Each desktop environment implements the same interface:

```bash
de_<name>_apply_gtk()
de_<name>_apply_cursor()
de_<name>_apply_icon()
de_<name>_apply_wallpaper()
de_<name>_get_current_themes()
```

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         MAIN ENTRY POINT                            │
│                            main()                                   │
└─────────────────────────────────┬───────────────────────────────────┘
                                  │
                ┌─────────────────┴─────────────────┐
                │                                   │
                ▼                                   ▼
    ┌───────────────────┐               ┌───────────────────┐
    │   CLI INTERFACE   │               │ INTERACTIVE MODE  │
    │ handle_cli_args() │               │ run_interactive() │
    └─────────┬─────────┘               └─────────┬─────────┘
              │                                   │
              └─────────────┬─────────────────────┘
                            │
                            ▼
    ┌───────────────────────────────────────────────────────┐
    │              THEME PROCESSING ORCHESTRATOR             │
    │              process_theme_component()                 │
    └───────────────────────────┬───────────────────────────┘
                                │
      ┌─────────────────────────┼─────────────────────────┐
      │                         │                         │
      ▼                         ▼                         ▼
┌───────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ GNOME-LOOK    │     │   DOWNLOAD &    │     │   INSTALLATION  │
│ API CLIENT    │     │   EXTRACTION    │     │     SERVICE     │
└───────┬───────┘     └────────┬────────┘     └────────┬────────┘
        │                      │                       │
        └──────────────────────┼───────────────────────┘
                               │
                               ▼
    ┌───────────────────────────────────────────────────────┐
    │              DESKTOP ENVIRONMENT DISPATCHER           │
    │   apply_gtk_theme() → routes to correct DE adapter    │
    └───────────────────────────┬───────────────────────────┘
                                │
         ┌──────────────────────┼──────────────────────┐
         │                      │                      │
         ▼                      ▼                      ▼
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│  GNOME ADAPTER  │   │   KDE ADAPTER   │   │  XFCE ADAPTER   │
│ de_gnome_*()    │   │   (TODO)        │   │   (TODO)        │
└─────────────────┘   └─────────────────┘   └─────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      CORE UTILITIES                             │
│  Logging, Internet Check, Package Manager, File Operations      │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                  STORAGE & DATA LAYER                           │
│     Vault Management, files.json, history.json                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Layer-by-Layer Breakdown

### Section 1: Configuration & Constants
All settings in one place: paths, colors, API URLs, theme packages database.

### Section 2: Logging Utilities
Colorful output functions: `log_error()`, `log_info()`, `log_success()`, `log_warn()`, `show_spinner()`.

### Section 3-4: Core Utilities & Dependencies
Basic tools: internet check, package manager detection, dependency installation.

### Section 5-7: Data Access Layer
- **JSON Access**: Read theme package data
- **Vault Storage**: Manage local theme cache
- **Tracking**: Remember what's installed via `files.json`

### Section 8: GNOME-Look API Client
Fetches theme metadata, selects files, extracts download URLs.

### Section 9-10: Timestamp & Download Services
Compares versions, downloads archives, extracts them.

### Section 11-13: Desktop Environment Adapters
- **Interface**: Defines what each adapter must implement
- **GNOME Adapter**: Full implementation for GNOME
- **Dispatcher**: Routes calls to correct adapter

### Section 14: Installation Service
Copies themes from vault to system directories.

### Section 15: History Management
Save/restore theme configurations using `history.json`.

### Section 16: Wallpaper Management
Downloads and applies matching wallpapers.

### Section 17: Theme Orchestrator
Main workflow coordination for processing themes.

### Section 18: CLI Interface
Command-line argument parsing and help.

### Section 19: Interactive Mode
Pretty menu-based interface using `gum`.

### Section 20: Main Entry Point
Script initialization and startup.

---

## Directory Structure

```
~/.local/share/
├── theme-switcher-vault/          # Our cache/vault
│   ├── gtk/
│   │   └── {theme_id}/
│   │       └── {archive_name}/
│   │           ├── {archive_file}
│   │           └── {extracted_folder}/
│   ├── cursor/
│   ├── icon/
│   ├── wallpaper/
│   ├── files.json                 # Tracks installed folders
│   └── history.json               # Theme change history
│
├── themes/                        # System GTK themes
└── icons/                         # System icons/cursors
```

---

## How to Extend

### Adding a New Desktop Environment

1. **Add detection** in `detect_desktop_environment()`:
```bash
case "${XDG_CURRENT_DESKTOP:-}" in
    *KDE*) echo "kde"; return 0 ;;
esac
```

2. **Create adapter functions**:
```bash
de_kde_apply_gtk() {
    local theme_name="$1"
    # KDE-specific commands here
}

de_kde_apply_cursor() { ... }
de_kde_apply_icon() { ... }
de_kde_get_current_themes() { ... }
```

3. **Register in dispatchers**:
```bash
apply_gtk_theme() {
    case "$CURRENT_DE" in
        "gnome") de_gnome_apply_gtk "$theme_name" ;;
        "kde")   de_kde_apply_gtk "$theme_name" ;;    # Add
    esac
}
```

### Adding a New Theme Package

Edit `THEME_PACKAGES_JSON` in Section 1:

```bash
"My-Theme": {
    "gtk": {
        "id": "1234567",
        "file": "MyTheme.tar.xz",
        "name": "MyTheme"
    },
    "cursor": { ... },
    "icon": { ... },
    "wallpaper": { ... }
}
```

### Adding New Archive Format

Edit `extract_theme_archive()`:

```bash
case "$file_name" in
    *.zip)    unzip ... ;;
    *.tar.xz) tar -xf ... ;;
    *.7z)     7z x ... ;;    # Add new format
esac
```

---

## Testing Guidelines

### Manual Testing Checklist

```bash
# Test help
./refactored.sh -h

# Test interactive mode
./refactored.sh

# Test individual components
./refactored.sh -g 1687249  # GTK
./refactored.sh -c 1662218  # Cursor
./refactored.sh -i 1686927  # Icon

# Test history restore
./refactored.sh -r

# Test fresh install (delete vault first)
rm -rf ~/.local/share/theme-switcher-vault
./refactored.sh
```

### Function Testing

```bash
# Source without running main
source <(sed '/^main "\$@"/d' refactored.sh)

# Test functions
check_internet_connection && echo "Online"
detect_desktop_environment
get_available_theme_packages
```

---

## Key Files

| File | Purpose |
|------|---------|
| `refactored.sh` | Main script with all logic |
| `files.json` | Tracks installed theme folders |
| `history.json` | Theme change history for restore |
| `Arch.md` | This documentation |

---

## Questions?

- Each section in `refactored.sh` has detailed comments
- Functions include usage examples
- Comments are written to be easy to understand

Happy Contributing! 🎨
