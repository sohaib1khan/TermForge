#!/bin/bash

# Termforge - Modern Terminal Enhancement Suite
# Transform your bash terminal into a powerful, modern development environment
# https://github.com/your-username/termforge

TOOL_NAME="Termforge"
VERSION="1.0.0"

# Parse command line arguments
SKIP_ALIASES=false
for arg in "$@"; do
    case $arg in
        --skip-aliases)
            SKIP_ALIASES=true
            shift
            ;;
        --help|-h)
            echo "$TOOL_NAME v$VERSION - Modern Terminal Enhancement Suite"
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --skip-aliases    Don't install any aliases"
            echo "  --help, -h        Show this help message"
            exit 0
            ;;
    esac
done

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root!"
   exit 1
fi

# Create necessary directories
mkdir -p ~/.local/bin
mkdir -p ~/.config

# Step 1: Install system dependencies
print_status "Installing system dependencies..."
sudo apt update
sudo apt install -y curl git gawk build-essential

# Step 2: Install ble.sh
print_status "Installing ble.sh (Bash Line Editor)..."
if [ ! -d ~/.local/share/blesh ]; then
    cd /tmp
    # Try to install pre-built version first (faster)
    if command -v wget &> /dev/null; then
        print_status "Downloading pre-built ble.sh..."
        mkdir -p ~/.local/share/blesh
        cd ~/.local/share/blesh
        wget -q https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz
        tar xf ble-nightly.tar.xz --strip-components=1
        rm ble-nightly.tar.xz
        print_success "ble.sh installed successfully!"
    else
        # Fallback to building from source
        print_status "Building ble.sh from source..."
        cd /tmp
        git clone --recursive https://github.com/akinomyoga/ble.sh.git
        cd ble.sh
        make install PREFIX=~/.local
        cd /tmp
        rm -rf ble.sh
        print_success "ble.sh built and installed successfully!"
    fi
else
    print_warning "ble.sh already installed, skipping..."
fi

# Step 3: Install Starship prompt
print_status "Installing Starship prompt..."
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir ~/.local/bin -y
    print_success "Starship installed successfully!"
else
    print_warning "Starship already installed, skipping..."
fi

# Step 4: Install Atuin for shell history
print_status "Installing Atuin (enhanced shell history)..."
if ! command -v atuin &> /dev/null; then
    bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
    print_success "Atuin installed successfully!"
else
    print_warning "Atuin already installed, skipping..."
fi

# Step 5: Install fzf for fuzzy finding
print_status "Installing fzf (fuzzy finder)..."
if [ ! -d ~/.fzf ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all --no-update-rc
    print_success "fzf installed successfully!"
else
    print_warning "fzf already installed, skipping..."
fi

# Step 6: Configure Starship
print_status "Configuring Starship..."
mkdir -p ~/.config

# Create a DevOps-focused Starship configuration
cat > ~/.config/starship.toml << 'EOF'
# Starship configuration for DevOps

[username]
style_user = "green bold"
style_root = "red bold"
format = "[$user]($style) "
disabled = false
show_always = true

[hostname]
ssh_only = false
format = "on [$hostname](bold blue) "
disabled = false

[directory]
truncation_length = 3
truncate_to_repo = false
format = "[$path]($style)[$read_only]($read_only_style) "

[git_branch]
format = "[$symbol$branch(:$remote_branch)]($style) "

[git_status]
format = "[$all_status$ahead_behind]($style) "

[kubernetes]
format = '[⎈ $context \($namespace\)](bold cyan) '
disabled = false

[docker_context]
format = '[🐋 $context](blue bold) '
disabled = false

[python]
format = '[${symbol}${pyenv_prefix}(${version} )(\($virtualenv\) )]($style)'

[package]
disabled = false

[cmd_duration]
min_time = 500
format = "⏱️ [$duration](bold yellow)"

[memory_usage]
disabled = false
threshold = 75
format = "via [$ram_pct](bold red) "

[time]
disabled = false
format = "[%T](bright-black) "

[status]
disabled = false
format = '[$status]($style) '

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[✗](bold red)"
EOF

# Step 7: Check for existing aliases
print_status "Checking for existing aliases..."
EXISTING_ALIASES=""
for alias_name in k d dc tf g ll l; do
    if alias $alias_name &>/dev/null; then
        EXISTING_ALIASES="$EXISTING_ALIASES $alias_name"
    fi
done

if [ -n "$EXISTING_ALIASES" ]; then
    print_warning "Found existing aliases:$EXISTING_ALIASES"
    print_status "These will be preserved. Termforge aliases will only be added for missing ones."
fi

# Step 8: Backup existing .bashrc
print_status "Backing up existing .bashrc..."
cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)

