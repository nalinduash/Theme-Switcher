#!/bin/bash

# GNOME Theme Switcher 
# A comprehensive tool for managing GNOME themes, cursors, and icons at once
# Author: Nalindu Ashirwada
# Version: 1.5

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT="${HOME}/.local/share/theme-switcher-vault"
THEMES_DIR="${HOME}/.local/share/themes"
ICONS_DIR="${HOME}/.local/share/icons"
CURSORS_DIR="${HOME}/.local/share/icons"
WALLPAPERS_DIR="${HOME}/Pictures/Wallpapers"
HISTORY_FILE="$VAULT/history.json"
FILES_JSON="$VAULT/files.json"
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


#  <========= Messages =========>
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
#  <========= END of Messages =========>



#  <========= System & Dependency Management =========>
# Detect package manager and return manager name and install command
detect_package_manager() {
    if command -v dnf &>/dev/null; then
        echo "dnf|sudo dnf install -yq"
    elif command -v apt &>/dev/null; then
        echo "apt|sudo apt install -y"
    elif command -v pacman &>/dev/null; then
        echo "pacman|sudo pacman -S --noconfirm"
    elif command -v zypper &>/dev/null; then
        echo "zypper|sudo zypper install -y"
    else
        return 1
    fi
}

# Setup gum repository for apt-based systems
setup_gum_repository() {
    if [[ ! -f /etc/apt/sources.list.d/charm.list ]]; then
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
        sudo apt update
    fi
}

# Check and install a single dependency
check_and_install_dependency() {
    local cmd="$1"
    local package="$2"
    local pkg_manager="$3"
    local install_cmd="$4"
    
    if ! command -v "$cmd" &>/dev/null; then
        warn "$cmd is required but not installed. Installing..."
        
        # Special handling for gum on apt
        if [[ "$cmd" == "gum" && "$pkg_manager" == "apt" ]]; then
            setup_gum_repository
        fi
        
        $install_cmd "$package"
    fi
}

# Get package name for gsettings based on package manager
get_gsettings_package() {
    local pkg_manager="$1"
    
    case "$pkg_manager" in
        "dnf") echo "glib2" ;;
        "apt") echo "libglib2.0-bin" ;;
        "pacman") echo "glib2" ;;
        "zypper") echo "glib2-tools" ;;
        *) echo "glib2" ;;
    esac
}

# Check for all required dependencies
check_dependencies() {
    local pkg_info
    pkg_info=$(detect_package_manager)
    
    if [[ $? -ne 0 ]]; then
        error "Unsupported package manager. Please install dependencies manually:"
        error "  - jq, gum, curl, tar, unzip, glib2 (for gsettings)"
        exit 1
    fi
    
    IFS='|' read -r pkg_manager install_cmd <<< "$pkg_info"
    info "Detected package manager: $pkg_manager"
    
    # Check and install each dependency
    check_and_install_dependency "jq" "jq" "$pkg_manager" "$install_cmd"
    check_and_install_dependency "gum" "gum" "$pkg_manager" "$install_cmd"
    check_and_install_dependency "curl" "curl" "$pkg_manager" "$install_cmd"
    check_and_install_dependency "tar" "tar" "$pkg_manager" "$install_cmd"
    check_and_install_dependency "unzip" "unzip" "$pkg_manager" "$install_cmd"
    
    # gsettings requires special package name handling
    local gsettings_pkg=$(get_gsettings_package "$pkg_manager")
    check_and_install_dependency "gsettings" "$gsettings_pkg" "$pkg_manager" "$install_cmd"
    
    success "All dependencies are installed!"
}
#  <========= END of System & Dependency Management =========>



#  <========= JSON & Data Functions =========>
# Get theme package names
get_theme_package_names(){
    echo "$DATA_JSON" | jq -r 'keys[]'
}

# Get key values from the data.json for relevant theme package
read_value(){
    local key="$1"
    local themePackage="$2"
    echo "$DATA_JSON" | jq -er ".\"$themePackage\"$key"
}

