#!/bin/bash
# ==============================================================================
# GNOME Theme Switcher - Refactored Edition
# ==============================================================================
# A modular, extensible tool for managing Linux desktop themes, cursors, icons.
#
# Author: Nalindu Ashirwada
# Licence: Apache License 2.0
# Version: 2.0.0
# ==============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# ==============================================================================
# SECTION 1: CONFIGURATION & CONSTANTS
# ==============================================================================
# This section defines all the settings and paths used throughout the script.
# Think of it like a recipe card listing all ingredients before cooking!

# --- Script Identity ---
readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_NAME="Theme Switcher"

# --- Directory Paths ---
# Where we store different types of files (like having separate drawers for socks, shirts, etc.)
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VAULT_DIR="${HOME}/.local/share/theme-switcher-vault"
readonly THEMES_DIR="${HOME}/.local/share/themes"
readonly ICONS_DIR="${HOME}/.local/share/icons"
readonly CURSORS_DIR="${HOME}/.local/share/icons"  # Cursors live with icons in Linux
readonly WALLPAPERS_DIR="${HOME}/Pictures/Wallpapers"
readonly CONFIG_DIR="${HOME}/.config"

# --- Data Files ---
# Files that remember what we've done (like a diary for themes!)
readonly HISTORY_FILE="${VAULT_DIR}/history.json"
readonly FILES_JSON="${VAULT_DIR}/files.json"

# --- Terminal Colors ---
# Colors make messages pretty and easier to understand
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_BOLD='\033[1m'
readonly COLOR_RESET='\033[0m'

# --- API Configuration ---
readonly GNOME_LOOK_API="https://www.gnome-look.org/p"

# --- Theme Package Database ---
# This is like a catalog of theme "bundles" - each bundle has a GTK theme,
# cursor, icons, and wallpapers that look good together.
readonly THEME_PACKAGES_JSON='{
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
            "light": "nord-light.png",
            "lightURL": "https://raw.githubusercontent.com/dracula/wallpaper/master/first-collection/base.png",
            "dark": "nord-dark.png",
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
            "light": "catppuccin-light.png",
            "lightURL": "https://raw.githubusercontent.com/zhichaoh/catppuccin-wallpapers/main/waves/wavy_lines_v01_5120x2880.png",
            "dark": "catppuccin-dark.png",
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


# ==============================================================================
# SECTION 2: LOGGING UTILITIES
# ==============================================================================
# These functions print colorful messages to the screen.
# Like traffic lights: Red = Stop/Error, Yellow = Caution, Green = Go/Success!

# Prints an error message in red with [ERROR] prefix
# Usage: log_error "Something went wrong!"
log_error() {
    local message="$1"
    echo -e "${COLOR_RED}${COLOR_BOLD}[ERROR]${COLOR_RESET} ${message}" >&2
}

# Prints an info message in blue with [INFO] prefix
# Usage: log_info "Starting download..."
log_info() {
    local message="$1"
    echo -e "${COLOR_BLUE}${COLOR_BOLD}[INFO]${COLOR_RESET} ${message}"
}

# Prints a success message in green with [SUCCESS] prefix
# Usage: log_success "Theme installed!"
log_success() {
    local message="$1"
    echo -e "${COLOR_GREEN}${COLOR_BOLD}[SUCCESS]${COLOR_RESET} ${message}"
}

# Prints a warning message in yellow with [WARN] prefix
# Usage: log_warn "File already exists, skipping..."
log_warn() {
    local message="$1"
    echo -e "${COLOR_YELLOW}${COLOR_BOLD}[WARN]${COLOR_RESET} ${message}"
}

# Prints a fancy header with decorative lines
# Usage: log_header "Installing GTK Theme"
log_header() {
    local title="$1"
    echo -e "\n${COLOR_BOLD}${COLOR_BLUE}━━━ ${title} ━━━${COLOR_RESET}\n"
}

# Shows a cool animated progress indicator while something is loading
# Like a bouncing ball that shows "I'm working on it!"
# Usage: show_spinner $PID "Downloading theme..."
show_spinner() {
    local pid=$1           # The process ID we're waiting for
    local message=$2       # What to show the user
    local dot_count=20     # How many dots in our animation
    
    # Keep animating while the background process is running
    while kill -0 "$pid" 2>/dev/null; do
        for ((i=1; i<=dot_count; i++)); do
            local bar=""
            for ((j=1; j<=dot_count; j++)); do
                if (( j < i )); then
                    bar+="●"         # Filled dot (already passed)
                elif (( j == i )); then
                    bar+="⦿"         # Current position (the bouncing ball!)
                else
                    bar+=" "         # Empty space (not yet reached)
                fi
            done
            printf "\r       %s ${COLOR_BLUE}[:%s:]${COLOR_RESET}" "$message" "$bar" >&2
            sleep 0.12
        done
    done
    printf "\r\033[K" >&2  # Clear the line when done (like erasing a whiteboard)
}


# ==============================================================================
# SECTION 3: CORE UTILITY FUNCTIONS
# ==============================================================================
# These are helper functions used by many parts of the script.
# Think of them as the basic tools in a toolbox - hammer, screwdriver, etc.

# Checks if we can reach the internet by pinging Google
# Returns: 0 if connected, exits with error if not
# Why: We need internet to download themes from gnome-look.org
check_internet_connection() {
    if ! ping -c 1 -W 3 google.com &>/dev/null; then
        log_error "No internet connection available. Please check your network."
        return 1
    fi
    return 0
}

# Figures out which package manager the system uses
# Different Linux distributions use different package managers:
#   - Fedora uses 'dnf'
#   - Ubuntu/Debian uses 'apt'
#   - Arch uses 'pacman'
#   - openSUSE uses 'zypper'
# Returns: "manager_name|install_command"
detect_package_manager() {
    if command -v dnf &>/dev/null; then
        echo "dnf|sudo dnf install -yq"
    elif command -v apt &>/dev/null; then
        echo "apt|sudo apt install -yq"
    elif command -v pacman &>/dev/null; then
        echo "pacman|sudo pacman -S --noconfirm"
    elif command -v zypper &>/dev/null; then
        echo "zypper|sudo zypper install -y"
    else
        log_error "Could not detect package manager"
        return 1
    fi
}

# Checks if a command exists on the system
# Usage: command_exists "curl" && echo "curl is available"
command_exists() {
    local cmd="$1"
    command -v "$cmd" &>/dev/null
}

# Creates a directory if it doesn't exist (and parent directories too)
# Like mkdir -p but with logging
# Usage: ensure_directory_exists "/path/to/folder"
ensure_directory_exists() {
    local dir_path="$1"
    if [[ ! -d "$dir_path" ]]; then
        mkdir -p "$dir_path"
    fi
}

# Gets the filename without its extension
# Example: "theme.tar.xz" becomes "theme"
# Usage: get_name_without_extension "Nordic.tar.xz"  # Returns: Nordic
get_name_without_extension() {
    local filename="$1"
    echo "${filename%%.*}"
}


# ==============================================================================
# SECTION 4: DEPENDENCY MANAGEMENT
# ==============================================================================
# This section makes sure all required programs are installed.
# It's like checking you have all ingredients before baking a cake!

# Adds the gum repository for Debian/Ubuntu systems
# 'gum' is a tool that makes pretty menus - it's not in default Ubuntu repos
add_gum_repository_for_apt() {
    if [[ ! -f /etc/apt/sources.list.d/charm.list ]]; then
        log_info "Adding gum repository for apt..."
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | \
            sudo tee /etc/apt/sources.list.d/charm.list > /dev/null
        sudo apt update -qq
    fi
}

# Installs a single package if it's not already installed
# Parameters:
#   $1 - command name to check (e.g., "jq")
#   $2 - package name to install (usually same as command)
#   $3 - package manager name ("apt", "dnf", etc.)
#   $4 - full install command ("sudo apt install -y")
install_package_if_missing() {
    local cmd_name="$1"
    local package_name="$2"
    local pkg_manager="$3"
    local install_cmd="$4"
    
    if ! command_exists "$cmd_name"; then
        log_warn "'$cmd_name' is not installed. Installing..."
        
        # Special case: gum needs extra setup on Ubuntu/Debian
        if [[ "$cmd_name" == "gum" && "$pkg_manager" == "apt" ]]; then
            add_gum_repository_for_apt
        fi
        
        # Run the install command
        if ! $install_cmd "$package_name"; then
            log_error "Failed to install '$package_name'"
            return 1
        fi
        log_success "'$cmd_name' installed successfully"
    fi
    return 0
}

