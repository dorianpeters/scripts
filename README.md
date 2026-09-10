# Scripts

This repository contains scripts for setting up development environments across Linux distributions and macOS.

## dev_setup.sh

A cross-platform development setup script that standardizes tool and runtime management using [mise](https://mise.jdx.dev/).

### Supported Platforms
- **macOS** (Apple Silicon & Intel)
- **Ubuntu / Debian / Crostini (ChromeOS Linux)**
- **Fedora / RHEL / CentOS**
- **WSL2** (Windows Subsystem for Linux)
- **openSUSE**

### Core Manager: mise
- **mise**: Automatically installed via `https://mise.run` into `~/.local/bin/mise` (no root or Homebrew required).
- Configured with non-interactive, fast defaults:
  - `upgrade.auto_prune = true`: Automatically removes old, superseded versions during `mise upgrade`.
  - `yes = true`: Suppresses interactive confirmation prompts during tool installations.
  - `all_compile = false`: Prefers fast pre-compiled binaries instead of building from source.
- Persists shell activation in `~/.bashrc` and `~/.zshrc`.

### Tools Installed & Configured
- **JavaScript & Node**:
  - `node@lts`: Modern Node.js runtime.
  - `aube`: Fast, Rust-based Node package manager from the creator of mise (replacing bun and pnpm).
- **Python**:
  - `uv`: Fast Python package and tool manager.
  - Latest stable Python installed and managed via `uv python install`.
- **Git & GitHub**:
  - `git`: Installed via system packages and configured with user details and recommended defaults (`init.defaultBranch main`, `color.ui auto`, `pull.rebase false`).
  - `gh` (GitHub CLI): Prompts to run `gh auth login` to authenticate and automatically generate/upload SSH keys to GitHub.
- **Modern CLI Utilities**:
  - `zoxide`: Smarter `cd` command.
  - `eza`: Modern, active replacement for `exa` / `ls`.
  - `fd`: Fast, user-friendly alternative to `find`.
  - `ripgrep` (`rg`): Extremely fast search alternative to `grep`.
  - `bat`: Syntax-highlighting `cat` clone with Git integration.
  - `sd`: Intuitive find & replace CLI (`sed` alternative).
  - `jq`: Command-line JSON processor.
  - `btop`: Modern terminal resource monitor.
  - `tealdeer` (`tldr`): Ultra-fast simplified man pages.
  - `lazygit`: Simple terminal UI for git commands.
  - `fzf`: Interactive command-line fuzzy finder.

### Personal Information & Configuration
Your personal Git information is decoupled from the script and resolved using the following order of precedence:

1. **Environment Variables**:
   ```bash
   export GIT_NAME="Your Name"
   export GIT_EMAIL="your.email@example.com"
   ./dev_setup.sh
   ```
2. **Configuration File**:
   Copy `.dev_setup.env.example` to `~/.dev_setup.env` or `.dev_setup.env`:
   ```bash
   cp .dev_setup.env.example ~/.dev_setup.env
   # Edit ~/.dev_setup.env with your details
   ```
3. **Existing Git Configuration**:
   Uses existing `user.name` and `user.email` from `git config --global` if present.
4. **Interactive Prompt**:
   If running in an interactive terminal and no details are found, the script prompts for your name and email, with an option to save them to `~/.dev_setup.env`.

---

## js_setup.sh
Installs Node.js using the NodeSource repository on Debian-based systems.

## new_js_setup.sh
Installs Node.js using the fnm (Fast Node Manager) version manager.