# Load json data file from the gnome-look-org
load_json(){
    local id="$1"

    json=$(curl -Lfs "https://www.gnome-look.org/p/${id}/loadFiles")
    if [[ -z "$json" ]]; then
        error "Failed to fetch loadFiles JSON."
        return 1
    fi

    echo "$json"
}

# Select the name/s of the theme file/s from available files in JSON
select_theme_file() {
    local json="$1"
    local id="$2"
    
    # Get list of active files
    local files
    files=$(echo "$json" | jq -r '.files[] | select(.active == "1") | .name')
    
    if [[ -z "$files" ]]; then
        error "No active files found for ID $id"
        return 1
    fi
    
    # Count files and let user choose if multiple
    local file_count
    file_count=$(echo "$files" | wc -l)
    
    if [[ "$file_count" -gt 1 ]]; then
        echo "$files" | gum choose --header "Pick a file for this theme:"
    else
        echo "$files"
    fi
}

# Derive theme name from filename by getting the name before the dot
derive_theme_name() {
    local filename="$1"
    echo "${filename%%.*}"
}
#  <========= END of JSON & Data Functions =========>



#  <========= Vault & Storage Functions =========>
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

# Get all extracted directory names for a theme (handles variants like light/dark)
get_extracted_dir_names() {
    local type="$1"
    local id="$2"
    
    # Find all directories in the vault for this type/id (excluding the archive file)
    local dir_names=$(find "$VAULT/$type/$id" -mindepth 1 -maxdepth 1 -type d -printf "%f\n")
    
    if [[ -z "$dir_names" ]]; then
        error "Could not find extracted directories in $VAULT/$type/$id"
        return 1
    fi
    
    echo "$dir_names"
}

# Get the primary (first) extracted directory name - used for applying themes
get_primary_dir_name() {
    local type="$1"
    local id="$2"
    
    # Get all directories and return the first one
    local dir_name=$(get_extracted_dir_names "$type" "$id" | head -n 1)
    
    if [[ -z "$dir_name" ]]; then
        error "Could not find primary directory in $VAULT/$type/$id"
        return 1
    fi
    
    echo "$dir_name"
}
#  <========= END of Vault & Storage Functions =========>



#  <========= Timestamp & Update Functions =========>
# Get the latest updated date of the local theme
get_local_theme_last_updated_date() {
    local dir="$1"

    if [[ ! -d "$dir" ]]; then
        error "$dir is not a directory."
        return 1
    fi

    # Find newest file/directory mtime and return
    newest=$(find "$dir" -type f -printf "%T@\n" 2>/dev/null | sort -nr | head -n 1)

    if [[ -z "$newest" ]]; then
        error "No files found in directory."
        return 1
    fi

    # Return UNIX timestamp
    echo "${newest%.*}"
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

    # Convert the date string to UNIX timestamp
    # API returns format like "2022-01-07 09:15:30"
    date -d "$last_updated" +%s
}

# Update extracted theme timestamp to match remote
update_theme_timestamp() {
    local type="$1"
    local id="$2"
    
    # Use current system time for timestamp
    local now=$(date +%s)
    
    if [[ -d "$VAULT/$type/$id" ]]; then
        # Update all extracted directories in the ID folder
        # This handles cases where an archive extracts multiple directories (e.g. Theme and Theme-Dark)
        find "$VAULT/$type/$id" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
            # Recursively update all files and the directory itself
            # Use -h to handle symlinks without following them
            find "$dir" -exec touch -h -d "@$now" {} + 2>/dev/null || true
        done
        info "Updated local timestamp to current time."
    fi
}

