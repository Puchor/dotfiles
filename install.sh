#!/bin/bash

DOTFILES_DIR="$HOME/dotfiles"

echo "Setting up dotfiles..."

# Create symlinks
ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"

echo "Dotfiles installed successfully."
