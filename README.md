# Scripts

This repository contains scripts for setting up development environments across Linux distributions, macOS, and Windows.

## dev_setup.sh (Linux & macOS)

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
  - `aube`: Fast Node.js package manager.
- **Python**:
  - `uv`: Fast Python package and tool manager.
  - Latest stable Python installed and managed via `uv python install`.
- **Git & GitHub**:
  - `git`: Installed via system packages and configured with user details and recommended defaults (`init.defaultBranch main`, `color.ui auto`, `pull.rebase false`).
  - `gh` (GitHub CLI): Prompts to run `gh auth login` to authenticate and automatically generate/upload SSH keys to GitHub.
- **Modern CLI Utilities & AI**:
  - `eza`: Modern, active replacement for `exa` / `ls`.
  - `btop`: Modern terminal resource monitor.
  - `htop`: Interactive process viewer.
  - `fastfetch`: Fast, customizable system information tool.
  - `wl-clipboard` & `xclip` (Linux): Clipboard utilities for Wayland and X11 (`gh auth login`, agent clipboard pasting, etc.).
  - `antigravity` (`agy`): Gemini CLI (installed via native installer: `curl -fsSL https://antigravity.google/cli/install.sh | bash`).

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

## win_setup.ps1 (Windows)

A native Windows PowerShell equivalent of `dev_setup.sh` for Windows 10 and Windows 11 using `winget` and [mise](https://mise.jdx.dev/).

### Usage
Run in PowerShell (5.1 or PowerShell 7+):
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\win_setup.ps1
```

### What It Sets Up
- **System Packages via `winget`**:
  - `Git.Git`: Git for Windows.
  - `jdx.mise`: `mise` tool and runtime manager, configured in your PowerShell `$PROFILE` (`(&mise activate pwsh) | Out-String | Invoke-Expression`).
  - `aristocratos.btop4win`: Native Windows port of `btop++` (`btop`).
- **Developer Tools via `mise`**:
  - **JavaScript & Node**: `node@lts`, `pnpm`, `aube`.
  - **Python**: `uv` + latest stable Python (`uv python install`).
  - **GitHub**: `gh` (with interactive `gh auth login` prompt).
  - **Modern CLI Utilities**: `eza`, `fastfetch`, and `bottom` (`btm` — cross-platform process/system monitor with `btm --basic` `htop` mode).
- **AI CLI**:
  - `antigravity` (`agy`): Installed via the native Windows PowerShell installer (`irm https://antigravity.google/cli/install.ps1 | iex`).
- **Git Configuration**:
  - Supports the same `.dev_setup.env` file (`~/.dev_setup.env` or `.dev_setup.env`), `GIT_NAME` / `GIT_EMAIL` environment variables, existing `git config --global`, or interactive prompt.
