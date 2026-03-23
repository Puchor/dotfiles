#!/bin/bash

# =============================================================================
# Dotfiles Bootstrap Script
# Automatically detects hardware and configures the development environment
# =============================================================================

set -e  # Exit on any error

DOTFILES_DIR="$HOME/dotfiles"

echo ""
echo "====================================="
echo "  Dotfiles Bootstrap"
echo "====================================="
echo ""

# -----------------------------------------------------------------------------
# Step 1 — Create symlinks
# -----------------------------------------------------------------------------
echo ">> Creating symlinks..."

ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"

echo "   Symlinks created."
echo ""

# -----------------------------------------------------------------------------
# Step 2 — Install core packages
# -----------------------------------------------------------------------------
echo ">> Installing core packages..."

sudo apt update -qq
sudo apt install -y curl wget git build-essential zsh zstd unzip pciutils

echo "   Core packages installed."
echo ""

# -----------------------------------------------------------------------------
# Step 3 — Install Oh My Zsh
# -----------------------------------------------------------------------------
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo ">> Installing Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    chsh -s $(which zsh)
    echo "   Oh My Zsh installed."
else
    echo ">> Oh My Zsh already installed, skipping."
fi
echo ""

# -----------------------------------------------------------------------------
# Step 4 — Install Zsh plugins
# -----------------------------------------------------------------------------
echo ">> Installing Zsh plugins..."

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

echo "   Plugins installed."
echo ""

# -----------------------------------------------------------------------------
# Step 5 — Install Starship
# -----------------------------------------------------------------------------
if ! command -v starship &> /dev/null; then
    echo ">> Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
    echo "   Starship installed."
else
    echo ">> Starship already installed, skipping."
fi
echo ""

# -----------------------------------------------------------------------------
# Step 6 — Install nvm and Node.js
# -----------------------------------------------------------------------------
if [ ! -d "$HOME/.nvm" ]; then
    echo ">> Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
    echo "   nvm and Node.js installed."
else
    echo ">> nvm already installed, skipping."
fi
echo ""

# -----------------------------------------------------------------------------
# Step 7 — Install Python
# -----------------------------------------------------------------------------
echo ">> Installing Python..."
sudo apt install -y python3 python3-pip python3-venv
echo "   Python installed."
echo ""

# -----------------------------------------------------------------------------
# Step 8 — Install Docker
# -----------------------------------------------------------------------------
if ! command -v docker &> /dev/null; then
    echo ">> Installing Docker..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update -qq
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker $USER
    echo "   Docker installed."
else
    echo ">> Docker already installed, skipping."
fi
echo ""

# -----------------------------------------------------------------------------
# Step 9 — Install AWS CLI
# -----------------------------------------------------------------------------
if ! command -v aws &> /dev/null; then
    echo ">> Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    unzip /tmp/awscliv2.zip -d /tmp
    sudo /tmp/aws/install
    rm -rf /tmp/awscliv2.zip /tmp/aws
    echo "   AWS CLI installed."
else
    echo ">> AWS CLI already installed, skipping."
fi
echo ""

# -----------------------------------------------------------------------------
# Step 10 — Install GitHub CLI
# -----------------------------------------------------------------------------
if ! command -v gh &> /dev/null; then
    echo ">> Installing GitHub CLI..."
    sudo apt install -y gh
    echo "   GitHub CLI installed."
else
    echo ">> GitHub CLI already installed, skipping."
fi
echo ""

# -----------------------------------------------------------------------------
# Step 11 — Install Ollama
# -----------------------------------------------------------------------------
if ! command -v ollama &> /dev/null; then
    echo ">> Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
    echo "   Ollama installed."
else
    echo ">> Ollama already installed, skipping."
fi
echo ""

# -----------------------------------------------------------------------------
# Step 12 — Hardware detection and model selection
# -----------------------------------------------------------------------------
echo ">> Detecting hardware..."

OLLAMA_MODEL=""
CONTEXT_LENGTH=""
AI_ALIAS=""

detect_nvidia() {
    if command -v nvidia-smi &> /dev/null; then
        VRAM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1 | tr -d ' ')
        echo "   Nvidia GPU detected — ${VRAM}MB VRAM"
        if [ "$VRAM" -ge 24000 ]; then
            OLLAMA_MODEL="glm-4.7-flash"
            CONTEXT_LENGTH=32000
        elif [ "$VRAM" -ge 16000 ]; then
            OLLAMA_MODEL="glm-4.7-flash"
            CONTEXT_LENGTH=16000
        elif [ "$VRAM" -ge 8000 ]; then
            OLLAMA_MODEL="qwen2.5-coder:7b"
            CONTEXT_LENGTH=8192
        else
            OLLAMA_MODEL="qwen2.5-coder:3b"
            CONTEXT_LENGTH=4096
        fi
        return 0
    fi
    return 1
}

