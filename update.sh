#!/bin/bash

# =============================================================================
# Dotfiles Update Script
# Keeps your development environment up to date
# Run periodically to update all tools and pull latest dotfiles config
# =============================================================================

echo ""
echo "====================================="
echo "  Dotfiles Update"
echo "====================================="
echo ""

# -----------------------------------------------------------------------------
# Step 1 — Pull latest dotfiles
# -----------------------------------------------------------------------------
echo ">> Pulling latest dotfiles..."
cd "$HOME/dotfiles"
git pull
echo "   Dotfiles updated."
echo ""

# -----------------------------------------------------------------------------
# Step 2 — Update Ubuntu packages
# -----------------------------------------------------------------------------
echo ">> Updating Ubuntu packages..."
sudo apt update -qq
sudo apt upgrade -y
sudo apt autoremove -y
echo "   Ubuntu packages updated."
echo ""

# -----------------------------------------------------------------------------
# Step 3 — Update Oh My Zsh
# -----------------------------------------------------------------------------
echo ">> Updating Oh My Zsh..."
"$HOME/.oh-my-zsh/tools/upgrade.sh" 2>/dev/null || echo "   Oh My Zsh update skipped."
echo ""

# -----------------------------------------------------------------------------
# Step 4 — Update Zsh plugins
# -----------------------------------------------------------------------------
echo ">> Updating Zsh plugins..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git -C "$ZSH_CUSTOM/plugins/zsh-autosuggestions" pull
fi

if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git -C "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" pull
fi

echo "   Plugins updated."
echo ""

# -----------------------------------------------------------------------------
# Step 5 — Update Starship
# -----------------------------------------------------------------------------
echo ">> Updating Starship..."
curl -sS https://starship.rs/install.sh | sh -s -- --yes 2>/dev/null
echo "   Starship updated."
echo ""

# -----------------------------------------------------------------------------
# Step 6 — Update Node.js
# -----------------------------------------------------------------------------
echo ">> Updating Node.js..."
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm alias default lts/*
echo "   Node.js updated."
echo ""

# -----------------------------------------------------------------------------
# Step 7 — Update npm
# -----------------------------------------------------------------------------
echo ">> Updating npm..."
npm install -g npm@latest
echo "   npm updated."
echo ""

# -----------------------------------------------------------------------------
# Step 8 — Update Claude Code
# -----------------------------------------------------------------------------
echo ">> Updating Claude Code..."
npm install -g @anthropic-ai/claude-code
echo "   Claude Code updated."
echo ""

# -----------------------------------------------------------------------------
# Step 9 — Update AWS CLI
# -----------------------------------------------------------------------------
if command -v aws &> /dev/null; then
    echo ">> Updating AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    unzip -q /tmp/awscliv2.zip -d /tmp
    sudo /tmp/aws/install --update
    rm -rf /tmp/awscliv2.zip /tmp/aws
    echo "   AWS CLI updated."
else
    echo ">> AWS CLI not installed — skipping."
fi
echo ""

# -----------------------------------------------------------------------------
# Step 10 — Update Ollama
# -----------------------------------------------------------------------------
if command -v ollama &> /dev/null; then
    echo ">> Updating Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
    echo "   Ollama updated."
else
    echo ">> Ollama not installed — skipping."
fi
echo ""

# -----------------------------------------------------------------------------
# Step 11 — Update qwen3-coder:30b base model
# -----------------------------------------------------------------------------
if command -v ollama &> /dev/null && ollama list | grep -q "qwen3-coder:30b"; then
    echo ">> Updating qwen3-coder:30b..."
    ollama pull qwen3-coder:30b
    echo "   qwen3-coder:30b updated."
else
    echo ">> qwen3-coder:30b not installed — skipping."
fi
echo ""

# -----------------------------------------------------------------------------
# Step 12 — Update Cursor extensions
# -----------------------------------------------------------------------------
if command -v cursor &> /dev/null; then
    echo ">> Updating Cursor extensions..."
    cursor --install-extension bradlc.vscode-tailwindcss
    cursor --install-extension ckolkman.vscode-postgres
    cursor --install-extension dbaeumer.vscode-eslint
    cursor --install-extension eamodio.gitlens
    cursor --install-extension esbenp.prettier-vscode
    cursor --install-extension humao.rest-client
    cursor --install-extension ms-azuretools.vscode-containers
    cursor --install-extension ms-azuretools.vscode-docker
    cursor --install-extension prisma.prisma
    cursor --install-extension saoudrizwan.claude-dev
    echo "   Extensions updated."
else
    echo ">> Cursor not detected in WSL2 — skipping extensions."
fi
echo ""

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
echo "====================================="
echo "  Update complete!"
echo "====================================="
echo ""
echo "Restart your terminal to apply all changes."
echo ""
