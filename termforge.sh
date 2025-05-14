#!/bin/bash

# Termforge Lite - Clean Terminal Enhancement Tools
# Only installs: ble.sh, Starship, Atuin, fzf
# Does NOT modify existing prompt or aliases

TOOL_NAME="Termforge Lite"
VERSION="2.0.0"

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
USE_SUDO=true
CONFIGURE_BASHRC=true

for arg in "$@"; do
    case $arg in
        --no-config)
            CONFIGURE_BASHRC=false
            print_warning "Will not modify .bashrc - manual configuration required"
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
        --no-fzf)
            INSTALL_FZF=false
            shift
            ;;
        --no-sudo)
            USE_SUDO=false
            shift
            ;;
        --help|-h)
            echo "$TOOL_NAME v$VERSION"
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --no-config     Install tools but don't modify .bashrc"
            echo "  --no-starship   Skip Starship installation"
            echo "  --no-blesh      Skip ble.sh installation"
            echo "  --no-atuin      Skip Atuin installation"
            echo "  --no-fzf        Skip fzf installation"
            echo "  --no-sudo       Run without sudo"
            echo "  --help, -h      Show this help message"
            exit 0
            ;;
    esac
done

# Detect if running in a container
if [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
    print_warning "Container environment detected"
    if [ "$USE_SUDO" = true ]; then
        USE_SUDO=false
    fi
fi

# Create necessary directories
mkdir -p ~/.local/bin
mkdir -p ~/.config

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to append to bashrc safely
append_to_bashrc() {
    local content="$1"
    local marker="$2"
    
    # Check if marker already exists
    if grep -q "$marker" ~/.bashrc 2>/dev/null; then
        print_warning "$marker already in .bashrc, skipping..."
    else
        echo "$content" >> ~/.bashrc
    fi
}

# Backup .bashrc if we're configuring it
if [ "$CONFIGURE_BASHRC" = true ]; then
    BACKUP_FILE=~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)
    cp ~/.bashrc "$BACKUP_FILE"
    print_success "Backup created: $BACKUP_FILE"
fi

# Install fzf
if [ "$INSTALL_FZF" = true ]; then
    print_status "Installing fzf..."
    if [ ! -d ~/.fzf ]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all --no-update-rc
        print_success "fzf installed!"
        
        if [ "$CONFIGURE_BASHRC" = true ]; then
            append_to_bashrc "[ -f ~/.fzf.bash ] && source ~/.fzf.bash" "# fzf"
        fi
    else
        print_warning "fzf already installed"
    fi
fi

# Install ble.sh
if [ "$INSTALL_BLESH" = true ]; then
    # Check for gawk
    if ! command_exists gawk; then
        print_warning "gawk not found - required for ble.sh"
        if [ "$USE_SUDO" = true ]; then
            print_status "Installing gawk..."
            if command_exists apt; then
                sudo apt update && sudo apt install -y gawk
            elif command_exists yum; then
                sudo yum install -y gawk
            fi
        else
            print_error "Please install gawk manually for ble.sh"
            INSTALL_BLESH=false
        fi
    fi
    
    if [ "$INSTALL_BLESH" = true ]; then
        print_status "Installing ble.sh..."
        if [ ! -d ~/.local/share/blesh ]; then
            mkdir -p ~/.local/share/blesh
            cd ~/.local/share/blesh
            wget -q https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz
            tar xf ble-nightly.tar.xz --strip-components=1
            rm ble-nightly.tar.xz
            cd ~
            print_success "ble.sh installed!"
            
            if [ "$CONFIGURE_BASHRC" = true ]; then
                # Use the safer loading method
                cat >> ~/.bashrc << 'EOF'

# ble.sh - Bash Line Editor
[[ $- == *i* ]] && [[ -f ~/.local/share/blesh/ble.sh ]] && source ~/.local/share/blesh/ble.sh --noattach
[[ ${BLE_VERSION-} ]] && ble-attach
EOF
            fi
        else
            print_warning "ble.sh already installed"
        fi
    fi
fi

# Install Starship
if [ "$INSTALL_STARSHIP" = true ]; then
    print_status "Installing Starship..."
    if ! command_exists starship; then
        curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir ~/.local/bin -y
        print_success "Starship installed!"
        
        # Create a minimal, safe config
        cat > ~/.config/starship.toml << 'EOF'
# Minimal Starship configuration
format = """
$username\
$hostname\
$directory\
$git_branch\
$character"""

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"

[directory]
truncation_length = 3
truncate_to_repo = false

[git_branch]
symbol = ""
format = "[$symbol$branch]($style) "

[username]
disabled = false
show_always = false

[hostname]
disabled = false
ssh_only = true
EOF
        
        if [ "$CONFIGURE_BASHRC" = true ]; then
            # Add starship but keep existing prompt as fallback
            cat >> ~/.bashrc << 'EOF'

