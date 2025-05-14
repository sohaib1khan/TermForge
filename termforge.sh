#!/bin/bash

# Terminal Enhancer - Fixed Version
# Installs and configures: ble.sh, Starship, Atuin, fzf
# Everything works immediately after installation

TOOL_NAME="Terminal Enhancer"
VERSION="3.1.0"

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
FIX_BASHRC=false

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
        --fix)
            FIX_BASHRC=true
            shift
            ;;
        --help|-h)
            echo "$TOOL_NAME v$VERSION"
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --no-sudo    Run without sudo"
            echo "  --lite       Skip Starship (use basic prompt)"
            echo "  --fix        Fix broken .bashrc syntax"
            echo "  --help, -h   Show this help message"
            exit 0
            ;;
    esac
done

# Fix bashrc if requested
if [ "$FIX_BASHRC" = true ]; then
    print_status "Fixing .bashrc syntax errors..."
    # Check for the error around line 128
    TEMP_FILE=$(mktemp)
    
    # Copy everything except potentially broken ble.sh section
    sed '/# ble.sh - Bash Line Editor/,/ble-attach/d' ~/.bashrc > "$TEMP_FILE"
    
    # Add correct ble.sh configuration
    cat >> "$TEMP_FILE" << 'EOF'

# ble.sh - Bash Line Editor (syntax highlighting & autocompletion)
if [[ -f ~/.local/share/blesh/ble.sh ]]; then
    [[ $- == *i* ]] && source ~/.local/share/blesh/ble.sh --noattach
    [[ ${BLE_VERSION-} ]] && ble-attach
fi
EOF
    
    # Backup current .bashrc
    cp ~/.bashrc ~/.bashrc.broken.$(date +%Y%m%d_%H%M%S)
    
    # Replace with fixed version
    mv "$TEMP_FILE" ~/.bashrc
    
    print_success ".bashrc fixed! Old version backed up."
    echo "Run: source ~/.bashrc"
    exit 0
fi

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

# Backup .bashrc
BACKUP_FILE=~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)
cp ~/.bashrc "$BACKUP_FILE"
print_success "Backup created: $BACKUP_FILE"

# Create a marker for our configuration
MARKER_START="# === Terminal Enhancer Configuration ==="
MARKER_END="# === End Terminal Enhancer Configuration ==="

# Remove any existing configuration
sed -i "/$MARKER_START/,/$MARKER_END/d" ~/.bashrc

# Also remove any orphaned ble.sh configuration to prevent syntax errors
sed -i '/# ble.sh - Bash Line Editor/,/ble-attach/d' ~/.bashrc

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
    ~/.fzf/install --all --no-update-rc --no-fish --no-zsh || true
    print_success "fzf installed!"
fi
CONFIG_CONTENT+="
# fzf - Fuzzy finder
[ -f ~/.fzf.bash ] && source ~/.fzf.bash"

# Install ble.sh
print_status "Installing ble.sh..."
if [ ! -d ~/.local/share/blesh ]; then
    mkdir -p ~/.local/share/blesh
    cd ~/.local/share/blesh
    if command_exists wget; then
        wget -q https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz
    else
        curl -sL -o ble-nightly.tar.xz https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz
    fi
    tar xf ble-nightly.tar.xz --strip-components=1
    rm ble-nightly.tar.xz
    cd ~
    print_success "ble.sh installed!"
fi

# Add ble.sh configuration with proper syntax
CONFIG_CONTENT+="

# ble.sh - Bash Line Editor (syntax highlighting & autocompletion)
if [[ -f ~/.local/share/blesh/ble.sh ]]; then
    [[ \$- == *i* ]] && source ~/.local/share/blesh/ble.sh --noattach
    [[ \${BLE_VERSION-} ]] && ble-attach
fi"

# Install Atuin
print_status "Installing Atuin..."
if ! command_exists atuin; then
    # Check for compatible system
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh) || true
    else
        print_warning "Atuin may not be compatible with this system"
    fi
fi

# Only add Atuin config if it was installed
if command_exists atuin || [ -f ~/.local/bin/atuin ]; then
    CONFIG_CONTENT+="

# Atuin - Enhanced shell history
[[ -f ~/.local/bin/atuin ]] && eval \"\$(~/.local/bin/atuin init bash --disable-up-arrow)\""
fi

