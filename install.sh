#!/usr/bin/env bash
set -euo pipefail
trap 'echo "FAILED at line $LINENO"' ERR

### HELPERS ###
check_if_installed() {
    local program="$1"

    if command -v "$program" >/dev/null 2>&1; then
        log success "$program installed - proceeding"
        return 0
    else
        log error "$program not installed - aborting"
        return 1
    fi
}

require_or_install() {
    local pkg="$1"

    if command -v "$pkg" >/dev/null 2>&1; then
        log success "$pkg already installed"
    else
        log error "$pkg missing - installing"
        sudo pacman -S --noconfirm "$pkg"
    fi
}

log() {
    local MSG_TYPE="${1:-info}"
    shift
    local MESSAGE="$*"

    local available_msg=("info" "error" "success")
    local valid=0

    for m in "${available_msg[@]}"; do
        if [[ "$MSG_TYPE" == "$m" ]]; then
            valid=1
            break
        fi
    done

    [[ $valid -eq 0 ]] && MSG_TYPE="unknown"
    
    echo "[${MSG_TYPE}] ${MESSAGE}"
}

paru_needed() {
    if ! check_if_installed paru; then
        log error "cannot proceed further - make sure paru is installed"
        exit 1
    fi
}

prerequisites() {
    if ! pacman --version >/dev/null 2>&1; then
        log error "pacman not working - aborting"
        exit 1
    fi

    sudo pacman -Syyu
    
    require_or_install git
}

### INSTALLATION HELPERS ###
enable_hyprpolkitagent() {
    systemctl --user enable --now hyprpolkitagent.service
}

enable_xdgdesktopportal() {
    systemctl --user enable --now xdg-desktop-portal-hyprland
}

### INSTALLATION FUNCTIONS ###
initial() {
    # install tooling like openssh, ohmyzsh, vim etc.
    sudo pacman -Syu --noconfirm fzf \
        hyprland \
        kitty \
        sddm \
        hyprlock \
        yazi \
        brightnessctl \
        hyprpolkitagent \
        xdg-desktop-portal-hyprland \
        waybar \
        unzip \
        zip \
        p7zip \
        wget \
        curl \
        git \
        htop \
        fastfetch \
        wl-clipboard \
        stow

    enable_hyprpolkitagent
    enable_xdgdesktopportal

    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
}

brave() {
    paru_needed
    paru -Syu brave
}

aur_helper() {
    sudo pacman -Syu --noconfirm --needed base-devel
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si
}

walker() {
    # deps
    # - GTK4 development files
    # - gtk4-layer-shell development files
    # - Protocol Buffers compiler (protoc)
    # - cairo development files
    # - poppler-glib development files
    # - Rust toolchain (via rustup)

    sudo pacman -Syu --noconfirm gtk4 gtk4-layer-shell cairo poppler-glib protobuf

    paru_needed
    
    paru -Syu walker \
        elephant
}

walker_post() {
    check_if_installed elephant
    
    elephant service enable
    systemctl --user start elephant.service
}

### MAIN FLOW ###
prerequisites
initial
aur_helper
brave
walker
walker_post