#!/usr/bin/env bash

# ----------------------------------------------------------
# Pre-Flight Checks
# ----------------------------------------------------------

if [ "$EUID" -eq 0 ]; then
  echo -e "Don't start this script as root (sudo). It will ask itself for sudo-permissions, if needed."
  exit 1
fi

# ----------------------------------------------------------
# Packages
# ----------------------------------------------------------

aur=(
    agelessd
    ananicy-cpp
    bruno
    cachyos-ananicy-rules
    libation
    makemkv
    nohang
    protonup-qt
    teamspeak
    ttf-ms-wincorefonts
    vesktop
    visual-studio-code-bin
)

flatpak=(
    "com.bitwarden.desktop"
    "com.brave.Browser"
    "com.github.iwalton3.jellyfin-media-player"
    "com.github.tchx84.Flatseal"
    "com.rtosta.zapzap"
    "io.ente.auth"
    "io.gitlab.adhami3310.Impression"
    "io.missioncenter.MissionCenter"
    "org.prismlauncher.PrismLauncher"
    "org.signal.Signal"
    "org.telegram.desktop"
)

# ----------------------------------------------------------
# Status
# ----------------------------------------------------------

GREEN='\033[0;32m'
NONE='\033[0m'

_sendStatus() {
    local msg="$1"
    printf "${GREEN}%s${NONE}\n" "$msg"
}

# ----------------------------------------------------------
# Graphics Drivers
# ----------------------------------------------------------

_sendStatus "Which graphics card is installed? (Vulkan/Proton support)"
echo -e "  [A]MD"
echo -e "  [I]ntel"
echo -e "  [N]VIDIA (Proprietary + DKMS for linux-zen)"
echo -e "  [S]kip (Already installed / VM)"

read -p "Please choose an option (A/I/N/S): " gpu_choice

case "$gpu_choice" in
    A|a)
        _sendStatus "Installing AMD Vulkan drivers..."
        sudo pacman -S --needed --noconfirm vulkan-radeon lib32-vulkan-radeon
        ;;
    I|i)
        _sendStatus "Installing Intel Vulkan drivers..."
        sudo pacman -S --needed --noconfirm vulkan-intel lib32-vulkan-intel
        ;;
    N|n)
        _sendStatus "Installing NVIDIA drivers (DKMS) and Vulkan support..."
        sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils lib32-nvidia-utils egl-wayland nvidia-settings cuda
        ;;
    S|s)
        _sendStatus "Skipping graphics driver installation."
        ;;
    *)
        echo -e "${GREEN}Invalid choice, skipping driver installation.${NONE}"
        ;;
esac

# ----------------------------------------------------------
# Content
# ----------------------------------------------------------

cd "$HOME"

# yay
_sendStatus "Now installing: yay"
sudo pacman -S --needed --noconfirm git base-devel
git clone https://aur.archlinux.org/yay.git "$HOME/yay"
cd "$HOME/yay"
makepkg -si --noconfirm
cd "$HOME"
rm -rf "$HOME/yay"

# Programs
## AUR
_sendStatus "Now installing AUR packages"
yay --noconfirm --needed -S "${aur[@]}"

## Flatpak
_sendStatus "Now installing Flatpaks"
flatpak install -y flathub "${flatpak[@]}"

## ohmyzsh
_sendStatus "Now installing: ohmyzsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

## Powerlevel10k
_sendStatus "Now installing: Powerlevel10k"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

## zsh-autosuggestions
_sendStatus "Now installing: zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"

## zsh-syntax-highlighting
_sendStatus "Now installing: zsh-syntax-highlighting"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"

## sddm-astronaut-theme
_sendStatus "Now installing: sddm-astronaut-theme"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/keyitdev/sddm-astronaut-theme/master/setup.sh)"

## npm & pnpm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install --lts
corepack enable pnpm

## Tree-Sitter CLI
npm install -g tree-sitter-cli

# ----------------------------------------------------------

# Custom
## dotfiles
_sendStatus "Now setting up: dotfiles"
git clone https://github.com/Murmeltierchen/dotfiles.git "$HOME/dotfiles"
cd "$HOME/dotfiles"
stow --adopt .
git restore .
cd "$HOME"

## Neovim Config
_sendStatus "Now setting up: Neovim Config"
git clone --depth 1 https://github.com/Murmeltierchen/Vimski.git "$HOME/.config/nvim"

## Monospace Font
_sendStatus "Now setting up: Monospace Font"
git clone https://github.com/Murmeltierchen/SchmakyFont.git "$HOME/SchmakyFont"
sudo mv "$HOME/SchmakyFont/TTF" /usr/share/fonts/SchmakyFont
rm -rf "$HOME/SchmakyFont"

# ----------------------------------------------------------

# Settings
_sendStatus "Now configuring settings"

## Generic SCSI Module
echo sg | sudo tee /etc/modules-load.d/sg.conf > /dev/null

## 99-bbr.conf
cat <<EOF | sudo tee /etc/sysctl.d/99-bbr.conf > /dev/null
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF

## 99-max_map_count.conf
echo "vm.max_map_count = 2147483642" | sudo tee /etc/sysctl.d/99-max_map_count.conf > /dev/null

## thp.conf
echo "w /sys/kernel/mm/transparent_hugepage/enabled - - - - always" | sudo tee /etc/tmpfiles.d/thp.conf > /dev/null

## 60-ioschedulers.rules
cat <<EOF | sudo tee /etc/udev/rules.d/60-ioschedulers.rules > /dev/null
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
EOF

## systemctl
sudo systemctl enable ananicy-cpp
sudo systemctl enable cpupower
sudo systemctl enable nohang-desktop

## Firewall
sudo firewall-cmd --permanent --zone=public --add-service=kdeconnect

## Shell
sudo chsh -s "$(which zsh)" "$USER"

# ----------------------------------------------------------
# Completed
# ----------------------------------------------------------

_sendStatus "Setup complete"
sudo reboot