# Installs all required dependencies for the script to work
# Required tools:
#   - jq: For reading/writing JSON files
#   - gum: For pretty interactive menus
#   - curl: For downloading files from the internet
#   - tar: For extracting .tar.xz and .tar.gz files
#   - unzip: For extracting .zip files
install_dependencies() {
    local pkg_info
    
    if ! pkg_info=$(detect_package_manager); then
        log_error "Unsupported system. Please install manually: jq, gum, curl, tar, unzip"
        return 1
    fi
    
    # Split the package info into manager name and install command
    local pkg_manager install_cmd
    IFS='|' read -r pkg_manager install_cmd <<< "$pkg_info"
    log_info "Using package manager: $pkg_manager"
    
    # Install each required dependency
    local -a dependencies=("jq" "gum" "curl" "tar" "unzip")
    for dep in "${dependencies[@]}"; do
        install_package_if_missing "$dep" "$dep" "$pkg_manager" "$install_cmd" || return 1
    done
    
    log_success "All dependencies are ready!"
    return 0
}


# ==============================================================================
# SECTION 5: JSON DATA ACCESS LAYER
# ==============================================================================
# Functions for reading data from our theme package database.
# Think of this like a librarian who knows exactly where every book is!

# Gets all available theme package names from our catalog
# Returns: List of theme names, one per line (e.g., "Dracula", "Nord", "Graphite")
get_available_theme_packages() {
    echo "$THEME_PACKAGES_JSON" | jq -r 'keys[]'
}

# Reads a specific value from the theme package database
# Parameters:
#   $1 - JSON path to the value (e.g., ".gtk.id")
#   $2 - Theme package name (e.g., "Dracula")
# Returns: The value at that path
# Example: read_package_value ".cursor.name" "Nord"  # Returns: Nordic-cursors
read_package_value() {
    local json_path="$1"
    local package_name="$2"
    echo "$THEME_PACKAGES_JSON" | jq -er ".\"${package_name}\"${json_path}"
}


# ==============================================================================
# SECTION 6: VAULT STORAGE MANAGEMENT
# ==============================================================================
# The "vault" is our local storage for downloaded themes.
# It's like a warehouse where we keep themes so we don't download them again!

# Creates all the directories we need to store themes and data
# Called once when the script starts
initialize_storage() {
    ensure_directory_exists "$VAULT_DIR"
    ensure_directory_exists "$THEMES_DIR"
    ensure_directory_exists "$ICONS_DIR"
    ensure_directory_exists "$CURSORS_DIR"
    ensure_directory_exists "$WALLPAPERS_DIR"
    ensure_directory_exists "$VAULT_DIR/gtk"
    ensure_directory_exists "$VAULT_DIR/cursor"
    ensure_directory_exists "$VAULT_DIR/icon"
    ensure_directory_exists "$VAULT_DIR/wallpaper"
}

# Checks if a theme already exists in our vault
# Parameters:
#   $1 - type: "gtk", "cursor", or "icon"
#   $2 - id: The gnome-look.org ID
#   $3 - name: The theme folder name
# Returns: 0 if exists, 1 if not
vault_has_theme() {
    local theme_type="$1"
    local theme_id="$2"
    local theme_name="$3"
    
    [[ -d "$VAULT_DIR/$theme_type/$theme_id/$theme_name" ]]
}

# Gets the path to a theme in the vault
# Usage: get_vault_path "gtk" "1687249" "Dracula"
get_vault_path() {
    local theme_type="$1"
    local theme_id="$2"
    local theme_name="$3"
    
    echo "$VAULT_DIR/$theme_type/$theme_id/$theme_name"
}

# Lists all extracted folder names inside a theme's vault directory
# Some theme archives contain multiple folders (e.g., "Theme" and "Theme-Dark")
# Returns: List of folder names, one per line
get_extracted_folders() {
    local theme_type="$1"
    local theme_id="$2"
    local theme_name="$3"
    
    local vault_path
    vault_path=$(get_vault_path "$theme_type" "$theme_id" "$theme_name")
    
    if [[ ! -d "$vault_path" ]]; then
        return 1
    fi
    
    # Find only immediate subdirectories (not deeper)
    find "$vault_path" -mindepth 1 -maxdepth 1 -type d -printf "%f\n"
}

# Gets the first (primary) extracted folder name
# When a theme has multiple variants, this returns the main one
get_primary_extracted_folder() {
    local theme_type="$1"
    local theme_id="$2"
    local theme_name="$3"
    
    get_extracted_folders "$theme_type" "$theme_id" "$theme_name" | head -n 1
}


# ==============================================================================
# SECTION 7: FILES.JSON TRACKING
# ==============================================================================
# files.json remembers what themes we've installed and where.
# It's like a map that shows where each theme folder came from!

# Creates the files.json tracking file if it doesn't exist
initialize_files_json() {
    if [[ ! -f "$FILES_JSON" ]]; then
        cat > "$FILES_JSON" << 'EOF'
{
    "gtk": {},
    "cursor": {},
    "icon": {}
}
EOF
        log_info "Created theme tracking file: files.json"
    fi
}

# Records the folders for a theme in files.json
# So we know which folders to delete when cleaning up
# Parameters:
#   $1 - theme_type: "gtk", "cursor", or "icon"
#   $2 - theme_id: The gnome-look.org ID
#   $3 - theme_name: The archive name (without extension)
track_theme_folders() {
    local theme_type="$1"
    local theme_id="$2"
    local theme_name="$3"
    
    # Get all extracted directories and convert to JSON array
    local folders_json
    folders_json=$(get_extracted_folders "$theme_type" "$theme_id" "$theme_name" | jq -R . | jq -s .)
    
    if [[ -z "$folders_json" || "$folders_json" == "[]" ]]; then
        log_warn "No folders to track for $theme_type/$theme_id"
        return 0
    fi
    
    # Update the JSON file with the new entry
    local updated_json
    updated_json=$(jq --arg type "$theme_type" \
                      --arg id "$theme_id" \
                      --arg name "$theme_name" \
                      --argjson folders "$folders_json" \
                      '.[$type][$id] = {"name": $name, "folders": $folders}' "$FILES_JSON")
    
    echo "$updated_json" > "$FILES_JSON"
    log_info "Tracked $theme_type theme folders in files.json"
}

# Gets the stored theme name for a given ID from files.json
get_tracked_theme_name() {
    local theme_type="$1"
    local theme_id="$2"
    
    if [[ ! -f "$FILES_JSON" ]]; then
        return 0
    fi
    
    jq -r --arg type "$theme_type" --arg id "$theme_id" \
        '.[$type][$id].name // ""' "$FILES_JSON" 2>/dev/null
}

# Gets all tracked folders for a theme from files.json
get_tracked_folders() {
    local theme_type="$1"
    local theme_id="$2"
    
    if [[ ! -f "$FILES_JSON" ]]; then
        return 0
    fi
    
    jq -r --arg type "$theme_type" --arg id "$theme_id" \
        '.[$type][$id].folders[]? // empty' "$FILES_JSON" 2>/dev/null
}

# Removes a theme entry from files.json
untrack_theme() {
    local theme_type="$1"
    local theme_id="$2"
    
    if [[ ! -f "$FILES_JSON" ]]; then
        return 0
    fi
    
    local updated_json
    updated_json=$(jq --arg type "$theme_type" --arg id "$theme_id" \
                      'del(.[$type][$id])' "$FILES_JSON")
    echo "$updated_json" > "$FILES_JSON"
}


# ==============================================================================
# SECTION 8: GNOME-LOOK.ORG API CLIENT
# ==============================================================================
# Functions for talking to gnome-look.org to get theme information.
# It's like asking a librarian about books in their online catalog!

