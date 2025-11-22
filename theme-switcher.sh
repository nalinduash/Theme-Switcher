#!/bin/bash
set -e

# GNOME Theme Switcher 
# A comprehensive tool for managing GNOME themes, cursors, and icons at once
# Author: Nalindu Ashirwada
# Version: 1.0

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT="${HOME}/.local/share/theme-switcher-vault"
THEMES_DIR="${HOME}/.local/share/themes"
ICONS_DIR="${HOME}/.local/share/icons"
CURSORS_DIR="${HOME}/.local/share/icons"
WALLPAPERS_DIR="${HOME}/Pictures/Wallpapers"
DATA_JSON='{
    "Dracula": {
        "gtk": {
            "id": "1687249",
            "file": "Dracula.tar.xz",
            "name": "Dracula"
        },
        "cursor": {
            "id": "1662218",
            "file": "Nordic-cursors.tar.xz",
            "name": "Nordic-cursors"
        },
        "icon": {
            "id": "1541561",
            "file": "main.zip",
            "name": "dracula-icons-main"
        },
        "wallpaper": {
            "light": "dracula-light.png",
            "lightURL": "https://raw.githubusercontent.com/dracula/wallpaper/master/first-collection/base.png",
            "dark": "dracula-dark.png",
            "darkURL": "https://raw.githubusercontent.com/dracula/wallpaper/master/first-collection/base.png"
        }
    },
    "Nord": {
        "gtk": {
            "id": "1267246",
            "file": "Nordic-darker.tar.xz",
            "name": "Nordic-darker"
        },
        "cursor": {
            "id": "1662218",
            "file": "Nordic-cursors.tar.xz",
            "name": "Nordic-cursors"
        },
        "icon": {
            "id": "1686927",
            "file": "Nordzy.tar.gz",
            "name": "Nordzy"
        },
        "wallpaper": {
            "light": "dracula-light.png",
            "lightURL": "https://raw.githubusercontent.com/dracula/wallpaper/master/first-collection/base.png",
            "dark": "dracula-dark.png",
            "darkURL": "https://raw.githubusercontent.com/dracula/wallpaper/master/first-collection/base.png"
        }
    },
    "Catppuccin-Mocha": {
        "gtk": {
            "id": "1715554",
            "file": "Catppuccin-B-MB-dark.tar.xz",
            "name": "Catppuccin-B-MB-Dark"
        },
        "cursor": {
            "id": "1148692",
            "file": "capitaine-cursors-r4.tar.gz",
            "name": "capitaine-cursors"
        },
        "icon": {
            "id": "1405756",
            "file": "WhiteSur-grey.tar.xz",
            "name": "WhiteSur-grey"
        },
        "wallpaper": {
            "light": "capitaine-light.png",
            "lightURL": "https://raw.githubusercontent.com/zhichaoh/catppuccin-wallpapers/main/waves/wavy_lines_v01_5120x2880.png",
            "dark": "capitaine-dark.png",
            "darkURL": "https://raw.githubusercontent.com/zhichaoh/catppuccin-wallpapers/main/waves/wavy_lines_v01_5120x2880.png"
        }
    },
    "Graphite": {
        "gtk": {
            "id": "1598493",
            "file": "Graphite-Dark-nord.tar.xz",
            "name": "Graphite-Dark-nord"
        },
        "cursor": {
            "id": "1651517",
            "file": "Graphite-nord.tar.xz",
            "name": "Graphite-dark-nord-cursors"
        },
        "icon": {
            "id": "1359276",
            "file": "Tela-circle-black.tar.xz",
            "name": "Tela-circle-black"
        },
        "wallpaper": {
            "light": "graphite-light.png",
            "lightURL": "https://raw.githubusercontent.com/vinceliuice/Graphite-gtk-theme/main/wallpaper/wallpapers-nord/wave-Light-nord.jpg",
            "dark": "graphite-dark.png",
            "darkURL": "https://raw.githubusercontent.com/vinceliuice/Graphite-gtk-theme/main/wallpaper/wallpapers-nord/wave-Dark-nord.jpg"
        }
    }
}'

# Global variables
json=""


# colours
readonly RED='\033[0;31m'      # errors
readonly GREEN='\033[0;32m'    # success
readonly YELLOW='\033[0;33m'   # warnings / info
readonly BLUE='\033[0;34m'     # info
readonly BOLD='\033[1m'
readonly RESET='\033[0m'