# Step 8: Configure .bashrc
print_status "Configuring .bashrc..."

# Check if we've already installed Termforge
if grep -q "# Modern Terminal Enhancement with Termforge" ~/.bashrc; then
    print_warning "Termforge configuration already exists in .bashrc"
    print_status "Updating existing configuration..."
    # Remove only our specific block
    sed -i '/# Modern Terminal Enhancement with Termforge/,/# End Termforge Setup/d' ~/.bashrc
else
    print_status "Adding Termforge configuration to .bashrc..."
fi

# Remove any orphaned lines from previous installations
sed -i '/source .*blesh.*ble\.sh/d' ~/.bashrc
sed -i '/eval.*starship init bash/d' ~/.bashrc
sed -i '/eval.*atuin init bash/d' ~/.bashrc

# Add our configuration
cat >> ~/.bashrc << 'EOF'

# Modern Terminal Enhancement with Termforge
# ble.sh - Bash Line Editor
[[ $- == *i* ]] && source ~/.local/share/blesh/ble.sh

# Starship prompt
export PATH="$HOME/.local/bin:$PATH"
eval "$(starship init bash)"

# Atuin - Better shell history
eval "$(atuin init bash)"

# fzf - Fuzzy finder
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# Better bash completion
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

# Custom aliases for DevOps (only add if they don't exist)
if [ "$SKIP_ALIASES" = false ]; then
    alias k &>/dev/null || alias k='kubectl'
    alias d &>/dev/null || alias d='docker'
    alias dc &>/dev/null || alias dc='docker-compose'
    alias tf &>/dev/null || alias tf='terraform'
    alias g &>/dev/null || alias g='git'
    alias ll &>/dev/null || alias ll='ls -alh'
    alias l &>/dev/null || alias l='ls -lh'
fi

# Kubectl completion
if command -v kubectl &> /dev/null; then
    source <(kubectl completion bash)
    complete -F __start_kubectl k
fi

# Docker completion
if command -v docker &> /dev/null; then
    source <(docker completion bash 2>/dev/null || true)
fi

# End Termforge Setup
EOF

# Step 9: Create update script
print_status "Creating update script..."
cat > ~/.local/bin/update-termforge << 'EOF'
#!/bin/bash
# Update script for Termforge tools

echo "Updating Termforge tools..."

# Update ble.sh
echo "Updating ble.sh..."
cd ~/.local/share/blesh
wget -q https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz
tar xf ble-nightly.tar.xz --strip-components=1
rm ble-nightly.tar.xz

# Update Starship
echo "Updating Starship..."
curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir ~/.local/bin -y

# Update Atuin
echo "Updating Atuin..."
bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)

# Update fzf
echo "Updating fzf..."
cd ~/.fzf && git pull && ./install --all

echo "Termforge tools updated successfully!"
EOF

chmod +x ~/.local/bin/update-termforge

print_success "$TOOL_NAME installation completed successfully!"
print_status "To apply the changes, either:"
print_status "  1. Run: source ~/.bashrc"
print_status "  2. Open a new terminal"
print_warning "Your original .bashrc has been backed up with timestamp"
print_status "To update all tools in the future, run: update-termforge"

# Optional: Show what was installed
echo
echo -e "${BLUE}================================${NC}"
echo -e "${GREEN}$TOOL_NAME v$VERSION${NC}"
echo -e "${BLUE}================================${NC}"
echo
print_status "Installed components:"
echo "  - ble.sh (Bash Line Editor) - Syntax highlighting, autosuggestions"
echo "  - Starship - Modern, customizable prompt"
echo "  - Atuin - Enhanced shell history with search"
echo "  - fzf - Fuzzy finder for files and history"
echo
print_status "DevOps aliases added:"
echo "  - k  = kubectl"
echo "  - d  = docker"
echo "  - dc = docker-compose"
echo "  - tf = terraform"
echo "  - g  = git"
echo
echo -e "${BLUE}================================${NC}"

# Ask if user wants to apply changes now
echo
read -p "Would you like to apply the changes now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    exec bash
fi