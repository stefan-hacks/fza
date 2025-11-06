#!/usr/bin/env bash

# fza - Fuzzy APT Package Manager
# A beautiful interactive terminal package manager combining nala, fzf, and bat
# Version: 2.3.1

set -euo pipefail

# Colors
readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[1;33m'
readonly BLUE=$'\033[0;34m'
readonly MAGENTA=$'\033[0;35m'
readonly CYAN=$'\033[0;36m'
readonly WHITE=$'\033[1;37m'
readonly BOLD=$'\033[1m'
readonly DIM=$'\033[2m'
readonly RESET=$'\033[0m'

# Icons
readonly ICON_SEARCH="🔍"
readonly ICON_INSTALL="📦"
readonly ICON_REMOVE="🗑️"
readonly ICON_UPDATE="🔄"
readonly ICON_UPGRADE="⬆️"
readonly ICON_INFO="ℹ️"
readonly ICON_LIST="📋"
readonly ICON_CHECK="✓"
readonly ICON_CROSS="✗"
readonly ICON_WARNING="⚠️"
readonly ICON_BAT="🦇"

# Configuration
FZA_CACHE_DIR="${HOME}/.cache/fza"
FZA_HISTORY_FILE="${FZA_CACHE_DIR}/history"

mkdir -p "$FZA_CACHE_DIR"

# FZF configuration
export FZF_DEFAULT_OPTS="
    --height=99%
    --layout=reverse
    --border=rounded
    --margin=1
    --padding=1
    --info=inline
    --prompt='❯ '
    --pointer='▶'
    --marker='✓'
    --color=fg:#c0caf5,bg:#1a1b26,hl:#7aa2f7
    --color=fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff
    --color=info:#7aa2f7,prompt:#7dcfff,pointer:#f7768e
    --color=marker:#9ece6a,spinner:#9ece6a,header:#7aa2f7
    --color=border:#565f89
    --preview-window='right:50%:hidden:wrap:border-left'
    --bind='ctrl-/:toggle-preview'
    --bind='ctrl-u:preview-page-up'
    --bind='ctrl-d:preview-page-down'
    --bind='ctrl-b:preview-page-up'
    --bind='ctrl-f:preview-page-down'
    --bind='ctrl-y:preview-up'
    --bind='ctrl-e:preview-down'
    --bind='alt-up:preview-up'
    --bind='alt-down:preview-down'
    --bind='shift-up:preview-page-up'
    --bind='shift-down:preview-page-down'
    --bind='alt-w:toggle-preview-wrap'
    --bind='ctrl-r:toggle-all'
    --bind='ctrl-s:toggle-sort'
    --bind='ctrl-g:top'
    --bind='alt-g:last'
    --bind='alt-a:select-all'
    --bind='alt-d:deselect-all'
    --bind='alt-t:toggle-all'
    --bind='ctrl-p:up'
    --bind='ctrl-n:down'
    --bind='alt-p:toggle-preview'
    --bind='ctrl-space:toggle+down'
    --bind='ctrl-a:toggle-all'
    --bind='alt-1:change-preview-window(right,40%,border-left,wrap)'
    --bind='alt-2:change-preview-window(right,50%,border-left,wrap)'
    --bind='alt-3:change-preview-window(right,60%,border-left,wrap)'
    --bind='alt-4:change-preview-window(down,40%,border-top,wrap)'
    --bind='alt-5:change-preview-window(down,50%,border-top,wrap)'
    --bind='alt-0:change-preview-window(down,99%,border-top,wrap)'
"

log_action() {
  local action="$1"
  local packages="${2:-}"
  echo "$(date '+%Y-%m-%d %H:%M:%S') | $action | $packages" >>"$FZA_HISTORY_FILE"
}

check_dependencies() {
  local missing_deps=()

  if ! command -v fzf &>/dev/null; then
    missing_deps+=("fzf")
  fi

  if ! command -v nala &>/dev/null; then
    if ! command -v apt &>/dev/null; then
      missing_deps+=("nala/apt")
    fi
  fi

  if ! command -v bat &>/dev/null && ! command -v batcat &>/dev/null; then
    missing_deps+=("bat")
  fi

  if [ ${#missing_deps[@]} -ne 0 ]; then
    echo -e "${RED}${BOLD}Error: Missing dependencies${RESET}"
    echo -e "${YELLOW}Please install: ${missing_deps[*]}${RESET}"
    echo ""
    echo "Installation commands:"
    [[ " ${missing_deps[*]} " =~ " fzf " ]] && echo "  sudo apt install fzf"
    [[ " ${missing_deps[*]} " =~ " bat " ]] && echo "  sudo apt install bat"
    exit 1
  fi
}

get_bat_command() {
  if command -v bat &>/dev/null; then
    echo "bat"
  elif command -v batcat &>/dev/null; then
    echo "batcat"
  else
    echo "cat"
  fi
}

get_package_manager() {
  if command -v nala &>/dev/null; then
    echo "nala"
  else
    echo "apt"
  fi
}

check_root() {
  if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}${BOLD}Error: This operation requires root privileges${RESET}"
    echo -e "${YELLOW}Please run with sudo: sudo fza${RESET}"
    exit 1
  fi
}

show_banner() {
  clear
  echo -e "${CYAN}${BOLD}"
  cat <<"EOF"
    ╔═══════════════════════════════════════════╗
    ║   FZA - Fuzzy APT Package Manager         ║
    ║   Powered by nala + fzf + bat             ║
    ╚═══════════════════════════════════════════╝
EOF
  echo -e "${RESET}"
  local bat_cmd
  bat_cmd=$(get_bat_command)
  echo -e "${DIM}Version: 2.3.1 | Package Manager: $(get_package_manager) | Syntax Highlighter: ${bat_cmd}${RESET}"
  echo ""
}

show_keybinds() {
  local bat_cmd
  bat_cmd=$(get_bat_command)

  cat <<EOF

╔════════════════════════════════════════════════════════════════════════╗
║                         FZF KEYBINDS REFERENCE                         ║
╠════════════════════════════════════════════════════════════════════════╣
║ NAVIGATION (Main List)                                                 ║
║   ↑/↓, j/k             Navigate up/down                                ║
║   Ctrl+p/n             Navigate up/down (alternative)                  ║
║   Ctrl+g               Jump to top                                     ║
║   Alt+g                Jump to bottom                                  ║
║   Page Up/Down         Scroll page                                     ║
║                                                                         ║
║ PREVIEW WINDOW NAVIGATION                                              ║
║   Ctrl+u/d             Scroll preview up/down (page)                   ║
║   Ctrl+b/f             Scroll preview up/down (page, alternative)      ║
║   Ctrl+y/e             Scroll preview up/down (line)                   ║
║   Alt+↑/↓              Scroll preview up/down (line)                   ║
║   Shift+↑/↓            Scroll preview up/down (page)                   ║
║                                                                         ║
║ PREVIEW CONTROL                                                        ║
║   Ctrl+/               Toggle preview window on/off                    ║
║   Alt+p                Toggle preview window on/off                    ║
║   Alt+w                Toggle preview text wrapping                    ║
║   Alt+1/2/3            Resize preview right (40%/50%/60%)              ║
║   Alt+4/5              Resize preview down (40%/50%)                   ║
║   Alt+0                Maximize preview (99%)                          ║
║                                                                         ║
║ SELECTION                                                              ║
║   Tab                  Select/deselect current item                    ║
║   Shift+Tab            Select/deselect + move up                       ║
║   Ctrl+Space           Select + move down                              ║
║   Alt+a                Select all items                                ║
║   Alt+d                Deselect all items                              ║
║   Alt+t                Toggle all selections                           ║
║   Ctrl+r               Toggle all selections                           ║
║   Ctrl+a               Toggle all selections                           ║
║                                                                         ║
║ ACTIONS                                                                ║
║   Enter                Confirm selection                               ║
║   Esc                  Return to main menu                             ║
║   q                    Quit fza completely                             ║
║   Ctrl+c               Quit fza completely                             ║
║   Ctrl+s               Toggle sort                                     ║
║   Alt+i                View full details in pager (with ${bat_cmd})    ║
║   Alt+f                View package files (where applicable)           ║
║                                                                         ║
║ SEARCH                                                                 ║
║   Type                 Fuzzy search                                    ║
║   Ctrl+w               Delete word backward                            ║
║   Alt+Backspace        Delete word backward                            ║
╚════════════════════════════════════════════════════════════════════════╝

Press any key to continue...
EOF
  read -n 1 -s
}

get_package_descriptions() {
  local cache_file="${FZA_CACHE_DIR}/package_descriptions.cache"
  local cache_age=3600

  if [[ -f "$cache_file" ]] && [[ $(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0))) -lt $cache_age ]]; then
    cat "$cache_file"
    return
  fi

  echo -e "${DIM}Building package cache...${RESET}" >&2

  local pkg_manager
  pkg_manager=$(get_package_manager)

  if [[ "$pkg_manager" == "nala" ]]; then
    nala search --names . 2>/dev/null |
      grep -E '^[a-zA-Z0-9]' |
      awk '{
                name=$1
                $1=""
                desc=$0
                gsub(/^[ \t]+/, "", desc)
                printf "\033[1;32m%-35s\033[0m \033[2m%s\033[0m\n", name, desc
            }' | tee "$cache_file"
  else
    apt-cache search . 2>/dev/null | head -10000 |
      awk -F ' - ' '{
                name=$1
                desc=$2
                printf "\033[1;32m%-35s\033[0m \033[2m%s\033[0m\n", name, desc
            }' | tee "$cache_file"
  fi
}