# Fetches theme metadata from gnome-look.org for a given theme ID
# The website returns JSON with download URLs, file names, and update dates
# Parameters:
#   $1 - theme_id: The numeric ID from gnome-look.org URL
# Returns: JSON data about the theme files
fetch_theme_metadata() {
    local theme_id="$1"
    local temp_file
    temp_file=$(mktemp)
    
    check_internet_connection || return 1
    
    # Download the theme metadata in the background
    curl -Lfs "${GNOME_LOOK_API}/${theme_id}/loadFiles" > "$temp_file" &
    local curl_pid=$!
    
    show_spinner "$curl_pid" "Fetching theme data..."
    wait "$curl_pid"
    local curl_result=$?
    
    if [[ $curl_result -ne 0 ]]; then
        rm -f "$temp_file"
        log_error "Failed to fetch theme metadata for ID: $theme_id"
        return 1
    fi
    
    # Read and output the JSON, then cleanup
    cat "$temp_file"
    rm -f "$temp_file"
}

# Extracts the list of available (active) files from theme metadata
# Some themes have multiple files to choose from
# Returns: List of file names, one per line
get_available_theme_files() {
    local metadata_json="$1"
    echo "$metadata_json" | jq -r '.files[] | select(.active == "1") | .name'
}

# Lets the user pick which file to download if there are multiple options
# Parameters:
#   $1 - metadata_json: JSON from fetch_theme_metadata
#   $2 - theme_id: For error messages
# Returns: Selected filename
select_theme_file() {
    local metadata_json="$1"
    local theme_id="$2"
    
    local available_files
    available_files=$(get_available_theme_files "$metadata_json")
    
    if [[ -z "$available_files" ]]; then
        log_error "No active files found for theme ID: $theme_id"
        return 1
    fi
    
    # Count how many files are available
    local file_count
    file_count=$(echo "$available_files" | wc -l)
    
    if [[ "$file_count" -gt 1 ]]; then
        # Multiple files: let user choose using gum
        echo "$available_files" | gum choose --header "📦 Pick a file to download:"
    else
        # Single file: just use it
        echo "$available_files"
    fi
}

# Gets the download URL for a specific file from theme metadata
# The URL is encoded, so we decode it before returning
extract_download_url() {
    local metadata_json="$1"
    local file_name="$2"
    
    local encoded_url
    encoded_url=$(echo "$metadata_json" | jq -r --arg name "$file_name" \
        '.files[] | select(.active == "1" and .name == $name) | .url' | head -n 1)
    
    if [[ -z "$encoded_url" || "$encoded_url" == "null" ]]; then
        log_error "Download URL not found for file: $file_name"
        return 1
    fi
    
    # Decode percent-encoded characters (e.g., %20 becomes space)
    printf '%b' "${encoded_url//%/\\x}"
}

# Gets the last update timestamp for a file from theme metadata
# Returns: Unix timestamp (seconds since 1970)
get_remote_update_timestamp() {
    local metadata_json="$1"
    local file_name="$2"
    
    local update_date
    update_date=$(echo "$metadata_json" | jq -r --arg name "$file_name" \
        '.files[] | select(.active == "1" and .name == $name) | .updated_timestamp' | head -n 1)
    
    if [[ -z "$update_date" || "$update_date" == "null" ]]; then
        log_error "Could not find update timestamp for file: $file_name"
        return 1
    fi
    
    # Convert date string to Unix timestamp
    date -d "$update_date" +%s
}


# ==============================================================================
# SECTION 9: TIMESTAMP MANAGEMENT
# ==============================================================================
# Functions to compare when themes were last updated.
# We check if gnome-look.org has a newer version before downloading again!

# Gets the modification time of the newest file in a directory
# Returns: Unix timestamp
get_local_update_timestamp() {
    local dir_path="$1"
    
    if [[ ! -d "$dir_path" ]]; then
        echo "0"
        return 0
    fi
    
    # Find the most recently modified file
    local newest_timestamp
    newest_timestamp=$(find "$dir_path" -type f -printf "%T@\n" 2>/dev/null | sort -nr | head -n 1)
    
    if [[ -z "$newest_timestamp" ]]; then
        echo "0"
        return 0
    fi
    
    # Remove decimal part (we only need seconds)
    echo "${newest_timestamp%.*}"
}

# Updates the timestamps of all files in a theme directory to current time
# This prevents the script from thinking the theme needs updating right after install
sync_theme_timestamps() {
    local theme_type="$1"
    local theme_id="$2"
    local theme_name="$3"
    
    local vault_path
    vault_path=$(get_vault_path "$theme_type" "$theme_id" "$theme_name")
    
    if [[ -d "$vault_path" ]]; then
        local now
        now=$(date +%s)
        
        # Touch all files and directories to update their timestamps
        find "$vault_path" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
            find "$dir" -exec touch -h -d "@$now" {} + 2>/dev/null || true
        done
        
        log_info "Synchronized local timestamps"
    fi
}

# Checks if we need to download a theme (new or updated)
# Returns: 0 if download needed, 1 if up-to-date
needs_download() {
    local theme_type="$1"
    local theme_id="$2"
    local theme_name="$3"
    local metadata_json="$4"
    local file_name="$5"
    
    # If theme not in vault, we definitely need to download
    if ! vault_has_theme "$theme_type" "$theme_id" "$theme_name"; then
        log_info "$theme_type theme not in vault. Will download."
        return 0
    fi
    
    # Get local timestamp
    local vault_path
    vault_path=$(get_vault_path "$theme_type" "$theme_id" "$theme_name")
    local local_timestamp
    local_timestamp=$(get_local_update_timestamp "$vault_path")
    
    # Get remote timestamp
    local remote_timestamp
    if ! remote_timestamp=$(get_remote_update_timestamp "$metadata_json" "$file_name"); then
        # If we can't get remote timestamp, assume we need update
        return 0
    fi
    
    # Compare: if remote is newer, download is needed
    if [[ "$remote_timestamp" -gt "$local_timestamp" ]]; then
        log_info "$theme_type theme has updates available. Will download."
        return 0
    fi
    
    log_info "$theme_type theme is up-to-date."
    return 1
}


# ==============================================================================
# SECTION 10: DOWNLOAD & EXTRACTION SERVICE
# ==============================================================================
# Functions for downloading and extracting theme archives.
# Like unpacking a delivery box from an online store!

# Downloads a theme file from gnome-look.org
# Parameters:
#   $1-5: metadata, filename, type, id, name
download_theme_file() {
    local metadata_json="$1"
    local file_name="$2"
    local theme_type="$3"
    local theme_id="$4"
    local theme_name="$5"
    
    # Get the download URL
    local download_url
    if ! download_url=$(extract_download_url "$metadata_json" "$file_name"); then
        return 1
    fi
    
    # Prepare destination directory
    local vault_path
    vault_path=$(get_vault_path "$theme_type" "$theme_id" "$theme_name")
    ensure_directory_exists "$vault_path"
    
    # Remove old file if exists
    rm -f "$vault_path/$file_name"
    
    check_internet_connection || return 1
    
    # Download the file
    curl -sL -o "$vault_path/$file_name" "$download_url" &
    local curl_pid=$!
    
    show_spinner "$curl_pid" "Downloading $file_name..."
    wait "$curl_pid"
    
    if [[ $? -ne 0 ]]; then
        log_error "Download failed for: $file_name"
        return 1
    fi
    
    log_success "Downloaded: $file_name"
    return 0
}

# Extracts a downloaded theme archive
# Supports: .zip, .tar.xz, .tar.gz
# Parameters:
#   $1 - theme_type, $2 - theme_id, $3 - theme_name, $4 - file_name
extract_theme_archive() {
    local theme_type="$1"
    local theme_id="$2"
    local theme_name="$3"
    local file_name="$4"
    
    local vault_path
    vault_path=$(get_vault_path "$theme_type" "$theme_id" "$theme_name")
    local archive_path="$vault_path/$file_name"
    
    if [[ ! -f "$archive_path" ]]; then
        log_error "Archive not found: $archive_path"
        return 1
    fi
    
    log_info "Extracting: $file_name"
    
    # Extract based on file extension
    case "$file_name" in
        *.zip)
            unzip -o -q "$archive_path" -d "$vault_path"
            ;;
        *.tar.xz)
            tar -xf "$archive_path" -C "$vault_path"
            ;;
        *.tar.gz | *.tgz)
            tar -xzf "$archive_path" -C "$vault_path"
            ;;
        *.tar.bz2)
            tar -xjf "$archive_path" -C "$vault_path"
            ;;
        *)
            log_error "Unknown archive format: $file_name"
            return 1
            ;;
    esac
    
    log_success "Extracted: $file_name"
    return 0
}