# Determine if theme needs to be downloaded
should_download_theme() {
    local type="$1"
    local id="$2"
    local name="$3"
    local json="$4"
    local file="$5"
    
    # If not in vault, download is needed
    if ! is_in_vault "$type" "$name" "$id"; then
        info "$type theme is not in vault. Downloading..."
        return 0
    fi
    
    # If in vault, check if update is needed
    local local_updated=""
    if [[ -d "$VAULT/$type/$id/$name" ]]; then
        local_updated=$(get_local_theme_last_updated_date "$VAULT/$type/$id/$name") || true
    fi

    # Get remote update timestamp
    local remote_updated=""
    remote_updated=$(get_remote_theme_last_updated_date "$json" "$file")
    
    if [[ -n "$local_updated" && "$remote_updated" -gt "$local_updated" ]]; then
        info "$type theme is out of date. Downloading..."
        return 0
    fi
    
    info "$type theme is up to date."
    return 1
}
#  <========= END of Timestamp & Update Functions =========>



#  <========= Download & Extraction Functions =========>
# Clean old theme versions
clean_theme() {
    local type="$1"
    local id="$2"
    
    info "Cleaning up old version of $type theme (ID: $id)..."
    
    # Get all folders for this theme from files.json
    local folders=$(get_theme_folders "$type" "$id")
    
    # Determine installation directory
    local install_dir=""
    case "$type" in
        "gtk") install_dir="$THEMES_DIR" ;;
        "cursor") install_dir="$CURSORS_DIR" ;;
        "icon") install_dir="$ICONS_DIR" ;;
    esac
    
    # Remove each tracked folder from installation directory
    if [[ -n "$folders" && -n "$install_dir" ]]; then
        while IFS= read -r folder; do
            if [[ -n "$folder" && -d "$install_dir/$folder" ]]; then
                rm -rf "$install_dir/$folder"
            fi
        done <<< "$folders"
    fi
    
    # Remove from vault
    if [[ -d "$VAULT/$type/$id" ]]; then
        rm -rf "$VAULT/$type/$id"
    fi
    
    # Remove entry from files.json
    if [[ -f "$FILES_JSON" ]]; then
        local updated_json=$(jq --arg type "$type" --arg id "$id" \
            'del(.[$type][$id])' "$FILES_JSON")
        echo "$updated_json" > "$FILES_JSON"
    fi
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

    # Delete file if exist
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

# Download and prepare theme (download, extract, update timestamp, track files)
download_and_prepare_theme() {
    local type="$1"
    local id="$2"
    local json="$3"
    local file="$4"
    
    download_theme "$json" "$file" "$type" "$id"
    info "$type theme downloaded."
    
    extract_theme "$type" "$file" "$id"
    info "$type theme extracted."
    
    update_theme_timestamp "$type" "$id"
    update_files_json "$type" "$id"
    
    # Return all extracted directory names (for caching icons on all variants)
    get_extracted_dir_names "$type" "$id"
}
#  <========= END of Download & Extraction Functions =========>



#  <========= CLI & Help Functions =========>
# Show help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -g <ID>    Install GTK theme by GNOME-Look ID"
    echo "  -c <ID>    Install cursor theme by GNOME-Look ID"
    echo "  -i <ID>    Install icon theme by GNOME-Look ID"
    echo "  -r         Restore theme from history"
    echo "  -h         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -g 2315765    # Install GTK theme with ID 2315765"
    echo "  $0 -c 1411743    # Install cursor theme with ID 1411743"
    echo "  $0 -i 1686927    # Install icon theme with ID 1686927"
    echo "  $0 -r            # Restore theme from history"
    echo ""
    echo "If no options are provided, the script runs in interactive mode."
}
#  <========= END of CLI & Help Functions =========>



#  <========= History Management Functions =========>
# Get currently applied themes from gsettings
get_current_themes() {
    local gtk_theme=""
    local cursor_theme=""
    local icon_theme=""
    
    # Get GTK theme (fallback to empty if not set)
    gtk_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'") || gtk_theme="Adwaita"
    
    # Get cursor theme
    cursor_theme=$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | tr -d "'") || cursor_theme="Adwaita"
    
    # Get icon theme
    icon_theme=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'") || icon_theme="Adwaita"
    
    echo "${gtk_theme}|${cursor_theme}|${icon_theme}"
}

