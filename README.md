# Scripts

This repository contains scripts for setting up development environments across Linux distributions and macOS.

## dev_setup.sh

A cross-platform development setup script that standardizes tool management using [Homebrew](https://brew.sh/).

### Supported Platforms
- **macOS** (Apple Silicon & Intel)
- **Ubuntu / Debian / Crostini (ChromeOS Linux)**
- **Fedora / RHEL / CentOS**
- **WSL2** (Windows Subsystem for Linux)
- **openSUSE**

### Tools Installed & Configured
- **Homebrew**: Automatically bootstrapped (including system prerequisites on Linux) if missing.
- **git**: Installed via Homebrew, configured with user details and recommended defaults (`init.defaultBranch main`, `color.ui auto`, `pull.rebase false`).
- **gh** (GitHub CLI): Installed via Homebrew; prompts to run `gh auth login` to authenticate and automatically generate/upload SSH keys to GitHub.
- **bun**: Fast all-in-one JavaScript/TypeScript runtime and package manager installed via Homebrew.
- **uv**: Fast Python package manager installed via Homebrew.
- **Python**: Latest stable Python installed and managed via `uv python install`.

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