# Messages
error(){
    local msg="$1"
    echo -e "${RED}${BOLD}[ERROR]${RESET} ${msg}"
}

info(){
    local msg="$1"
    echo -e "${BLUE}${BOLD}[INFO]${RESET} ${msg}"
}

success(){
    local msg="$1"
    echo -e "${GREEN}${BOLD}[SUCCESS]${RESET} ${msg}"
}

warn(){
    local msg="$1"
    echo -e "${YELLOW}${BOLD}[WARN]${RESET} ${msg}"
}

header(){
    local title="$1"
    echo -e "\n${BOLD}${BLUE}━━━ ${title} ━━━${RESET}\n"
}


## Helper functions
# Check for dependencies
check_dependencies(){
    # Detect package manager and distribution
    local pkg_manager=""
    local install_cmd=""
    
    if command -v dnf &>/dev/null; then
        pkg_manager="dnf"
        install_cmd="sudo dnf install -yq"
    elif command -v apt &>/dev/null; then
        pkg_manager="apt"
        install_cmd="sudo apt install -y"
    elif command -v pacman &>/dev/null; then
        pkg_manager="pacman"
        install_cmd="sudo pacman -S --noconfirm"
    elif command -v zypper &>/dev/null; then
        pkg_manager="zypper"
        install_cmd="sudo zypper install -y"
    else
        error "Unsupported package manager. Please install dependencies manually:"
        error "  - jq, gum, curl, tar, unzip, glib2 (for gsettings)"
        exit 1
    fi
    
    info "Detected package manager: $pkg_manager"
    
    # Check and install jq
    if ! command -v jq &>/dev/null; then
        warn "jq is required but not installed. Installing..."
        $install_cmd jq
    fi
    
    # Check and install gum
    if ! command -v gum &>/dev/null; then
        warn "gum is required but not installed. Installing..."
        case "$pkg_manager" in
            "dnf")
                $install_cmd gum
                ;;
            "apt")
                # gum requires adding charm repository for Debian/Ubuntu
                if [[ ! -f /etc/apt/sources.list.d/charm.list ]]; then
                    sudo mkdir -p /etc/apt/keyrings
                    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
                    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
                    sudo apt update
                fi
                $install_cmd gum
                ;;
            "pacman")
                $install_cmd gum
                ;;
            "zypper")
                $install_cmd gum
                ;;
        esac
    fi
    
    # Check and install curl
    if ! command -v curl &>/dev/null; then
        warn "curl is required but not installed. Installing..."
        $install_cmd curl
    fi
    
    # Check and install tar (usually pre-installed)
    if ! command -v tar &>/dev/null; then
        warn "tar is required but not installed. Installing..."
        $install_cmd tar
    fi
    
    # Check and install unzip
    if ! command -v unzip &>/dev/null; then
        warn "unzip is required but not installed. Installing..."
        $install_cmd unzip
    fi
    
    # Check and install gsettings (part of glib2)
    if ! command -v gsettings &>/dev/null; then
        warn "gsettings is required but not installed. Installing..."
        case "$pkg_manager" in
            "dnf")
                $install_cmd glib2
                ;;
            "apt")
                $install_cmd libglib2.0-bin
                ;;
            "pacman")
                $install_cmd glib2
                ;;
            "zypper")
                $install_cmd glib2-tools
                ;;
        esac
    fi
    
    success "All dependencies are installed!"
}

# Get theme package names
get_theme_names(){
    echo "$DATA_JSON" | jq -r 'keys[]'
}

# Parse values from the data.json to variables
read_value(){
    local key="$1"
    local themePackage="$2"
    echo "$DATA_JSON" | jq -er ".[\"$themePackage\"]$key"
}

#Load json data file from the gnome-look-org
load_json(){
    local id="$1"

    json=$(curl -Lfs "https://www.gnome-look.org/p/${id}/loadFiles")
    if [[ -z "$json" ]]; then
        error "Failed to fetch loadFiles JSON."
        return 1
    fi

    echo "$json"
}

# Check if the theme is in vault
is_in_vault(){
    local type="$1"
    local name="$2"
    local id="$3"

    if [[ -d "$VAULT/$type/$id/$name" ]]; then
        return 0
    fi

    return 1
}

