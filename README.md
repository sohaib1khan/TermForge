# Termforge 🔨

> Transform your terminal into a modern powerhouse with syntax highlighting, intelligent autocompletion, and a beautiful prompt.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/bash-5.0%2B-blue)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-linux-lightgrey)](https://www.linux.org/)


## ✨ Features

Termforge combines the best modern terminal tools into a single, cohesive experience:

### 🎨 Visual Enhancements
- **Syntax Highlighting** - Real-time syntax highlighting as you type
- **Auto-suggestions** - Fish-like autosuggestions from your command history
- **Beautiful Prompt** - Informative and customizable with git, kubernetes, docker status

### 🚀 Productivity Tools
- **Smart History** - Enhanced history search with context and timestamps
- **Fuzzy Finding** - Quick file and command discovery with fzf
- **IDE-like Completion** - Intelligent tab completion with descriptions

### 🔧 DevOps Focused
- **Kubernetes Integration** - Shows current context and namespace
- **Docker Status** - Displays active Docker context
- **Git Awareness** - Branch, status, and repository information
- **Tool Aliases** - Quick shortcuts for kubectl, docker, terraform

## 📦 What's Included

- **[ble.sh](https://github.com/akinomyoga/ble.sh)** - Bash Line Editor with IDE features
- **[Starship](https://starship.rs/)** - Fast, customizable, minimal prompt
- **[Atuin](https://github.com/ellie/atuin)** - Magical shell history
- **[fzf](https://github.com/junegunn/fzf)** - Command-line fuzzy finder

## 🚀 Quick Start

### One-Line Installation

```bash
curl -sL https://raw.githubusercontent.com/sohaib1khan/TermForge/refs/heads/main/termforge.sh | bash
```

### Manual Installation

```bash
# Download the installer
wget https://raw.githubusercontent.com/sohaib1khan/TermForge/refs/heads/main/termforge.sh

# Make it executable
chmod +x termforge.sh

# Run the installer
./termforge.sh

# Run without sudo (for containers or restricted environments)
./termforge.sh --no-sudo

# Container mode (no sudo, no automatic dependencies)
./termforge.sh --container

# Skip alias installation
./termforge.sh --no-aliases

# Minimal installation
./termforge.sh --minimal
```

## 🐳 Container Usage

Termforge works great in Docker containers and other containerized environments:

```dockerfile
# In your Dockerfile
RUN apt update && apt install -y curl git wget gawk
RUN curl -sL https://raw.githubusercontent.com/sohaib1khan/TermForge/refs/heads/main/termforge.sh | bash -s -- --container
```

Or run manually in a container:
```bash
# Inside container
./termforge.sh --container
# or
./termforge.sh --no-sudo --no-deps
```

## 🛡️ Safe Installation

Termforge is designed to be non-destructive:

- **Preserves existing aliases** - Only adds aliases that don't already exist
- **Backs up .bashrc** - Creates timestamped backup before modifications
- **Checks for existing installations** - Won't duplicate configurations
- **Optional components** - Use `--skip-aliases` to skip alias installation
- **No sudo mode** - Use `--no-sudo` for restricted environments
- **Container mode** - Use `--container` for Docker/Podman environments

## 📋 Prerequisites

- **OS**: Linux (Ubuntu, Debian, RHEL, CentOS, Arch, etc.)
- **Shell**: Bash 4.0+
- **Permissions**: Ability to install packages (sudo access)

The installer will automatically install required dependencies:
- `curl`
- `git`
- `gawk`
- `build-essential`

## 🔧 Configuration

### Starship Prompt

The default configuration is optimized for DevOps workflows. Customize it by editing `~/.config/starship.toml`:

```toml
# Example: Minimal prompt
[character]
success_symbol = "[➜](bold green)"
error_symbol = "[✗](bold red)"

[kubernetes]
disabled = false
format = '[⎈ $context](bold cyan) '
```

### Bash Aliases

Termforge includes helpful aliases for DevOps tools. **Existing aliases are preserved** - Termforge only adds aliases that don't already exist:

```bash
k     # kubectl (only if not already defined)
d     # docker (only if not already defined)
dc    # docker-compose (only if not already defined)
tf    # terraform (only if not already defined)
g     # git (only if not already defined)
ll    # ls -alh (only if not already defined)
```

Add your own aliases to `~/.bashrc`:

```bash
# Custom aliases
alias kgp='kubectl get pods'
alias dps='docker ps'
alias gst='git status'
```

### Updating Tools

Keep all tools up-to-date with the included update script:

```bash
update-termforge
```

## 🎯 Usage Examples

### Smart History Search (Atuin)
```bash
# Search through command history
ctrl+r

# Search for specific commands
ctrl+r docker

# View command statistics
atuin stats
```

### Fuzzy Finding (fzf)
```bash
# Find files
ctrl+t

# Change directory
alt+c

# Search command history
ctrl+r
```

### IDE-like Features (ble.sh)
- **Tab**: Intelligent completion with descriptions
- **Ctrl+Space**: Show all completions
- **Alt+/**: Dynamic abbreviation expansion
- **Syntax highlighting**: Automatic as you type

## 🛠️ Troubleshooting

### Installation Issues

**Problem**: `gawk not found`
```bash
sudo apt install gawk  # Debian/Ubuntu
sudo yum install gawk  # RHEL/CentOS
```

**Problem**: Prompt not changing
```bash
source ~/.bashrc
# or open a new terminal
```

### Performance Issues

If you experience slowness:

1. Disable unused features in `~/.config/starship.toml`
2. Reduce ble.sh features in `~/.blerc`
3. Check `~/.bashrc` for duplicate sourcing

