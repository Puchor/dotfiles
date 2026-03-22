# Dotfiles

Personal development environment configuration for WSL2 Ubuntu.

## What's included
- `.zshrc` — Zsh configuration, Oh My Zsh, Starship, nvm, plugins, environment variables
- `.gitconfig` — Git global configuration

## Setup on a new machine
1. Clone this repo: `git clone git@github.com:Puchor/dotfiles.git ~/dotfiles`
2. Run the install script: `cd ~/dotfiles && ./install.sh`
3. Restart your terminal

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
