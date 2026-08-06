#!/bin/bash
set -e
DOTFILES=~/dotfiles

if [ -d "$DOTFILES" ]; then
  cd "$HOME"
  rm -rf "$DOTFILES"
fi
git clone https://github.com/catpotato42/dotfiles.git "$DOTFILES"

setup_vim() {
  if ! command -v vim >/dev/null 2>&1; then
    if command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y vim-enhanced 2>/dev/null || echo "vim: dnf install failed, skipped"
    elif command -v apt >/dev/null 2>&1; then
      sudo apt install -y vim 2>/dev/null || echo "vim: apt install failed, skipped"
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -S --noconfirm vim 2>/dev/null || echo "vim: pacman install failed, skipped"
    elif command -v zypper >/dev/null 2>&1; then
      sudo zypper install -y vim 2>/dev/null || echo "vim: zypper install failed, skipped"
    elif command -v apk >/dev/null 2>&1; then
      sudo apk add vim 2>/dev/null || echo "vim: apk install failed, skipped"
    else
      echo "vim: no known package manager, skipped"
    fi
  fi

  if ! command -v vimx >/dev/null 2>&1; then
    if command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y vim-X11 2>/dev/null || echo "vimx: dnf install failed, skipped"
    elif command -v apt >/dev/null 2>&1; then
      sudo apt install -y vim-gtk3 2>/dev/null || echo "vimx: apt install failed, skipped"
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -S --noconfirm gvim 2>/dev/null || echo "vimx: pacman install failed, skipped"
    elif command -v zypper >/dev/null 2>&1; then
      sudo zypper install -y vim-X11 2>/dev/null || echo "vimx: zypper install failed, skipped"
    else
      echo "vimx: no known package manager or package unavailable, skipped"
    fi
  fi
}

setup_vim || true

# add files as "path in repo:path in $HOME"
LINKS=(
  "vim/.vimrc:.vimrc"
  "vim/autoload:.vim/autoload"
  "vim/colors:.vim/colors"
  "vim/doc:.vim/doc"
  "bash/.bashrc:.bashrc"
  ".gitconfig:.gitconfig"
)

for pair in "${LINKS[@]}"; do
  src="$DOTFILES/${pair%%:*}"
  dest="$HOME/${pair##*:}"

  mkdir -p "$(dirname "$dest")"

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    rm -rf "$dest"
  fi

  ln -s "$src" "$dest"
  echo "Linked ${pair##*:}"
done

setup_keyboard() {
  local applied=0
  local SUDO=""

  if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
  elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    SUDO="sudo -n"
  else
    SUDO="none"
  fi

  if command -v gsettings >/dev/null 2>&1 && [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    if gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us+dvp')]" 2>/dev/null; then
      gsettings set org.gnome.desktop.input-sources current 0 2>/dev/null || true
      echo "keyboard: set via gsettings (persistent, GNOME)"
      applied=1
    fi
  fi

  if [ "$SUDO" != "none" ] && command -v localectl >/dev/null 2>&1; then
    if $SUDO localectl set-x11-keymap us "" dvp 2>/dev/null; then
      echo "keyboard: set via localectl (persistent, system-wide X11/Wayland)"
      applied=1
    fi
    if localectl list-keymaps 2>/dev/null | grep -qx dvorak-programmer; then
      if $SUDO localectl set-keymap dvorak-programmer 2>/dev/null; then
        echo "keyboard: console keymap set (persistent)"
        applied=1
      fi
    fi
  fi

  if [ "$applied" -eq 0 ] && [ -n "${DISPLAY:-}" ] && command -v setxkbmap >/dev/null 2>&1; then
    if setxkbmap us -variant dvp 2>/dev/null; then
      echo "keyboard: set via setxkbmap (session only)"
      applied=1
    fi
  fi

  if [ "$applied" -eq 0 ] && command -v loadkeys >/dev/null 2>&1 && [ -w /dev/console ]; then
    if loadkeys dvorak-programmer 2>/dev/null; then
      echo "keyboard: console keymap loaded (session only)"
      applied=1
    fi
  fi

  [ "$applied" -eq 1 ] || echo "keyboard: no usable mechanism, skipped"
}

setup_keyboard || true

source ~/.bashrc
echo "dotfiles installed successfully"
