#!/bin/bash

# Terminal Enhancer - All-in-One Automated Installation
# Installs and configures: ble.sh, Starship, Atuin, fzf
# Everything works immediately after installation

TOOL_NAME="Terminal Enhancer"
VERSION="3.0.0"

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Parse command line arguments
USE_SUDO=true
LITE_MODE=false

for arg in "$@"; do
    case $arg in
        --no-sudo)
            USE_SUDO=false
            shift
            ;;
        --lite)
            LITE_MODE=true
            shift
            ;;
        --help|-h)
            echo "$TOOL_NAME v$VERSION"
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --no-sudo    Run without sudo"
            echo "  --lite       Skip Starship (use basic prompt)"
            echo "  --help, -h   Show this help message"
            exit 0
            ;;
    esac
done

print_status "Starting $TOOL_NAME installation..."

# Detect if running in a container
if [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
    print_warning "Container environment detected"
    USE_SUDO=false
fi

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    USE_SUDO=false
fi

# Create necessary directories
mkdir -p ~/.local/bin
mkdir -p ~/.config
mkdir -p ~/.cache

# Add local bin to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install dependencies
install_deps() {
    local deps="$1"
    if [ "$USE_SUDO" = true ]; then
        if command_exists apt; then
            sudo apt update
            sudo apt install -y $deps
        elif command_exists yum; then
            sudo yum install -y $deps
        elif command_exists pacman; then
            sudo pacman -Sy --noconfirm $deps
        fi
    else
        print_warning "Cannot install dependencies without sudo"
        print_warning "Please install manually: $deps"
    fi
}

# Check and install basic dependencies
print_status "Checking dependencies..."
MISSING_DEPS=""
for cmd in curl git wget; do
    if ! command_exists $cmd; then
        MISSING_DEPS="$MISSING_DEPS $cmd"
    fi
done

if [ -n "$MISSING_DEPS" ]; then
    print_status "Installing missing dependencies:$MISSING_DEPS"
    install_deps "$MISSING_DEPS"
fi

# Backup .bashrc
BACKUP_FILE=~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)
cp ~/.bashrc "$BACKUP_FILE"
print_success "Backup created: $BACKUP_FILE"

# Create a marker for our configuration
MARKER_START="# === Terminal Enhancer Configuration ==="
MARKER_END="# === End Terminal Enhancer Configuration ==="

# Remove any existing configuration
sed -i "/$MARKER_START/,/$MARKER_END/d" ~/.bashrc

# Start building our configuration
CONFIG_CONTENT="

$MARKER_START
# Added by Terminal Enhancer v$VERSION on $(date)

# Add local bin to PATH
export PATH=\"\$HOME/.local/bin:\$PATH\"
"

