#!/usr/bin/env bash

# Dotfiles Installation Script
# Automated setup for personal development environment on Arch Linux


set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo
    echo "================================================"
    echo "$1"
    echo "================================================"
    echo
}

# Check if running on Arch Linux
check_arch() {
    if [ ! -f /etc/arch-release ]; then
        print_warning "This script is designed for Arch Linux. Proceeding anyway..."
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Check for required tools
check_dependencies() {
    print_header "Checking Dependencies"
    
    local deps=("git" "stow" "curl")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
            print_error "$dep is not installed"
        else
            print_success "$dep is available"
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        echo "Install them with: sudo pacman -S ${missing_deps[*]}"
        exit 1
    fi
}

# Install AUR helper if not present
install_aur_helper() {
    if command -v yay &> /dev/null; then
        print_success "yay AUR helper is available"
        return 0
    elif command -v paru &> /dev/null; then
        print_success "paru AUR helper is available"
        return 0
    fi
    
    print_info "Installing yay AUR helper..."
    
    if [ ! -d "/tmp/yay" ]; then
        git clone https://aur.archlinux.org/yay.git /tmp/yay
    fi
    
    cd /tmp/yay
    makepkg -si --noconfirm
    cd - > /dev/null
    
    print_success "yay AUR helper installed"
}

# Install essential packages
install_packages() {
    print_header "Installing Essential Packages"
    
    # Core system packages
    local system_packages=(
        "base-devel" "git" "curl" "wget" "unzip" "zip"
        "neovim" "tmux" "zsh" "alacritty" 
        "fd" "ripgrep" "bat" "exa" "fzf" "zoxide"
        "nodejs" "npm" "python" "python-pip"
    )
    
    # Desktop environment packages (conditional)
    local desktop_packages=()
    if [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
        desktop_packages+=("kde-applications" "konsole")
    fi
    
    print_info "Installing system packages..."
    sudo pacman -S --needed --noconfirm "${system_packages[@]}"
    
    if [ ${#desktop_packages[@]} -ne 0 ]; then
        print_info "Installing desktop packages..."
        sudo pacman -S --needed --noconfirm "${desktop_packages[@]}"
    fi
    
    # AUR packages
    local aur_packages=(
        "visual-studio-code-bin"
        "zinit-git"
    )
    
    # Add KDE-specific AUR packages
    if [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
        aur_packages+=("kwin-scripts-krohnkite-git")
    fi
    
    print_info "Installing AUR packages..."
    if command -v yay &> /dev/null; then
        yay -S --needed --noconfirm "${aur_packages[@]}"
    elif command -v paru &> /dev/null; then
        paru -S --needed --noconfirm "${aur_packages[@]}"
    fi
    
    print_success "Packages installed successfully"
}

# Apply dotfiles configuration
apply_dotfiles() {
    print_header "Applying Dotfiles Configuration"
    
    # Ensure we're in the dotfiles directory
    DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cd "$DOTFILES_DIR"
    
    print_info "Current directory: $DOTFILES_DIR"
    
    # Backup existing configurations
    backup_configs() {
        local backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
        print_info "Creating backup at $backup_dir"
        
        mkdir -p "$backup_dir"
        
        # Backup key config files that might exist
        local configs=(
            ".zshrc" ".tmux.conf" ".gitconfig"
            ".config/nvim" ".config/alacritty" ".config/Code"
        )
        
        for config in "${configs[@]}"; do
            if [ -e "$HOME/$config" ]; then
                print_info "Backing up $config"
                cp -r "$HOME/$config" "$backup_dir/" 2>/dev/null || true
            fi
        done
        
        print_success "Backup created at $backup_dir"
    }
    
    # Create backup
    backup_configs
    
    # Apply configurations using stow
    print_info "Applying dotfiles with stow..."
    ./stowup
    
    print_success "Dotfiles applied successfully"
}

# Setup Zsh as default shell
setup_zsh() {
    print_header "Setting up Zsh"
    
    if [ "$SHELL" != "/usr/bin/zsh" ] && [ "$SHELL" != "/bin/zsh" ]; then
        print_info "Changing default shell to zsh..."
        chsh -s "$(which zsh)"
        print_success "Default shell changed to zsh (will take effect on next login)"
    else
        print_success "Zsh is already the default shell"
    fi
    
    # Install zinit if not present
    if [ ! -d "$HOME/.local/share/zinit/zinit.git" ]; then
        print_info "Installing zinit plugin manager..."
        bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
        print_success "Zinit installed"
    else
        print_success "Zinit is already installed"
    fi
}

# Setup KDE specific configurations
setup_kde() {
    if [ "$XDG_CURRENT_DESKTOP" != "KDE" ]; then
        print_info "Not running KDE, skipping KDE-specific setup"
        return 0
    fi
    
    print_header "Setting up KDE Plasma Configuration"
    
    # Setup Krohnkite if it's installed
    if [ -d "$HOME/.local/share/kwin/scripts/krohnkite" ]; then
        print_info "Setting up Krohnkite tiling window manager..."
        "$DOTFILES_DIR/bin/setup-krohnkite"
        
        # Apply captured shortcuts if available
        if [ -f "$DOTFILES_DIR/kde/shortcuts-presets.conf" ] && grep -q "\[current-system\]" "$DOTFILES_DIR/kde/shortcuts-presets.conf"; then
            print_info "Applying your captured shortcut configuration..."
            "$DOTFILES_DIR/bin/apply-shortcuts-preset" current-system
        fi
    else
        print_warning "Krohnkite not found. Install it with: yay -S kwin-scripts-krohnkite-git"
    fi
}

# Setup development environment
setup_development() {
    print_header "Setting up Development Environment"
    
    # Install global npm packages
    print_info "Installing global npm packages..."
    npm install -g typescript ts-node eslint prettier nodemon

    # Install pi coding agent
    if ! command -v pi &> /dev/null; then
        print_info "Installing pi coding agent..."
        npm install -g @mariozechner/pi-coding-agent
        print_success "Pi coding agent installed"
    else
        print_success "Pi coding agent already installed"
    fi
    
    # Setup Git (if not configured)
    if ! git config --global user.name &> /dev/null; then
        print_info "Git user configuration needed"
        echo "Please configure Git:"
        read -p "Enter your Git username: " git_username
        read -p "Enter your Git email: " git_email
        
        git config --global user.name "$git_username"
        git config --global user.email "$git_email"
        git config --global init.defaultBranch main
        
        print_success "Git configured successfully"
    else
        print_success "Git is already configured"
    fi
    
    print_success "Development environment setup complete"
}

# Post-installation instructions
post_install() {
    print_header "Installation Complete!"
    
    echo "Your dotfiles have been successfully installed!"
    echo
    echo "Next steps:"
    echo "1. Log out and log back in (or reboot) to ensure all changes take effect"
    echo "2. Open a new terminal to see the new configuration"
    
    if [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
        echo "3. KDE Plasma shortcuts are configured - check System Settings → Shortcuts"
        echo "4. Krohnkite tiling shortcuts:"
        echo "   Meta+F          - Toggle tiling"
        echo "   Meta+Shift+F    - Toggle floating"
        echo "   Meta+Return     - Set as master"
        echo "   Meta+J/K        - Navigate windows"
    fi
    
    echo
    echo "Configuration directories:"
    echo "- Neovim: ~/.config/nvim"
    echo "- Alacritty: ~/.config/alacritty" 
    echo "- VS Code: ~/.config/Code"
    echo "- Tmux: ~/.tmux.conf"
    echo "- Zsh: ~/.zshrc"
    echo "- Pi coding agent: ~/.pi/agent"
    echo
    echo "Pi coding agent setup:"
    echo "  Run 'pi' then '/login' to authenticate (credentials are NOT synced via dotfiles)"
    
    if [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
        echo "- KDE configs: ~/.config/kwin*, ~/.config/plasma*"
    fi
    
    echo
    print_success "Enjoy your new development environment!"
}

# Main installation flow
main() {
    print_header "Dotfiles Installation Script"
    echo "This script will set up your complete development environment."
    echo
    
    read -p "Continue with installation? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    
    check_arch
    check_dependencies
    install_aur_helper
    install_packages
    apply_dotfiles
    setup_zsh
    setup_kde
    setup_development
    post_install
}

# Run main function
main "$@"