get_package_info() {
  local pkg="$1"
  local pkg_manager
  pkg_manager=$(get_package_manager)
  local bat_cmd
  bat_cmd=$(get_bat_command)

  echo -e "\033[1;36m╔══════════════════════════════════════════════════════════════╗\033[0m"
  echo -e "\033[1;36m║ Package: \033[1;32m$pkg\033[1;36m\033[0m"
  echo -e "\033[1;36m╚══════════════════════════════════════════════════════════════╝\033[0m"
  echo ""

  if [[ "$pkg_manager" == "nala" ]]; then
    nala show "$pkg" 2>/dev/null | head -40 | $bat_cmd --language=ini --style=plain --color=always -p 2>/dev/null ||
      nala show "$pkg" 2>/dev/null | head -40
  else
    apt-cache show "$pkg" 2>/dev/null | head -40 | $bat_cmd --language=ini --style=plain --color=always -p 2>/dev/null ||
      apt-cache show "$pkg" 2>/dev/null | head -40
  fi

  echo ""
  echo -e "\033[1;36m════ Dependencies ════\033[0m"
  apt-cache depends "$pkg" 2>/dev/null | head -20 | $bat_cmd --language=sh --style=plain --color=always -p 2>/dev/null ||
    apt-cache depends "$pkg" 2>/dev/null | head -20
}