# Save current theme configuration to history
save_theme_to_history() {
    local gtk_name="$1"
    local cursor_name="$2"
    local icon_name="$3"
    
    local timestamp=$(date -Iseconds)
    local display_date=$(date "+%Y-%m-%d %H:%M")
    
    # Create display string
    local display_label="${display_date} - GTK: ${gtk_name}, Cursor: ${cursor_name}, Icon: ${icon_name}"
    
    # Create new entry
    local new_entry=$(jq -n \
        --arg ts "$timestamp" \
        --arg gtk "$gtk_name" \
        --arg cursor "$cursor_name" \
        --arg icon "$icon_name" \
        --arg display "$display_label" \
        '{
            timestamp: $ts,
            gtk: $gtk,
            cursor: $cursor,
            icon: $icon,
            display: $display
        }')
    
    # Load existing history or create empty array
    local history="[]"
    if [[ -f "$HISTORY_FILE" ]]; then
        history=$(load_history)
    fi
    
    # Append new entry and keep last 50 entries
    history=$(echo "$history" | jq --argjson entry "$new_entry" '. + [$entry] | .[-50:]')
    
    # Save to file
    echo "$history" > "$HISTORY_FILE"
    
    info "Theme configuration saved to history."
}

# Load history from JSON file
load_history() {    
    if [[ ! -f "$HISTORY_FILE" ]]; then
        return 1
    fi
    
    cat "$HISTORY_FILE"
}

# Display history menu and let user select
display_history_menu() {
    local history=$(load_history)
    
    if [[ -z "$history" || "$history" == "[]" ]]; then
        error "No theme history found."
        return 1
    fi
    
    # Extract display labels for gum (in reverse order - newest first)
    local display_options=$(echo "$history" | jq -r '.[] | .display' | tac)
    
    if [[ -z "$display_options" ]]; then
        error "No valid history entries found."
        return 1
    fi
    
    # Let user choose
    local selected_display=$(echo "$display_options" | gum choose --header "Select a theme configuration to restore:")
    
    if [[ -z "$selected_display" ]]; then
        warn "No selection made."
        return 1
    fi
    
    # Find the matching entry in history
    echo "$history" | jq --arg display "$selected_display" '.[] | select(.display == $display)'
}

# Restore theme from history entry
restore_theme_from_history() {
    local entry="$1"
    
    local gtk_name=$(echo "$entry" | jq -r '.gtk')
    local cursor_name=$(echo "$entry" | jq -r '.cursor')
    local icon_name=$(echo "$entry" | jq -r '.icon')
    
    header "Restoring Theme Configuration"
    info "GTK: $gtk_name"
    info "Cursor: $cursor_name"
    info "Icon: $icon_name"
    
    # Apply GTK theme
    apply_gtk "$gtk_name"
    success "GTK theme applied: $gtk_name"
    
    # Apply cursor theme
    apply_cursor "$cursor_name"
    success "Cursor theme applied: $cursor_name"

    # Apply icon theme
    apply_icon "$icon_name"
    success "Icon theme applied: $icon_name"
    
    success "Theme configuration restored successfully!"
}

# Main function to handle history restoration
restore_from_history() {    
    header "Theme History"
    
    local selected_entry
    selected_entry=$(display_history_menu)
    
    if [[ $? -ne 0 ]]; then
        error "Failed to select history entry."
        info "Aborting... Byeeeee"
        exit 0
    fi
    
    restore_theme_from_history "$selected_entry"
}
#  <========= END of History Management Functions =========>



