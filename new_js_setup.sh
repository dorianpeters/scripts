log "Installing fnm (Fast Node Manager) if missing"
if ! command -v fnm >/dev/null 2>&1; then
  curl -fsSL https://fnm.vercel.app/install | bash
fi

# Try common fnm install locations (Linux installer commonly uses ~/.local/share/fnm) [5](https://fnm.vercel.app/install)[6](https://github.com/Schniz/fnm/issues/862)
for d in "$HOME/.local/share/fnm" "$HOME/.fnm" "${XDG_DATA_HOME:-$HOME/.local/share}/fnm"; do
  if [[ -d "$d" ]]; then
    export PATH="$d:$PATH"
  fi
done

command -v fnm >/dev/null 2>&1 || { echo "❌ fnm not found after install."; exit 1; }

# Ensure shell integration for future sessions (bash) [4](https://michaelcharl.es/aubrey/en/code/installing-fnm-on-windows-for-powershell-git-bash-and-command-prompt)[3](https://stackoverflow.com/questions/78606679/unable-to-install-and-use-nodejs-using-fnm)
FNM_BASH_LINE='eval "$(fnm env --use-on-cd --shell bash)"'
grep -qxF "$FNM_BASH_LINE" "$HOME/.bashrc" || echo "$FNM_BASH_LINE" >> "$HOME/.bashrc"

# Load fnm into *this* session too (so the script can use node right now) [3](https://stackoverflow.com/questions/78606679/unable-to-install-and-use-nodejs-using-fnm)[4](https://michaelcharl.es/aubrey/en/code/installing-fnm-on-windows-for-powershell-git-bash-and-command-prompt)
eval "$(fnm env --use-on-cd --shell bash)"

log "Installing Node.js LTS via fnm"
fnm install --lts
fnm use --lts
fnm default --lts

log "Enabling Corepack + pnpm"
corepack enable
corepack prepare pnpm@latest --activate  # common way to get latest pnpm under corepack [7](https://www.freecodecamp.org/news/how-to-use-pnpm/)[8](https://gist.github.com/washopilot/c164fd26d8a180a402b09401399daa86)

log "Adding 'pn' alias to ~/.bash_aliases (only if missing)"
ALIAS_FILE="$HOME/.bash_aliases"
ALIAS_LINE="alias pn=pnpm"
touch "$ALIAS_FILE"
grep -qxF "$ALIAS_LINE" "$ALIAS_FILE" || echo "$ALIAS_LINE" >> "$ALIAS_FILE"

log "Ensuring ~/.bashrc sources ~/.bash_aliases"
SOURCE_SNIPPET='if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi'
grep -qxF "$SOURCE_SNIPPET" "$HOME/.bashrc" || echo "$SOURCE_SNIPPET" >> "$HOME/.bashrc"

log "Verification of Node and pnpm installation"
echo "Node Version: $(node --version)"
echo "pnpm Version: $(pnpm --version)"
``