human_readable_bytes() {
  local bytes="$1"
  if ! [[ "$bytes" =~ ^[0-9]+$ ]]; then
    echo "$bytes"
    return
  fi
  local unit="B"
  local value="$bytes"
  if [ "$value" -ge 1099511627776 ]; then
    unit="TiB"
    value=$(awk -v b="$value" 'BEGIN{printf "%.2f", b/1099511627776}')
  elif [ "$value" -ge 1073741824 ]; then
    unit="GiB"
    value=$(awk -v b="$value" 'BEGIN{printf "%.2f", b/1073741824}')
  elif [ "$value" -ge 1048576 ]; then
    unit="MiB"
    value=$(awk -v b="$value" 'BEGIN{printf "%.2f", b/1048576}')
  elif [ "$value" -ge 1024 ]; then
    unit="KiB"
    value=$(awk -v b="$value" 'BEGIN{printf "%.2f", b/1024}')
  else
    unit="B"
    value="$value"
  fi
  echo "${value} ${unit}"
}

get_keybind_header() {
  echo -e "${CYAN}Keybinds:${RESET} ${DIM}Ctrl+/${RESET}=preview ${DIM}Alt+1/2/3${RESET}=resize ${DIM}Tab${RESET}=select ${DIM}Esc${RESET}=menu ${DIM}q${RESET}=quit ${DIM}?${RESET}=help"
}

show_main_menu() {
  local bat_cmd
  bat_cmd=$(get_bat_command)

  local sel
  mapfile -t sel < <(
    cat <<EOF | fzf --ansi --expect=q,esc,ctrl-c \
      --header="$(echo -e "${CYAN}${BOLD}FZA - Fuzzy APT Package Manager${RESET} | Press ${DIM}q${RESET} to quit | ${DIM}?${RESET} for keybinds")" \
      --preview='echo -e "${CYAN}${BOLD}FZA - Fuzzy APT Package Manager${RESET}\n"; echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"; echo -e "Select an operation to manage packages\n\n${GREEN}${BOLD}Available operations:${RESET}\n  ${ICON_SEARCH}  Search & Install - Find and install packages\n  ${ICON_REMOVE}  Remove Packages - Uninstall selected packages\n  ${ICON_LIST}   List Installed - Browse installed packages\n  ${ICON_UPDATE}  Update Lists - Refresh package database\n  ${ICON_UPGRADE}  Upgrade All - Update all installed packages\n  ${ICON_INFO}   Package Info - Detailed package information\n  🧹  Autoremove - Remove unused packages\n  🔧  Fix Broken - Fix dependency issues\n  📊  Statistics - Show package statistics\n  🚀  History - View operation history\n  🌐  Fetch Mirrors - Benchmark and configure mirrors\n\n${ICON_BAT} ${DIM}All previews use ${bat_cmd} for syntax highlighting${RESET}"' \
      --preview-window='down:50%:hidden:wrap:border-top' \
      --height=70% \
      --bind='?:execute('"$(declare -f show_keybinds)"'; show_keybinds)'
${ICON_SEARCH}  Search & Install Packages
${ICON_REMOVE}  Remove Packages
${ICON_LIST}   List Installed Packages
${ICON_UPDATE}  Update Package Lists
${ICON_UPGRADE}  Upgrade All Packages
${ICON_INFO}   Show Package Info
🧹  Autoremove Unused Packages
🔧  Fix Broken Dependencies
📊  Show Package Statistics
🚀  History & Rollback
🌐  Nala Fetch Mirrors
❓  Show Keybinds Help
❌  Exit
EOF
  )

  local key="${sel[0]:-}"
  local choice="${sel[1]:-}"

  if [ "$key" = "q" ] || [ "$key" = "ctrl-c" ]; then
    echo -e "\n${YELLOW}Exiting fza...${RESET}"
    exit 0
  fi

  if [ "$key" = "esc" ] && [ -z "$choice" ]; then
    show_main_menu
    return
  fi

  case "$choice" in
  "${ICON_SEARCH}"*) search_install_packages ;;
  "${ICON_REMOVE}"*) remove_packages ;;
  "${ICON_LIST}"*) list_installed_packages ;;
  "${ICON_UPDATE}"*) update_package_lists ;;
  "${ICON_UPGRADE}"*) upgrade_packages ;;
  "${ICON_INFO}"*) show_package_info ;;
  "🧹"*) autoremove_packages ;;
  "🔧"*) fix_broken_dependencies ;;
  "📊"*) show_statistics ;;
  "🚀"*) show_history ;;
  "🌐"*) run_nala_fetch ;;
  "❓"*)
    show_keybinds
    show_main_menu
    ;;
  "❌"*)
    echo -e "\n${YELLOW}Exiting fza...${RESET}"
    exit 0
    ;;
  *) show_main_menu ;;
  esac
}

