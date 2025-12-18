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


# ==============================================================================
# CONSTANTS - SCRIPT IDENTITY
# ==============================================================================

readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_NAME="Theme Switcher"


# ==============================================================================
# CONSTANTS - DIRECTORY PATHS
# ==============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VAULT_DIR="${HOME}/.local/share/theme-switcher-vault"
readonly THEMES_DIR="${HOME}/.local/share/themes"
readonly ICONS_DIR="${HOME}/.local/share/icons"
readonly CURSORS_DIR="${HOME}/.local/share/icons"
readonly WALLPAPERS_DIR="${HOME}/Pictures/Wallpapers"
readonly CONFIG_DIR="${HOME}/.config"


# ==============================================================================
# CONSTANTS - DATA FILES
# ==============================================================================

readonly HISTORY_FILE="${VAULT_DIR}/history.json"
readonly FILES_JSON="${VAULT_DIR}/files.json"


# ==============================================================================
# CONSTANTS - TERMINAL COLORS
# ==============================================================================

readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_BOLD='\033[1m'
readonly COLOR_RESET='\033[0m'


# ==============================================================================
# CONSTANTS - API CONFIGURATION
# ==============================================================================

readonly GNOME_LOOK_API="https://www.gnome-look.org/p"


# ==============================================================================
# GLOBAL VARIABLES
# ==============================================================================

# Verbose mode flag - controls visibility of log messages
VERBOSE_MODE=false


# ==============================================================================
# CONSTANTS - THEME PACKAGE DATABASE
# ==============================================================================

readonly THEME_PACKAGES_JSON='{
    "Dracula": {
        "gtk": {
            "id": "1687249",
            "file": "Dracula.tar.xz",
            "name": "Dracula",
            "folders": ["Dracula"]
        },
        "cursor": {
            "id": "1662218",
            "file": "Nordic-cursors.tar.xz",
            "name": "Nordic-cursors",
            "folders": ["Nordic-cursors"]
        },
        "icon": {
            "id": "1541561",
            "file": "main.zip",
            "name": "dracula-icons-main",
            "folders": ["dracula-icons-main"]
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
            "name": "Nordic-darker",
            "folders": ["Nordic-darker"]
        },
        "cursor": {
            "id": "1662218",
            "file": "Nordic-cursors.tar.xz",
            "name": "Nordic-cursors",
            "folders": ["Nordic-cursors"]
        },
        "icon": {
            "id": "1686927",
            "file": "Nordzy.tar.gz",
            "name": "Nordzy",
            "folders": ["Nordzy"]
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
            "name": "Catppuccin-B-MB-Dark",
            "folders": ["Catppuccin-B-MB-Dark"]
        },
        "cursor": {
            "id": "1148692",
            "file": "capitaine-cursors-r4.tar.gz",
            "name": "capitaine-cursors",
            "folders": ["capitaine-cursors"]   
        },
        "icon": {
            "id": "1405756",
            "file": "WhiteSur-yellow.tar.xz",
            "name": "WhiteSur-yellow",
            "folders": ["WhiteSur-yellow"]
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
            "name": "Graphite-Dark-nord",
            "folders": ["Graphite-Dark-nord"]   
        },
        "cursor": {
            "id": "1651517",
            "file": "Graphite-nord.tar.xz",
            "name": "Graphite-dark-nord-cursors",
            "folders": ["Graphite-dark-nord-cursors"]
        },
        "icon": {
            "id": "1359276",
            "file": "Tela-circle-nord.tar.xz",
            "name": "Tela-circle-nord",
            "folders": ["Tela-circle-nord"]
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
# LOGGING FUNCTIONS
# ==============================================================================

log_error() {
    local message="$1"
    echo -e "${COLOR_RED}${COLOR_BOLD}[ERROR]${COLOR_RESET} ${message}" >&2
}

log_info() {
    local message="$1"
    if [[ "$VERBOSE_MODE" == true ]]; then
        echo -e "${COLOR_BLUE}${COLOR_BOLD}[INFO]${COLOR_RESET} ${message}"
    fi
}

log_success() {
    local message="$1"
    if [[ "$VERBOSE_MODE" == true ]]; then
        echo -e "${COLOR_GREEN}${COLOR_BOLD}[SUCCESS]${COLOR_RESET} ${message}"
    fi
}

log_warn() {
    local message="$1"
    if [[ "$VERBOSE_MODE" == true ]]; then
        echo -e "${COLOR_YELLOW}${COLOR_BOLD}[WARN]${COLOR_RESET} ${message}"
    fi
}

log_header() {
    local title="$1"
    if [[ "$VERBOSE_MODE" == true ]]; then
        echo -e "\n${COLOR_BOLD}${COLOR_BLUE}━━━ ${title} ━━━${COLOR_RESET}"
    fi
}

show_progressbar() {
    local pid=$1           # The process ID we're waiting for
    local message=$2       
    local dot_count=20     
    
    local label=""
    if [[ "$VERBOSE_MODE" == false ]]; then
        label=$message
    else
        label="       ${message}"
    fi
    
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
            printf "\r%s ${COLOR_BLUE}[:${bar}:]${COLOR_RESET}" "$label" >&2
            sleep 0.12
        done
    done
    printf "\r\033[K" >&2  # Clear the line when done
}

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

show_help() {
    echo -e "${COLOR_BOLD}${SCRIPT_NAME} v${SCRIPT_VERSION}${COLOR_RESET}"
    echo "A modular tool for managing Linux desktop themes."
    echo ""
    echo -e "${COLOR_BOLD}USAGE:${COLOR_RESET}"
    echo "    $0 [OPTIONS]"
    echo ""
    echo -e "${COLOR_BOLD}OPTIONS:${COLOR_RESET}"
    echo "    -g <ID>    Install GTK theme by GNOME-Look ID"
    echo "    -c <ID>    Install cursor theme by GNOME-Look ID"
    echo "    -i <ID>    Install icon theme by GNOME-Look ID"
    echo "    -r         Restore theme from history"
    echo "    -v         Enable verbose mode (show detailed logs)"
    echo "    -h         Show this help message"
    echo ""
    echo -e "${COLOR_BOLD}EXAMPLES:${COLOR_RESET}"
    echo "    $0 -g 1687249       # Install Dracula GTK theme"
    echo "    $0 -v -g 1687249    # Install Dracula GTK theme with verbose output"
    echo "    $0 -c 1662218       # Install Nordic cursors"
    echo "    $0 -i 1686927       # Install Nordzy icons"
    echo "    $0 -r               # Restore from history"
    echo "    $0                  # Interactive mode (no arguments)"
    echo ""
    echo -e "${COLOR_BOLD}INTERACTIVE MODE:${COLOR_RESET}"
    echo "    Run without arguments to select from pre-configured theme packages."
}

# ==============================================================================
# BASIC UTILITIES - SIMPLE HELPERS
# ==============================================================================

is_command_exist() {
    local cmd="$1"
    if command -v "$cmd" &>/dev/null; then
        return 0
    fi
    return 1
}

get_name_without_extension() {
    local filename="$1"
    echo "${filename%%.*}"
}

read_json_value() {
    local json_file_or_data="$1"
    local json_path="$2"

    if [[ -f "$json_file_or_data" ]]; then
        local json_data=$(cat "$json_file_or_data")
    else
        local json_data="$json_file_or_data"
    fi

    echo "$json_data" | jq -er "$json_path"
}

is_internet_exist() {
    if ! ping -c 1 -W 3 google.com &>/dev/null; then
        log_error "No internet connection available. Please check your network."
        return 1
    fi
    return 0
}

detect_desktop_environment() {
    case "${XDG_CURRENT_DESKTOP:-}" in
        *GNOME*)  echo "gnome"; return 0 ;;
        *KDE*)    echo "kde"; return 0 ;;
        *XFCE*)   echo "xfce"; return 0 ;;
        *MATE*)   echo "mate"; return 0 ;;
        *Cinnamon*) echo "cinnamon"; return 0 ;;
        *) echo "unknown"; return 0 ;;
    esac
}