# Removes old theme files before installing a new version
# Cleans both vault and installation directories
clean_old_theme() {
    local theme_type="$1"
    local theme_id="$2"
    
    log_info "Cleaning old $theme_type theme (ID: $theme_id)..."
    
    # Get tracked folders from files.json
    local tracked_folders
    tracked_folders=$(get_tracked_folders "$theme_type" "$theme_id")
    
    # Determine the installation directory
    local install_dir
    case "$theme_type" in
        "gtk")    install_dir="$THEMES_DIR" ;;
        "cursor") install_dir="$CURSORS_DIR" ;;
        "icon")   install_dir="$ICONS_DIR" ;;
    esac
    
    # Remove each tracked folder from the installation directory
    if [[ -n "$tracked_folders" && -n "$install_dir" ]]; then
        while IFS= read -r folder; do
            if [[ -n "$folder" && -d "$install_dir/$folder" ]]; then
                rm -rf "$install_dir/$folder"
            fi
        done <<< "$tracked_folders"
    fi
    
    # Remove from vault
    local old_name
    old_name=$(get_tracked_theme_name "$theme_type" "$theme_id")
    
    if [[ -n "$old_name" ]]; then
        local old_vault_path
        old_vault_path=$(get_vault_path "$theme_type" "$theme_id" "$old_name")
        rm -rf "$old_vault_path"
    else
        # Fallback: remove entire ID directory
        rm -rf "$VAULT_DIR/$theme_type/$theme_id"
    fi
    
    # Remove tracking entry
    untrack_theme "$theme_type" "$theme_id"
}

# High-level function: Download and extract a theme
# Combines download, extraction, timestamp sync, and tracking
download_and_install_theme() {
    local theme_type="$1"
    local theme_id="$2"
    local theme_name="$3"
    local metadata_json="$4"
    local file_name="$5"
    
    # Download the theme file
    if ! download_theme_file "$metadata_json" "$file_name" "$theme_type" "$theme_id" "$theme_name"; then
        return 1
    fi
    
    # Extract the archive
    if ! extract_theme_archive "$theme_type" "$theme_id" "$theme_name" "$file_name"; then
        return 1
    fi
    
    # Update timestamps so we know when this was installed
    sync_theme_timestamps "$theme_type" "$theme_id" "$theme_name"
    
    # Track the folders for cleanup later
    track_theme_folders "$theme_type" "$theme_id" "$theme_name"
    
    return 0
}


# ==============================================================================
# SECTION 11: DESKTOP ENVIRONMENT ADAPTER INTERFACE
# ==============================================================================
# This section defines the "contract" that all desktop environment adapters must follow.
# It's like a blueprint - any new desktop environment (KDE, XFCE) must implement these!
#
# EXTENDING FOR NEW DESKTOP ENVIRONMENTS:
# 1. Create functions: de_<name>_apply_gtk, de_<name>_apply_cursor, etc.
# 2. Add detection logic in detect_desktop_environment()
# 3. Register your adapter in the dispatcher functions

# Detects which desktop environment is running
# Returns: "gnome", "kde", "xfce", or "unknown"
detect_desktop_environment() {
    # Check XDG_CURRENT_DESKTOP first (most reliable)
    case "${XDG_CURRENT_DESKTOP:-}" in
        *GNOME*)  echo "gnome"; return 0 ;;
        *KDE*)    echo "kde"; return 0 ;;
        *XFCE*)   echo "xfce"; return 0 ;;
        *MATE*)   echo "mate"; return 0 ;;
        *Cinnamon*) echo "cinnamon"; return 0 ;;
    esac
    
    # Fallback: check for running processes
    if pgrep -x "gnome-shell" > /dev/null 2>&1; then
        echo "gnome"
    elif pgrep -x "plasmashell" > /dev/null 2>&1; then
        echo "kde"
    elif pgrep -x "xfce4-session" > /dev/null 2>&1; then
        echo "xfce"
    else
        echo "unknown"
    fi
}

# Current desktop environment (set during initialization)
CURRENT_DE=""

# Name of the folder that should be applied after installation (set by installers)
LAST_APPLY_NAME=""


# ==============================================================================
# SECTION 12: GNOME DESKTOP ENVIRONMENT ADAPTER
# ==============================================================================
# These functions apply themes specifically for GNOME desktop.
# GNOME uses gsettings to configure appearance.

# Applies a GTK3 theme in GNOME
de_gnome_apply_gtk3() {
    local theme_name="$1"
    gsettings set org.gnome.desktop.interface gtk-theme "$theme_name"
}

# Applies the GNOME Shell theme (the top bar and activities view)
de_gnome_apply_shell() {
    local theme_name="$1"
    # This requires the User Themes extension
    gsettings set org.gnome.shell.extensions.user-theme name "$theme_name" 2>/dev/null || true
}

# Applies GTK4 theme by creating symlinks
# GTK4/libadwaita apps need special handling - we link CSS files directly
de_gnome_apply_gtk4() {
    local theme_name="$1"
    local gtk4_config="$CONFIG_DIR/gtk-4.0"
    
    # Create config directory if needed
    ensure_directory_exists "$gtk4_config"
    
    # Remove old symlinks
    rm -f "$gtk4_config/gtk.css"
    rm -f "$gtk4_config/gtk-dark.css"
    rm -rf "$gtk4_config/assets"
    rm -rf "$CONFIG_DIR/assets"
    
    # Create new symlinks if theme has gtk-4.0 support
    local theme_path="$THEMES_DIR/$theme_name"
    
    if [[ -f "$theme_path/gtk-4.0/gtk.css" ]]; then
        ln -sf "$theme_path/gtk-4.0/gtk.css" "$gtk4_config/gtk.css"
    fi
    
    if [[ -f "$theme_path/gtk-4.0/gtk-dark.css" ]]; then
        ln -sf "$theme_path/gtk-4.0/gtk-dark.css" "$gtk4_config/gtk-dark.css"
    fi
    
    if [[ -d "$theme_path/gtk-4.0/assets" ]]; then
        ln -sf "$theme_path/gtk-4.0/assets" "$gtk4_config/assets"
    fi
    
    if [[ -d "$theme_path/assets" ]]; then
        ln -sf "$theme_path/assets" "$CONFIG_DIR/assets"
    fi
}

# Applies all GTK-related themes (GTK3 + Shell + GTK4)
de_gnome_apply_gtk() {
    local theme_name="$1"
    de_gnome_apply_gtk3 "$theme_name"
    de_gnome_apply_shell "$theme_name"
    de_gnome_apply_gtk4 "$theme_name"
    log_success "Applied GTK theme: $theme_name"
}

# Applies a cursor theme in GNOME
de_gnome_apply_cursor() {
    local cursor_name="$1"
    gsettings set org.gnome.desktop.interface cursor-theme "$cursor_name"
    log_success "Applied cursor theme: $cursor_name"
}

# Applies an icon theme in GNOME
de_gnome_apply_icon() {
    local icon_name="$1"
    gsettings set org.gnome.desktop.interface icon-theme "$icon_name"
    log_success "Applied icon theme: $icon_name"
}

# Applies wallpapers in GNOME (supports separate light/dark wallpapers)
de_gnome_apply_wallpaper() {
    local light_wallpaper="$1"
    local dark_wallpaper="$2"
    
    gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPERS_DIR/$light_wallpaper"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPERS_DIR/$dark_wallpaper"
    log_success "Applied wallpapers"
}

# Gets current theme settings from GNOME
# Returns: "gtk_theme|cursor_theme|icon_theme"
de_gnome_get_current_themes() {
    local gtk_theme cursor_theme icon_theme
    
    gtk_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'") || gtk_theme="Adwaita"
    cursor_theme=$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | tr -d "'") || cursor_theme="Adwaita"
    icon_theme=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'") || icon_theme="Adwaita"
    
    echo "${gtk_theme}|${cursor_theme}|${icon_theme}"
}


# ==============================================================================
# SECTION 13: DESKTOP ENVIRONMENT DISPATCHER
# ==============================================================================
# Routes theme operations to the correct desktop environment adapter.
# This is the "switchboard" that connects requests to the right handler.

