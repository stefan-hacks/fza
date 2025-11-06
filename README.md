# fza - Fuzzy APT Package Manager

<div align="center">

![Version](https://img.shields.io/badge/version-2.3.1-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Platform](https://img.shields.io/badge/platform-Debian%20%7C%20Ubuntu-orange.svg)

**A beautiful, interactive terminal package manager powered by nala, fzf, and bat**

[Features](#features) • [Installation](#installation) • [Usage](#usage) • [Keybinds](#keybinds) • [Screenshots](#screenshots)

</div>

---

## 🌟 Features

- 🔍 **Fuzzy Search** - Lightning-fast package search with fuzzy finding
- 🎨 **Syntax Highlighting** - Beautiful syntax highlighting for package info with bat
- 🖼️ **Interactive Previews** - Real-time package information in preview panes
- ⚡ **Fast Operations** - Powered by nala for faster package management
- 🎯 **Multi-Select** - Select multiple packages at once with Tab
- 📊 **Statistics** - View detailed package statistics
- 📜 **History Tracking** - All operations logged for reference
- 🌐 **Mirror Management** - Benchmark and configure mirrors with nala fetch
- ⌨️ **Rich Keybinds** - Extensive keyboard shortcuts for efficient navigation
- 🎭 **Hidden Previews** - Preview windows hidden by default, toggle with `Ctrl+/`

---

## 📋 Requirements

- **Debian-based distribution** (Debian, Ubuntu, Linux Mint, Pop!_OS, etc.)
- **fzf** - Fuzzy finder
- **bat** or **batcat** - Syntax highlighter
- **nala** (optional, falls back to apt) - Fast package manager
- **sudo** privileges for package operations

---

## 🚀 Installation

### Quick Install (Recommended)

```bash
# Download the script
curl -o fza https://raw.githubusercontent.com/stefan-hacks/fza/main/fza.sh

# Make it executable
chmod +x fza

# Move to system path
sudo mv fza /usr/local/bin/

# Install dependencies
sudo apt update
sudo apt install -y nala fzf bat

# Optional: Install nala for better performance
echo "deb https://deb.volian.org/volian/ scar main" | sudo tee /etc/apt/sources.list.d/volian-archive-scar-unstable.list
wget -qO - https://deb.volian.org/volian/scar.key | sudo tee /etc/apt/trusted.gpg.d/volian-archive-scar-unstable.gpg > /dev/null
sudo apt update && sudo apt install -y nala
```

### Manual Installation

1. **Clone the repository:**
```bash
git clone https://github.com/stefan-hacks/fza.git
cd fza
```

2. **Install dependencies:**
```bash
sudo apt update
sudo apt install -y nala fzf bat
```

3. **Install nala (optional but recommended):**
```bash
echo "deb https://deb.volian.org/volian/ scar main" | sudo tee /etc/apt/sources.list.d/volian-archive-scar-unstable.list
wget -qO - https://deb.volian.org/volian/scar.key | sudo tee /etc/apt/trusted.gpg.d/volian-archive-scar-unstable.gpg > /dev/null
sudo apt update && sudo apt install -y nala
```

4. **Make executable and install:**
```bash
chmod +x fza.sh
sudo cp fza.sh /usr/local/bin/fza
```

5. **Verify installation:**
```bash
fza --help
```

---

## 💻 Usage

### Interactive Mode (Recommended)

Simply run fza with sudo to open the interactive menu:

```bash
sudo fza
```

Navigate through the beautiful menu to:
- Search and install packages
- Remove packages
- List installed packages
- Update package lists
- Upgrade all packages
- View package information
- And more!

### Command Line Mode

fza also supports direct command-line operations:

```bash
# Search for packages (interactive)
fza search

# Search for specific package
fza search firefox

# Install packages (interactive)
sudo fza install

# Install specific packages
sudo fza install firefox vlc

# Remove packages (interactive)
sudo fza remove

# Remove specific packages
sudo fza remove firefox

# Update package lists
sudo fza update

# Upgrade all packages
sudo fza upgrade

# List installed packages
fza list

# Show package information
fza info firefox

# View operation history
fza history

# Show package statistics
fza stats

# Benchmark and configure mirrors (nala only)
sudo fza fetch
```

### Command Aliases

Short forms are also supported:

```bash
sudo fza i          # install
sudo fza r          # remove
fza s               # search
sudo fza u          # update
sudo fza U          # upgrade
fza l               # list
fza h               # history
fza t               # stats
```

---

## ⌨️ Keybinds

### Main Navigation
| Key | Action |
|-----|--------|
| `↑`/`↓`, `j`/`k` | Navigate up/down |
| `Ctrl+p`/`n` | Navigate up/down (alternative) |
| `Ctrl+g` | Jump to top |
| `Alt+g` | Jump to bottom |
| `Page Up`/`Down` | Scroll page |

### Preview Window
| Key | Action |
|-----|--------|
| `Ctrl+/` | Toggle preview on/off |
| `Alt+p` | Toggle preview on/off |
| `Ctrl+u`/`d` | Scroll preview page up/down |
| `Ctrl+y`/`e` | Scroll preview line up/down |
| `Alt+↑`/`↓` | Scroll preview line up/down |
| `Shift+↑`/`↓` | Scroll preview page up/down |
| `Alt+w` | Toggle text wrapping |
| `Alt+1`/`2`/`3` | Resize preview right (40%/50%/60%) |
| `Alt+4`/`5` | Resize preview down (40%/50%) |
| `Alt+0` | Maximize preview (99%) |

### Selection
| Key | Action |
|-----|--------|
| `Tab` | Select/deselect current item |
| `Shift+Tab` | Select/deselect + move up |
| `Ctrl+Space` | Select + move down |
| `Alt+a` | Select all items |
| `Alt+d` | Deselect all items |
| `Alt+t` | Toggle all selections |

### Actions
| Key | Action |
|-----|--------|
| `Enter` | Confirm selection |
| `Esc` | Return to main menu |
| `q` | Quit fza completely |
| `Ctrl+c` | Quit fza completely |
| `?` | Show full keybinds help |
| `Alt+i` | View full package details with bat |
| `Alt+f` | View package files |
| `Ctrl+s` | Toggle sort |

---

## 🎨 Screenshots

### Main Menu
```
╔═══════════════════════════════════════════╗
║   FZA - Fuzzy APT Package Manager         ║
║   Powered by nala + fzf + bat             ║
╚═══════════════════════════════════════════╝

🔍  Search & Install Packages
🗑️  Remove Packages
📋  List Installed Packages
🔄  Update Package Lists
⬆️  Upgrade All Packages
ℹ️  Show Package Info
🧹  Autoremove Unused Packages
🔧  Fix Broken Dependencies
📊  Show Package Statistics
🚀  History & Rollback
🌐  Nala Fetch Mirrors
❓  Show Keybinds Help
❌  Exit
```

### Package Search with Preview
```
Search & Install Packages
Keybinds: Ctrl+/=preview Alt+1/2/3=resize Tab=select Esc=menu q=quit ?=help

> firefox
  firefox              Mozilla Firefox web browser
  firefox-esr          Mozilla Firefox ESR web browser
  firefox-locale-en    Firefox English language pack

Preview (Ctrl+/ to toggle):
╔══════════════════════════════════════════╗
║ Package: firefox                         ║
╚══════════════════════════════════════════╝

Package: firefox
Version: 120.0+build1-0ubuntu1
Architecture: amd64
Description: Mozilla Firefox web browser
 Firefox is a powerful, extensible web browser...
```

---

## 🔧 Configuration

fza stores its cache and history in `~/.cache/fza/`:
- `package_descriptions.cache` - Package list cache (refreshed every hour)
- `history` - Operation history log

To clear the cache:
```bash
rm -rf ~/.cache/fza/
```

---

## 🐛 Troubleshooting

### "Missing dependencies" error
Make sure all dependencies are installed:
```bash
sudo apt install fzf bat
```

### "This operation requires root privileges" error
Most package operations require sudo:
```bash
sudo fza
```

### bat command not found
On some systems, bat is installed as `batcat`. fza automatically detects this.

### Preview window not showing
Press `Ctrl+/` or `Alt+p` to toggle the preview window (hidden by default).

### Nala not available
fza automatically falls back to apt if nala is not installed. For better performance, install nala:
```bash
sudo apt install nala
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request
