# Dotfiles

Personal development environment configuration for WSL2 Ubuntu.

## What's included
- `.zshrc` — Zsh configuration, Oh My Zsh, Starship, nvm, plugins, environment variables
- `.gitconfig` — Git global configuration

## Setup on a new machine
1. Clone this repo: `git clone git@github.com:Puchor/dotfiles.git ~/dotfiles`
2. Run the install script: `cd ~/dotfiles && ./install.sh`
3. Restart your terminal

## Machine-specific configuration
Each machine can have a `~/.zshrc.local` file for local overrides that 
won't affect other machines. This file is never committed to the repo.
Create `~/.zshrc.local` on any machine and add any settings that should
only apply to that machine — different models, paths, or aliases.

## Tools configured
- Zsh + Oh My Zsh
- Starship prompt
- nvm (Node Version Manager)
- zsh-autosuggestions
- zsh-syntax-highlighting
- Git
- Docker
- AWS CLI
- Ollama + Claude Code (running locally with qwen3-coder-cc, 32k context)
# Last updated: Sun Mar 22 23:28:20 EDT 2026