# ==============================================================================
# INITIALIZATION FUNCTIONS
# ==============================================================================

initialize_storage() {
    mkdir -p "$VAULT_DIR"
    mkdir -p "$THEMES_DIR"
    mkdir -p "$ICONS_DIR"
    mkdir -p "$CURSORS_DIR"
    mkdir -p "$WALLPAPERS_DIR"
    mkdir -p "$VAULT_DIR/gtk"
    mkdir -p "$VAULT_DIR/cursor"
    mkdir -p "$VAULT_DIR/icon"
    mkdir -p "$VAULT_DIR/wallpaper"
}

initialize_files_json() {
    if [[ ! -f "$FILES_JSON" ]]; then
        echo "{}" > "$FILES_JSON"
        log_info "Created files.json"
    fi
}

initialize_history() {
    if [[ ! -f "$HISTORY_FILE" ]]; then        
        cat > "$HISTORY_FILE" << EOF
[
]
EOF
        log_info "Created history.json"
    fi
}


# ==============================================================================
# DEPENDENCY MANAGEMENT
# ==============================================================================

get_package_install_command() {
    if command -v dnf &>/dev/null; then
        echo "sudo dnf install -yq"
    elif command -v apt &>/dev/null; then
        echo "sudo apt install -yq"
    elif command -v pacman &>/dev/null; then
        echo "sudo pacman -S --noconfirm"
    elif command -v zypper &>/dev/null; then
        echo "sudo zypper install -y"
    else
        log_error "Could not detect package manager"
        return 1
    fi
}

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

install_single_package() {
    local package_name="$1"

    local install_cmd=$(get_package_install_command)
    
    if ! is_command_exist "$package_name"; then
        log_warn "'$package_name' is not installed. Installing..."

        # Exit if the package manager is not found
        if [[ $install_cmd == 1 ]]; then
            log_error "Failed to install '$package_name'"
            log_warn "Try installing these dependencies manually"
            log_warn "  │─> jq"
            log_warn "  │─> gum"
            log_warn "  │─> curl"
            log_warn "  │─> tar"
            log_warn "  ╰─> unzip"
            exit 1
        fi
        
        # Run the install command
        if ! $install_cmd "$package_name"; then
            log_error "Failed to install '$package_name'"
            return 1
        fi

        log_success "$package_name installed successfully"
    fi
    return 0
}