detect_amd() {
    if lspci 2>/dev/null | grep -i "amd" | grep -i "vga\|3d\|display" &> /dev/null; then
        echo "   AMD GPU detected — attempting ROCm path"
        OLLAMA_MODEL="qwen2.5-coder:7b"
        CONTEXT_LENGTH=8192
        return 0
    fi
    return 1
}

detect_intel_arc() {
    if lspci 2>/dev/null | grep -i "intel arc" &> /dev/null; then
        echo "   Intel Arc GPU detected"
        OLLAMA_MODEL="qwen2.5-coder:7b"
        CONTEXT_LENGTH=8192
        return 0
    fi
    return 1
}

detect_cpu_only() {
    RAM=$(free -m | awk '/^Mem:/{print $2}')
    echo "   No discrete GPU detected — CPU only, ${RAM}MB RAM"
    if [ "$RAM" -ge 12000 ]; then
        OLLAMA_MODEL="qwen2.5-coder:3b"
        CONTEXT_LENGTH=2048
    else
        echo "   Insufficient RAM for local AI — skipping Ollama model setup"
        echo "   Use Claude.ai in browser for AI assistance"
        OLLAMA_MODEL=""
        CONTEXT_LENGTH=""
    fi
}

if ! detect_nvidia; then
    if ! detect_amd; then
        if ! detect_intel_arc; then
            detect_cpu_only
        fi
    fi
fi

echo ""

# -----------------------------------------------------------------------------
# Step 13 — Pull and configure Ollama model
# -----------------------------------------------------------------------------
if [ -n "$OLLAMA_MODEL" ]; then
    echo ">> Setting up Ollama model: $OLLAMA_MODEL"
    ollama pull "$OLLAMA_MODEL"

    # Create custom model with correct context window
    MODELFILE="/tmp/Modelfile"
    echo "FROM $OLLAMA_MODEL" > "$MODELFILE"
    echo "PARAMETER num_ctx $CONTEXT_LENGTH" >> "$MODELFILE"
    ollama create dev-cc -f "$MODELFILE"
    rm "$MODELFILE"

    AI_ALIAS="alias ai='claude --model dev-cc --dangerously-skip-permissions'"
    echo "   Model configured."
else
    AI_ALIAS="# ai alias not configured — no suitable GPU/RAM detected"
fi
echo ""

# -----------------------------------------------------------------------------
# Step 14 — Install Claude Code and claude-launcher
# -----------------------------------------------------------------------------
if ! command -v claude &> /dev/null; then
    echo ">> Installing Claude Code..."
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    npm install -g @anthropic-ai/claude-code
    npm install -g claude-launcher
    echo "   Claude Code installed."
else
    echo ">> Claude Code already installed, skipping."
fi
echo ""

# -----------------------------------------------------------------------------
# Step 15 — Generate .zshrc.local
# -----------------------------------------------------------------------------
echo ">> Generating .zshrc.local..."

cat > "$HOME/.zshrc.local" << EOF
# Machine-specific configuration
# Auto-generated by install.sh on $(date)
# Hardware: $(lscpu | grep "Model name" | sed 's/Model name:[ \t]*//')

# Ollama context window
export OLLAMA_CONTEXT_LENGTH=$CONTEXT_LENGTH

# Claude Code launcher
$AI_ALIAS
EOF

echo "   .zshrc.local generated."
echo ""

# -----------------------------------------------------------------------------
# Step 16 — Install Cursor extensions
# -----------------------------------------------------------------------------
if command -v cursor &> /dev/null; then
    echo ">> Installing Cursor extensions..."
    cursor --install-extension bradlc.vscode-tailwindcss
    cursor --install-extension ckolkman.vscode-postgres
    cursor --install-extension dbaeumer.vscode-eslint
    cursor --install-extension eamodio.gitlens
    cursor --install-extension esbenp.prettier-vscode
    cursor --install-extension humao.rest-client
    cursor --install-extension ms-azuretools.vscode-containers
    cursor --install-extension ms-azuretools.vscode-docker
    cursor --install-extension prisma.prisma
    echo "   Extensions installed."
else
    echo ">> Cursor not found — skipping extensions."
fi
echo ""

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
echo "====================================="
echo "  Bootstrap complete!"
echo "====================================="
echo ""
echo "Next steps:"
echo "  1. Restart your terminal"
echo "  2. Run 'gh auth login' to authenticate GitHub CLI"
echo "  3. Generate SSH key: ssh-keygen -t ed25519 -C 'your@email.com'"
echo "  4. Add SSH key to GitHub"
echo ""