# Get the latest updated date of the local theme
get_local_theme_last_updated_date() {
    local dir="$1"

    if [[ ! -d "$dir" ]]; then
        error "$dir is not a directory."
        return 1
    fi

    # Find newest file/directory mtime
    newest=$(find "$dir" -type f -printf "%T@\n" 2>/dev/null | sort -nr | head -n 1)

    if [[ -z "$newest" ]]; then
        error "No files found in directory."
        return 1
    fi

    # Convert UNIX timestamp → readable date
    date -d @"${newest%.*}" "+%Y-%m-%d %H:%M:%S"
}

# Get the latest updated date of the Gnome-look.org theme
get_remote_theme_last_updated_date() {
    local json="$1"
    local file="$2"

    # Extract updated_timestamp of active=1 entries
    last_updated=$(echo "$json" \
        | jq -r --arg name "$file" '.files[] | select(.active == "1" and .name == $name) | .updated_timestamp' \
        | head -n 1)

    if [[ -z "$last_updated" || "$last_updated" == "null" ]]; then
        error "Could not find active file updated_timestamp."
        return 1
    fi

    echo "$last_updated"
}

# Download the theme
download_theme() {
    local json="$1"
    local file="$2"
    local type="$3"
    local id="$4"

    # Extract encoded URL for that variant
    encoded_url=$(echo "$json" | jq -r --arg name "$file" \
        '.files[] | select(.active == "1" and .name == $name) | .url' | head -n 1)

    if [[ -z "$encoded_url" || "$encoded_url" == "null" ]]; then
        error "URL not found for '$file'."
        return 1
    fi

    # Decode percent encoding
    url=$(printf '%b' "${encoded_url//%/\\x}")

    # Create directory if it doesn't exist
    mkdir -p "$VAULT/$type/$id"
    if [[ -f "$VAULT/$type/$id/$file" ]]; then
        rm "$VAULT/$type/$id/$file"
    fi

    # Download
    curl -L -o "$VAULT/$type/$id/$file" "$url"
}

extract_theme() {
    local type="$1"
    local file="$2"
    local id="$3"

    mkdir -p "$VAULT/$type/$id"

    # Extract theme
    case "$file" in
        *.zip)
            unzip -o "$VAULT/$type/$id/$file" -d "$VAULT/$type/$id"
            ;;
        *.tar.xz)
            tar -xf "$VAULT/$type/$id/$file" -C "$VAULT/$type/$id"
            ;;
        *.tar.gz)
            tar -xzf "$VAULT/$type/$id/$file" -C "$VAULT/$type/$id"
            ;;
        *)
            error "Unknown format: $file"
            return 1
            ;;
    esac
}   

# Show help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -g <ID>    Install GTK theme by GNOME-Look ID"
    echo "  -c <ID>    Install cursor theme by GNOME-Look ID"
    echo "  -i <ID>    Install icon theme by GNOME-Look ID"
    echo "  -h         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -g 2315765    # Install GTK theme with ID 2315765"
    echo "  $0 -c 1411743    # Install cursor theme with ID 1411743"
    echo "  $0 -i 1686927    # Install icon theme with ID 1686927"
    echo ""
    echo "If no options are provided, the script runs in interactive mode."
}

# Get the name of the extracted directory
get_extracted_dir_name() {
    local type="$1"
    local id="$2"
    
    # Find the first directory in the vault for this type/id (excluding the archive file)
    local dir_name=$(find "$VAULT/$type/$id" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | head -n 1)
    
    if [[ -z "$dir_name" ]]; then
        error "Could not find extracted directory in $VAULT/$type/$id"
        return 1
    fi
    
    echo "$dir_name"
}