install_all_packages() {
    local install_cmd=$(get_package_install_command)
    
    # Install each required dependency except gum
    local -a dependencies=("jq" "curl" "tar" "unzip")
    for dep in "${dependencies[@]}"; do
        install_single_package "$dep"
    done

    # Install gum if it's not already installed
    if [[ $install_cmd == *"apt"* ]]; then
        add_gum_repository_for_apt
    fi
    install_single_package "gum"
    
    log_success "All dependencies are ready!"
    return 0
}


# ==============================================================================
# DESKTOP ENVIRONMENT ADAPTERS - GET CURRENT THEMES
# ==============================================================================

get_current_gtk_theme_gnome() {
    local gtk_theme
    
    gtk_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'") || gtk_theme="Adwaita"
    
    echo "$gtk_theme"
}

get_current_cursor_theme_gnome() {
    local cursor_theme
    
    cursor_theme=$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | tr -d "'") || cursor_theme="Adwaita"
    
    echo "$cursor_theme"
}

get_current_icon_theme_gnome() {
    local icon_theme
    
    icon_theme=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'") || icon_theme="Adwaita"
    
    echo "$icon_theme"
}


# ==============================================================================
# DESKTOP ENVIRONMENT ADAPTERS - APPLY THEMES
# ==============================================================================