search_install_packages() {
  show_banner
  echo -e "${CYAN}${BOLD}${ICON_SEARCH} Search for packages to install${RESET}"
  echo -e "$(get_keybind_header)"
  echo ""

  local sel
  mapfile -t sel < <(
    get_package_descriptions |
      fzf --ansi --expect=q,esc,ctrl-c \
        --multi \
        --header="$(echo -e "${YELLOW}${BOLD}Search & Install Packages${RESET}\n$(get_keybind_header)")" \
        --preview-window='right:50%:hidden:wrap:border-left:~3' \
        --preview='pkg=$(echo {} | awk "{print \$1}"); '"$(
          declare -f get_package_info
          declare -f get_package_manager
          declare -f get_bat_command
        )"'; get_package_info "$pkg"' \
        --bind='?:execute('"$(declare -f show_keybinds)"'; show_keybinds)' \
        --bind="ctrl-r:reload($(
          declare -f get_package_descriptions
          declare -f get_package_manager
        ); get_package_descriptions)" \
        --bind='alt-i:execute(sh -c '\''apt-cache show "$1" 2>/dev/null | { '"$(get_bat_command)"' --language=ini --style=plain --color=always 2>/dev/null || cat; } | less -R'\'' -- {1})'
  )

  local key="${sel[0]:-}"

  if [ "$key" = "q" ] || [ "$key" = "ctrl-c" ]; then
    echo -e "\n${YELLOW}Exiting fza...${RESET}"
    exit 0
  fi

  if [ "$key" = "esc" ]; then
    show_main_menu
    return
  fi

  local packages=""
  packages=$(printf '%s\n' "${sel[@]:1}" | awk '{print $1}')

  if [ -z "$packages" ]; then
    echo -e "${YELLOW}No packages selected${RESET}"
    read -p "Press ENTER to return to menu..."
    show_main_menu
    return
  fi

  check_root

  echo -e "\n${GREEN}${BOLD}Installing packages:${RESET}"
  echo "$packages" | tr '\n' ' ' | sed 's/ $//'
  echo -e "\n"

  local pkg_manager
  pkg_manager=$(get_package_manager)

  local packages_array
  IFS=$'\n' read -d '' -r -a packages_array <<<"$packages" || true

  if ! $pkg_manager install -y "${packages_array[@]}"; then
    echo -e "${RED}${ICON_CROSS} Installation failed!${RESET}"
    read -p "Press ENTER to return to menu..."
    show_main_menu
    return
  fi

  log_action "INSTALL" "$packages"

  echo -e "\n${GREEN}${ICON_CHECK} Installation complete!${RESET}"
  read -p "Press ENTER to return to menu..."
  show_main_menu
}

