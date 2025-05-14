#!/bin/bash

# Termforge - Modern Terminal Enhancement Suite (Safe Version)
# Transform your bash terminal into a powerful, modern development environment
# https://github.com/your-username/termforge

TOOL_NAME="Termforge"
VERSION="1.1.0"

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
INSTALL_STARSHIP=true
INSTALL_BLESH=true
INSTALL_ATUIN=true
INSTALL_FZF=true
INSTALL_ALIASES=true
SAFE_MODE=false
USE_SUDO=true
AUTO_INSTALL_DEPS=true

for arg in "$@"; do
    case $arg in
        --safe)
            SAFE_MODE=true
            INSTALL_STARSHIP=false
            print_warning "Safe mode: Installing only basic enhancements"
            shift
            ;;
        --no-sudo)
            USE_SUDO=false
            print_warning "Running without sudo. Some features may require manual dependency installation."
            shift
            ;;
        --no-deps)
            AUTO_INSTALL_DEPS=false
            print_warning "Skipping automatic dependency installation."
            shift
            ;;
        --container)
            USE_SUDO=false
            AUTO_INSTALL_DEPS=false
            print_warning "Container mode: No sudo, no automatic dependencies"
            shift
            ;;
        --no-starship)
            INSTALL_STARSHIP=false
            shift
            ;;
        --no-blesh)
            INSTALL_BLESH=false
            shift
            ;;
        --no-atuin)
            INSTALL_ATUIN=false
            shift
            ;;
        --no-aliases)
            INSTALL_ALIASES=false
            shift
            ;;
        --minimal)
            INSTALL_STARSHIP=false
            INSTALL_ATUIN=false
            INSTALL_BLESH=false
            print_warning "Minimal mode: Only fzf and aliases"
            shift
            ;;
        --help|-h)
            echo "$TOOL_NAME v$VERSION - Modern Terminal Enhancement Suite"
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --safe          Safe mode (skip problematic components)"
            echo "  --minimal       Minimal installation (fzf + aliases only)"
            echo "  --no-sudo       Run without sudo (for restricted environments)"
            echo "  --no-deps       Skip automatic dependency installation"
            echo "  --container     Container mode (no sudo, no auto dependencies)"
            echo "  --no-starship   Skip Starship prompt"
            echo "  --no-blesh      Skip ble.sh (syntax highlighting)"
            echo "  --no-atuin      Skip Atuin (enhanced history)"
            echo "  --no-aliases    Skip alias installation"
            echo "  --help, -h      Show this help message"
            exit 0
            ;;
    esac
done

# Detect if running in a container
if [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
    print_warning "Container environment detected"
    if [ "$USE_SUDO" = true ]; then
        print_status "Switching to no-sudo mode for container"
        USE_SUDO=false
    fi
fi

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    if [ "$USE_SUDO" = true ]; then
        print_warning "Running as root. Sudo not needed."
        USE_SUDO=false
    fi
fi

# Check system compatibility
print_status "Checking system compatibility..."
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    print_warning "This script is designed for Linux. Some features may not work correctly."
fi

# Check bash version
BASH_MAJOR_VERSION=${BASH_VERSION%%.*}
if [[ $BASH_MAJOR_VERSION -lt 4 ]]; then
    print_warning "Bash version is $BASH_VERSION. Some features require Bash 4.0+"
    SAFE_MODE=true
fi

# Create backup
print_status "Backing up existing .bashrc..."
BACKUP_FILE=~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)
cp ~/.bashrc "$BACKUP_FILE"
print_success "Backup created: $BACKUP_FILE"

# Install system dependencies
if [ "$AUTO_INSTALL_DEPS" = true ]; then
    print_status "Checking for required dependencies..."
    MISSING_DEPS=""
    
    # Check for required commands
    for cmd in curl git wget; do
        if ! command -v $cmd &> /dev/null; then
            MISSING_DEPS="$MISSING_DEPS $cmd"
        fi
    done
    
    if [ -n "$MISSING_DEPS" ]; then
        if [ "$USE_SUDO" = true ]; then
            print_status "Installing missing dependencies:$MISSING_DEPS"
            if command -v apt &> /dev/null; then
                sudo apt update
                sudo apt install -y $MISSING_DEPS
            elif command -v yum &> /dev/null; then
                sudo yum install -y $MISSING_DEPS
            elif command -v pacman &> /dev/null; then
                sudo pacman -Sy --noconfirm $MISSING_DEPS
            else
                print_warning "Could not detect package manager. Please install: $MISSING_DEPS"
            fi
        else
            print_warning "Missing dependencies:$MISSING_DEPS"
            print_warning "Please install these manually or run with sudo"
            print_warning "In a container, you might need to run: apt update && apt install -y$MISSING_DEPS"
            
            # Ask if user wants to continue
            read -p "Continue anyway? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_error "Installation cancelled. Please install dependencies first."
                exit 1
            fi
        fi
    else
        print_success "All required dependencies are installed"
    fi