# GTK4/libadwaita apps need special handling - we link CSS files directly
apply_gtk4() {
    local theme_name="$1"
    local gtk4_config="$CONFIG_DIR/gtk-4.0"
    
    mkdir -p "$gtk4_config"
    
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

apply_gtk_theme_gnome() {
    local theme_name="$1"

    # Apply gtk3 theme and shell
    gsettings set org.gnome.desktop.interface gtk-theme "$theme_name"
    gsettings set org.gnome.shell.extensions.user-theme name "$theme_name"

    apply_gtk4 "$theme_name"
}

apply_icon_theme_gnome() {
    local theme_name="$1"

    gsettings set org.gnome.desktop.interface icon-theme "$theme_name"
}

apply_cursor_theme_gnome() {
    local theme_name="$1"

    gsettings set org.gnome.desktop.interface cursor-theme "$theme_name"
}


# ==============================================================================
# VAULT PATH UTILITIES
# ==============================================================================

get_vault_path_to_the_zip_file() {
    local theme_type="$1"
    local theme_id="$2"
    local zip_name="$3"

    local zip_name_without_extension
    zip_name_without_extension=$(get_name_without_extension "$zip_name")
    
    echo "$VAULT_DIR/$theme_type/$theme_id/$zip_name_without_extension"
}

get_folder_names_in_vault() {
    local theme_type="$1"
    local theme_id="$2"
    local zip_name="$3"
    
    local vault_path
    vault_path=$(get_vault_path_to_the_zip_file "$theme_type" "$theme_id" "$zip_name")
    
    if [[ ! -d "$vault_path" ]]; then
        return 1
    fi
    
    find "$vault_path" -mindepth 1 -maxdepth 1 -type d -printf "%f\n"
}


# ==============================================================================
# METADATA AND TIMESTAMP FUNCTIONS
# ==============================================================================

fetch_theme_metadata() {
    local theme_id="$1"

    local temp_file
    temp_file=$(mktemp)
    
    is_internet_exist || return 1
    
    curl -Lfs "${GNOME_LOOK_API}/${theme_id}/loadFiles" > "$temp_file" &
    local curl_pid=$!
    
    show_progressbar "$curl_pid" "Fetching theme metadata..."
    wait "$curl_pid"
    local curl_result=$?
    
    if [[ $curl_result -ne 0 ]]; then
        rm -f "$temp_file"
        log_error "Failed to fetch theme metadata for ID: $theme_id"
        return 1
    fi

    cat "$temp_file"
    rm -f "$temp_file"
}

extract_download_url() {
    local metadata_json="$1"
    local zip_name="$2"
    
    local encoded_url
    encoded_url=$(echo "$metadata_json" | jq -r --arg name "$zip_name" \
        '.files[] | select(.active == "1" and .name == $name) | .url' | head -n 1)
    
    if [[ -z "$encoded_url" || "$encoded_url" == "null" ]]; then
        log_error "Download URL not found for file: $zip_name"
        return 1
    fi
    
    printf '%b' "${encoded_url//%/\\x}"

}

get_local_update_timestamp() {
    local theme_type="$1"
    local theme_id="$2"

    local latest_date
    latest_date=$(cat "$FILES_JSON" | jq -r --arg type "$theme_type" --arg id "$theme_id" \
        '.[$type][$id] | to_entries[] | .value.date // empty' | sort -r | head -n 1)

    if [[ -z "$latest_date" || "$latest_date" == "null" ]]; then
        log_error "Could not find the local update timestamp for theme type: $theme_type, id: $theme_id"
        exit 1
    fi

    date -d "$latest_date" +%s
}

get_remote_update_timestamp() {
    local metadata_json="$1"
    local zip_name="$2"
    
    local update_date
    update_date=$(echo "$metadata_json" | jq -r --arg name "$zip_name" \
        '.files[] | select(.active == "1" and .name == $name) | .updated_timestamp' | head -n 1)   
    
    if [[ -z "$update_date" || "$update_date" == "null" ]]; then
        log_error "Could not find update timestamp for file: $zip_name"
        exit 1
    fi
    
    date -d "$update_date" +%s
}


# ==============================================================================
# FILES TRACKING FUNCTIONS
# ==============================================================================

track_theme_folders() {
    local theme_type="$1"
    local theme_id="$2"
    local zip_name="$3"
    
    local folders_json
    folders_json=$(get_folder_names_in_vault "$theme_type" "$theme_id" "$zip_name" | jq -R . | jq -s .)
    
    if [[ -z "$folders_json" || "$folders_json" == "[]" ]]; then
        log_warn "No folders to track for $theme_type/$theme_id"
        return 0
    fi
    
    local updated_json
    updated_json=$(jq --arg type "$theme_type" \
                      --arg id "$theme_id" \
                      --arg zip_name "$zip_name" \
                      --argjson folders_json "$folders_json" \
                      '.[$type][$id] += {
                            ($zip_name): {
                                "folders": $folders_json,
                                "date": ""
                            }
                      }' "$FILES_JSON")
    
    echo "$updated_json" > "$FILES_JSON"
    log_info "Tracked $theme_type theme folders in files.json"
}

save_the_downloaded_date() {
    local theme_type="$1"
    local theme_id="$2"
    local zip_name="$3"

    local zip_name_without_extension
    zip_name_without_extension=$(get_name_without_extension "$zip_name")
    
    local data_time
    data_time=$(date "+%Y-%m-%d %H:%M")
    
    local json_entry
    # Check if the entry exists first to avoid errors
    if ! cat "$FILES_JSON" | jq -e --arg type "$theme_type" --arg id "$theme_id" --arg zip_name "$zip_name" \
        '.[$type][$id][$zip_name]' > /dev/null; then
        exit 1
    fi

    local new_files_json
    new_files_json=$(cat "$FILES_JSON" | jq --arg type "$theme_type" --arg id "$theme_id" --arg zip_name "$zip_name" --arg date "$data_time" \
        '.[$type][$id][$zip_name].date = $date')
    
    echo "$new_files_json" > "$FILES_JSON"   
    
}

get_tracked_folder_names_for_the_theme() {
    local theme_type="$1"
    local theme_id="$2"
    
    if [[ ! -f "$FILES_JSON" ]]; then
        return 0
    fi
    
    local tracked_folders
    tracked_folders=$(read_json_value "$FILES_JSON" ".\"$theme_type\".\"$theme_id\"? | .[]? | .folders[]?")
    
    echo "$tracked_folders"
}

untrack_full_theme() {
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
# DOWNLOAD AND EXTRACTION FUNCTIONS
# ==============================================================================

download_theme_zip_to_vault() {
    local theme_type="$1"
    local theme_id="$2"
    local zip_name="$3"
    local metadata_json="$4"
    
    local download_url
    if ! download_url=$(extract_download_url "$metadata_json" "$zip_name"); then
        exit 1
    fi
    
    local vault_path
    vault_path=$(get_vault_path_to_the_zip_file "$theme_type" "$theme_id" "$zip_name")
    mkdir -p "$vault_path"
    
    rm -f "$vault_path/$zip_name"
    
    is_internet_exist || exit 1
    
    curl -sL -o "$vault_path/$zip_name" "$download_url" &
    local curl_pid=$!
    
    show_progressbar "$curl_pid" "Downloading $zip_name..."
    wait "$curl_pid"
    
    if [[ $? -ne 0 ]]; then
        log_error "Download failed for: $zip_name"
        exit 1
    fi
    
    log_success "Downloaded: $zip_name"
    return 0
}

extract_theme_zip_to_vault(){
    local theme_type="$1"
    local theme_id="$2"
    local zip_name="$3"
    
    local vault_path
    vault_path=$(get_vault_path_to_the_zip_file "$theme_type" "$theme_id" "$zip_name")
    local archive_path="$vault_path/$zip_name"
    
    if [[ ! -f "$archive_path" ]]; then
        log_error "Archive not found: $archive_path"
        exit 1
    fi
    
    log_info "Extracting: $zip_name"
    
    # Extract based on file extension
    case "$zip_name" in
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
            log_error "Unknown archive format: $zip_name"
            exit 1
            ;;
    esac
    
    log_success "Extracted: $zip_name"
    return 0
}


# ==============================================================================
# THEME STATUS CHECK FUNCTIONS
# ==============================================================================

is_theme_already_downloaded() {
    local theme_type="$1"
    local theme_id="$2"
    local zip_name="$3"
    local folder_name="$4"

    local zip_name_without_extension
    zip_name_without_extension=$(get_name_without_extension "$zip_name")
    
    [[ -d "$VAULT_DIR/$theme_type/$theme_id/$zip_name_without_extension/$folder_name" ]]
}

is_update_available() {
    local theme_type="$1"
    local theme_id="$2"
    local zip_name="$3"
    local metadata_json="$4"
    
    local local_timestamp
    if ! local_timestamp=$(get_local_update_timestamp "$theme_type" "$theme_id"); then
        exit 1
    fi
    local remote_timestamp
    if ! remote_timestamp=$(get_remote_update_timestamp "$metadata_json" "$zip_name"); then
        exit 1
    fi
    
    if [[ "$remote_timestamp" -gt "$local_timestamp" ]]; then
        log_info "$theme_type theme has updates available. Will download."
        return 0
    fi

    return 1
}


# ==============================================================================
# THEME DELETION FUNCTIONS
# ==============================================================================

delete_full_theme_from_vault() {
    local theme_type="$1"
    local theme_id="$2"
    
    if [[ -d "$VAULT_DIR/$theme_type/$theme_id" ]]; then
        rm -rf "$VAULT_DIR/$theme_type/$theme_id"
    fi
}

delete_full_theme_from_theme_dir() {
    local theme_type="$1"
    local theme_id="$2"
    
    local tracked_folders
    tracked_folders=$(get_tracked_folder_names_for_the_theme "$theme_type" "$theme_id")

    local theme_dir
    case "$theme_type" in
        "gtk")    theme_dir="$THEMES_DIR" ;;
        "cursor") theme_dir="$CURSORS_DIR" ;;
        "icon")   theme_dir="$ICONS_DIR" ;;
    esac
    
    while IFS= read -r folder; do
        if [[ -n "$folder" && -d "$theme_dir/$folder" ]]; then
            rm -rf "$theme_dir/$folder"
        fi
    done <<< "$tracked_folders"
}


