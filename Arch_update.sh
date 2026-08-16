#!/bin/bash
if ! command -v checkupdates &> /dev/null; then
    echo "Installing pacman-contrib..."
    sudo pacman -S --needed pacman-contrib
fi

if ! command -v yay &> /dev/null; then
    echo "⚠️yay is not installed do you want to install it? (y/n): "
    read ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        sudo pacman -S --needed git base-devel
        git clone https://aur.archlinux.org/yay.git
        cd yay && makepkg -si && cd .. && rm -rf yay
    else
        echo "can't update the aur pak without yay"
    fi
fi

updates=$(checkupdates 2>/dev/null)


if command -v yay &> /dev/null; then
    aur_updates=$(yay -Qua 2>/dev/null)
    if [ -n "$aur_updates" ]; then
        updates="$updates"$'\n'"$aur_updates"
    fi
fi


if [ -z "$updates" ]; then
    echo "There is no updates✅"
    exit 0
fi

echo "Avalabile updates:📦"
echo "$updates" | nl


echo
read -p "Enter the number of pk(s) and space between them: " choices

# chose pkg
selected_packages=""
for choice in $choices; do
    pkg=$(echo "$updates" | sed -n "${choice}p" | awk '{print $1}')
    if pacman -Si "$pkg" &>/dev/null; then
        selected_packages="$selected_packages $pkg"
    elif command -v yay &> /dev/null && yay -Si "$pkg" &>/dev/null; then
        selected_packages="$selected_packages $pkg"
    else
        echo "⚠️ '$pkg' Not Found in pacman or AUR"
    fi
done

# Confirm
if [ -n "$selected_packages" ]; then
    echo
    echo "It will update: $selected_packages"
    read -p "do you want to continue? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        for pkg in $selected_packages; do
            if pacman -Si "$pkg" &>/dev/null; then
                sudo pacman -S "$pkg"
            elif yay -Si "$pkg" &>/dev/null; then
                yay -S "$pkg"
            fi
        done
    else
        echo "Canceled"
    fi
else
    echo "🚫There is no Pkg(s) to be updated"
fi