# Applies a GTK theme using the current desktop environment adapter
apply_gtk_theme() {
    local theme_name="$1"
    
    case "$CURRENT_DE" in
        "gnome") de_gnome_apply_gtk "$theme_name" ;;
        *)
            log_warn "GTK theme application not supported for: $CURRENT_DE"
            log_info "Please apply the theme manually or add support for your DE"
            ;;
    esac
}

# Applies a cursor theme using the current desktop environment adapter
apply_cursor_theme() {
    local cursor_name="$1"
    
    case "$CURRENT_DE" in
        "gnome") de_gnome_apply_cursor "$cursor_name" ;;
        *)
            log_warn "Cursor theme application not supported for: $CURRENT_DE"
            ;;
    esac
}

# Applies an icon theme using the current desktop environment adapter
apply_icon_theme() {
    local icon_name="$1"
    
    case "$CURRENT_DE" in
        "gnome") de_gnome_apply_icon "$icon_name" ;;
        *)
            log_warn "Icon theme application not supported for: $CURRENT_DE"
            ;;
    esac
}

# Applies wallpapers using the current desktop environment adapter
apply_wallpaper() {
    local light_wallpaper="$1"
    local dark_wallpaper="$2"
    
    case "$CURRENT_DE" in
        "gnome") de_gnome_apply_wallpaper "$light_wallpaper" "$dark_wallpaper" ;;
        *)
            log_warn "Wallpaper application not supported for: $CURRENT_DE"
            ;;
    esac
}

# Gets current theme settings from the current desktop environment
get_current_themes() {
    case "$CURRENT_DE" in
        "gnome") de_gnome_get_current_themes ;;
        *)
            echo "Unknown|Unknown|Unknown"
            ;;
    esac
}


# ==============================================================================
# SECTION 14: FOLDER SELECTION SERVICE
# ==============================================================================
# When a theme archive contains multiple variant folders (e.g., Theme-Dark, 
# Theme-Light, Theme-Bordered), this section helps pick the right ones.
# We detect a "base" folder (1.5x larger than others) and let user pick a variant.

# Gets the size of a directory in bytes
# Usage: get_folder_size "/path/to/folder"
get_folder_size() {
    local folder_path="$1"
    du -sb "$folder_path" 2>/dev/null | cut -f1
}

# Analyzes folders to find a base folder (1.5x larger than average of others)
# Parameters:
#   $1 - vault_path: Path containing the extracted folders
# Returns: Name of base folder, or empty if none found
# Also sets global: FOLDER_SIZES_JSON for later use
detect_base_folder() {
    local vault_path="$1"
    
    # Get all folders and their sizes
    local folders_with_sizes=""
    local total_size=0
    local folder_count=0
    local largest_folder=""
    local largest_size=0
    
    while IFS= read -r folder; do
        [[ -z "$folder" ]] && continue
        
        local folder_path="$vault_path/$folder"
        [[ ! -d "$folder_path" ]] && continue
        
        local size
        size=$(get_folder_size "$folder_path")
        
        folders_with_sizes+="$folder:$size"$'\n'
        total_size=$((total_size + size))
        folder_count=$((folder_count + 1))
        
        if [[ $size -gt $largest_size ]]; then
            largest_size=$size
            largest_folder=$folder
        fi
    done < <(find "$vault_path" -mindepth 1 -maxdepth 1 -type d -printf "%f\n")
    
    # Need at least 2 folders to compare
    if [[ $folder_count -lt 2 ]]; then
        echo ""
        return 0
    fi
    
    # Calculate average size of OTHER folders (excluding largest)
    local other_total=$((total_size - largest_size))
    local other_count=$((folder_count - 1))
    local other_average=$((other_total / other_count))
    
    # Check if largest is 1.5x bigger than average of others
    local threshold=$((other_average * 3 / 2))  # 1.5x
    
    if [[ $largest_size -ge $threshold ]]; then
        echo "$largest_folder"
    else
        echo ""
    fi
}

# Gets all variant folders (non-base folders) from a vault path
# Parameters:
#   $1 - vault_path
#   $2 - base_folder (to exclude, can be empty)
# Returns: List of folder names, one per line
get_variant_folders() {
    local vault_path="$1"
    local base_folder="$2"
    
    while IFS= read -r folder; do
        [[ -z "$folder" ]] && continue
        [[ "$folder" == "$base_folder" ]] && continue
        echo "$folder"
    done < <(find "$vault_path" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort)
}

# Interactive folder selection for theme installation
# Detects base folder, confirms with user, lets them pick a variant
# Parameters:
#   $1 - vault_path: Path containing extracted folders
#   $2 - theme_type: "gtk", "cursor", or "icon" (for display)
# Returns: Space-separated list of folders to install (echoed)
select_folders_to_install() {
    local vault_path="$1"
    local theme_type="$2"
    
    # Count folders
    local folder_count
    folder_count=$(find "$vault_path" -mindepth 1 -maxdepth 1 -type d | wc -l)
    
    # If only one folder, just use it
    if [[ $folder_count -eq 1 ]]; then
        find "$vault_path" -mindepth 1 -maxdepth 1 -type d -printf "%f\n"
        return 0
    fi
    
    # If no folders, return empty
    if [[ $folder_count -eq 0 ]]; then
        return 0
    fi
    
    log_info "Found $folder_count ${theme_type} variant folders in archive"
    
    # Detect base folder
    local base_folder
    base_folder=$(detect_base_folder "$vault_path")
    
    local selected_folders=""
    
    if [[ -n "$base_folder" ]]; then
        # Found a base folder - confirm with user
        echo ""
        
        # Calculate base folder size and comparison
        local base_size_kb other_avg_kb
        base_size_kb=$(du -sk "$vault_path/$base_folder" 2>/dev/null | cut -f1)
        
        # Calculate average of other folders
        local other_total=0 other_count=0
        while IFS= read -r folder; do
            [[ -z "$folder" || "$folder" == "$base_folder" ]] && continue
            local sz
            sz=$(du -sk "$vault_path/$folder" 2>/dev/null | cut -f1)
            other_total=$((other_total + sz))
            other_count=$((other_count + 1))
        done < <(find "$vault_path" -mindepth 1 -maxdepth 1 -type d -printf "%f\n")
        
        if [[ $other_count -gt 0 ]]; then
            other_avg_kb=$((other_total / other_count))
        else
            other_avg_kb=0
        fi
        
        # Format sizes for display
        local base_size_display ratio_display
        if [[ $base_size_kb -ge 1024 ]]; then
            base_size_display="$((base_size_kb / 1024)) MB"
        else
            base_size_display="${base_size_kb} KB"
        fi
        
        if [[ $other_avg_kb -gt 0 ]]; then
            local ratio=$((base_size_kb * 100 / other_avg_kb))
            ratio_display="${ratio}% of avg variant size"
        else
            ratio_display="only folder"
        fi
        
        log_info "Detected base folder: ${COLOR_BOLD}$base_folder${COLOR_RESET}"
        log_info "📁 Size: ${base_size_display} (${ratio_display})"
        log_info "(This folder is significantly larger than others - likely contains shared assets)"
        
        local confirm
        confirm=$(gum confirm "📂 Is '$base_folder' the correct base folder?" && echo "yes" || echo "no")
        
        if [[ "$confirm" == "yes" ]]; then
            selected_folders="$base_folder"
            log_success "Base folder confirmed: $base_folder"
        else
            log_info "Base folder rejected. You'll select all folders manually."
            base_folder=""
        fi
    else
        log_info "No base folder detected (no folder is 1.5x larger than others)"
    fi
    
    # Get variant folders (excluding base if confirmed)
    local variants
    variants=$(get_variant_folders "$vault_path" "$base_folder")
    
    if [[ -z "$variants" ]]; then
        # No variants, just return base (or nothing)
        echo "$selected_folders"
        return 0
    fi
    
    # Let user pick a variant - build display list with sizes
    echo ""
    log_info "Available ${theme_type} variants:"
    
    local variant_display=""
    while IFS= read -r folder; do
        [[ -z "$folder" ]] && continue
        local size_kb size_display
        size_kb=$(du -sk "$vault_path/$folder" 2>/dev/null | cut -f1)
        if [[ $size_kb -ge 1024 ]]; then
            size_display="$((size_kb / 1024)) MB"
        else
            size_display="${size_kb} KB"
        fi
        variant_display+="📁 $folder ($size_display)"$'\n'
    done <<< "$variants"
    variant_display=$(echo "$variant_display" | sed '/^$/d')  # Remove empty lines
    
    local chosen_display
    chosen_display=$(echo "$variant_display" | gum choose --header "🎨 Pick a ${theme_type} variant to install:")
    
    # Extract folder name from display (remove emoji and size)
    local chosen_variant
    chosen_variant=$(echo "$chosen_display" | sed 's/^📁 //; s/ ([^)]*KB)$//; s/ ([^)]*MB)$//')
    
    if [[ -n "$chosen_variant" ]]; then
        if [[ -n "$selected_folders" ]]; then
            selected_folders="$selected_folders"$'\n'"$chosen_variant"
        else
            selected_folders="$chosen_variant"
        fi
        log_success "Selected variant: $chosen_variant"
    else
        log_warn "No variant selected"
    fi
    
    echo "$selected_folders"
}


