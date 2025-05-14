# Terminal Enhancer 🚀

> Modern terminal setup made simple - syntax highlighting, smart history, fuzzy finding, and beautiful prompts that actually work.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/bash-4.0%2B-blue)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-linux-lightgrey)](https://www.linux.org/)

## ✨ Features

Terminal Enhancer provides a hassle-free setup of modern terminal tools:

### 🎨 Visual Enhancements
- **Syntax Highlighting** - Real-time highlighting with ble.sh
- **Smart Completions** - Context-aware suggestions as you type
- **Beautiful Prompt** - Clean, informative prompt with Starship

### 🚀 Productivity Tools
- **Enhanced History** - Searchable command history with Atuin
- **Fuzzy Finding** - Quick file/command search with fzf
- **Auto-configuration** - Everything works immediately after install

### 🛡️ Safe & Smart
- **Automatic Backups** - Your .bashrc is always backed up
- **Syntax Error Prevention** - Smart configuration to avoid breaks
- **Fix Tools Included** - Built-in utilities to repair issues

## 📦 What's Included

- **[ble.sh](https://github.com/akinomyoga/ble.sh)** - Bash Line Editor for IDE-like features
- **[Starship](https://starship.rs/)** - Fast, customizable cross-shell prompt
- **[Atuin](https://github.com/ellie/atuin)** - Magical shell history with sync
- **[fzf](https://github.com/junegunn/fzf)** - Command-line fuzzy finder

## 🚀 Quick Start

### Automated Installation (Recommended)

```bash
curl -sL https://raw.githubusercontent.com/yourusername/terminal-enhancer/main/terminal-enhancer.sh | bash
```

### Manual Installation

```bash
# Download the installer
wget https://raw.githubusercontent.com/sohaib1khan/TermForge/refs/heads/main/termforge.sh

# Make it executable
chmod +x termforge.sh

# Run full installation
./termforge.sh

# Or run in lite mode (skip Starship)
./termforge.sh --lite

# Fix existing .bashrc issues
./termforge.sh --fix
```

## 🔧 Installation Options

```bash
# Standard installation
./termforge.sh

# Lite mode - Skip Starship, use simple prompt
./termforge.sh --lite

# No sudo - For restricted environments
./termforge.sh --no-sudo

# Fix mode - Repair .bashrc syntax errors
./termforge.sh --fix

# Show help
./termforge.sh --help
```

## 🛡️ Safety Features

Terminal Enhancer is designed to be bulletproof:

- **Automatic Backups** - Creates timestamped .bashrc backups
- **Syntax Protection** - Properly structured configurations
- **Clean Markers** - Easy identification of added content
- **Fix Utilities** - Built-in tools to repair common issues
- **Non-destructive** - Preserves your existing configurations

## 🐳 Container & Server Usage

Works perfectly in Docker containers and remote servers:

```dockerfile
# In your Dockerfile
RUN apt update && apt install -y curl git wget
RUN curl -sL https://raw.githubusercontent.com/sohaib1khan/TermForge/refs/heads/main/termforge.sh | bash -s -- --no-sudo
```

Or in containers:
```bash
# Inside container
./termforge.sh --no-sudo
```

## 🔨 Included Utilities

After installation, you'll have these commands available:

- **`termforge.sh-fix`** - Fix .bashrc syntax errors
- **`termforge.sh-uninstall`** - Clean uninstall of all components

## 🎯 Usage Examples

### After Installation

Just run:
```bash
source ~/.bashrc
```

Or open a new terminal - everything works automatically!

### Using the Tools

**Enhanced History (Atuin)**
- `Ctrl+R` - Smart history search
- Type to filter through your command history
- Arrow keys to navigate results

**Fuzzy Finding (fzf)**
- `Ctrl+T` - Find files in current directory
- `Alt+C` - Navigate to directories
- `Ctrl+R` - Enhanced command history

**Syntax Highlighting (ble.sh)**
- Automatic as you type
- `Tab` - Smart completions
- Error highlighting in red

## 🛠️ Troubleshooting

### Common Issues

**Syntax errors in .bashrc?**
```bash
termforge.sh-fix
source ~/.bashrc
```

**Want to start fresh?**
```bash
termforge.sh-uninstall
./termforge.sh
```

**Need a minimal setup?**
```bash
./termforge.sh --lite
```

### Manual Fixes

If you encounter issues:

1. **Restore backup**:
   ```bash
   cp ~/.bashrc.backup.* ~/.bashrc
   source ~/.bashrc
   ```

2. **Remove all enhancements**:
   ```bash
   sed -i '/# === Terminal Enhancer Configuration ===/,/# === End Terminal Enhancer Configuration ===/d' ~/.bashrc
   ```

3. **Try lite mode**:
   ```bash
   ./termforge.sh --lite
   ```

## 📋 Prerequisites

- **OS**: Linux (Ubuntu, Debian, RHEL, CentOS, Arch)
- **Shell**: Bash 4.0+
- **Network**: Internet connection for downloads

Required packages (auto-installed):
- `curl`
- `git` 
- `wget`
- `gawk` (for ble.sh)