remove_packages() {
  show_banner
  echo -e "${CYAN}${BOLD}${ICON_REMOVE} Select packages to remove${RESET}"
  echo -e "$(get_keybind_header)"
  echo ""

  local sel
  mapfile -t sel < <(
    dpkg -l | grep '^ii' |
      awk '{
        name=$2
        version=$3
        $1=$2=$3=$4=$5=""
        desc=$0
        gsub(/^[ \t]+/, "", desc)
        printf "\033[1;31m%-35s\033[0m \033[1;33m%-15s\033[0m \033[2m%s\033[0m\n", name, version, desc
    }' |
      fzf --ansi --expect=q,esc,ctrl-c \
        --multi \
        --header="$(echo -e "${YELLOW}${BOLD}Remove Packages${RESET}\n$(get_keybind_header)")" \
        --preview-window='right:50%:hidden:wrap:border-left:~3' \
        --preview='pkg=$(echo {} | awk "{print \$1}"); 
           bat_cmd='"$(get_bat_command)"';
           echo -e "\033[1;36m╔══════════════════════════════════════════════════════════════╗\033[0m";
           echo -e "\033[1;36m║ Package: \033[1;31m$pkg\033[1;36m\033[0m";
           echo -e "\033[1;36m╚══════════════════════════════════════════════════════════════╝\033[0m";
           echo "";
           dpkg -s "$pkg" 2>/dev/null | head -30 | $bat_cmd --language=ini --style=plain --color=always -p 2>/dev/null || dpkg -s "$pkg" 2>/dev/null | head -30;
           echo "";
           echo -e "\033[1;36m════ Dependencies ════\033[0m";
           apt-cache depends "$pkg" 2>/dev/null | head -15 | $bat_cmd --language=sh --style=plain --color=always -p 2>/dev/null || apt-cache depends "$pkg" 2>/dev/null | head -15;
           ' \
        --bind='?:execute('"$(declare -f show_keybinds)"'; show_keybinds)' \
        --bind='alt-i:execute(sh -c '\''dpkg -s "$1" 2>/dev/null | { '"$(get_bat_command)"' --language=ini --style=plain --color=always 2>/dev/null || cat; } | less -R'\'' -- {1})' \
        --bind="alt-f:execute(dpkg -L {1} 2>/dev/null | less -R)"
  )

  local key="${sel[0]:-}"

  if [ "$key" = "q" ] || [ "$key" = "ctrl-c" ]; then
    echo -e "\n${YELLOW}Exiting fza...${RESET}"
    exit 0
  fi

  if [ "$key" = "esc" ]; then
    show_main_menu
    return
  fi

  local packages=""
  packages=$(printf '%s\n' "${sel[@]:1}" | awk '{print $1}')

  if [ -z "$packages" ]; then
    echo -e "${YELLOW}No packages selected${RESET}"
    read -p "Press ENTER to return to menu..."
    show_main_menu
    return
  fi

  check_root

  echo -e "\n${RED}${BOLD}Removing packages:${RESET}"
  echo "$packages" | tr '\n' ' ' | sed 's/ $//'
  echo -e "\n"

  echo -e "${YELLOW}${ICON_WARNING} The following packages will be removed:${RESET}"
  for pkg in $packages; do
    echo "  - $pkg"
  done
  echo ""

  read -p "Are you sure you want to remove these packages? (y/N): " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cancelled${RESET}"
    read -p "Press ENTER to return to menu..."
    show_main_menu
    return
  fi

  local pkg_manager
  pkg_manager=$(get_package_manager)

  local packages_array
  IFS=$'\n' read -d '' -r -a packages_array <<<"$packages" || true

  if ! $pkg_manager remove -y "${packages_array[@]}"; then
    echo -e "${RED}${ICON_CROSS} Removal failed!${RESET}"
    read -p "Press ENTER to return to menu..."
    show_main_menu
    return
  fi

  log_action "REMOVE" "$packages"

  echo -e "\n${GREEN}${ICON_CHECK} Removal complete!${RESET}"
  read -p "Press ENTER to return to menu..."
  show_main_menu
}

list_installed_packages() {
  show_banner
  echo -e "${CYAN}${BOLD}${ICON_LIST} Installed packages${RESET}"
  echo -e "$(get_keybind_header)"
  echo ""

  local sel
  mapfile -t sel < <(
    dpkg -l | grep '^ii' |
      awk '{
        name=$2
        version=$3
        $1=$2=$3=$4=$5=""
        desc=$0
        gsub(/^[ \t]+/, "", desc)
        printf "\033[1;32m%-35s\033[0m \033[1;33m%-15s\033[0m \033[2m%s\033[0m\n", name, version, desc
    }' |
      fzf --ansi --expect=q,esc,ctrl-c \
        --header="$(echo -e "${YELLOW}${BOLD}Installed Packages${RESET}\n$(get_keybind_header)")" \
        --preview-window='right:50%:hidden:wrap:border-left:~3' \
        --preview='pkg=$(echo {} | awk "{print \$1}");
                   bat_cmd='"$(get_bat_command)"';
                   echo -e "\033[1;36m╔══════════════════════════════════════════════════════════════╗\033[0m";
                   echo -e "\033[1;36m║ Package Details: \033[1;32m$pkg\033[1;36m\033[0m";
                   echo -e "\033[1;36m╚══════════════════════════════════════════════════════════════╝\033[0m";
                   echo "";
                   dpkg -s "$pkg" 2>/dev/null | head -35 | $bat_cmd --language=ini --style=plain --color=always -p 2>/dev/null || dpkg -s "$pkg" 2>/dev/null | head -35;
                   ' \
        --bind='?:execute('"$(declare -f show_keybinds)"'; show_keybinds)' \
        --bind='alt-i:execute(sh -c '\''dpkg -s "$1" 2>/dev/null | { '"$(get_bat_command)"' --language=ini --style=plain --color=always 2>/dev/null || cat; } | less -R'\'' -- {1})' \
        --bind="alt-f:execute(dpkg -L {1} 2>/dev/null | less -R)"
  )

  local key="${sel[0]:-}"

  if [ "$key" = "q" ] || [ "$key" = "ctrl-c" ]; then
    echo -e "\n${YELLOW}Exiting fza...${RESET}"
    exit 0
  fi

  if [ "$key" = "esc" ]; then
    show_main_menu
    return
  fi

  show_main_menu
}