# ==============================================================================
# THEME SELECTION FUNCTIONS
# ==============================================================================

get_available_theme_packages() {
    echo "$THEME_PACKAGES_JSON" | jq -r 'keys[]'
}

get_active_theme_file_names() {
    local metadata_json="$1"

    echo "$metadata_json" | jq -r '.files[] | select(.active == "1") | .name'
}

select_theme_file() {
    local metadata_json="$1"
    local theme_id="$2"
    
    local available_files
    available_files=$(get_active_theme_file_names "$metadata_json")
    
    if [[ -z "$available_files" ]]; then
        log_error "No active files found for theme ID: $theme_id"
        exit 1
    fi
    
    local selected_file
    selected_file=$(echo "$available_files" | gum choose --header "📦 Pick a file to download:" \
                                                         --select-if-one \
                                                         --cursor.background="220" \
                                                         --cursor.foreground="0" \
                                                         --cursor.bold \
                                                         --cursor="   ➔➔ ")

    echo -e "📦 $selected_file" >&2
    echo "$selected_file"
}

select_theme_folder(){
    local theme_type="$1"
    local theme_id="$2"
    local zip_name="$3"
    
    local vault_path
    vault_path=$(get_vault_path_to_the_zip_file "$theme_type" "$theme_id" "$zip_name")
    
    local folder_list
    folder_list=($(find "$vault_path" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | gum choose --header "   ⮩ 📁 Select a theme:" \
                                                                                                  --select-if-one \
                                                                                                  --cursor.background="220" \
                                                                                                  --cursor.foreground="0" \
                                                                                                  --cursor.bold \
                                                                                                  --cursor="      ➔➔ " ))
    
    echo -e "   ⮩ 📁 ${folder_list[@]}" >&2
    echo "${folder_list[@]}"
}


# ==============================================================================
# THEME INSTALLATION FUNCTIONS
# ==============================================================================

install_gtk_theme() {
    local theme_id="$1"
    local zip_name="$2"
    local folder_list="$3"
    
    local zip_name_without_extension
    zip_name_without_extension=$(get_name_without_extension "$zip_name")
    
    for folder in $folder_list; do
        if [[ -d "$THEMES_DIR/$folder" ]]; then
            rm -rf "$THEMES_DIR/$folder"
        fi
        cp -r "$VAULT_DIR/gtk/$theme_id/$zip_name_without_extension/$folder" "$THEMES_DIR/"
    done
}

install_cursor_theme() {
    local theme_id="$1"
    local zip_name="$2"
    local folder_list="$3"
    
    local zip_name_without_extension
    zip_name_without_extension=$(get_name_without_extension "$zip_name")
    
    for folder in $folder_list; do
        if [[ -d "$CURSORS_DIR/$folder" ]]; then
            rm -rf "$CURSORS_DIR/$folder"
        fi
        cp -r "$VAULT_DIR/cursor/$theme_id/$zip_name_without_extension/$folder" "$CURSORS_DIR/"
    done
}

install_icon_theme() {
    local theme_id="$1"
    local zip_name="$2"
    local folder_list="$3"
    
    local zip_name_without_extension
    zip_name_without_extension=$(get_name_without_extension "$zip_name")
    
    for folder in $folder_list; do
        if [[ -d "$ICONS_DIR/$folder" ]]; then
            rm -rf "$ICONS_DIR/$folder"
        fi
        cp -r "$VAULT_DIR/icon/$theme_id/$zip_name_without_extension/$folder" "$ICONS_DIR/"
    done
}

