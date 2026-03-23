#!/bin/bash

# =============================================================================
# Dotfiles Bootstrap Script
# Automatically detects hardware and configures the development environment
# Run this after cloning the dotfiles repo on a new machine
# =============================================================================

set -e

DOTFILES_DIR="$HOME/dotfiles"

echo ""
echo "====================================="
echo "  Dotfiles Bootstrap"
echo "====================================="
echo ""

# -----------------------------------------------------------------------------
# Step 1 — Git configuration
# -----------------------------------------------------------------------------
echo ">> Configuring Git..."

read -p "   Enter your full name: " GIT_NAME
read -p "   Enter your GitHub email: " GIT_EMAIL

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main
git config --global core.autocrlf input

echo "   Git configured."
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
    # Change default shell to Zsh
    ZSH_PATH=$(which zsh)
    if chsh -s "$ZSH_PATH" 2>/dev/null; then
        echo "   Default shell changed to Zsh."
    else
        echo "   Could not change shell automatically — run: chsh -s $(which zsh)"
    fi
    echo "   Oh My Zsh installed."
else
    echo ">> Oh My Zsh already installed, skipping."
fi
echo ""

# -----------------------------------------------------------------------------
# Step 4 — Create symlinks (after Oh My Zsh to prevent overwrite)
# -----------------------------------------------------------------------------
echo ">> Creating symlinks..."

ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"

echo "   Symlinks created."
echo ""

# -----------------------------------------------------------------------------
# Step 5 — Install Zsh plugins
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
# Step 6 — Install Starship
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
# Step 7 — Install nvm and Node.js
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
# Step 8 — Install Python
# -----------------------------------------------------------------------------
echo ">> Installing Python..."
sudo apt install -y python3 python3-pip python3-venv
echo "   Python installed."
echo ""

# -----------------------------------------------------------------------------
# Step 9 — Install Docker
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
# Step 10 — Install AWS CLI
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
# Step 11 — Install GitHub CLI
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
# Step 12 — Install Ollama
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
# Step 13 — Hardware detection and model selection
# -----------------------------------------------------------------------------
echo ">> Detecting hardware..."

OLLAMA_MODEL=""
CONTEXT_LENGTH=""
AI_ALIAS=""
CPU_ONLY=false

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
            OLLAMA_MODEL="glm-4.7-flash"
            CONTEXT_LENGTH=8192
        else
            OLLAMA_MODEL="glm-4.7-flash"
            CONTEXT_LENGTH=4096
        fi
        return 0
    fi
    return 1
}

detect_amd() {
    if lspci 2>/dev/null | grep -i "amd" | grep -i "vga\|3d\|display" &> /dev/null; then
        if command -v rocm-smi &> /dev/null; then
            VRAM=$(rocm-smi --showmeminfo vram 2>/dev/null | awk '/Total Memory/ {print int($NF/1024/1024)}' | head -1)
        else
            VRAM=$(lspci -v 2>/dev/null | grep -A 10 -i "amd" | grep -i "prefetchable" | grep -oP '[0-9]+(?=M)' | sort -n | tail -1)
        fi
        VRAM=${VRAM:-0}
        echo "   AMD GPU detected — ${VRAM}MB VRAM"
        if [ "$VRAM" -ge 24000 ]; then
            OLLAMA_MODEL="glm-4.7-flash"
            CONTEXT_LENGTH=32000
        elif [ "$VRAM" -ge 16000 ]; then
            OLLAMA_MODEL="glm-4.7-flash"
            CONTEXT_LENGTH=16000
        elif [ "$VRAM" -ge 8000 ]; then
            OLLAMA_MODEL="glm-4.7-flash"
            CONTEXT_LENGTH=8192
        else
            OLLAMA_MODEL="glm-4.7-flash"
            CONTEXT_LENGTH=4096
        fi
        return 0
    fi
    return 1
}

detect_intel_arc() {
    if lspci 2>/dev/null | grep -i "intel arc" &> /dev/null; then
        echo "   Intel Arc GPU detected"
        OLLAMA_MODEL="glm-4.7-flash"
        CONTEXT_LENGTH=8192
        return 0
    fi
    return 1
}

detect_cpu_only() {
    RAM=$(free -m | awk '/^Mem:/{print $2}')
    echo "   No discrete GPU detected — CPU only, ${RAM}MB RAM"
    echo "   Claude Code via Ollama is not viable on CPU-only hardware"
    echo "   Recommendation: Use Cline extension in Cursor + Claude.ai in browser"
    CPU_ONLY=true
    OLLAMA_MODEL=""
    CONTEXT_LENGTH=""
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
# Step 14 — Pull and configure Ollama model
# -----------------------------------------------------------------------------
if [ -n "$OLLAMA_MODEL" ]; then
    echo ">> Setting up Ollama model: $OLLAMA_MODEL"
    ollama pull "$OLLAMA_MODEL"

    MODELFILE="/tmp/Modelfile"
    echo "FROM $OLLAMA_MODEL" > "$MODELFILE"
    echo "PARAMETER num_ctx $CONTEXT_LENGTH" >> "$MODELFILE"
    ollama create dev-cc -f "$MODELFILE"
    rm "$MODELFILE"

    AI_ALIAS="alias ai='claude --model dev-cc --dangerously-skip-permissions'"
    echo "   Model configured."
else
    AI_ALIAS="# ai alias not configured — CPU only machine, use Cline + Claude.ai instead"
fi
echo ""

# -----------------------------------------------------------------------------
# Step 15 — Install Claude Code and claude-launcher
# -----------------------------------------------------------------------------
if [ "$CPU_ONLY" = false ]; then
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
else
    echo ">> Skipping Claude Code — CPU only machine."
    echo "   Install Cline extension in Cursor after setup."
fi
echo ""

# -----------------------------------------------------------------------------
# Step 16 — Generate .zshrc.local
# -----------------------------------------------------------------------------
echo ">> Generating .zshrc.local..."

cat > "$HOME/.zshrc.local" << EOF
# Machine-specific configuration
# Auto-generated by install.sh on $(date)
# Hardware: $(lscpu | grep "Model name" | sed 's/Model name:[ \t]*//')

# Ollama context window
export OLLAMA_CONTEXT_LENGTH=${CONTEXT_LENGTH:-0}

# Claude Code launcher
$AI_ALIAS

# Start SSH agent and add key automatically
eval "\$(ssh-agent -s)" > /dev/null 2>&1
ssh-add ~/.ssh/id_ed25519 2>/dev/null
EOF

echo "   .zshrc.local generated."
echo ""

# -----------------------------------------------------------------------------
# Step 17 — Install Cursor extensions
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
    echo ">> Cursor not detected in WSL2 — skipping extensions."
    echo "   After installing Cursor on Windows and connecting to WSL2,"
    echo "   run: cursor --install-extension <extension-id> for each extension."
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
echo "  2. Generate SSH key: ssh-keygen -t ed25519 -C '$GIT_EMAIL'"
echo "  3. Add SSH key to GitHub: cat ~/.ssh/id_ed25519.pub"
echo "  4. Authenticate GitHub CLI: gh auth login"
if [ "$CPU_ONLY" = true ]; then
echo "  5. Install Cline extension in Cursor for AI coding assistance"
echo "  6. Use Claude.ai in browser for planning and architecture"
else
echo "  5. Test Claude Code: cd ~/projects && mkdir test && cd test && ai"
fi
echo ""