else
    print_warning "Skipping dependency check. Make sure you have: curl, git, wget"
fi

# Create necessary directories
mkdir -p ~/.local/bin
mkdir -p ~/.config

# Install components based on options
COMPONENTS_INSTALLED=""

# Install fzf (most stable component)
if [ "$INSTALL_FZF" = true ]; then
    print_status "Installing fzf (fuzzy finder)..."
    if [ ! -d ~/.fzf ]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all --no-update-rc
        COMPONENTS_INSTALLED="$COMPONENTS_INSTALLED fzf"
        print_success "fzf installed successfully!"
    else
        print_warning "fzf already installed, skipping..."
    fi
fi

# Install ble.sh (check for gawk first)
if [ "$INSTALL_BLESH" = true ] && [ "$SAFE_MODE" = false ]; then
    if command -v gawk &> /dev/null; then
        print_status "Installing ble.sh (syntax highlighting)..."
        if [ ! -d ~/.local/share/blesh ]; then
            mkdir -p ~/.local/share/blesh
            cd ~/.local/share/blesh
            wget -q https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz
            tar xf ble-nightly.tar.xz --strip-components=1
            rm ble-nightly.tar.xz
            COMPONENTS_INSTALLED="$COMPONENTS_INSTALLED ble.sh"
            print_success "ble.sh installed successfully!"
            cd ~
        else
            print_warning "ble.sh already installed, skipping..."
        fi
    else
        print_warning "gawk not found. Skipping ble.sh installation."
        if [ "$USE_SUDO" = true ] && [ "$AUTO_INSTALL_DEPS" = true ]; then
            print_status "Attempting to install gawk..."
            if command -v apt &> /dev/null; then
                sudo apt install -y gawk
            elif command -v yum &> /dev/null; then
                sudo yum install -y gawk
            fi
            # Try again after installing gawk
            if command -v gawk &> /dev/null; then
                print_status "Installing ble.sh (syntax highlighting)..."
                mkdir -p ~/.local/share/blesh
                cd ~/.local/share/blesh
                wget -q https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz
                tar xf ble-nightly.tar.xz --strip-components=1
                rm ble-nightly.tar.xz
                COMPONENTS_INSTALLED="$COMPONENTS_INSTALLED ble.sh"
                print_success "ble.sh installed successfully!"
                cd ~
            fi
        else
            print_status "To install ble.sh later, install gawk and re-run the script"
        fi
    fi
fi

# Install Starship (with compatibility check)
if [ "$INSTALL_STARSHIP" = true ] && [ "$SAFE_MODE" = false ]; then
    print_status "Installing Starship prompt..."
    if ! command -v starship &> /dev/null; then
        # Check if terminal supports Unicode
        if echo -e "\u2713" | grep -q "✓"; then
            curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir ~/.local/bin -y
            COMPONENTS_INSTALLED="$COMPONENTS_INSTALLED starship"
            print_success "Starship installed successfully!"
        else
            print_warning "Terminal may not support Unicode. Skipping Starship."
        fi
    else
        print_warning "Starship already installed, skipping..."
    fi
fi

# Install Atuin
if [ "$INSTALL_ATUIN" = true ] && [ "$SAFE_MODE" = false ]; then
    print_status "Installing Atuin (enhanced history)..."
    if ! command -v atuin &> /dev/null; then
        bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
        COMPONENTS_INSTALLED="$COMPONENTS_INSTALLED atuin"
        print_success "Atuin installed successfully!"
    else
        print_warning "Atuin already installed, skipping..."
    fi
fi

# Configure .bashrc
print_status "Configuring .bashrc..."

# Remove existing Termforge configuration
sed -i '/# Termforge Configuration Start/,/# Termforge Configuration End/d' ~/.bashrc

# Add new configuration
cat >> ~/.bashrc << 'EOF'

# Termforge Configuration Start
# Generated by Termforge v1.1.0

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

EOF

# Add components based on what was installed
if [[ $COMPONENTS_INSTALLED == *"fzf"* ]]; then
    echo '# fzf - Fuzzy finder' >> ~/.bashrc
    echo '[ -f ~/.fzf.bash ] && source ~/.fzf.bash' >> ~/.bashrc
    echo '' >> ~/.bashrc
fi