#  <========= Theme Processing Functions =========>
# Process and install a theme component (unified function for CLI and interactive modes)
process_theme_component() {
    local type="$1"
    local id="$2"
    local file="${3:-}"  # Optional: if not provided, user will select
    local name="${4:-}"  # Optional: if not provided, derived from file
    
    info "Processing $type theme with ID: $id"
    
    # Load JSON from GNOME-Look
    local json
    json=$(load_json "$id")
    
    # Select file if not provided
    if [[ -z "$file" ]]; then
        file=$(select_theme_file "$json" "$id")
        if [[ -z "$file" ]]; then
            error "No file selected."
            exit 1
        fi
    fi
    
    # Derive theme name if not provided
    if [[ -z "$name" ]]; then
        name=$(derive_theme_name "$file")
    fi
    
    # Determine if download is needed
    if should_download_theme "$type" "$id" "$name" "$json" "$file"; then
        clean_theme "$type" "$id"
        local extracted_names
        extracted_names=$(download_and_prepare_theme "$type" "$id" "$json" "$file")
        
        # Cache icons if this is an icon theme (for all variants)
        if [[ "$type" == "icon" ]]; then
            while IFS= read -r dir_name; do
                if [[ -n "$dir_name" ]]; then
                    cache_icons_if_needed "$dir_name"
                fi
            done <<< "$extracted_names"
        fi
    fi
    
    # Get the primary extracted directory name for installation and application
    local extracted_name
    extracted_name=$(get_primary_dir_name "$type" "$id")
    
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

# Save a single component change to history
save_component_to_history() {
    local type="$1"
    local theme_name="$2"
    
    # Get current theme states
    local current_themes=$(get_current_themes)
    IFS='|' read -r current_gtk current_cursor current_icon <<< "$current_themes"
    
    # Use the newly applied theme for this type, keep others from current state
    case "$type" in
        "gtk")
            save_theme_to_history "$theme_name" "$current_cursor" "$current_icon"
            ;;
        "cursor")
            save_theme_to_history "$current_gtk" "$theme_name" "$current_icon"
            ;;
        "icon")
            save_theme_to_history "$current_gtk" "$current_cursor" "$theme_name"
            ;;
    esac
}

# Install a single component by ID (CLI mode wrapper)
install_single_component() {
    local type="$1"
    local id="$2"
    process_theme_component "$type" "$id"
}
#  <========= END of Theme Processing Functions =========>



#  <========= Component Installation Functions =========>
# Install cursor
install_cursor() {
    local cursor_name="$1"
    local id="$2"

    # Get all folders for this cursor theme from files.json
    local folders=$(get_theme_folders "cursor" "$id")
    
    if [[ -z "$folders" ]]; then
        # Fallback to single folder if files.json not populated yet
        rm -rf "$CURSORS_DIR/$cursor_name"
        cp -r "$VAULT/cursor/$id/$cursor_name" "$CURSORS_DIR/$cursor_name"
    else
        # Copy all tracked folders
        while IFS= read -r folder; do
            if [[ -n "$folder" && -d "$VAULT/cursor/$id/$folder" ]]; then
                rm -rf "$CURSORS_DIR/$folder"
                cp -r "$VAULT/cursor/$id/$folder" "$CURSORS_DIR/$folder"
            fi
        done <<< "$folders"
    fi
}

# Install GTK theme
install_gtk() {
    local theme_name="$1"
    local id="$2"

    # Get all folders for this GTK theme from files.json
    local folders=$(get_theme_folders "gtk" "$id")
    
    if [[ -z "$folders" ]]; then
        # Fallback to single folder if files.json not populated yet
        rm -rf "$THEMES_DIR/$theme_name"
        cp -r "$VAULT/gtk/$id/$theme_name" "$THEMES_DIR/$theme_name"
    else
        # Copy all tracked folders
        while IFS= read -r folder; do
            if [[ -n "$folder" && -d "$VAULT/gtk/$id/$folder" ]]; then
                rm -rf "$THEMES_DIR/$folder"
                cp -r "$VAULT/gtk/$id/$folder" "$THEMES_DIR/$folder"
            fi
        done <<< "$folders"
    fi
}