# Install a single component by ID (with vault checking and update logic)
install_single_component() {
    local type="$1"
    local id="$2"
    
    info "Processing $type theme with ID: $id"
    
    # Load JSON from GNOME-Look
    local json
    json=$(load_json "$id")
    
    # Get list of active files
    local files
    files=$(echo "$json" | jq -r '.files[] | select(.active == "1") | .name')
    
    if [[ -z "$files" ]]; then
        error "No active files found for ID $id"
        exit 1
    fi
    
    # Count files and let user choose if multiple
    local file_count
    file_count=$(echo "$files" | wc -l)
    
    local chosen_file
    if [[ "$file_count" -gt 1 ]]; then
        chosen_file=$(echo "$files" | gum choose --header "Pick a file for this theme:")
    else
        chosen_file="$files"
    fi
    
    if [[ -z "$chosen_file" ]]; then
        error "No file selected."
        exit 1
    fi
    
    # Derive theme name from filename (remove extension)
    local theme_name="${chosen_file%%.*}"
    
    # Check if theme exists in vault and compare timestamps
    local remote_updated
    remote_updated=$(get_remote_theme_last_updated_date "$json" "$chosen_file")
    
    local local_updated=""
    if [[ -d "$VAULT/$type/$id/$theme_name" ]]; then
        local_updated=$(get_local_theme_last_updated_date "$VAULT/$type/$id/$theme_name") || true
    fi
    
    local need_download=false
    
    if is_in_vault "$type" "$theme_name" "$id"; then
        if [[ -n "$local_updated" && "$remote_updated" > "$local_updated" ]]; then
            info "$type theme is out of date. Downloading..."
            need_download=true
        else
            info "$type theme is up to date."
        fi
    else
        info "$type theme is not in vault. Downloading..."
        need_download=true
    fi
    
    # Download and extract if needed
    if [[ "$need_download" == "true" ]]; then
        download_theme "$json" "$chosen_file" "$type" "$id"
        info "$type theme downloaded."
        extract_theme "$type" "$chosen_file" "$id"
        info "$type theme extracted."
    fi
    
    # Get the actual extracted directory name
    local extracted_name
    extracted_name=$(get_extracted_dir_name "$type" "$id")
    
    if [[ -z "$extracted_name" ]]; then
        error "Could not determine extracted directory name."
        exit 1
    fi
    
    # Install and apply
    local install_func="install_${type}"
    local apply_func="apply_${type}"
    
    $install_func "$extracted_name" "$id"
    $apply_func "$extracted_name"
    
    success "$type theme ($extracted_name) installed and applied!"
}


# Install cursor
install_cursor() {
    local cursor_name="$1"
    local id="$2"

    # delete if exist
    rm -rf "$CURSORS_DIR/$cursor_name"

    # copy cursor to cursor directory
    cp -r "$VAULT/cursor/$id/$cursor_name" "$CURSORS_DIR/$cursor_name"
}
    
# Apply cursor
apply_cursor() {
    local cursor_name="$1"
    gsettings set org.gnome.desktop.interface cursor-theme "$cursor_name"
}

# Install icon
install_icon() {
    local icon_name="$1"
    local id="$2"

    # delete if exist
    rm -rf "$ICONS_DIR/$icon_name"

    # copy icon to icon directory
    cp -r "$VAULT/icon/$id/$icon_name" "$ICONS_DIR/$icon_name"
}

# Apply icon
apply_icon() {
    local icon_name="$1"
    gsettings set org.gnome.desktop.interface icon-theme "$icon_name"
}

# Download wallpaper
download_wallpaper() {
    local url="$1"
    local filename="$2"

    # Create directory if it doesn't exist
    mkdir -p "$VAULT/wallpaper"

    # Download wallpaper
    curl -L -o "$VAULT/wallpaper/$filename" "$url"
}

# Install wallpaper
install_wallpaper() {
    local filename="$1"

    # Create wallpapers directory if it doesn't exist
    mkdir -p "$WALLPAPERS_DIR"

    # Copy wallpaper to Pictures directory
    cp "$VAULT/wallpaper/$filename" "$WALLPAPERS_DIR/$filename"
}

# Apply wallpaper
apply_wallpaper() {
    local light_wallpaper="$1"
    local dark_wallpaper="$2"

    # Set light wallpaper
    gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPERS_DIR/$light_wallpaper"
    
    # Set dark wallpaper
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPERS_DIR/$dark_wallpaper"
}

# Install GTK theme
install_gtk() {
    local theme_name="$1"
    local id="$2"

    # delete if exist
    rm -rf "$THEMES_DIR/$theme_name"

    # copy theme to themes directory
    cp -r "$VAULT/gtk/$id/$theme_name" "$THEMES_DIR/$theme_name"
}

