#!/bin/bash

# Colours for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    clear
    echo -e "${PURPLE}${BOLD}"
    echo "=========================================="
    echo "     Gitit - Unified Package Manager      "
    echo "       Dependency Installer Wizard        "
    echo "==========================================${NC}"
    echo
}

print_status() {
    echo -e "${CYAN}[*] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

print_error() {
    echo -e "${RED}[✗] $1${NC}"
}

# Check if a command exists
has_command() {
    command -v "$1" >/dev/null 2>&1
}

install_linuxbrew() {
    if has_command brew; then
        print_success "Linuxbrew (Homebrew) is already installed."
        return 0
    fi

    print_status "Installing Linuxbrew (Homebrew for Linux)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" < /dev/null

    if has_command brew; then
        print_success "Linuxbrew installed successfully!"
        echo -e "${YELLOW}    Tip: Add to your shell profile if needed:${NC}"
        echo '    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
        return 0
    else
        print_error "Failed to install Linuxbrew."
        return 1
    fi
}

install_flatpak() {
    if has_command flatpak; then
        print_success "Flatpak is already installed."
        return 0
    fi

    print_status "Installing Flatpak..."
    if has_command apt-get; then
        sudo apt-get update && sudo apt-get install -y flatpak
    elif has_command dnf; then
        sudo dnf install -y flatpak
    elif has_command pacman; then
        sudo pacman -S --noconfirm flatpak
    elif has_command zypper; then
        sudo zypper install -y flatpak
    else
        print_error "Unsupported distro for automatic Flatpak install."
        print_warning "Please install Flatpak manually: https://flatpak.org/setup/"
        return 1
    fi

    if has_command flatpak; then
        print_success "Flatpak installed!"
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        print_success "Flathub repository added."
    fi
}

install_snap() {
    if has_command snap; then
        print_success "Snap is already installed."
        return 0
    fi

    print_status "Installing Snap..."
    if has_command apt-get; then
        sudo apt-get update && sudo apt-get install -y snapd
    elif has_command dnf; then
        sudo dnf install -y snapd
        sudo ln -s /var/lib/snapd/snap /snap
    elif has_command pacman; then
        print_warning "Snap on Arch requires extra steps (snapd + reboot)."
        sudo pacman -S --noconfirm snapd
        sudo systemctl enable --now snapd.socket
        sudo ln -s /var/lib/snapd/snap /snap
    else
        print_error "Snap installation not automated for this distro."
        return 1
    fi

    if has_command snap; then
        print_success "Snap installed!"
    fi
}

install_nix() {
    if has_command nix; then
        print_success "Nix is already installed."
        return 0
    fi

    print_status "Installing Nix (single-user mode)..."
    sh <(curl -L https://nixos.org/nix/install) --no-daemon < /dev/null

    if has_command nix; then
        print_success "Nix installed!"
    else
        print_error "Nix installation failed."
        return 1
    fi
}

show_menu() {
    print_header
    echo -e "${BOLD}Select package managers to install for Gitit:${NC}"
    echo
    echo "1) Linuxbrew (Homebrew)    $(has_command brew && echo -e "${GREEN}[Installed]${NC}" || echo -e "${RED}[Missing]${NC}")"
    echo "2) Flatpak + Flathub       $(has_command flatpak && echo -e "${GREEN}[Installed]${NC}" || echo -e "${RED}[Missing]${NC}")"
    echo "3) Snap                    $(has_command snap && echo -e "${GREEN}[Installed]${NC}" || echo -e "${RED}[Missing]${NC}")"
    echo "4) Nix                     $(has_command nix && echo -e "${GREEN}[Installed]${NC}" || echo -e "${RED}[Missing]${NC}")"
    echo
    echo "5) Install Gitit binary (latest release)"
    echo "6) Install ALL missing above"
    echo
    echo "0) Exit"
    echo
    read -p "Enter your choice(s) [e.g. 1 2 5 or 6]: " choices
}

main() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Do not run this script as root!"
        exit 1
    fi

    while true; do
        show_menu

        case $choices in
            *"0"*) 
                echo -e "${CYAN}Goodbye! Gitit is ready when you are.${NC}"
                exit 0 ;;
            *"1"*) install_linuxbrew ;;
            *"2"*) install_flatpak ;;
            *"3"*) install_snap ;;
            *"4"*) install_nix ;;
            *"5"*)
                print_status "Downloading latest Gitit release..."
                # Replace with your actual GitHub repo
                curl -L https://github.com/yourusername/gitit/releases/latest/download/gitit-x86_64-unknown-linux-gnu.tar.gz -o /tmp/gitit.tar.gz
                tar -xzf /tmp/gitit.tar.gz -C /tmp
                sudo mv /tmp/gitit /usr/local/bin/gitit
                sudo chmod +x /usr/local/bin/gitit
                print_success "Gitit installed to /usr/local/bin/gitit"
                ;;
            *"6"*)
                install_linuxbrew
                install_flatpak
                install_snap
                install_nix
                ;;
        esac

        echo
        read -p "Press Enter to continue..."
    done
}

main