# Install icon
install_icon() {
    local icon_name="$1"
    local id="$2"

    # Get all folders for this icon theme
    local folders=$(get_theme_folders "icon" "$id")
    
    if [[ -z "$folders" ]]; then
        # Fallback to single folder if files.json not populated yet
        rm -rf "$ICONS_DIR/$icon_name"
        cp -r "$VAULT/icon/$id/$icon_name" "$ICONS_DIR/$icon_name"
    else
        # Copy all tracked folders
        while IFS= read -r folder; do
            if [[ -n "$folder" && -d "$VAULT/icon/$id/$folder" ]]; then
                rm -rf "$ICONS_DIR/$folder"
                cp -r "$VAULT/icon/$id/$folder" "$ICONS_DIR/$folder"
            fi
        done <<< "$folders"
    fi
}
#  <========= END of Component Installation Functions =========>


#  <========= Component Application Functions =========>
# Check if icon cache is possible
can_cache_icons() {
    local icon_name="$1"
    
    if [[ -f "$ICONS_DIR/$icon_name/index.theme" ]]; then
        return 0
    else
        return 1
    fi
}

# Update icon cache
cache_icons() {
    local icon_name="$1"
    
    # Try gtk-update-icon-cache
    if command -v gtk-update-icon-cache &>/dev/null; then
        info "Updating icon cache with gtk3 apps..."
        gtk-update-icon-cache -f -t "$ICONS_DIR/$icon_name" 2>/dev/null || warn "gtk-update-icon-cache failed."
    fi
    
    # Try gtk4-update-icon-cache
    if command -v gtk4-update-icon-cache &>/dev/null; then
        info "Updating icon cache with gtk4 apps..."
        gtk4-update-icon-cache -f -t "$ICONS_DIR/$icon_name" 2>/dev/null || warn "gtk4-update-icon-cache failed."
    fi
}

# Cache icons if index.theme exists
cache_icons_if_needed() {
    local icon_name="$1"
    
    if can_cache_icons "$icon_name"; then
        cache_icons "$icon_name"
    fi
}

# Apply cursor
apply_cursor() {
    local cursor_name="$1"
    gsettings set org.gnome.desktop.interface cursor-theme "$cursor_name"
}