update_package_lists() {
  check_root
  show_banner
  echo -e "${CYAN}${BOLD}${ICON_UPDATE} Updating package lists...${RESET}\n"

  local pkg_manager
  pkg_manager=$(get_package_manager)

  if ! $pkg_manager update; then
    echo -e "${RED}${ICON_CROSS} Update failed!${RESET}"
    read -p "Press ENTER to return to menu..."
    show_main_menu
    return
  fi

  rm -f "${FZA_CACHE_DIR}/package_descriptions.cache"

  log_action "UPDATE" "package lists"

  echo -e "\n${GREEN}${ICON_CHECK} Update complete!${RESET}"
  read -p "Press ENTER to return to menu..."
  show_main_menu
}

upgrade_packages() {
  check_root
  show_banner
  echo -e "${CYAN}${BOLD}${ICON_UPGRADE} Upgrading all packages...${RESET}\n"

  local pkg_manager
  pkg_manager=$(get_package_manager)

  if ! $pkg_manager full-upgrade -y; then
    echo -e "${RED}${ICON_CROSS} Upgrade failed!${RESET}"
    read -p "Press ENTER to return to menu..."
    show_main_menu
    return
  fi

  log_action "UPGRADE" "all packages"

  echo -e "\n${GREEN}${ICON_CHECK} Upgrade complete!${RESET}"
  read -p "Press ENTER to return to menu..."
  show_main_menu
}

show_package_info() {
  show_banner
  echo -e "${CYAN}${BOLD}${ICON_INFO} Package information${RESET}"
  echo -e "$(get_keybind_header)"
  echo ""

  local sel
  mapfile -t sel < <(
    get_package_descriptions |
      fzf --ansi --expect=q,esc,ctrl-c \
        --header="$(echo -e "${YELLOW}${BOLD}Package Information${RESET}\n$(get_keybind_header)")" \
        --preview-window='right:50%:hidden:wrap:border-left:~3' \
        --preview='pkg={1}; '"$(
          declare -f get_package_info
          declare -f get_package_manager
          declare -f get_bat_command
        )"'; get_package_info "$pkg"' \
        --bind='?:execute('"$(declare -f show_keybinds)"'; show_keybinds)' \
        --bind='alt-i:execute(sh -c '\''apt-cache show "$1" 2>/dev/null | { '"$(get_bat_command)"' --language=ini --style=plain --color=always 2>/dev/null || cat; } | less -R'\'' -- {1})'
  )

  local key="${sel[0]:-}"

  if [ "$key" = "q" ] || [ "$key" = "ctrl-c" ]; then
    echo -e "\n${YELLOW}Exiting fza...${RESET}"
    exit 0
  fi

  if [ "$key" = "esc" ]; then
    show_main_menu
    return
  fi

  local package=""
  package=$(printf '%s\n' "${sel[@]:1}" | awk '{print $1}' | head -n1)

  if [ -n "$package" ]; then
    clear
    echo -e "${CYAN}${BOLD}Package Information: $package${RESET}\n"
    get_package_info "$package"
    echo ""
    read -p "Press ENTER to return to menu..."
  fi

  show_main_menu
}

autoremove_packages() {
  check_root
  show_banner
  echo -e "${CYAN}${BOLD}🧹 Removing unused packages...${RESET}\n"

  local pkg_manager
  pkg_manager=$(get_package_manager)

  if ! $pkg_manager autoremove -y; then
    echo -e "${RED}${ICON_CROSS} Autoremove failed!${RESET}"
    read -p "Press ENTER to return to menu..."
    show_main_menu
    return
  fi

  log_action "AUTOREMOVE" "unused packages"

  echo -e "\n${GREEN}${ICON_CHECK} Autoremove complete!${RESET}"
  read -p "Press ENTER to return to menu..."
  show_main_menu
}