# Apply GTK3 theme
apply_gtk3() {
    local theme_name="$1"
    gsettings set org.gnome.desktop.interface gtk-theme "$theme_name"
}

# Apply Shell theme
apply_shell() {
    local theme_name="$1"
    gsettings set org.gnome.shell.extensions.user-theme name "$theme_name"
}

# Apply GTK4 theme (libadwaita bypass)
apply_gtk4() {
    local theme_name="$1"
    local config_dir="$HOME/.config"
    
    # Remove previous theme config
    rm -rf "$config_dir/gtk-4.0/gtk.css"
    rm -rf "$config_dir/gtk-4.0/gtk-dark.css"
    rm -rf "$config_dir/gtk-4.0/assets"
    rm -rf "$config_dir/assets"

    # Create gtk-4.0 directory if it doesn't exist
    mkdir -p "$config_dir/gtk-4.0"

    # Link new theme files
    if [[ -f "$THEMES_DIR/$theme_name/gtk-4.0/gtk.css" ]]; then
        ln -s "$THEMES_DIR/$theme_name/gtk-4.0/gtk.css" "$config_dir/gtk-4.0/gtk.css"
    fi
    
    if [[ -f "$THEMES_DIR/$theme_name/gtk-4.0/gtk-dark.css" ]]; then
        ln -s "$THEMES_DIR/$theme_name/gtk-4.0/gtk-dark.css" "$config_dir/gtk-4.0/gtk-dark.css"
    fi
    
    if [[ -d "$THEMES_DIR/$theme_name/gtk-4.0/assets" ]]; then
        ln -s "$THEMES_DIR/$theme_name/gtk-4.0/assets" "$config_dir/gtk-4.0/assets"
    fi
    
    if [[ -d "$THEMES_DIR/$theme_name/assets" ]]; then
        ln -s "$THEMES_DIR/$theme_name/assets" "$config_dir/assets"
    fi
}


# Apply all GTK related themes
apply_gtk() {
    local theme_name="$1"
    apply_gtk3 "$theme_name"
    apply_shell "$theme_name"
    apply_gtk4 "$theme_name"
}

# Manage wallpapers
manage_wallpapers() {
    local light_file="$1"
    local light_url="$2"
    local dark_file="$3"
    local dark_url="$4"

    info "Managing wallpapers..."

    # Check if wallpapers exist in vault
    if [[ -f "$VAULT/wallpaper/$light_file" ]] && [[ -f "$VAULT/wallpaper/$dark_file" ]]; then
        info "Wallpapers are already in vault."
    else
        info "Wallpapers not in vault (or incomplete). Downloading..."
        
        # Download light wallpaper
        if [[ ! -f "$VAULT/wallpaper/$light_file" ]]; then
            info "Downloading light wallpaper..."
            download_wallpaper "$light_url" "$light_file" || exit 1
            info "Light wallpaper downloaded."
        fi
        
        # Download dark wallpaper
        if [[ ! -f "$VAULT/wallpaper/$dark_file" ]]; then
            info "Downloading dark wallpaper..."
            download_wallpaper "$dark_url" "$dark_file" || exit 1
            info "Dark wallpaper downloaded."
        fi
    fi

    # Install and apply wallpapers
    install_wallpaper "$light_file"
    install_wallpaper "$dark_file"
    apply_wallpaper "$light_file" "$dark_file"
    success "Wallpapers applied successfully!"
}

# Generic component manager
manage_component() {
    local type="$1"
    local id="$2"
    local file="$3"
    local name="$4"
    
    local install_func="install_${type}"
    local apply_func="apply_${type}"
    local dir_var=""
    
    # Determine directory variable based on type
    case "$type" in
        "gtk") dir_var="$THEMES_DIR" ;;
        "cursor") dir_var="$CURSORS_DIR" ;; 
        "icon") dir_var="$ICONS_DIR" ;;
        *) error "Unknown component type: $type"; return 1 ;;
    esac
    
    info "Managing $type theme: $name"

    local json
    json=$(load_json "$id")
    
    local remote_updated
    remote_updated=$(get_remote_theme_last_updated_date "$json" "$file")
    
    local local_updated=""
    if [[ -d "$VAULT/$type/$id/$name" ]]; then
        local_updated=$(get_local_theme_last_updated_date "$VAULT/$type/$id/$name") || true
    fi

    local need_download=false
    
    if is_in_vault "$type" "$name" "$id"; then
        if [[ -n "$local_updated" && "$remote_updated" > "$local_updated" ]]; then
            info "$type theme is out of date. Downloading..."
            need_download=true
        else
            info "$type theme is up to date."
        fi
    else
        info "$type theme is not in vault. Downloading..."
        need_download=true
    fi
    
    if [[ "$need_download" == "true" ]]; then
        download_theme "$json" "$file" "$type" "$id"
        info "$type theme downloaded."
        extract_theme "$type" "$file" "$id"
    fi
    
    # Always install and apply to ensure consistency
    $install_func "$name" "$id"
    $apply_func "$name"
    success "$type theme applied successfully!"
}

