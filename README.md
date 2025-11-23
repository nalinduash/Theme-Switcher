# GNOME Theme Switcher

A comprehensive command-line tool for managing GNOME themes, cursors, and icons with automatic downloading, caching, and version management.

<img width="1920" height="1033" alt="Screenshot From 2025-11-22 23-27-43" src="https://github.com/user-attachments/assets/c7902645-5803-46cd-a330-f1e815f5b23d" />
<img width="1916" height="1039" alt="Screenshot From 2025-11-22 23-30-26" src="https://github.com/user-attachments/assets/92dcbe5f-06de-4a82-9dff-daf14c966404" />
<img width="1920" height="1033" alt="Screenshot From 2025-11-22 23-32-11" src="https://github.com/user-attachments/assets/a44e8d90-b8cd-4e24-97ce-24e875d9e8cf" />

## Features

- 🎨 **Complete Theme Management**: Install and apply GTK themes, cursor themes, and icon themes
- 📦 **Theme Packages**: Pre-configured theme packages (Dracula, Nord, Catppuccin-Mocha, Graphite)
- 🔄 **Automatic Updates**: Checks for theme updates and downloads only when necessary
- 💾 **Smart Caching**: Stores downloaded themes in a local vault to avoid re-downloading
- 🖼️ **Wallpaper Support**: Automatically downloads and applies matching wallpapers
- 🎯 **CLI & Interactive Modes**: Use command-line arguments or interactive menu
- 🔧 **Auto-Dependency Installation**: Automatically installs required dependencies

## Prerequisites
The script will automatically install missing dependencies

## Download and Installation

### Method 1: Direct Download

```bash
# Download the script
curl -O https://raw.githubusercontent.com/nalinduash/Theme-Switcher/main/theme-switcher.sh

# Make it executable
chmod +x theme-switcher.sh

# Make it available in terminal
cp theme-switcher.sh ~/.local/bin

# Run it
theme-switcher
```

### Method 2: Clone Repository

```bash
# Clone the repository
git clone https://github.com/nalinduash/Theme-Switcher.git

# Navigate to directory
cd Theme-Switcher

# Make it executable
chmod +x theme-switcher.sh

# Make it available in terminal
cp theme-switcher.sh ~/.local/bin

# Run it
theme-switcher
```

## Usage

### Interactive Mode

Simply run the script without any arguments to launch the interactive menu:

```bash
theme-switcher
```

You'll be presented with a menu to choose from pre-configured theme packages:
- **Dracula**: Orchis-Green GTK + WhiteSur cursors + Nordzy-yellow icons
- **Nord**: Nordic GTK + Nordzy cursors + Nordzy icons
- **Catppuccin-Mocha**: Catppuccin Mocha theme package
- **Graphite**: Graphite GTK + Graphite cursors + Graphite icons


### CLI Mode

Install individual themes using command-line arguments:
You can replace <GNOME-LOOK-ID> with the correct ID from the [gnome-look.org](https://www.gnome-look.org) site

#### Install GTK Theme

```bash
theme-switcher -g <GNOME-LOOK-ID>
```
#### Install Cursor Theme

```bash
./theme-switcher.sh -c <GNOME-LOOK-ID>
```
#### Install Icon Theme

```bash
./theme-switcher.sh -i <GNOME-LOOK-ID>
```

### Using Theme Package Method

Theme packages are pre-configured combinations of GTK, cursor, icon themes, and wallpapers. To use them:

1. Run the script in interactive mode:
   ```bash
   theme-switcher
   ```

2. Select a theme package from the menu (e.g., "Dracula", "Nord", etc.)

3. The script will automatically:
   - Check if themes are already cached
   - Download themes if needed or if updates are available
   - Extract and install all components
   - Apply the themes to your GNOME desktop
   - Download and set matching wallpapers

### Using Custom Theme Method

To install custom themes not in the pre-configured packages:

1. **Find the theme on GNOME-Look.org**:
   - Visit [gnome-look.org](https://www.gnome-look.org/)
   - Search for your desired theme
   - Note the ID from the URL (e.g., `https://www.gnome-look.org/p/1357889/` → ID is `1357889`)

2. **Install using CLI mode**:
   ```bash
   # For GTK themes
   theme-switcher -g 1357889
   
   # For cursor themes
   theme-switcher -c 1411743
   
   # For icon themes
   theme-switcher -i 1686927
   ```

3. **Interactive file selection**:
   - If the theme has multiple variants, you'll be prompted to choose which one to install
   - Use arrow keys to select and press Enter

**Example workflow:**
```bash
# Install a custom GTK theme
./theme-switcher.sh -g 2315765

# Install matching cursor theme
./theme-switcher.sh -c 1234567

# Install matching icon theme
./theme-switcher.sh -i 7654321
```

## How It Works

1. **Vault System**: Downloaded themes are stored in `~/.local/share/theme-switcher-vault/` organized by type and ID
2. **Version Checking**: Compares local theme timestamps with remote versions to detect updates
3. **Smart Installation**: Only downloads when necessary (new theme or update available)
4. **Automatic Application**: Themes are automatically applied using `gsettings` after installation

## Dependencies

The script automatically installs these dependencies if missing:
- `jq` - JSON parsing
- `gum` - Interactive UI components
- `curl` - Downloading themes
- `tar` - Extracting archives
- `unzip` - Extracting ZIP files
- `gsettings` - Applying GNOME settings

## Troubleshooting

### Permission Errors
If you encounter permission errors, ensure the script is executable:
```bash
chmod +x theme-switcher.sh
```

### Dependency Installation Fails
If automatic dependency installation fails, install manually:
```bash
# For Fedora/RHEL
sudo dnf install jq gum curl tar unzip glib2

# For Ubuntu/Debian
sudo apt install jq gum curl tar unzip libglib2.0-bin

# For Arch Linux
sudo pacman -S jq gum curl tar unzip glib2
```

### Theme Not Applying
1. Ensure you're using GNOME desktop environment
2. For shell themes, install the User Themes extension:
   ```bash
   gnome-extensions install user-theme@gnome-shell-extensions.gcampax.github.com
   ```
3. Log out and log back in to see changes

### Finding Theme IDs
1. Go to [gnome-look.org](https://www.gnome-look.org/)
2. Search for your theme
3. The ID is in the URL: `https://www.gnome-look.org/p/XXXXXXX/`

## Contributing

Contributions are welcome! Feel free to:
- Add new theme packages to the `DATA_JSON` configuration
- Report bugs or issues
- Suggest new features

## License

This project is open source and available under the MIT License.

## Author

**Nalindu Ashirwada**

## Acknowledgments

- Theme creators on GNOME-Look.org
- The GNOME community
- All theme package maintainers