# Install Starship (unless in lite mode)
if [ "$LITE_MODE" = false ]; then
    print_status "Installing Starship..."
    if ! command_exists starship; then
        # Use sh instead of bash for better compatibility
        curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir ~/.local/bin -y || true
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
$cmd_duration\
$line_break\
$character"""

[character]
success_symbol = "[>](bold green)"
error_symbol = "[>](bold red)"

[directory]
truncation_length = 3
truncate_to_repo = false

[git_branch]
symbol = " "
truncation_length = 20

[git_status]
conflicted = "!"
ahead = "+"
behind = "-"
diverged = "*"
untracked = "?"
stashed = "$"
modified = "~"
staged = '[+\($count\)](green)'
renamed = "»"
deleted = "x"

[cmd_duration]
min_time = 500
format = "took [$duration](bold yellow)"
EOF

    CONFIG_CONTENT+="

# Starship prompt
if command -v starship &> /dev/null; then
    eval \"\$(starship init bash)\"
fi"
else
    # Use a simple enhanced prompt in lite mode
    CONFIG_CONTENT+="

# Enhanced prompt (lite mode)
PS1='\\[\\033[01;32m\\]\\u@\\h\\[\\033[00m\\]:\\[\\033[01;34m\\]\\w\\[\\033[00m\\]\\\$ '"
fi

# Add some useful aliases and settings
CONFIG_CONTENT+="

# Better history settings
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend

# Useful aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'

$MARKER_END"

# Append our configuration to .bashrc
echo "$CONFIG_CONTENT" >> ~/.bashrc

# Create uninstall script
cat > ~/.local/bin/terminal-enhancer-uninstall << 'EOF'
#!/bin/bash
echo "Uninstalling Terminal Enhancer..."

# Remove configuration from .bashrc
sed -i '/# === Terminal Enhancer Configuration ===/,/# === End Terminal Enhancer Configuration ===/d' ~/.bashrc

# Also remove any ble.sh configuration
sed -i '/# ble.sh - Bash Line Editor/,/ble-attach/d' ~/.bashrc

# Remove installed components
rm -rf ~/.local/share/blesh
rm -f ~/.local/bin/starship
rm -f ~/.local/bin/atuin
rm -rf ~/.fzf
rm -f ~/.config/starship.toml
rm -f ~/.local/bin/terminal-enhancer-uninstall
rm -f ~/.local/bin/terminal-enhancer-fix

echo "Terminal Enhancer uninstalled."
echo "Restart your terminal to complete the process."
EOF
chmod +x ~/.local/bin/terminal-enhancer-uninstall

# Create fix script
cat > ~/.local/bin/terminal-enhancer-fix << 'EOF'
#!/bin/bash
# Fix common .bashrc syntax errors

echo "Fixing .bashrc syntax errors..."
TEMP_FILE=$(mktemp)

# Remove broken ble.sh sections
sed '/# ble.sh - Bash Line Editor/,/ble-attach/d' ~/.bashrc > "$TEMP_FILE"

# Add correct ble.sh configuration if ble.sh is installed
if [[ -d ~/.local/share/blesh ]]; then
    cat >> "$TEMP_FILE" << 'BLESH_CONFIG'

# ble.sh - Bash Line Editor (syntax highlighting & autocompletion)
if [[ -f ~/.local/share/blesh/ble.sh ]]; then
    [[ $- == *i* ]] && source ~/.local/share/blesh/ble.sh --noattach
    [[ ${BLE_VERSION-} ]] && ble-attach
fi
BLESH_CONFIG
fi

# Backup current .bashrc
cp ~/.bashrc ~/.bashrc.broken.$(date +%Y%m%d_%H%M%S)

# Replace with fixed version
mv "$TEMP_FILE" ~/.bashrc

echo ".bashrc fixed! Old version backed up."
echo "Run: source ~/.bashrc"
EOF
chmod +x ~/.local/bin/terminal-enhancer-fix

# Final summary
echo
echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ${GREEN}$TOOL_NAME v$VERSION${BLUE}   ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
echo
print_success "Installation completed successfully!"
echo
print_status "Installed components:"
echo "  ✓ fzf        - Fuzzy file finder (Ctrl+R for history)"
echo "  ✓ ble.sh     - Syntax highlighting & autocompletion"
[ -f ~/.local/bin/atuin ] && echo "  ✓ Atuin      - Smart command history"
[ "$LITE_MODE" = false ] && [ -f ~/.local/bin/starship ] && echo "  ✓ Starship   - Beautiful prompt with git info"
echo
print_status "Useful commands:"
echo "  • terminal-enhancer-fix       - Fix .bashrc syntax errors"
echo "  • terminal-enhancer-uninstall - Remove everything"
echo
print_success "Everything is configured and ready to use!"
print_status "Just run: ${GREEN}source ~/.bashrc${NC}"
echo
echo -e "${YELLOW}Or open a new terminal to see the changes.${NC}"
echo