# Starship prompt (optional - comment out to use default prompt)
if command -v starship &> /dev/null; then
    # To enable Starship, uncomment the next line:
    # eval "$(starship init bash)"
fi
EOF
            print_warning "Starship installed but NOT activated by default"
            print_status "To enable Starship, uncomment the line in .bashrc"
        fi
    else
        print_warning "Starship already installed"
    fi
fi

# Install Atuin
if [ "$INSTALL_ATUIN" = true ]; then
    print_status "Installing Atuin..."
    if ! command_exists atuin; then
        bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
        print_success "Atuin installed!"
        
        if [ "$CONFIGURE_BASHRC" = true ]; then
            # Add atuin but make it optional
            cat >> ~/.bashrc << 'EOF'

# Atuin - Enhanced history (optional)
if command -v atuin &> /dev/null; then
    # To enable Atuin, uncomment the next line:
    # eval "$(atuin init bash)"
fi
EOF
            print_warning "Atuin installed but NOT activated by default"
            print_status "To enable Atuin, uncomment the line in .bashrc"
        fi
    else
        print_warning "Atuin already installed"
    fi
fi

# Create enable/disable scripts
print_status "Creating helper scripts..."

cat > ~/.local/bin/termforge-enable << 'EOF'
#!/bin/bash
# Enable Termforge components

echo "Enabling Termforge components..."

# Enable Starship
if grep -q "# eval \"\$(starship init bash)\"" ~/.bashrc; then
    sed -i 's/# eval "\$(starship init bash)"/eval "\$(starship init bash)"/' ~/.bashrc
    echo "✓ Starship enabled"
fi

# Enable Atuin
if grep -q "# eval \"\$(atuin init bash)\"" ~/.bashrc; then
    sed -i 's/# eval "\$(atuin init bash)"/eval "\$(atuin init bash)"/' ~/.bashrc
    echo "✓ Atuin enabled"
fi

echo "Please run: source ~/.bashrc"
EOF
chmod +x ~/.local/bin/termforge-enable

cat > ~/.local/bin/termforge-disable << 'EOF'
#!/bin/bash
# Disable Termforge components

echo "Disabling Termforge components..."

# Disable Starship
if grep -q "eval \"\$(starship init bash)\"" ~/.bashrc; then
    sed -i 's/eval "\$(starship init bash)"/# eval "\$(starship init bash)"/' ~/.bashrc
    echo "✓ Starship disabled"
fi

# Disable Atuin
if grep -q "eval \"\$(atuin init bash)\"" ~/.bashrc; then
    sed -i 's/eval "\$(atuin init bash)"/# eval "\$(atuin init bash)"/' ~/.bashrc
    echo "✓ Atuin disabled"
fi

echo "Please run: source ~/.bashrc"
EOF
chmod +x ~/.local/bin/termforge-disable

# Create uninstall script
cat > ~/.local/bin/termforge-uninstall << 'EOF'
#!/bin/bash
echo "Uninstalling Termforge Lite..."

# Remove tools
rm -rf ~/.local/share/blesh
rm -f ~/.local/bin/starship
rm -f ~/.local/bin/atuin
rm -rf ~/.fzf

# Remove configs
rm -f ~/.config/starship.toml

# Remove helper scripts
rm -f ~/.local/bin/termforge-enable
rm -f ~/.local/bin/termforge-disable
rm -f ~/.local/bin/termforge-uninstall

echo "Termforge Lite uninstalled."
echo "Note: .bashrc modifications were not removed automatically."
echo "Please review and clean up .bashrc manually if needed."
EOF
chmod +x ~/.local/bin/termforge-uninstall

# Final summary
echo
echo -e "${BLUE}================================${NC}"
echo -e "${GREEN}$TOOL_NAME v$VERSION${NC}"
echo -e "${BLUE}================================${NC}"
echo
print_success "Installation completed!"
echo
print_status "Installed tools:"
[ "$INSTALL_FZF" = true ] && echo "  ✓ fzf (fuzzy finder)"
[ "$INSTALL_BLESH" = true ] && echo "  ✓ ble.sh (syntax highlighting)"
[ "$INSTALL_STARSHIP" = true ] && echo "  ✓ Starship (prompt) - NOT ACTIVATED"
[ "$INSTALL_ATUIN" = true ] && echo "  ✓ Atuin (history) - NOT ACTIVATED"
echo
print_status "Helper commands:"
echo "  - termforge-enable   : Enable Starship and Atuin"
echo "  - termforge-disable  : Disable Starship and Atuin"
echo "  - termforge-uninstall: Remove all Termforge tools"
echo
print_warning "IMPORTANT: Starship and Atuin are installed but NOT activated"
print_status "To use them, run: termforge-enable"
print_status "Then: source ~/.bashrc"
echo
if [ "$CONFIGURE_BASHRC" = false ]; then
    print_warning "Manual configuration required (.bashrc not modified)"
fi
echo -e "${BLUE}================================${NC}"
