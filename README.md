# GNOME Theme Switcher
A comprehensive command-line tool for managing GNOME themes, cursors, and icons with automatic downloading, caching, and version management.

| Graphite Theme Package | Dracula Theme Package | Catppuccin Theme Package |  
|--|--|--|
| ![Graphite Theme Package](https://github.com/user-attachments/assets/c7902645-5803-46cd-a330-f1e815f5b23d) | ![Dracula Theme Package](https://github.com/user-attachments/assets/92dcbe5f-06de-4a82-9dff-daf14c966404) |	![Catppuccin Theme Package](https://github.com/user-attachments/assets/a44e8d90-b8cd-4e24-97ce-24e875d9e8cf) |

<br>

## Features

- 🎨 **Complete Theme Management**: Install and apply GTK themes, cursor themes, and icon themes
- 📦 **Theme Packages**: Pre-configured theme packages (Dracula, Nord, Catppuccin-Mocha, Graphite)
- 🔄 **Automatic Updates**: Checks for theme updates and downloads only when necessary
- 💾 **Smart Caching**: Stores downloaded themes in a local vault to avoid re-downloading
- 🖼️ **Wallpaper Support**: Automatically downloads and applies matching wallpapers (Only for Pre-configured theme packages)
- 🎯 **CLI & Interactive Modes**: Use command-line arguments or interactive menu
- 🔧 **Auto-Dependency Installation**: Automatically installs required dependencies
- 📜 **Restore Previous Themes**: Let you restore previous themes by automatically tracking theme history

> Graphite Theme is my favourite BTW 🤗

<br>

## Download and Installation

```bash
# Download the script
curl -O https://raw.githubusercontent.com/nalinduash/Theme-Switcher/main/theme-switcher.sh

# Make it executable
chmod +x theme-switcher.sh

# Make it available in terminal (Optional, but recommended)
mkdir -p ~/.local/bin
mv theme-switcher.sh ~/.local/bin/theme-switcher

# Run it
theme-switcher
```
<br>

## How to use
### 1) - Interactive Mode
```bash
theme-switcher
```
You'll be presented with a menu to choose from pre-configured theme packages:
- **Dracula**: Orchis-Green GTK + WhiteSur cursors + Nordzy-yellow icons
- **Nord**: Nordic GTK + Nordzy cursors + Nordzy icons
- **Catppuccin-Mocha**: Catppuccin Mocha theme package
- **Graphite**: Graphite GTK + Graphite cursors + Graphite icons

### 2) - CLI Mode
#### 2.1) - Install GTK Theme
```bash
theme-switcher -g <GNOME-LOOK-ID>
```
You can replace <GNOME-LOOK-ID> with the correct ID from the [gnome-look.org](https://www.gnome-look.org) site

#### 2.2) - Install Cursor Theme
```bash
theme-switcher.sh -c <GNOME-LOOK-ID>
```
You can replace <GNOME-LOOK-ID> with the correct ID from the [gnome-look.org](https://www.gnome-look.org) site

#### 2.3) - Install Icon Theme
```bash
theme-switcher.sh -i <GNOME-LOOK-ID>
```
You can replace <GNOME-LOOK-ID> with the correct ID from the [gnome-look.org](https://www.gnome-look.org) site

#### 2.4) - Restore Previous Theme
```bash
theme-switcher.sh -r
```
You'll be presented with a list of all the previous themes you have installed with this script. You can choose one of them to apply.

#### 2.5) - See the help menu
```bash
theme-switcher.sh -h
```
<br>

**Example workflow for installing custom themes:**
```bash
# Install a custom GTK theme
./theme-switcher.sh -g 2315765

# Install matching cursor theme
./theme-switcher.sh -c 1234567

# Install matching icon theme
./theme-switcher.sh -i 7654321
```

<br>

## Dependencies

The script automatically installs these dependencies if missing:
- `jq` - JSON parsing
- `gum` - Interactive UI components
- `curl` - Downloading themes
- `tar` - Extracting archives
- `unzip` - Extracting ZIP files
- `user-theme extension` - Applying GNOME themes (Need to install manually)

> If shell-theme didn't apply correctly, try  `user-theme extension` might be missing. Install it and try again. [User Themes Gnome Extension](https://extensions.gnome.org/extension/19/user-themes/)

