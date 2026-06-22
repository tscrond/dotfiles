#!/usr/bin/env bash
set -euo pipefail

### HELPERS ###
check_if_installed() {
    PROGRAM=$1
    if command -v $PROGRAM; then
        log success "$PROGRAM installed - proceeding"
        return 0
    else
        log error "$PROGRAM not installed"
        return 1
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
    check_if_installed paru
    [[ $? != 0 ]] && log error "cannot proceed further - make sure paru is installed" && exit 1
}

prerequisites() {
    check_if_installed pacman
    [[ $? != 0 ]] && log error  "cannot proceed further - make sure pacman is installed" && exit 1
    check_if_installed git
    [[ $? != 0 ]] && sudo pacman -Syu git
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
    sudo pacman -Syu fzf \
        sddm \
        hyprlock \
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
    sudo pacman -S --needed base-devel
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

    sudo pacman -S gtk4 gtk4-layer-shell cairo poppler-glib protobuf

    paru_needed
    
    paru -Syu walker \
        elephant
}

walker_post() {
    check_if_installed elephant
    [[ $? != 0 ]] && log error "cannot proceed further - make sure elephant is installed"
    
    elephant service enable
    systemctl --user start elephant.service
}

### MAIN FLOW ###
prerequisites
aur_helper
brave
walker
walker_post