fix_broken_dependencies() {
  check_root
  show_banner
  echo -e "${CYAN}${BOLD}🔧 Fixing broken dependencies...${RESET}\n"

  local pkg_manager
  pkg_manager=$(get_package_manager)

  if ! $pkg_manager install --fix-broken -y; then
    echo -e "${RED}${ICON_CROSS} Fix failed!${RESET}"
    read -p "Press ENTER to return to menu..."
    show_main_menu
    return
  fi

  log_action "FIX_BROKEN" "dependencies"

  echo -e "\n${GREEN}${ICON_CHECK} Fix complete!${RESET}"
  read -p "Press ENTER to return to menu..."
  show_main_menu
}

run_nala_fetch() {
  show_banner
  if ! command -v nala >/dev/null 2>&1; then
    echo -e "${RED}${BOLD}nala is not installed. Install nala to use fetch mirrors.${RESET}"
    read -p "Press ENTER to return to menu..."
    show_main_menu
    return
  fi

  echo -e "${CYAN}${BOLD}🌐 Nala Fetch Mirrors${RESET}\n"
  echo -e "${DIM}This will benchmark mirrors and optionally update your sources list.${RESET}\n"
  read -p "Proceed to run 'nala fetch'? (y/N): " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cancelled${RESET}"
    read -p "Press ENTER to return to menu..."
    show_main_menu
    return
  fi

  if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Elevating privileges may be required to save sources changes.${RESET}\n"
    sudo nala fetch || true
  else
    nala fetch || true
  fi

  log_action "NALA_FETCH" "mirror benchmark"
  read -p "Press ENTER to return to menu..."
  show_main_menu
}

show_statistics() {
  show_banner
  echo -e "${CYAN}${BOLD}📊 Package Statistics${RESET}\n"

  local total_installed
  total_installed=$(dpkg -l 2>/dev/null | grep -c '^ii' || echo "0")
  local total_available
  total_available=$(apt-cache pkgnames 2>/dev/null | wc -l | tr -d ' ' || echo "0")
  local upgradable
  upgradable=$(apt list --upgradable 2>/dev/null | awk 'NR>1' | wc -l | tr -d ' ')
  local disk_usage_bytes
  disk_usage_bytes=$(dpkg-query -Wf '${Installed-Size}\n' 2>/dev/null | awk '{sum+=$1} END {printf "%d", sum*1024}' || echo "0")
  local disk_usage_hr
  disk_usage_hr=$(human_readable_bytes "$disk_usage_bytes")
  local cache_size
  cache_size=$(du -sh /var/cache/apt 2>/dev/null | cut -f1 || echo "0B")
  local bat_cmd
  bat_cmd=$(get_bat_command)
  local pkg_manager
  pkg_manager=$(get_package_manager)

  cat <<EOF

${GREEN}${BOLD}Installed Packages:${RESET}    ${WHITE}${total_installed}${RESET}
${CYAN}${BOLD}Available Packages:${RESET}    ${WHITE}${total_available}${RESET}
${YELLOW}${BOLD}Upgradable Packages:${RESET}  ${WHITE}${upgradable}${RESET}
${MAGENTA}${BOLD}Disk Usage:${RESET}           ${WHITE}${disk_usage_hr}${RESET}
${BLUE}${BOLD}APT Cache Size:${RESET}       ${WHITE}${cache_size}${RESET}
${GREEN}${BOLD}Package Manager:${RESET}      ${WHITE}${pkg_manager}${RESET}
${GREEN}${BOLD}BAT Command:${RESET}          ${WHITE}${bat_cmd}${RESET}

EOF

  if [[ "$upgradable" =~ ^[0-9]+$ ]] && [ "$upgradable" -gt 0 ]; then
    echo -e "${YELLOW}${ICON_WARNING} There are $upgradable packages that can be upgraded.${RESET}"
    echo -e "${YELLOW}Run 'Upgrade All Packages' to update them.${RESET}"
    echo ""
  fi

  read -p "Press ENTER to return to menu..."
  show_main_menu
}

