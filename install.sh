#!/bin/bash
set -e

DOTFILES=~/dotfiles

if [ -d "$DOTFILES" ]; then
  rm -rf "$DOTFILES"
fi
git clone https://github.com/catpotato42/dotfiles.git "$DOTFILES"

# List every dotfile/dotdir you want linked, relative to the repo root
LINKS=(
  ".vimrc"
  ".vim/autoload"
  ".vim/colors"
  ".vim/doc"
  ".bashrc"
  ".gitconfig"
  ".tmux.conf"
)

for item in "${LINKS[@]}"; do
  src="$DOTFILES/$item"
  dest="$HOME/$item"

  mkdir -p "$(dirname "$dest")"

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    rm -rf "$dest"
  fi

  ln -s "$src" "$dest"
  echo "Linked $item"
done

echo "dotfiles copied successfully"