update_icon_cache() {
    local icon_name="$1"
    
    if [[ ! -f "$ICONS_DIR/$icon_name/index.theme" ]]; then
        return 0
    fi
    
    if is_command_exist "gtk-update-icon-cache"; then
        log_info "Updating icon cache (GTK3)..."
        gtk-update-icon-cache -f -t "$ICONS_DIR/$icon_name" 2>/dev/null || true
    fi
    
    if is_command_exist "gtk4-update-icon-cache"; then
        log_info "Updating icon cache (GTK4)..."
        gtk4-update-icon-cache -f -t "$ICONS_DIR/$icon_name" 2>/dev/null || true
    fi
}


# ==============================================================================
# WALLPAPER MANAGEMENT
# ==============================================================================

download_wallpaper() {
    local url="$1"
    local filename="$2"
    
    is_internet_exist || exit 1
    
    curl -sL -o "$VAULT_DIR/wallpaper/$filename" "$url" &
    local curl_pid=$!
    
    show_progressbar "$curl_pid" "Downloading Wallpaper: $filename..."
    wait "$curl_pid"
    
    if [[ $? -ne 0 ]]; then
        log_error "Failed to download wallpaper: $filename"
        exit 1
    fi

    log_info "Downloaded wallpaper: $filename"
}

install_wallpaper() {
    local filename="$1"

    if [[ -f "$WALLPAPERS_DIR/$filename" ]]; then
        rm "$WALLPAPERS_DIR/$filename"
    fi

    cp "$VAULT_DIR/wallpaper/$filename" "$WALLPAPERS_DIR/$filename"
}

apply_wallpaper_gnome() {
    local light_wallpaper="$1"
    local dark_wallpaper="$2"
    
    gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPERS_DIR/$light_wallpaper"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPERS_DIR/$dark_wallpaper"
}

process_wallpapers() {
    local light_file="$1"
    local light_url="$2"
    local dark_file="$3"
    local dark_url="$4"
    local de="$5"
    
    log_header "Wallpapers"
    
    if [[ -f "$VAULT_DIR/wallpaper/$light_file" ]]; then
        log_info "Wallpaper already exists: $light_file"
    else
        download_wallpaper "$light_url" "$light_file"
    fi
    if [[ -f "$VAULT_DIR/wallpaper/$dark_file" ]]; then
        log_info "Wallpaper already exists: $dark_file"
    else
        download_wallpaper "$dark_url" "$dark_file"
    fi
    
    install_wallpaper "$light_file"
    install_wallpaper "$dark_file"
    
    local function_name="apply_wallpaper_${de}"
    $function_name "$light_file" "$dark_file"
    
    return 0
}


# ==============================================================================
# HISTORY MANAGEMENT
# ==============================================================================

save_current_theme_to_history() {
    local theme_type="$1"
    local de="$2"

    local current_themes
    local function_name="get_current_${theme_type}_theme_${de}"
    current_themes=$($function_name)
    
    local data_time
    data_time=$(date "+%Y-%m-%d %H:%M")
    
    local new_entry
    new_entry=$(jq -n \
        --arg type "$theme_type" \
        --arg name "$current_themes" \
        --arg data_time "$data_time" \
        '{type: $type, name: $name, data_time: $data_time}')
    
    local history="[]"
    if [[ -f "$HISTORY_FILE" ]]; then
        history=$(cat "$HISTORY_FILE")
    fi
    
    # Add new entry and keep only the last 100
    history=$(echo "$history" | jq --argjson entry "$new_entry" '. + [$entry] | .[-100:]')
    
    echo "$history" > "$HISTORY_FILE"
    log_info "Saved current $theme_type theme to history"
}

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
    
    local unique_entries
    unique_entries=$(echo "$history" | jq -r 'group_by(.type + ":" + .name) | .[] | .[-1] | "\(.type) theme: \(.name)"' | sort -u)
    
    if [[ -z "$unique_entries" ]]; then
        log_error "No valid history entries."
        return 1
    fi
    
    local selected
    selected=$(echo "$unique_entries" | gum choose --header "🔄 Select a theme configuration to restore:" \
                                                   --cursor.background="220" \
                                                   --cursor.foreground="0" \
                                                   --cursor.bold \
                                                   --cursor="   ➔➔ ")
    
    if [[ -z "$selected" ]]; then
        log_warn "No selection made."
        return 1
    fi

    echo -e "🔄 $selected" >&2
    
    local theme_type
    local theme_name
    theme_type=$(echo "$selected" | sed -E 's/^([^ ]+).*/\1/')
    theme_name=$(echo "$selected" | sed -E 's/^[^:]+: //')
    
    jq -n --arg type "$theme_type" --arg name "$theme_name" '{type: $type, name: $name}'
}