# ==============================================================================
# SECTION 15: THEME INSTALLATION SERVICE
# ==============================================================================
# Functions that copy themes from the vault to the installation directories.
# Like moving clothes from a shipping box to your closet!

# Copies a GTK theme from vault to the themes directory
# Uses interactive folder selection when multiple variants exist
install_gtk_theme() {
    local theme_name="$1"
    local theme_id="$2"
    local archive_name="$3"
    
    local vault_path
    vault_path=$(get_vault_path "gtk" "$theme_id" "$archive_name")
    
    # Reset and determine which folders to install
    LAST_APPLY_NAME=""
    local selected_folders
    selected_folders=$(select_folders_to_install "$vault_path" "GTK")
    
    if [[ -z "$selected_folders" ]]; then
        # Fallback: use theme_name directly if no folders selected
        if [[ -d "$vault_path/$theme_name" ]]; then
            rm -rf "$THEMES_DIR/$theme_name"
            cp -r "$vault_path/$theme_name" "$THEMES_DIR/"
            LAST_APPLY_NAME="$theme_name"
        else
            log_warn "No folders to install for GTK theme"
            return 1
        fi
    else
        while IFS= read -r folder; do
            if [[ -n "$folder" && -d "$vault_path/$folder" ]]; then
                rm -rf "$THEMES_DIR/$folder"
                cp -r "$vault_path/$folder" "$THEMES_DIR/"
                log_info "Copied: $folder"
            fi
        done <<< "$selected_folders"
        # Apply the last selected folder (variant) if present; otherwise base
        LAST_APPLY_NAME=$(echo "$selected_folders" | tail -n 1)
    fi
    
    log_info "Installed GTK theme to: $THEMES_DIR"
}

# Copies a cursor theme from vault to the icons directory
# Uses interactive folder selection when multiple variants exist
install_cursor_theme() {
    local cursor_name="$1"
    local theme_id="$2"
    local archive_name="$3"
    
    local vault_path
    vault_path=$(get_vault_path "cursor" "$theme_id" "$archive_name")
    
    # Use smart folder selection
    LAST_APPLY_NAME=""
    local selected_folders
    selected_folders=$(select_folders_to_install "$vault_path" "cursor")
    
    if [[ -z "$selected_folders" ]]; then
        if [[ -d "$vault_path/$cursor_name" ]]; then
            rm -rf "$CURSORS_DIR/$cursor_name"
            cp -r "$vault_path/$cursor_name" "$CURSORS_DIR/"
            LAST_APPLY_NAME="$cursor_name"
        else
            log_warn "No folders to install for cursor theme"
            return 1
        fi
    else
        while IFS= read -r folder; do
            if [[ -n "$folder" && -d "$vault_path/$folder" ]]; then
                rm -rf "$CURSORS_DIR/$folder"
                cp -r "$vault_path/$folder" "$CURSORS_DIR/"
                log_info "Copied: $folder"
            fi
        done <<< "$selected_folders"
        LAST_APPLY_NAME=$(echo "$selected_folders" | tail -n 1)
    fi
    
    log_info "Installed cursor theme to: $CURSORS_DIR"
}

# Copies an icon theme from vault to the icons directory
# Uses interactive folder selection when multiple variants exist
install_icon_theme() {
    local icon_name="$1"
    local theme_id="$2"
    local archive_name="$3"
    
    local vault_path
    vault_path=$(get_vault_path "icon" "$theme_id" "$archive_name")
    
    # Use smart folder selection
    LAST_APPLY_NAME=""
    local selected_folders
    selected_folders=$(select_folders_to_install "$vault_path" "icon")
    
    if [[ -z "$selected_folders" ]]; then
        if [[ -d "$vault_path/$icon_name" ]]; then
            rm -rf "$ICONS_DIR/$icon_name"
            cp -r "$vault_path/$icon_name" "$ICONS_DIR/"
            LAST_APPLY_NAME="$icon_name"
        else
            log_warn "No folders to install for icon theme"
            return 1
        fi
    else
        while IFS= read -r folder; do
            if [[ -n "$folder" && -d "$vault_path/$folder" ]]; then
                rm -rf "$ICONS_DIR/$folder"
                cp -r "$vault_path/$folder" "$ICONS_DIR/"
                log_info "Copied: $folder"
            fi
        done <<< "$selected_folders"
        LAST_APPLY_NAME=$(echo "$selected_folders" | tail -n 1)
    fi
    
    log_info "Installed icon theme to: $ICONS_DIR"
}

# Updates the icon cache for faster icon loading
# Not all icon themes need this, but it helps performance
update_icon_cache() {
    local icon_name="$1"
    
    # Check if the icon theme has an index.theme file (required for caching)
    if [[ ! -f "$ICONS_DIR/$icon_name/index.theme" ]]; then
        return 0
    fi
    
    # Try GTK3 icon cache update
    if command_exists "gtk-update-icon-cache"; then
        log_info "Updating icon cache (GTK3)..."
        gtk-update-icon-cache -f -t "$ICONS_DIR/$icon_name" 2>/dev/null || true
    fi
    
    # Try GTK4 icon cache update
    if command_exists "gtk4-update-icon-cache"; then
        log_info "Updating icon cache (GTK4)..."
        gtk4-update-icon-cache -f -t "$ICONS_DIR/$icon_name" 2>/dev/null || true
    fi
}


# ==============================================================================
# SECTION 16: HISTORY MANAGEMENT
# ==============================================================================
# Keeps track of theme changes so you can go back to previous configurations.
# Like a "Time Machine" for your desktop appearance!

# Creates the history file with the current theme as the first entry
initialize_history() {
    if [[ ! -f "$HISTORY_FILE" ]]; then
        local current_themes
        current_themes=$(get_current_themes)
        
        local gtk_theme cursor_theme icon_theme
        IFS='|' read -r gtk_theme cursor_theme icon_theme <<< "$current_themes"
        
        local timestamp display_date
        timestamp=$(date -Iseconds)
        display_date=$(date "+%Y-%m-%d %H:%M")
        
        cat > "$HISTORY_FILE" << EOF
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
        log_info "Created theme history file"
    fi
}

# Saves the current theme configuration to history
# Call this BEFORE applying new themes so you can restore later
save_to_history() {
    local current_themes
    current_themes=$(get_current_themes)
    
    local gtk_theme cursor_theme icon_theme
    IFS='|' read -r gtk_theme cursor_theme icon_theme <<< "$current_themes"
    
    local timestamp display_date display_label
    timestamp=$(date -Iseconds)
    display_date=$(date "+%Y-%m-%d %H:%M")
    display_label="${display_date} - GTK: ${gtk_theme}, Cursor: ${cursor_theme}, Icon: ${icon_theme}"
    
    # Create new entry as JSON
    local new_entry
    new_entry=$(jq -n \
        --arg ts "$timestamp" \
        --arg gtk "$gtk_theme" \
        --arg cursor "$cursor_theme" \
        --arg icon "$icon_theme" \
        --arg display "$display_label" \
        '{timestamp: $ts, gtk: $gtk, cursor: $cursor, icon: $icon, display: $display}')
    
    # Load existing history or start with empty array
    local history="[]"
    if [[ -f "$HISTORY_FILE" ]]; then
        history=$(cat "$HISTORY_FILE")
    fi
    
    # Add new entry and keep only the last 50
    history=$(echo "$history" | jq --argjson entry "$new_entry" '. + [$entry] | .[-50:]')
    
    echo "$history" > "$HISTORY_FILE"
    log_info "Saved current theme to history"
}