show_history() {
  show_banner
  echo -e "${CYAN}${BOLD}🚀 FZA History${RESET}"
  echo -e "$(get_keybind_header)"
  echo ""

  if [ -f "$FZA_HISTORY_FILE" ] && [ -s "$FZA_HISTORY_FILE" ]; then
    local sel
    mapfile -t sel < <(
      tac "$FZA_HISTORY_FILE" | head -100 |
        fzf --ansi --expect=q,esc,ctrl-c \
          --header="$(echo -e "${YELLOW}${BOLD}FZA History (last 100 entries)${RESET}\n$(get_keybind_header)")" \
          --preview-window='down:40%:hidden:wrap:border-top:~3' \
          --preview='echo -e "\033[1;36m╔══════════════════════════════════════════════════════════════╗\033[0m";
                   echo -e "\033[1;36m║ History Entry Details\033[0m";
                   echo -e "\033[1;36m╚══════════════════════════════════════════════════════════════╝\033[0m";
                   echo "";
                   echo {};
                   echo "";
                   echo -e "\033[2mThis shows the operation, timestamp, and affected packages\033[0m"' \
          --bind='?:execute('"$(declare -f show_keybinds)"'; show_keybinds)'
    )
    local key="${sel[0]:-}"

    if [ "$key" = "q" ] || [ "$key" = "ctrl-c" ]; then
      echo -e "\n${YELLOW}Exiting fza...${RESET}"
      exit 0
    fi

    if [ "$key" = "esc" ]; then
      show_main_menu
      return
    fi
  else
    echo -e "${YELLOW}No FZA history found${RESET}"
    echo ""
    read -p "Press ENTER to return to menu..."
  fi

  show_main_menu
}

main() {
  check_dependencies

  if [ $# -gt 0 ]; then
    case "$1" in
    install | i | --install | -i)
      check_root
      shift
      if [ $# -eq 0 ]; then
        search_install_packages
      else
        local pkg_manager
        pkg_manager=$(get_package_manager)
        $pkg_manager install "$@"
        log_action "INSTALL" "$*"
      fi
      ;;
    remove | r | --remove | -r)
      check_root
      shift
      if [ $# -eq 0 ]; then
        remove_packages
      else
        local pkg_manager
        pkg_manager=$(get_package_manager)
        $pkg_manager remove "$@"
        log_action "REMOVE" "$*"
      fi
      ;;
    search | s | --search | -s)
      shift
      if [ $# -eq 0 ]; then
        search_install_packages
      else
        local pkg_manager
        pkg_manager=$(get_package_manager)
        $pkg_manager search "$@"
      fi
      ;;
    update | u | --update | -u)
      update_package_lists
      ;;
    upgrade | U | --upgrade | -U)
      upgrade_packages
      ;;
    list | l | --list | -l)
      list_installed_packages
      ;;
    info | show | --info | -I)
      shift
      show_package_info
      ;;
    history | h | --history | -H)
      show_history
      ;;
    stats | stat | --stats | -t)
      show_statistics
      ;;
    fetch | --fetch | -f)
      run_nala_fetch
      ;;
    --help | -h)
      local bat_cmd
      bat_cmd=$(get_bat_command)
      cat <<EOF
fza - Fuzzy APT Package Manager
Version: 2.3.1

Usage: fza [command|flag] [arguments]

Commands:
  install, i          Install package(s) - interactive if no package specified
  remove, r           Remove package(s) - interactive if no package specified
  search, s           Search for packages
  update, u           Update package lists
  upgrade, U          Upgrade all packages
  list, l             List installed packages
  info, show          Show package information
  history, h          Show installation history
  stats, stat         Show package statistics
  fetch               Nala fetch (benchmark & configure mirrors)
  
Flags (dash forms):
  -i, --install       Install
  -r, --remove        Remove
  -s, --search        Search
  -u, --update        Update lists
  -U, --upgrade       Upgrade all
  -l, --list          List installed
  -I, --info          Info
  -H, --history       History
  -t, --stats         Stats
  -f, --fetch         Nala fetch mirrors
  -h, --help          Help

Run without arguments for the full-screen interactive menu.

Features:
  - Fuzzy finding with fzf
  - Fast package management with nala/apt
  - Beautiful syntax highlighting with ${bat_cmd}
  - Colorful interactive interface
  - Package previews and information with syntax highlighting
  - Multi-select with keyboard shortcuts
  - Operation history logging
  - Nala fetch mirrors benchmarking and configuration

Keybinds in interactive mode:
  ?          Show all keybinds reference
  Tab        Select package
  Ctrl+Space Select and move down
  Ctrl+/     Toggle preview window on/off
  Alt+p      Toggle preview window on/off
  Alt+1/2/3  Resize preview (40%/50%/60%)
  Alt+i      View full package info with ${bat_cmd}
  Alt+f      Browse package files
  Esc        Return to main menu (in submenus)
  q          Quit fza completely
  Ctrl+c     Quit fza completely

Navigation:
  ↑/↓, j/k   Navigate list
  Ctrl+u/d   Scroll preview page up/down
  Ctrl+y/e   Scroll preview line up/down
  Ctrl+g     Jump to top
  Alt+g      Jump to bottom

EOF
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown command: $1${RESET}"
      echo "Run 'fza --help' for usage information"
      exit 1
      ;;
    esac
  else
    show_banner
    show_main_menu
  fi
}

trap 'echo -e "\n${YELLOW}Exiting fza...${RESET}"; exit 0' INT

main "$@"
