#!/bin/bash

# تأكد من وجود checkupdates
if ! command -v checkupdates &> /dev/null; then
    echo "جارِ تثبيت pacman-contrib..."
    sudo pacman -S --needed pacman-contrib
fi

# تأكد من وجود yay
if ! command -v yay &> /dev/null; then
    echo "⚠️ أداة yay غير مثبتة. هل تريد تثبيتها؟ (y/n): "
    read ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        sudo pacman -S --needed git base-devel
        git clone https://aur.archlinux.org/yay.git
        cd yay && makepkg -si && cd .. && rm -rf yay
    else
        echo "لا يمكن تحديث حزم الـ AUR بدون yay."
    fi
fi

# جلب التحديثات
updates=$(checkupdates 2>/dev/null)

# إضافة تحديثات AUR لو yay موجود
if command -v yay &> /dev/null; then
    aur_updates=$(yay -Qua 2>/dev/null)
    if [ -n "$aur_updates" ]; then
        updates="$updates"$'\n'"$aur_updates"
    fi
fi

# لو مفيش أي تحديثات
if [ -z "$updates" ]; then
    echo "✅ لا توجد تحديثات متاحة."
    exit 0
fi

echo "📦 التحديثات المتاحة:"
echo "$updates" | nl

# إدخال الأرقام المطلوبة
echo
read -p "أدخل أرقام الحزم التي تريد تحديثها (مفصولة بمسافة): " choices

# اختيار الحزم
selected_packages=""
for choice in $choices; do
    pkg=$(echo "$updates" | sed -n "${choice}p" | awk '{print $1}')
    if pacman -Si "$pkg" &>/dev/null; then
        selected_packages="$selected_packages $pkg"
    elif command -v yay &> /dev/null && yay -Si "$pkg" &>/dev/null; then
        selected_packages="$selected_packages $pkg"
    else
        echo "⚠️ الحزمة '$pkg' غير موجودة في المستودعات أو AUR."
    fi
done

# تأكيد التحديث
if [ -n "$selected_packages" ]; then
    echo
    echo "سيتم تحديث: $selected_packages"
    read -p "هل تريد المتابعة؟ (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        for pkg in $selected_packages; do
            if pacman -Si "$pkg" &>/dev/null; then
                sudo pacman -S "$pkg"
            elif yay -Si "$pkg" &>/dev/null; then
                yay -S "$pkg"
            fi
        done
    else
        echo "تم الإلغاء."
    fi
else
    echo "🚫 لا توجد حزم صالحة للتحديث."
fi
