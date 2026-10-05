#!/bin/bash
set -e
DOTFILES="$HOME/dotfiles"
REPO_URL="https://github.com/catpotato42/dotfiles.git"

pkg_install() {
  # pkg_install <label> <dnf pkgs> <apt pkgs> [pacman pkgs] [zypper pkgs]
  local label="$1" dnf_p="$2" apt_p="$3" pac_p="${4:-}" zyp_p="${5:-}"
  if command -v dnf >/dev/null 2>&1 && [ -n "$dnf_p" ]; then
    sudo dnf install -y $dnf_p 2>/dev/null && return 0
  elif command -v apt >/dev/null 2>&1 && [ -n "$apt_p" ]; then
    sudo apt install -y $apt_p 2>/dev/null && return 0
  elif command -v pacman >/dev/null 2>&1 && [ -n "$pac_p" ]; then
    sudo pacman -S --noconfirm $pac_p 2>/dev/null && return 0
  elif command -v zypper >/dev/null 2>&1 && [ -n "$zyp_p" ]; then
    sudo zypper install -y $zyp_p 2>/dev/null && return 0
  fi
  echo "$label: package install failed or no known package manager, skipped"
  return 1
}

if [ -d "$DOTFILES" ]; then
  cd "$HOME"
  rm -rf "$DOTFILES"
fi
git clone --recurse-submodules "$REPO_URL" "$DOTFILES"

#
# Packages
#
setup_vim() {
  if ! command -v vim >/dev/null 2>&1; then
    pkg_install vim "vim-enhanced" "vim" "vim" "vim" || true
  fi

  # Variants built with +clipboard. On Fedora that binary is vimx (vim-X11);
  # on Debian/Ubuntu it is vim.gtk3 (vim-gtk3). Both run in the terminal.
  if ! command -v vimx >/dev/null 2>&1 && ! command -v vim.gtk3 >/dev/null 2>&1; then
    pkg_install "vim clipboard build" "vim-X11" "vim-gtk3" "gvim" "vim-X11" || true
  fi
}

setup_lsp() {
  # C/C++ diagnostics and completion
  if ! command -v clangd >/dev/null 2>&1; then
    pkg_install clangd "clang-tools-extra" "clangd" "clang" "clang-tools-extra" || true
  fi

  # Python diagnostics and completion. Distro package first; pipx second,
  # because recent Debian/Ubuntu and Fedora refuse `pip install --user` into a
  # system Python (PEP 668, "externally-managed-environment").
  if ! command -v pylsp >/dev/null 2>&1; then
    if ! pkg_install pylsp \
         "python3-lsp-server python3-lsp-ruff" \
         "python3-pylsp python3-pylsp-ruff" \
         "python-lsp-server" \
         "python3-lsp-server"; then
      if ! command -v pipx >/dev/null 2>&1; then
        pkg_install pipx "pipx" "pipx" "python-pipx" "python3-pipx" || true
      fi
      if command -v pipx >/dev/null 2>&1; then
        pipx install python-lsp-server 2>/dev/null \
          && pipx inject python-lsp-server python-lsp-ruff 2>/dev/null \
          && echo "pylsp: installed via pipx" \
          || echo "pylsp: pipx install failed, Python LSP skipped"
      else
        echo "pylsp: not installed. Install python-lsp-server manually for Python LSP."
      fi
    fi
  fi

  # Generates compile_commands.json for make-based C/C++ projects, which is
  # what clangd needs to resolve includes and flags correctly.
  if ! command -v bear >/dev/null 2>&1; then
    pkg_install bear "bear" "bear" "bear" "bear" || true
  fi
}

setup_vim || true
setup_lsp || true

#
# Symlinks: "path in repo:path in $HOME"
#
LINKS=(
  "vim/.vimrc:.vimrc"
  "vim/autoload:.vim/autoload"
  "vim/colors:.vim/colors"
  "vim/doc:.vim/doc"
  "vim/after:.vim/after"
  "vim/pack:.vim/pack"
  "bash/.bashrc:.bashrc"
  ".gitconfig:.gitconfig"
  "clangd/config.yaml:.config/clangd/config.yaml"
)

for pair in "${LINKS[@]}"; do
  src="$DOTFILES/${pair%%:*}"
  dest="$HOME/${pair##*:}"

  if [ ! -e "$src" ]; then
    echo "skipped ${pair##*:} (missing $src)"
    continue
  fi

  mkdir -p "$(dirname "$dest")"

  if [ -L "$dest" ]; then
    # A symlink holds no content of its own, safe to replace
    rm -f "$dest"
  elif [ -e "$dest" ]; then
    # A real file or directory. Never delete it. This is how the distro's
    # default ~/.bashrc survives a first run on Ubuntu.
    mv "$dest" "$dest.bak"
    echo "backed up ${pair##*:} -> ${pair##*:}.bak"
  fi

  ln -s "$src" "$dest"
  echo "Linked ${pair##*:}"
done

mkdir -p "$HOME/.vim/undo"

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

# Deliberately no `source ~/.bashrc` here: sourcing an interactive rc from a
# non-interactive script does nothing useful, and under `set -e` any nonzero
# line in it kills the installer before it reports success.
echo
echo "dotfiles installed successfully. Open a new shell to pick up ~/.bashrc."