restore_from_history_entry() {
    local entry="$1"

    # TODO: save desktop environment to history json and reterive here 
    local de="gnome"
    
    local theme_type theme_name
    theme_type=$(echo "$entry" | jq -r '.type')
    theme_name=$(echo "$entry" | jq -r '.name')
    
    log_header "Restoring Theme Configuration"
    log_info "  ├─>Type: $theme_type"
    log_info "  ╰─>Name: $theme_name"
    
    local function_name="apply_${theme_type}_theme_${de}"
    $function_name "$theme_name"
    
    log_success "Theme restored!"
}

restore() {
    log_header "Theme History"
    
    local selected_entry
    if ! selected_entry=$(select_history_entry); then
        log_info "Restore cancelled. Exiting."
        exit 0
    fi
    
    restore_from_history_entry "$selected_entry"
}

# ==============================================================================
# MAIN THEME PROCESSING
# ==============================================================================

process_theme() {
    local theme_type="$1"      
    local theme_id="$2"        
    local de="$3"              
    local zip_name="${4:-}"       # Optional: specific zip file to download. 
                                  # There may be multiple variants for the same theme.
    local folder_name="${5:-}"    # Optional: name for the sub-varient. 
                                  # There may be multiple sub-variants in the same zip file.
    local folder_list="${6:-}"    # Optional: list of folders to copy. 
                                  # Eventhough we apply a single theme, it may consist of multiple folders. ex: base, light, dark
    
    log_header "Processing ${theme_type} Theme"
    
    local metadata_json
    if ! metadata_json=$(fetch_theme_metadata "$theme_id"); then
        log_error "Failed to fetch theme metadata"
        exit 1
    fi
    
    # Select file to download (if not specified)
    if [[ -z "$zip_name" ]]; then
        echo ""
        zip_name=$(select_theme_file "$metadata_json" "$theme_id")
        
        if [[ -z "$zip_name" ]]; then
            log_error "No files selected. Exiting."
            exit 0
        fi
    fi

    # Check if download is needed
    if is_theme_already_downloaded "$theme_type" "$theme_id" "$zip_name" "$folder_name"; then
        if is_update_available "$theme_type" "$theme_id" "$zip_name" "$metadata_json"; then
            delete_full_theme_from_vault "$theme_type" "$theme_id"
            delete_full_theme_from_theme_dir "$theme_type" "$theme_id"
            untrack_full_theme "$theme_type" "$theme_id"

            if ! download_theme_zip_to_vault "$theme_type" "$theme_id" "$zip_name" "$metadata_json"; then
                log_error "Failed to download/extract theme"
                exit 1
            fi
        else
            log_info "Theme is up-to-date"
        fi
    else
        if ! download_theme_zip_to_vault "$theme_type" "$theme_id" "$zip_name" "$metadata_json"; then
            log_error "Failed to download/extract theme"
            exit 1
        fi
    fi

    extract_theme_zip_to_vault "$theme_type" "$theme_id" "$zip_name"
    track_theme_folders "$theme_type" "$theme_id" "$zip_name"
    save_the_downloaded_date "$theme_type" "$theme_id" "$zip_name"        
    
    # Update icon cache if this is an icon theme
    if [[ "$theme_type" == "icon" ]]; then
        local extracted_folders
        extracted_folders=$(get_folder_names_in_vault "$theme_type" "$theme_id" "$zip_name")
        while IFS= read -r folder; do
            [[ -n "$folder" ]] && update_icon_cache "$folder"
        done <<< "$extracted_folders"
    fi

    # Select folder/folders to install (if not specified)
    if [[ -z "$folder_list" ]]; then
        if [[ -z "$folder_name" ]]; then
            folder_list=$(select_theme_folder "$theme_type" "$theme_id" "$zip_name")
            # We put the prefered variant at the top of the list
            folder_name=$(echo "$folder_list" | head -n 1)
        else
            folder_list="$folder_name"
        fi
    else
        folder_list=$(echo "$folder_list" | jq -r '.[]' | tr '\n' ' ' | sed 's/ $//')
        if [[ -z "$folder_name" ]]; then
            folder_name=$(echo "$folder_list" | head -n 1)
        fi
    fi
        
    # Install theme (copy to theme directories)
    local function_name="install_${theme_type}_theme"
    $function_name "$theme_id" "$zip_name" "$folder_list"
    
    # Apply theme
    local function_name="apply_${theme_type}_theme_${de}"
    $function_name "$folder_name"
    
    log_success "${theme_type} theme ($folder_name) complete!"
    return 0
}


# ==============================================================================
# MODES
# ==============================================================================

handle_cli_arguments() {
    local de
    de=$(detect_desktop_environment)

    while getopts "g:c:i:rvh" opt; do
        case $opt in
            v)
                VERBOSE_MODE=true
                ;;
        esac
    done
    
    OPTIND=1
    
    while getopts "g:c:i:rvh" opt; do
        case $opt in
            g)
                save_current_theme_to_history "gtk" "$de"
                process_theme "gtk" "$OPTARG" "$de"
                return 0
                ;;
            c)
                save_current_theme_to_history "cursor" "$de"
                process_theme "cursor" "$OPTARG" "$de"
                return 0
                ;;
            i)
                save_current_theme_to_history "icon" "$de"
                process_theme "icon" "$OPTARG" "$de"
                return 0
                ;;
            r)
                restore
                return 0
                ;;
            v)
                # Already handled in first pass
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
    return 1
}