### Starting point
mkdir -p $VAULT
check_dependencies

# Parse CLI arguments
if [[ $# -gt 0 ]]; then
    while getopts "g:c:i:h" opt; do
        case $opt in
            g) 
                install_single_component "gtk" "$OPTARG"
                exit 0
                ;;
            c) 
                install_single_component "cursor" "$OPTARG"
                exit 0
                ;;
            i) 
                install_single_component "icon" "$OPTARG"
                exit 0
                ;;
            h) 
                show_help
                exit 0
                ;;
            *) 
                error "Invalid option. Use -h for help."
                exit 1
                ;;
        esac
    done
fi

echo "                                                                                            ";
echo "                                                                                            ";
echo " .--.                       .---..                       .-.             .     .            ";
echo ":                             |  |                      (   )         o _|_    |            ";
echo "| --..--. .-. .--.--. .-.     |  |--. .-. .--.--. .-.    \`-..  .    ._.  |  .-.|--. .-. .--.";
echo ":   ||  |(   )|  |  |(.-'     |  |  |(.-' |  |  |(.-'   (   )\\  \\  /  |  | (   |  |(.-' |   ";
echo " \`--''  \`-\`-' '  '  \`-\`--'    '  '  \`-\`--''  '  \`-\`--'   \`-'  \`' \`' -' \`-\`-'\`-''  \`-\`--''   ";
echo "                                                                                            ";
echo "                                                                                            ";

themes="$(get_theme_names)" || exit 1  
chosen="$(echo "$themes" | gum choose --header "Pick a theme package:")" || {
    error "No theme selected."
    exit 1
}

CURSOR_ID=$(read_value     ".cursor.id"     "$chosen")
CURSOR_FILE=$(read_value   ".cursor.file"   "$chosen")
CURSOR_NAME=$(read_value   ".cursor.name"   "$chosen")

GTK_ID=$(read_value     ".gtk.id"       "$chosen")
GTK_FILE=$(read_value   ".gtk.file"     "$chosen")
GTK_NAME=$(read_value   ".gtk.name"     "$chosen")

ICON_ID=$(read_value     ".icon.id"     "$chosen")
ICON_FILE=$(read_value   ".icon.file"   "$chosen")
ICON_NAME=$(read_value   ".icon.name"   "$chosen")

WALLPAPER_LIGHT_FILE=$(read_value ".wallpaper.light"    "$chosen")
WALLPAPER_LIGHT_URL=$(read_value  ".wallpaper.lightURL" "$chosen")
WALLPAPER_DARK_FILE=$(read_value  ".wallpaper.dark"     "$chosen")
WALLPAPER_DARK_URL=$(read_value   ".wallpaper.darkURL"  "$chosen")

info "You selecthed $chosen theme package"
info "These themes will be applied:"
info "  $GTK_NAME"
info "  $CURSOR_NAME"
info "  $ICON_NAME"


### GTK Theme
manage_component "gtk" "$GTK_ID" "$GTK_FILE" "$GTK_NAME"

### Cursor
manage_component "cursor" "$CURSOR_ID" "$CURSOR_FILE" "$CURSOR_NAME"

### Icon
manage_component "icon" "$ICON_ID" "$ICON_FILE" "$ICON_NAME"

### Wallpaper
manage_wallpapers "$WALLPAPER_LIGHT_FILE" "$WALLPAPER_LIGHT_URL" "$WALLPAPER_DARK_FILE" "$WALLPAPER_DARK_URL"
success "Theme Switcher completed successfully!"