# Install fzf
print_status "Installing fzf..."
if [ ! -d ~/.fzf ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all --no-update-rc --no-fish --no-zsh
    print_success "fzf installed!"
fi
CONFIG_CONTENT+="
# fzf - Fuzzy finder
[ -f ~/.fzf.bash ] && source ~/.fzf.bash"

# Install ble.sh
print_status "Installing ble.sh..."
if ! command_exists gawk; then
    print_warning "gawk not found - installing..."
    install_deps "gawk"
fi

if [ ! -d ~/.local/share/blesh ]; then
    mkdir -p ~/.local/share/blesh
    cd ~/.local/share/blesh
    wget -q https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz
    tar xf ble-nightly.tar.xz --strip-components=1
    rm ble-nightly.tar.xz
    cd ~
    print_success "ble.sh installed!"
fi
CONFIG_CONTENT+="

# ble.sh - Bash Line Editor (syntax highlighting & autocompletion)
[[ \$- == *i* ]] && source ~/.local/share/blesh/ble.sh --noattach
[[ \${BLE_VERSION-} ]] && ble-attach"

# Install Atuin
print_status "Installing Atuin..."
if ! command_exists atuin; then
    bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
    # Initialize Atuin database
    ~/.local/bin/atuin init bash --disable-up-arrow > /dev/null 2>&1 || true
    print_success "Atuin installed!"
fi
CONFIG_CONTENT+="

# Atuin - Enhanced shell history
[[ -f ~/.local/bin/atuin ]] && eval \"\$(~/.local/bin/atuin init bash)\""

# Install Starship (unless in lite mode)
if [ "$LITE_MODE" = false ]; then
    print_status "Installing Starship..."
    if ! command_exists starship; then
        curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir ~/.local/bin -y
        print_success "Starship installed!"
    fi
    
    # Create a working Starship config
    cat > ~/.config/starship.toml << 'EOF'
# Starship prompt configuration
format = """
$username\
$hostname\
$directory\
$git_branch\
$git_status\
$python\
$nodejs\
$rust\
$golang\
$docker_context\
$kubernetes\
$cmd_duration\
$line_break\
$character"""

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[✗](bold red)"

[directory]
truncation_length = 3
truncate_to_repo = false

[git_branch]
symbol = "🌱 "
truncation_length = 20

[git_status]
conflicted = "🏳"
ahead = "🏎💨"
behind = "😰"
diverged = "😵"
untracked = "🤷"
stashed = "📦"
modified = "📝"
staged = '[++\($count\)](green)'
renamed = "👅"
deleted = "🗑"

[kubernetes]
format = 'on [⛵ $context \($namespace\)](dimmed green) '
disabled = false

[docker_context]
format = "via [🐋 $context](blue bold)"

[python]
symbol = "🐍 "
pyenv_version_name = true

[nodejs]
symbol = "⬢ "

[package]
symbol = "📦 "
EOF

    CONFIG_CONTENT+="

# Starship prompt
command -v starship &> /dev/null && eval \"\$(starship init bash)\""
else
    # Use a simple enhanced prompt in lite mode
    CONFIG_CONTENT+="

# Enhanced prompt (lite mode)
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '"
fi

# Add some useful aliases
CONFIG_CONTENT+="

# Useful aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Better defaults
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend

$MARKER_END"

# Append our configuration to .bashrc
echo "$CONFIG_CONTENT" >> ~/.bashrc

# Create uninstall script
cat > ~/.local/bin/terminal-enhancer-uninstall << 'EOF'
#!/bin/bash
echo "Uninstalling Terminal Enhancer..."

# Remove configuration from .bashrc
sed -i '/# === Terminal Enhancer Configuration ===/,/# === End Terminal Enhancer Configuration ===/d' ~/.bashrc

# Remove installed components
rm -rf ~/.local/share/blesh
rm -f ~/.local/bin/starship
rm -f ~/.local/bin/atuin
rm -rf ~/.fzf
rm -f ~/.config/starship.toml
rm -f ~/.local/bin/terminal-enhancer-uninstall

echo "Terminal Enhancer uninstalled."
echo "Restart your terminal to complete the process."
EOF
chmod +x ~/.local/bin/terminal-enhancer-uninstall

# Create update script
cat > ~/.local/bin/terminal-enhancer-update << 'EOF'
#!/bin/bash
echo "Updating Terminal Enhancer components..."

# Update fzf
cd ~/.fzf && git pull && ./install --all

# Update ble.sh
cd ~/.local/share/blesh
wget -q https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz
tar xf ble-nightly.tar.xz --strip-components=1
rm ble-nightly.tar.xz

# Update Starship
curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir ~/.local/bin -y

# Update Atuin
bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)

echo "All components updated!"
EOF
chmod +x ~/.local/bin/terminal-enhancer-update

# Final summary
echo
echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ${GREEN}$TOOL_NAME v$VERSION${BLUE}     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
echo
print_success "Installation completed successfully!"
echo
print_status "Installed components:"
echo "  ✓ fzf        - Fuzzy file finder (Ctrl+R for history)"
echo "  ✓ ble.sh     - Syntax highlighting & autocompletion"
echo "  ✓ Atuin      - Smart command history"
[ "$LITE_MODE" = false ] && echo "  ✓ Starship   - Beautiful prompt with git info"
echo
print_status "Useful commands:"
echo "  • terminal-enhancer-update    - Update all components"
echo "  • terminal-enhancer-uninstall - Remove everything"
echo
print_success "Everything is configured and ready to use!"
print_status "Just run: ${GREEN}source ~/.bashrc${NC}"
echo
echo -e "${YELLOW}Or open a new terminal to see the changes.${NC}"
echo