# Displays history entries and lets user pick one to restore
# Returns: JSON object of selected entry
select_history_entry() {
    if [[ ! -f "$HISTORY_FILE" ]]; then
        log_error "No theme history found."
        return 1
    fi
    
    local history
    history=$(cat "$HISTORY_FILE")
    
    if [[ -z "$history" || "$history" == "[]" ]]; then
        log_error "Theme history is empty."
        return 1
    fi
    
    # Get display labels (newest first)
    local display_options
    display_options=$(echo "$history" | jq -r '.[] | .display' | tac)
    
    if [[ -z "$display_options" ]]; then
        log_error "No valid history entries."
        return 1
    fi
    
    # Let user choose
    local selected
    selected=$(echo "$display_options" | gum choose --header "🔄 Select a theme configuration to restore:")
    
    if [[ -z "$selected" ]]; then
        log_warn "No selection made."
        return 1
    fi
    
    # Return the matching JSON entry
    echo "$history" | jq --arg display "$selected" '.[] | select(.display == $display)'
}

# Restores themes from a history entry
restore_from_history_entry() {
    local entry="$1"
    
    local gtk_name cursor_name icon_name
    gtk_name=$(echo "$entry" | jq -r '.gtk')
    cursor_name=$(echo "$entry" | jq -r '.cursor')
    icon_name=$(echo "$entry" | jq -r '.icon')
    
    log_header "Restoring Theme Configuration"
    log_info "GTK: $gtk_name"
    log_info "Cursor: $cursor_name"
    log_info "Icon: $icon_name"
    
    apply_gtk_theme "$gtk_name"
    apply_cursor_theme "$cursor_name"
    apply_icon_theme "$icon_name"
    
    log_success "Theme configuration restored!"
}

# Main restore function - called with -r flag
run_restore() {
    log_header "Theme History"
    
    local selected_entry
    if ! selected_entry=$(select_history_entry); then
        log_info "Restore cancelled."
        return 1
    fi
    
    restore_from_history_entry "$selected_entry"
}


# ==============================================================================
# SECTION 17: WALLPAPER MANAGEMENT
# ==============================================================================
# Downloads and applies wallpapers that match your theme.
# Because a good wallpaper ties the whole look together!

# Downloads a wallpaper to the vault
download_wallpaper_file() {
    local url="$1"
    local filename="$2"
    
    ensure_directory_exists "$VAULT_DIR/wallpaper"
    
    check_internet_connection || return 1
    
    curl -sL -o "$VAULT_DIR/wallpaper/$filename" "$url" &
    local curl_pid=$!
    
    show_spinner "$curl_pid" "Downloading $filename..."
    wait "$curl_pid"
    
    if [[ $? -ne 0 ]]; then
        log_error "Failed to download wallpaper: $filename"
        return 1
    fi
    
    return 0
}

# Copies a wallpaper from vault to the Pictures/Wallpapers folder
install_wallpaper_file() {
    local filename="$1"
    cp "$VAULT_DIR/wallpaper/$filename" "$WALLPAPERS_DIR/$filename"
}

# Downloads wallpapers if they're not already in the vault
ensure_wallpapers_downloaded() {
    local light_file="$1"
    local light_url="$2"
    local dark_file="$3"
    local dark_url="$4"
    
    # Check if both already exist
    if [[ -f "$VAULT_DIR/wallpaper/$light_file" && -f "$VAULT_DIR/wallpaper/$dark_file" ]]; then
        log_info "Wallpapers already in vault."
        return 0
    fi
    
    log_info "Downloading wallpapers..."
    
    # Download light wallpaper if missing
    if [[ ! -f "$VAULT_DIR/wallpaper/$light_file" ]]; then
        download_wallpaper_file "$light_url" "$light_file" || return 1
    fi
    
    # Download dark wallpaper if missing
    if [[ ! -f "$VAULT_DIR/wallpaper/$dark_file" ]]; then
        download_wallpaper_file "$dark_url" "$dark_file" || return 1
    fi
    
    return 0
}

# High-level function to handle all wallpaper operations
process_wallpapers() {
    local light_file="$1"
    local light_url="$2"
    local dark_file="$3"
    local dark_url="$4"
    
    log_header "Wallpapers"
    
    # Download if needed
    if ! ensure_wallpapers_downloaded "$light_file" "$light_url" "$dark_file" "$dark_url"; then
        log_error "Failed to download wallpapers"
        return 1
    fi
    
    # Install (copy to Pictures folder)
    install_wallpaper_file "$light_file"
    install_wallpaper_file "$dark_file"
    
    # Apply
    apply_wallpaper "$light_file" "$dark_file"
    
    return 0
}


# ==============================================================================
# SECTION 18: THEME PROCESSING ORCHESTRATOR
# ==============================================================================
# The main "conductor" that coordinates downloading, installing, and applying themes.
# Like the director of an orchestra, making sure everyone plays at the right time!

# Processes a single theme component (gtk, cursor, or icon)
# This is the main workhorse function that handles everything for one theme type
process_theme_component() {
    local theme_type="$1"      # "gtk", "cursor", or "icon"
    local theme_id="$2"        # gnome-look.org ID
    local file_name="${3:-}"   # Optional: specific file to download
    local archive_name="${4:-}" # Optional: name for the archive folder
    
    log_header "Processing ${theme_type^^} Theme"
    log_info "Theme ID: $theme_id"
    
    # Step 1: Fetch metadata from gnome-look.org
    local metadata_json
    if ! metadata_json=$(fetch_theme_metadata "$theme_id"); then
        log_error "Failed to fetch theme metadata"
        return 1
    fi
    
    # Step 2: Select file to download (if not specified)
    if [[ -z "$file_name" ]]; then
        if ! file_name=$(select_theme_file "$metadata_json" "$theme_id"); then
            log_error "Failed to select theme file"
            return 1
        fi
    fi
    
    # Step 3: Derive archive name from filename (if not specified)
    if [[ -z "$archive_name" ]]; then
        archive_name=$(get_name_without_extension "$file_name")
    fi
    
    # Step 4: Check if download is needed
    if needs_download "$theme_type" "$theme_id" "$archive_name" "$metadata_json" "$file_name"; then
        # Clean old version first
        clean_old_theme "$theme_type" "$theme_id"
        
        # Download and extract
        if ! download_and_install_theme "$theme_type" "$theme_id" "$archive_name" "$metadata_json" "$file_name"; then
            log_error "Failed to download/extract theme"
            return 1
        fi
        
        # Update icon cache if this is an icon theme
        if [[ "$theme_type" == "icon" ]]; then
            local extracted_folders
            extracted_folders=$(get_extracted_folders "$theme_type" "$theme_id" "$archive_name")
            while IFS= read -r folder; do
                [[ -n "$folder" ]] && update_icon_cache "$folder"
            done <<< "$extracted_folders"
        fi
    fi
    
    # Step 5: Get the primary extracted folder name
    local extracted_name
    if ! extracted_name=$(get_primary_extracted_folder "$theme_type" "$theme_id" "$archive_name"); then
        log_error "Could not find extracted theme folder"
        return 1
    fi
    
    # Step 6: Install theme (copy to system directories)
    case "$theme_type" in
        "gtk")    install_gtk_theme "$extracted_name" "$theme_id" "$archive_name" ;;
        "cursor") install_cursor_theme "$extracted_name" "$theme_id" "$archive_name" ;;
        "icon")   install_icon_theme "$extracted_name" "$theme_id" "$archive_name" ;;
    esac
    
    # Step 7: Apply theme (prefer the explicitly selected variant)
    local apply_name="${LAST_APPLY_NAME:-$extracted_name}"
    if [[ -z "$apply_name" ]]; then apply_name="$extracted_name"; fi
    case "$theme_type" in
        "gtk")    apply_gtk_theme "$apply_name" ;;
        "cursor") apply_cursor_theme "$apply_name" ;;
        "icon")   apply_icon_theme "$apply_name" ;;
    esac
    
    log_success "${theme_type^^} theme ($extracted_name) complete!"
    return 0
}