interactive_mode() {
    show_banner

    local de
    de=$(detect_desktop_environment)
    
    local packages
    packages=$(get_available_theme_packages)
    
    if [[ -z "$packages" ]]; then
        log_error "No theme packages available. Exiting."
        exit 0
    fi
    
    local chosen_package
    chosen_package=$(echo "$packages" | gum choose --header "🎨 Pick a theme package:" \
                                                   --cursor.background="220" \
                                                   --cursor.foreground="0" \
                                                   --cursor.bold \
                                                   --cursor="   ➔➔ ")
    
    if [[ -z "$chosen_package" ]]; then
        log_warn "No theme package selected. Exiting."
        exit 0
    fi
    
    log_info "🎨 $chosen_package"
    
    local gtk_id gtk_file gtk_name gtk_folders
    local cursor_id cursor_file cursor_name cursor_folders
    local icon_id icon_file icon_name icon_folders
    local wp_light_file wp_light_url wp_dark_file wp_dark_url
    
    gtk_id=$(read_json_value "$THEME_PACKAGES_JSON" ".\"${chosen_package}\".gtk.id")
    gtk_file=$(read_json_value "$THEME_PACKAGES_JSON" ".\"${chosen_package}\".gtk.file")
    gtk_name=$(read_json_value "$THEME_PACKAGES_JSON" ".\"${chosen_package}\".gtk.name")
    gtk_folders=$(read_json_value "$THEME_PACKAGES_JSON" ".\"${chosen_package}\".gtk.folders")
    
    cursor_id=$(read_json_value "$THEME_PACKAGES_JSON" ".\"${chosen_package}\".cursor.id")
    cursor_file=$(read_json_value "$THEME_PACKAGES_JSON" ".\"${chosen_package}\".cursor.file")
    cursor_name=$(read_json_value "$THEME_PACKAGES_JSON" ".\"${chosen_package}\".cursor.name")
    cursor_folders=$(read_json_value "$THEME_PACKAGES_JSON" ".\"${chosen_package}\".cursor.folders")
    
    icon_id=$(read_json_value "$THEME_PACKAGES_JSON" ".\"${chosen_package}\".icon.id")
    icon_file=$(read_json_value "$THEME_PACKAGES_JSON" ".\"${chosen_package}\".icon.file")
    icon_name=$(read_json_value "$THEME_PACKAGES_JSON" ".\"${chosen_package}\".icon.name")
    icon_folders=$(read_json_value "$THEME_PACKAGES_JSON" ".\"${chosen_package}\".icon.folders")
    
    wp_light_file=$(read_json_value "$THEME_PACKAGES_JSON" ".\"${chosen_package}\".wallpaper.light")
    wp_light_url=$(read_json_value "$THEME_PACKAGES_JSON" ".\"${chosen_package}\".wallpaper.lightURL")
    wp_dark_file=$(read_json_value "$THEME_PACKAGES_JSON" ".\"${chosen_package}\".wallpaper.dark")
    wp_dark_url=$(read_json_value "$THEME_PACKAGES_JSON" ".\"${chosen_package}\".wallpaper.darkURL")
    
    log_info "This package includes:"
    log_info "  ├─> GTK:    $gtk_name"
    log_info "  ├─> Cursor: $cursor_name"
    log_info "  ├─> Icon:   $icon_name"
    log_info "  ╰─> Wallpapers: $wp_light_file, $wp_dark_file"
    echo ""
    
    log_header "Saving current theme to history"
    save_current_theme_to_history "gtk" "$de"
    save_current_theme_to_history "cursor" "$de"
    save_current_theme_to_history "icon" "$de"
    
    process_theme "gtk" "$gtk_id" "$de" "$gtk_file" "$gtk_name" "$gtk_folders"
    process_theme "cursor" "$cursor_id" "$de" "$cursor_file" "$cursor_name" "$cursor_folders"
    process_theme "icon" "$icon_id" "$de" "$icon_file" "$icon_name" "$icon_folders"
    
    process_wallpapers "$wp_light_file" "$wp_light_url" "$wp_dark_file" "$wp_dark_url" "$de"
    
    log_header "Complete!"
    log_success "Theme package '$chosen_package' has been applied!"
    log_info "Use '$0 -r' to restore previous theme if needed."
    
    return 0
}


# ==============================================================================
# MAIN ENTRY POINT
# ==============================================================================

main() {
    initialize_storage
    initialize_files_json
    initialize_history
    
    if ! install_all_packages; then
        log_error "Failed to install dependencies. Exiting."
        exit 1
    fi
    
    # Handle CLI arguments (if any)
    if [[ $# -gt 0 ]]; then
        if handle_cli_arguments "$@"; then
            exit 0
        fi
    fi
    
    # If no CLI arguments then run interactive mode
    interactive_mode
}


# ==============================================================================
# RUN THE SCRIPT
# ==============================================================================

main "$@"