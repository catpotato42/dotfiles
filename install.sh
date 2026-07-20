#!/bin/bash
set -e
DOTFILES=~/dotfiles

if [ -d "$DOTFILES" ]; then
  cd "$HOME"
  rm -rf "$DOTFILES"
fi
git clone git@github.com:catpotato42/dotfiles.git "$DOTFILES"

# add files as "path in repo:path in $HOME"
LINKS=(
  "vim/.vimrc:.vimrc"
  "vim/autoload:.vim/autoload"
  "vim/colors:.vim/colors"
  "vim/doc:.vim/doc"
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

echo "dotfiles installed successfully"