# ==============================================================================
# SECTION 19: CLI INTERFACE
# ==============================================================================
# Handles command-line arguments and help messages.
# The "front door" for users who prefer typing commands!

# Shows the help/usage message
show_help() {
    cat << EOF
${COLOR_BOLD}${SCRIPT_NAME} v${SCRIPT_VERSION}${COLOR_RESET}
A modular tool for managing Linux desktop themes.

${COLOR_BOLD}USAGE:${COLOR_RESET}
    $0 [OPTIONS]

${COLOR_BOLD}OPTIONS:${COLOR_RESET}
    -g <ID>    Install GTK theme by GNOME-Look ID
    -c <ID>    Install cursor theme by GNOME-Look ID
    -i <ID>    Install icon theme by GNOME-Look ID
    -r         Restore theme from history
    -h         Show this help message

${COLOR_BOLD}EXAMPLES:${COLOR_RESET}
    $0 -g 1687249    # Install Dracula GTK theme
    $0 -c 1662218    # Install Nordic cursors
    $0 -i 1686927    # Install Nordzy icons
    $0 -r            # Restore from history
    $0               # Interactive mode (no arguments)

${COLOR_BOLD}INTERACTIVE MODE:${COLOR_RESET}
    Run without arguments to select from pre-configured theme packages.
EOF
}

# Parses and handles command-line arguments
# Returns: 0 if handled (script should exit), 1 if should continue to interactive
handle_cli_arguments() {
    while getopts "g:c:i:rh" opt; do
        case $opt in
            g)
                save_to_history
                process_theme_component "gtk" "$OPTARG"
                return 0
                ;;
            c)
                save_to_history
                process_theme_component "cursor" "$OPTARG"
                return 0
                ;;
            i)
                save_to_history
                process_theme_component "icon" "$OPTARG"
                return 0
                ;;
            r)
                run_restore
                return 0
                ;;
            h)
                show_help
                return 0
                ;;
            *)
                log_error "Invalid option. Use -h for help."
                return 0
                ;;
        esac
    done
    
    # No arguments handled, continue to interactive mode
    return 1
}


# ==============================================================================
# SECTION 20: INTERACTIVE MODE
# ==============================================================================
# The pretty menu-based interface for users who prefer clicking over typing!
# Uses 'gum' to create beautiful interactive menus.

# Displays the welcome banner
show_banner() {
    echo ""
    echo -e "${COLOR_BOLD}${COLOR_BLUE}"
    cat << 'EOF'
 ╔═══════════════════════════════════════════════════════════════════╗
 ║                                                                   ║
 ║   ████████╗██╗  ██╗███████╗███╗   ███╗███████╗                    ║
 ║   ╚══██╔══╝██║  ██║██╔════╝████╗ ████║██╔════╝                    ║
 ║      ██║   ███████║█████╗  ██╔████╔██║█████╗                      ║
 ║      ██║   ██╔══██║██╔══╝  ██║╚██╔╝██║██╔══╝                      ║
 ║      ██║   ██║  ██║███████╗██║ ╚═╝ ██║███████╗                    ║
 ║      ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚══════╝                    ║
 ║                                                                   ║
 ║   ███████╗██╗    ██╗██╗████████╗ ██████╗██╗  ██╗███████╗██████╗   ║
 ║   ██╔════╝██║    ██║██║╚══██╔══╝██╔════╝██║  ██║██╔════╝██╔══██╗  ║
 ║   ███████╗██║ █╗ ██║██║   ██║   ██║     ███████║█████╗  ██████╔╝  ║
 ║   ╚════██║██║███╗██║██║   ██║   ██║     ██╔══██║██╔══╝  ██╔══██╗  ║
 ║   ███████║╚███╔███╔╝██║   ██║   ╚██████╗██║  ██║███████╗██║  ██║  ║
 ║   ╚══════╝ ╚══╝╚══╝ ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝  ║
 ║                                                                   ║
 ╚═══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${COLOR_RESET}"
    echo -e "                    ${COLOR_BOLD}v${SCRIPT_VERSION}${COLOR_RESET} - Your Desktop, Your Style!"
    echo ""
}

# Runs the interactive theme package selection
run_interactive_mode() {
    show_banner
    
    # Get available theme packages
    local packages
    packages=$(get_available_theme_packages)
    
    if [[ -z "$packages" ]]; then
        log_error "No theme packages available."
        return 1
    fi
    
    # Let user choose a package
    local chosen_package
    chosen_package=$(echo "$packages" | gum choose --header "🎨 Pick a theme package:")
    
    if [[ -z "$chosen_package" ]]; then
        log_warn "No theme package selected. Exiting."
        exit 0
    fi
    
    log_info "Selected: $chosen_package"
    
    # Read all theme component data for the chosen package
    local gtk_id gtk_file gtk_name
    local cursor_id cursor_file cursor_name
    local icon_id icon_file icon_name
    local wp_light_file wp_light_url wp_dark_file wp_dark_url
    
    gtk_id=$(read_package_value ".gtk.id" "$chosen_package")
    gtk_file=$(read_package_value ".gtk.file" "$chosen_package")
    gtk_name=$(read_package_value ".gtk.name" "$chosen_package")
    
    cursor_id=$(read_package_value ".cursor.id" "$chosen_package")
    cursor_file=$(read_package_value ".cursor.file" "$chosen_package")
    cursor_name=$(read_package_value ".cursor.name" "$chosen_package")
    
    icon_id=$(read_package_value ".icon.id" "$chosen_package")
    icon_file=$(read_package_value ".icon.file" "$chosen_package")
    icon_name=$(read_package_value ".icon.name" "$chosen_package")
    
    wp_light_file=$(read_package_value ".wallpaper.light" "$chosen_package")
    wp_light_url=$(read_package_value ".wallpaper.lightURL" "$chosen_package")
    wp_dark_file=$(read_package_value ".wallpaper.dark" "$chosen_package")
    wp_dark_url=$(read_package_value ".wallpaper.darkURL" "$chosen_package")
    
    # Show what will be installed
    log_info "This package includes:"
    log_info "  ├─ GTK:    $gtk_name"
    log_info "  ├─ Cursor: $cursor_name"
    log_info "  ├─ Icon:   $icon_name"
    log_info "  └─ Wallpapers: $wp_light_file, $wp_dark_file"
    echo ""
    
    # Save current theme to history before making changes
    save_to_history
    
    # Process each component
    process_theme_component "gtk" "$gtk_id" "$gtk_file" "$gtk_name"
    process_theme_component "cursor" "$cursor_id" "$cursor_file" "$cursor_name"
    process_theme_component "icon" "$icon_id" "$icon_file" "$icon_name"
    
    # Process wallpapers
    process_wallpapers "$wp_light_file" "$wp_light_url" "$wp_dark_file" "$wp_dark_url"
    
    log_header "Complete!"
    log_success "Theme package '$chosen_package' has been applied!"
    log_info "Use '$0 -r' to restore previous theme if needed."
    
    return 0
}


# ==============================================================================
# SECTION 21: MAIN ENTRY POINT
# ==============================================================================
# This is where everything starts! The script runs from here.
# Think of it as the "Start" button of the whole program.

# Main function - the conductor that orchestrates everything
main() {
    # Step 1: Detect desktop environment
    CURRENT_DE=$(detect_desktop_environment)
    log_info "Detected desktop environment: $CURRENT_DE"
    
    if [[ "$CURRENT_DE" == "unknown" ]]; then
        log_warn "Unknown desktop environment. Some features may not work."
    fi
    
    # Step 2: Initialize storage directories and tracking files
    initialize_storage
    initialize_files_json
    initialize_history
    
    # Step 3: Ensure dependencies are installed
    if ! install_dependencies; then
        log_error "Failed to install dependencies. Exiting."
        exit 1
    fi
    
    # Step 4: Handle CLI arguments (if any)
    if [[ $# -gt 0 ]]; then
        if handle_cli_arguments "$@"; then
            exit 0
        fi
    fi
    
    # Step 5: No CLI arguments - run interactive mode
    run_interactive_mode
}

# ==============================================================================
# RUN THE SCRIPT
# ==============================================================================
# Pass all command-line arguments to main
main "$@"

