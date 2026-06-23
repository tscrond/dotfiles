#!/usr/bin/env bash
set -euo pipefail
trap 'echo "FAILED at line $LINENO"' ERR

### LOG ###
log() {
    local t="${1:-info}"
    shift
    echo "[$t] $*"
}

### CHECKS ###
is_installed() {
    command -v "$1" >/dev/null 2>&1
}

require_or_install() {
    local cmd="$1"
    local pkg="${2:-$1}"

    if is_installed "$cmd"; then
        log success "$cmd already installed"
    else
        log error "$cmd missing - installing $pkg"
        sudo pacman -S --noconfirm --needed "$pkg"
    fi
}

install_if_missing_paru() {
    local pkg="$1"

    if paru -Q "$pkg" >/dev/null 2>&1; then
        log success "$pkg already installed"
        return
    fi

    paru -S --noconfirm --needed --skipreview "$pkg"
}

clone_if_missing() {
    local repo="$1"
    local dest="$2"

    if [[ -d "$dest" ]]; then
        log success "$dest already exists - skipping clone"
    else
        git clone "$repo" "$dest"
    fi
}

### PREREQUISITES ###
prerequisites() {
    if ! pacman --version >/dev/null 2>&1; then
        log error "pacman not working"
        exit 1
    fi

    sudo pacman -Syu --noconfirm

    require_or_install git git
}

### OH MY ZSH (IDEMPOTENT) ###
install_ohmyzsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log success "Oh My Zsh already installed"
        return
    fi

    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

### SERVICES ###
enable_service() {
    systemctl --user enable --now "$1" 2>/dev/null || true
}

### INITIAL SETUP ###
initial() {
    sudo pacman -S --noconfirm --needed \
        fzf hyprland kitty sddm hyprlock yazi brightnessctl \
        hyprpolkitagent xdg-desktop-portal-hyprland waybar \
        unzip zip p7zip wget curl git htop fastfetch \
        wl-clipboard stow hyprpaper blueman swaync

    enable_service hyprpolkitagent.service
    enable_service xdg-desktop-portal-hyprland.service
    enable_service hyprpaper.service
    enable_service waybar.service
    enable_service swaync.service
    enable_service blueman-applet
    enable_service blueman-manager

    install_ohmyzsh

    clone_if_missing \
        https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"

    clone_if_missing \
        https://github.com/zsh-users/zsh-autosuggestions.git \
        "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"

    clone_if_missing \
        https://github.com/zsh-users/zsh-history-substring-search.git \
        "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-history-substring-search"
}

### AUR HELPER ###
aur_helper() {
    if is_installed paru; then
        log success "paru already installed"
        return
    fi

    sudo pacman -S --noconfirm --needed base-devel

    git clone https://aur.archlinux.org/paru.git /tmp/paru

    pushd /tmp/paru >/dev/null
    makepkg -si --noconfirm
    popd >/dev/null
}

### BRAVE ###
brave() {
    if is_installed brave; then
        log success "brave already installed"
        return
    fi

    install_if_missing_paru brave
}

### WALKER ###
walker() {
    sudo pacman -S --noconfirm --needed \
        gtk4 gtk4-layer-shell cairo poppler-glib protobuf

    install_if_missing_paru walker
    install_if_missing_paru elephant
}

walker_post() {
    if ! is_installed elephant; then
        log error "elephant missing"
        return 1
    fi

    elephant service enable || true
    systemctl --user start elephant || true
}

gtk_theme() {
    install_if_missing_paru "gnome-themes-extra"
    install_if_missing_paru "gtk-engine-murrine"
    install_if_missing_paru "sassc"

    clone_if_missing \
        https://github.com/vinceliuice/Colloid-icon-theme.git \
        ${HOME}/Colloid-icon-theme

    clone_if_missing \
        https://github.com/vinceliuice/Colloid-gtk-theme.git \
        ${HOME}/Colloid-gtk-theme

    cd ${HOME}/Colloid-icon-theme
    bash -x -c "${HOME}/Colloid-icon-theme/install.sh -s nord"
    cd -

    cd ${HOME}/Colloid-gtk-theme
    bash -x -c "${HOME}/Colloid-gtk-theme/install.sh"
    cd -

    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    gsettings set org.gnome.desktop.interface gtk-theme 'Colloid-Dark'

    sudo pacman -S --noconfirm --needed nautilus galculator loupe file-roller gnome-system-monitor amberol
}

sddm_theme() {
    sudo pacman -S --noconfirm --needed qt6-declarative qt6-5compat qt6-svg \
        qt6-multimedia qt6-multimedia-ffmpeg \
        gst-plugins-base gst-plugins-good \
        gst-plugins-bad gst-plugins-ugly
    
    git clone https://github.com/Darkkal44/qylock.git
    cd qylock
    chmod +x sddm.sh && ./sddm.sh
    cd -
}

config_setup() {
    mv ~/.zshrc ~/.zshrc.bak || true
    mv ~/.config/hypr/hyprland.lua ~/hyprland.lua.bak || true

    stow -R -t ~ hypr kitty zsh waybar gtk fastfetch
    
    sudo systemctl enable sddm
    sudo systemctl start sddm
}

### MAIN ###
prerequisites
initial
aur_helper
brave
walker
walker_post
gtk_theme
sddm_theme
config_setup