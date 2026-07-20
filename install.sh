#!/bin/bash
set -e
git clone https://github.com/catpotato42/dotfiles.git ~/dotfiles
mkdir -p ~/.vim
ln -s ~/dotfiles/vim/.vimrc ~/.vimrc
ln -s ~/dotfiles/vim/autoload ~/.vim/autoload
ln -s ~/dotfiles/vim/colors ~/.vim/colors
ln -s ~/dotfiles/vim/doc ~/.vim/doc
echo "dotfiles copied successfully"