# Apply icon
apply_icon() {
    local icon_name="$1"
    gsettings set org.gnome.desktop.interface icon-theme "$icon_name"
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

    # Create gtk-4.0 directory if it doesn't exist
    mkdir -p "$config_dir/gtk-4.0"
    
    # Remove previous theme config
    rm -rf "$config_dir/gtk-4.0/gtk.css"
    rm -rf "$config_dir/gtk-4.0/gtk-dark.css"
    rm -rf "$config_dir/gtk-4.0/assets"
    rm -rf "$config_dir/assets"

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
#  <========= END of Component Application Functions =========>



#  <========= Wallpaper Management Functions =========>
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

# Download wallpapers
download_wallpapers() {
    local light_file="$1"
    local light_url="$2"
    local dark_file="$3"
    local dark_url="$4"

    # Check if wallpapers exist in vault
    if [[ -f "$VAULT/wallpaper/$light_file" ]] && [[ -f "$VAULT/wallpaper/$dark_file" ]]; then
        info "Wallpapers are already in vault."
    else
        info "Wallpapers not in vault (or incomplete). Downloading..."
        
        # Download light wallpaper
        if [[ ! -f "$VAULT/wallpaper/$light_file" ]]; then
            info "Downloading light wallpaper..."
            download_wallpaper "$light_url" "$light_file" || exit 1
        fi
        
        # Download dark wallpaper
        if [[ ! -f "$VAULT/wallpaper/$dark_file" ]]; then
            info "Downloading dark wallpaper..."
            download_wallpaper "$dark_url" "$dark_file" || exit 1
        fi
    fi
}

# Manage wallpapers
manage_wallpapers() {
    local light_file="$1"
    local light_url="$2"
    local dark_file="$3"
    local dark_url="$4"

    info "Managing wallpapers..."
    download_wallpapers "$light_file" "$light_url" "$dark_file" "$dark_url"
    install_wallpaper "$light_file"
    install_wallpaper "$dark_file"
    apply_wallpaper "$light_file" "$dark_file"
    success "Wallpapers applied successfully!"
}
#  <========= END of Wallpaper Management Functions =========>



#  <========= File Tracking Functions =========>
create_history_file(){
    if [[ ! -f "$HISTORY_FILE" ]]; then
        touch "$HISTORY_FILE"
        
        # Get current themes from gsettings
        local current_themes=$(get_current_themes)
        IFS='|' read -r gtk_theme cursor_theme icon_theme <<< "$current_themes"
        
        # Get current timestamp
        local timestamp=$(date -Iseconds)
        local display_date=$(date "+%Y-%m-%d %H:%M")
        
        # Create initial history entry with current themes
        cat <<EOF > "$HISTORY_FILE"
[
  {
    "timestamp": "$timestamp",
    "gtk": "$gtk_theme",
    "cursor": "$cursor_theme",
    "icon": "$icon_theme",
    "display": "$display_date - GTK: $gtk_theme, Cursor: $cursor_theme, Icon: $icon_theme"
  }
]
EOF
    fi
}

# Create files.json if it doesn't exist
create_files_json(){
    if [[ ! -f "$VAULT/files.json" ]]; then
        touch "$VAULT/files.json"
        cat <<EOF > "$VAULT/files.json"
{
  "gtk": {},
  "icon": {},
  "cursor": {}
}
EOF
        info "Created files.json tracking file."
    fi
}

# Update files.json with extracted folder names
update_files_json(){
    local type="$1"
    local id="$2"
    
    # Get all extracted directories for this theme
    local folders=$(get_extracted_dir_names "$type" "$id" | jq -R . | jq -s .)
    
    if [[ -z "$folders" || "$folders" == "[]" ]]; then
        warn "No folders found to track for $type/$id"
        return 0
    fi
    
    # Update the JSON file
    local updated_json=$(jq --arg type "$type" --arg id "$id" --argjson folders "$folders" \
        '.[$type][$id] = $folders' "$FILES_JSON")
    
    echo "$updated_json" > "$FILES_JSON"
    info "Updated files.json: tracked folders for $type/$id"
}

# Get all folders for a theme from files.json
get_theme_folders(){
    local type="$1"
    local id="$2"
    
    if [[ ! -f "$FILES_JSON" ]]; then
        return 0
    fi
    
    # Extract folder array for this theme
    local folders=$(jq -r --arg type "$type" --arg id "$id" \
        '.[$type][$id] // [] | .[]' "$FILES_JSON" 2>/dev/null)
    
    echo "$folders"
}
#  <========= END of File Tracking Functions =========>


#  <========= Starting point =========>
# Prepare
mkdir -p $VAULT
create_history_file
create_files_json
check_dependencies

# Parse CLI arguments
if [[ $# -gt 0 ]]; then
    while getopts "g:c:i:rh" opt; do
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
            r)
                restore_from_history
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

themes="$(get_theme_package_names)" || exit 1  
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

info "You selected $chosen theme package"
info "These themes will be applied:"
info "  $GTK_NAME"
info "  $CURSOR_NAME"
info "  $ICON_NAME"

# Save previous theme configuration to history
save_theme_to_history "$GTK_NAME" "$CURSOR_NAME" "$ICON_NAME"

# GTK Theme
process_theme_component "gtk" "$GTK_ID" "$GTK_FILE" "$GTK_NAME"

# Cursor
process_theme_component "cursor" "$CURSOR_ID" "$CURSOR_FILE" "$CURSOR_NAME"

# Icon
process_theme_component "icon" "$ICON_ID" "$ICON_FILE" "$ICON_NAME"

# Wallpaper
manage_wallpapers "$WALLPAPER_LIGHT_FILE" "$WALLPAPER_LIGHT_URL" "$WALLPAPER_DARK_FILE" "$WALLPAPER_DARK_URL"
success "Theme Switcher completed successfully!"
#  <========= END =========>