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
  - `pnpm`: Fast, disk space efficient package manager.
- **Python**:
  - `uv`: Fast Python package and tool manager.
  - Latest stable Python installed and managed via `uv python install`.
- **Git & GitHub**:
  - `git`: Installed via system packages and configured with user details and recommended defaults (`init.defaultBranch main`, `color.ui auto`, `pull.rebase false`).
  - `gh` (GitHub CLI): Prompts to run `gh auth login` to authenticate and automatically generate/upload SSH keys to GitHub.
- **Modern CLI Utilities**:
  - `eza`: Modern, active replacement for `exa` / `ls`.
  - `btop`: Modern terminal resource monitor.
  - `htop`: Interactive process viewer.
  - `fastfetch`: Fast, customizable system information tool.
  - `antigravity` (`agy`): Gemini CLI

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