if [[ $COMPONENTS_INSTALLED == *"ble.sh"* ]]; then
    echo '# ble.sh - Bash Line Editor (syntax highlighting)' >> ~/.bashrc
    echo '[[ $- == *i* ]] && source ~/.local/share/blesh/ble.sh --noattach' >> ~/.bashrc
    echo '[[ ${BLE_VERSION-} ]] && ble-attach' >> ~/.bashrc
    echo '' >> ~/.bashrc
fi

if [[ $COMPONENTS_INSTALLED == *"starship"* ]]; then
    # Create a safe Starship config first
    cat > ~/.config/starship.toml << 'STARSHIP_CONFIG'
# Safe Starship configuration
format = """
$username\
$hostname\
$directory\
$git_branch\
$git_status\
$kubernetes\
$docker_context\
$python\
$character"""

[character]
success_symbol = "[>](bold green)"
error_symbol = "[>](bold red)"

[directory]
truncation_length = 3

[username]
format = "[$user]($style)@"
style_user = "green"
show_always = true

[hostname]
format = "[$hostname]($style) "
style = "blue"

[git_branch]
format = "on [$branch]($style) "

[kubernetes]
disabled = false
format = '[k8s:$context]($style) '
style = "cyan"

[docker_context]
format = '[docker:$context]($style) '
style = "blue"
STARSHIP_CONFIG

    echo '# Starship prompt' >> ~/.bashrc
    echo 'if command -v starship &> /dev/null; then' >> ~/.bashrc
    echo '    eval "$(starship init bash)"' >> ~/.bashrc
    echo 'else' >> ~/.bashrc
    echo '    PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> ~/.bashrc
    echo 'fi' >> ~/.bashrc
    echo '' >> ~/.bashrc
fi

if [[ $COMPONENTS_INSTALLED == *"atuin"* ]]; then
    echo '# Atuin - Enhanced history' >> ~/.bashrc
    echo 'if command -v atuin &> /dev/null; then' >> ~/.bashrc
    echo '    eval "$(atuin init bash)"' >> ~/.bashrc
    echo 'fi' >> ~/.bashrc
    echo '' >> ~/.bashrc
fi

# Add aliases if requested
if [ "$INSTALL_ALIASES" = true ]; then
    cat >> ~/.bashrc << 'EOF'
# DevOps aliases (only if not already defined)
alias k &>/dev/null || alias k='kubectl'
alias d &>/dev/null || alias d='docker'
alias dc &>/dev/null || alias dc='docker-compose'
alias tf &>/dev/null || alias tf='terraform'
alias g &>/dev/null || alias g='git'
alias ll &>/dev/null || alias ll='ls -alh'

EOF
fi

# Add completions
cat >> ~/.bashrc << 'EOF'
# Completions
if command -v kubectl &> /dev/null; then
    source <(kubectl completion bash 2>/dev/null || true)
    complete -F __start_kubectl k 2>/dev/null || true
fi

if command -v docker &> /dev/null; then
    source <(docker completion bash 2>/dev/null || true)
fi

# Termforge Configuration End
EOF

# Create uninstall script
cat > ~/.local/bin/uninstall-termforge << 'EOF'
#!/bin/bash
echo "Uninstalling Termforge..."

# Remove configuration from .bashrc
sed -i '/# Termforge Configuration Start/,/# Termforge Configuration End/d' ~/.bashrc

# Remove installed components
rm -rf ~/.local/share/blesh
rm -f ~/.local/bin/starship
rm -f ~/.local/bin/atuin
rm -rf ~/.fzf

# Remove this uninstall script
rm -f ~/.local/bin/uninstall-termforge

echo "Termforge uninstalled. Restart your terminal."
echo "Note: System packages (curl, git, wget, gawk) were not removed."
EOF
chmod +x ~/.local/bin/uninstall-termforge

# Final summary
echo
echo -e "${BLUE}================================${NC}"
echo -e "${GREEN}$TOOL_NAME v$VERSION${NC}"
echo -e "${BLUE}================================${NC}"
echo
print_success "Installation completed!"
echo
print_status "Installation mode:"
[ "$USE_SUDO" = false ] && echo "  - No sudo (container/restricted mode)"
[ "$AUTO_INSTALL_DEPS" = false ] && echo "  - Manual dependency installation"
[ "$SAFE_MODE" = true ] && echo "  - Safe mode (limited features)"
echo
print_status "Installed components: $COMPONENTS_INSTALLED"
echo
print_status "Next steps:"
echo "  1. Restart your terminal or run: source ~/.bashrc"
echo "  2. If you have issues, restore backup: cp $BACKUP_FILE ~/.bashrc"
echo "  3. To uninstall, run: uninstall-termforge"
echo
if [ "$USE_SUDO" = false ]; then
    print_warning "Installed without sudo. Some features may require manual setup."
fi
echo -e "${BLUE}================================${NC}"
