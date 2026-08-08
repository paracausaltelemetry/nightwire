#!/usr/bin/env bash

ctf_setup_shells() {
  ctf_install_starship
  ctf_install_terminal_fonts
  ctf_install_cli_shims

  case "$SHELL_MODE" in
    bash)
      ctf_install_blesh
      ctf_configure_readline
      ctf_configure_bash
      ctf_configure_tmux
      ctf_maybe_set_login_shell bash
      ;;
    zsh)
      ctf_configure_zsh
      ctf_configure_tmux
      ctf_maybe_set_login_shell zsh
      ;;
    both)
      ctf_install_blesh
      ctf_configure_readline
      ctf_configure_bash
      ctf_configure_zsh
      ctf_configure_tmux
      ;;
  esac
}

ctf_install_starship() {
  if command -v starship >/dev/null 2>&1; then
    ctf_info "Starship is already installed."
    return 0
  fi

  if ctf_package_available starship; then
    ctf_install_packages starship
  elif ((REMOTE_INSTALLERS)); then
    ctf_warn "Starship package unavailable; using official installer."
    ctf_install_packages curl ca-certificates
    ctf_run_root sh -c "curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b /usr/local/bin"
  else
    ctf_warn "Starship unavailable and remote installers are disabled; skipping Starship."
  fi
}

# Clone a git repo as the target user, preferring an offline cache copy under
# $CACHE_DIR/repos/<name> when present (see: nightwire cache prepare).
ctf_user_clone() {
  local name="$1"
  local url="$2"
  local dest="$3"
  if [[ -d "$dest" ]]; then
    ctf_info "Already present: $dest"
    return 0
  fi
  if [[ -n "$CACHE_DIR" && -d "$CACHE_DIR/repos/$name" ]]; then
    ctf_info "Using cached repo for $name."
    ctf_try_user_shell "cp -a '$CACHE_DIR/repos/$name' '$dest'"
    return 0
  fi
  ctf_try_user_shell "git clone --depth 1 '$url' '$dest'"
}

ctf_install_terminal_fonts() {
  ctf_install_packages fonts-firacode fonts-hack
  ctf_install_nerd_font
}

# Install a pinned Nerd Font so the Starship prompt and eza/exa icon glyphs
# render. Best-effort: archive integrity is checked and, when NERD_FONT_SHA256
# is set, the download is checksum-verified.
ctf_install_nerd_font() {
  local marker=".local/share/fonts/NerdFonts/.nightwire-${NERD_FONT_NAME}-${NERD_FONT_VERSION}"
  if [[ -e "$TARGET_HOME/$marker" ]]; then
    ctf_info "Nerd Font already installed: $NERD_FONT_NAME $NERD_FONT_VERSION"
    return 0
  fi

  ctf_install_packages curl ca-certificates unzip fontconfig
  ctf_warn "Installing $NERD_FONT_NAME Nerd Font ($NERD_FONT_VERSION) for glyph support."
  local url="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/${NERD_FONT_NAME}.zip"
  ctf_try_user_shell "set -e
fdir=\"\$HOME/.local/share/fonts/NerdFonts\"
mkdir -p \"\$fdir\"
tmp=\"\$(mktemp -d)\"
trap 'rm -rf \"\$tmp\"' EXIT
if [ -f '$CACHE_DIR/fonts/${NERD_FONT_NAME}.zip' ]; then
  cp '$CACHE_DIR/fonts/${NERD_FONT_NAME}.zip' \"\$tmp/font.zip\"
else
  curl -fsSL '$url' -o \"\$tmp/font.zip\"
fi
if [ -n '$NERD_FONT_SHA256' ]; then
  printf '%s  %s\n' '$NERD_FONT_SHA256' \"\$tmp/font.zip\" | sha256sum -c -
fi
unzip -tq \"\$tmp/font.zip\" >/dev/null
unzip -oq \"\$tmp/font.zip\" -d \"\$fdir\" -x 'LICENSE*' 'README*' '*.md'
touch \"\$HOME/$marker\"
command -v fc-cache >/dev/null 2>&1 && fc-cache -f \"\$fdir\" >/dev/null 2>&1 || true"
}

# Expose the modern `fd` and `bat` names even on Debian/Kali/Ubuntu, where the
# binaries ship as fdfind/batcat. fzf and assorted tooling expect the short
# names, so a symlink in ~/.local/bin keeps everything consistent.
ctf_install_cli_shims() {
  ctf_try_user_shell 'mkdir -p "$HOME/.local/bin"
if command -v fdfind >/dev/null 2>&1 && [ ! -e "$HOME/.local/bin/fd" ]; then
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi
if command -v batcat >/dev/null 2>&1 && [ ! -e "$HOME/.local/bin/bat" ]; then
  ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
fi'
}

# ble.sh brings fish-style inline autosuggestions and syntax highlighting to
# Bash, mirroring the Zsh experience. It is built from source because no distro
# packages it; the build is best-effort so a failure never blocks the install.
ctf_install_blesh() {
  if [[ -f "$TARGET_HOME/.local/share/blesh/ble.sh" ]]; then
    ctf_info "ble.sh already installed for $TARGET_USER."
    return 0
  fi

  ctf_install_packages git make gawk
  ctf_warn "Building ble.sh from source for Bash autosuggestions and syntax highlighting."
  ctf_try_user_shell "set -e
tmp=\"\$(mktemp -d)\"
trap 'rm -rf \"\$tmp\"' EXIT
if [ -d '$CACHE_DIR/repos/ble.sh' ]; then
  cp -a '$CACHE_DIR/repos/ble.sh' \"\$tmp/ble.sh\"
else
  git clone --recursive --depth 1 https://github.com/akinomyoga/ble.sh.git \"\$tmp/ble.sh\"
fi
make -C \"\$tmp/ble.sh\" install PREFIX=\"\$HOME/.local\""
}

# A tuned ~/.inputrc gives plain Bash sessions (without ble.sh) case-insensitive,
# colored, menu-style completion plus history search on the arrow keys.
ctf_configure_readline() {
  local inputrc="$TARGET_HOME/.inputrc"
  local owner="$TARGET_USER:$(id -gn "$TARGET_USER")"
  local block
  read -r -d '' block <<'EOF' || true
$include /etc/inputrc
set completion-ignore-case on
set completion-map-case on
set show-all-if-ambiguous on
set show-all-if-unmodified on
set menu-complete-display-prefix on
set colored-stats on
set colored-completion-prefix on
set mark-symlinked-directories on
set visible-stats on
set completion-query-items 200
set bell-style none
set echo-control-characters off
"\e[A": history-search-backward
"\e[B": history-search-forward
"\C-p": history-search-backward
"\C-n": history-search-forward
"\e[Z": menu-complete-backward
EOF

  ctf_append_marker_block_root "$inputrc" "readline" "$block" "$owner"
}

ctf_configure_bash() {
  local bashrc="$TARGET_HOME/.bashrc"
  local owner="$TARGET_USER:$(id -gn "$TARGET_USER")"
  local block
  read -r -d '' block <<'EOF' || true
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$HOME/go/bin:$PATH"
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)"
elif [ -x "$HOME/.local/bin/mise" ]; then
  eval "$("$HOME/.local/bin/mise" activate bash)"
fi
if command -v ruby >/dev/null 2>&1; then
  GEM_USER_BIN="$(ruby -rrubygems -e 'print Gem.user_dir' 2>/dev/null)/bin"
  [ -d "$GEM_USER_BIN" ] && export PATH="$GEM_USER_BIN:$PATH"
  unset GEM_USER_BIN
fi
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-$EDITOR}"
export PAGER="${PAGER:-less}"
export LESS="-R"
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=100000
export HISTFILESIZE=200000
export HISTTIMEFORMAT='%F %T '
shopt -s histappend checkwinsize globstar cmdhist autocd cdspell dirspell 2>/dev/null || true
PROMPT_COMMAND="history -a; ${PROMPT_COMMAND:-}"

# ble.sh: fish-style autosuggestions + syntax highlighting for interactive Bash.
if [[ $- == *i* && -r "$HOME/.local/share/blesh/ble.sh" ]]; then
  source "$HOME/.local/share/blesh/ble.sh" --attach=none
  ble-face -s auto_complete fg=240 2>/dev/null || true
fi

# Programmable completion.
if ! shopt -oq posix; then
  if [ -r /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -r /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto'
alias ports='sudo ss -tulpen'
alias myip='curl -fsSL https://ifconfig.me 2>/dev/null || ip addr'
alias serve='python3 -m http.server'
alias path='printf "%s\n" "${PATH//:/\\n}"'
alias scanfast='rustscan --ulimit 5000 --'
alias dc='docker compose'
alias nwnew='nightwire new'
alias nwdoctor='nightwire doctor'
alias nwupdate='nightwire update'
alias nwlabs='nightwire labs'

mkcd() { mkdir -p "$1" && cd "$1" || return; }

extract() {
  if [ ! -f "$1" ]; then
    printf 'extract: %s is not a file\n' "$1" >&2
    return 1
  fi
  case "$1" in
    *.tar.bz2) tar xjf "$1" ;;
    *.tar.gz) tar xzf "$1" ;;
    *.tar.xz) tar xJf "$1" ;;
    *.bz2) bunzip2 "$1" ;;
    *.rar) unrar x "$1" ;;
    *.gz) gunzip "$1" ;;
    *.tar) tar xf "$1" ;;
    *.tbz2) tar xjf "$1" ;;
    *.tgz) tar xzf "$1" ;;
    *.zip) unzip "$1" ;;
    *.7z) 7z x "$1" ;;
    *) printf 'extract: unsupported archive: %s\n' "$1" >&2; return 1 ;;
  esac
}

# Modern CLI replacements when present (icons need the installed Nerd Font).
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -alF --group-directories-first --icons --git'
  alias la='eza -a --group-directories-first --icons'
  alias lt='eza --tree --level=2 --icons'
fi
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"

# fzf: history (Ctrl-R), file (Ctrl-T) and directory (Alt-C) fuzzy pickers.
if command -v fdfind >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'
elif command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
fi
[ -n "${FZF_DEFAULT_COMMAND:-}" ] && export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="--height 45% --layout=reverse --border --info=inline --color=bg+:#1f2a33,fg+:#e5e9f0,hl:#88c0d0,hl+:#8fbcbb,info:#ebcb8b,prompt:#81a1c1,pointer:#bf616a,marker:#a3be8c,border:#4c566a"
if command -v fzf >/dev/null 2>&1; then
  if fzf --bash >/dev/null 2>&1; then
    eval "$(fzf --bash)"
  else
    [ -r /usr/share/doc/fzf/examples/key-bindings.bash ] && . /usr/share/doc/fzf/examples/key-bindings.bash
    [ -r /usr/share/doc/fzf/examples/completion.bash ] && . /usr/share/doc/fzf/examples/completion.bash
    [ -r /usr/share/fzf/key-bindings.bash ] && . /usr/share/fzf/key-bindings.bash
  fi
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

# Context banner for interactive login shells (kept out of every tmux pane).
if [[ $- == *i* ]] && shopt -q login_shell && command -v nightwire >/dev/null 2>&1; then
  nightwire banner
fi

# Attach ble.sh last so it wraps the final key map and prompt.
[[ ${BLE_VERSION-} ]] && ble-attach
EOF

  ctf_append_marker_block_root "$bashrc" "bash-console" "$block" "$owner"
  ctf_write_starship_config
}

ctf_configure_zsh() {
  ctf_install_packages zsh git curl
  ctf_install_oh_my_zsh
  ctf_install_zsh_plugins

  local zshrc="$TARGET_HOME/.zshrc"
  local owner="$TARGET_USER:$(id -gn "$TARGET_USER")"
  local block
  read -r -d '' block <<'EOF' || true
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$HOME/go/bin:$PATH"
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
elif [ -x "$HOME/.local/bin/mise" ]; then
  eval "$("$HOME/.local/bin/mise" activate zsh)"
fi
if command -v ruby >/dev/null 2>&1; then
  GEM_USER_BIN="$(ruby -rrubygems -e 'print Gem.user_dir' 2>/dev/null)/bin"
  [ -d "$GEM_USER_BIN" ] && export PATH="$GEM_USER_BIN:$PATH"
  unset GEM_USER_BIN
fi
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-$EDITOR}"
export PAGER="${PAGER:-less}"
export LESS="-R"
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=100000
export SAVEHIST=100000
setopt append_history share_history inc_append_history hist_ignore_all_dups hist_ignore_space hist_reduce_blanks
setopt autocd auto_pushd pushd_ignore_dups extended_glob interactive_comments no_beep
setopt complete_in_word always_to_end auto_menu

# Oh My Zsh: load the framework (aliases/completions) with the prompt left to
# Starship. ZSH_THEME is empty on purpose.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
zstyle ':omz:update' mode disabled
plugins=(git sudo docker docker-compose)
[[ -r "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

ZNW_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# zsh-completions: extend fpath before compinit runs.
[[ -d "$ZNW_CUSTOM/plugins/zsh-completions/src" ]] && fpath=("$ZNW_CUSTOM/plugins/zsh-completions/src" $fpath)
[[ -d /usr/share/zsh/vendor-completions ]] && fpath=(/usr/share/zsh/vendor-completions $fpath)

autoload -Uz compinit
mkdir -p "$HOME/.cache/zsh"
compinit -d "$HOME/.cache/zsh/zcompdump"

# Completion styling: case-insensitive matching, colors and a selectable menu.
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{cyan}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'
zstyle ':completion:*' rehash true
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.cache/zsh/zcompcache"

alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias ports='sudo ss -tulpen'
alias myip='curl -fsSL https://ifconfig.me 2>/dev/null || ip addr'
alias serve='python3 -m http.server'
alias scanfast='rustscan --ulimit 5000 --'
alias dc='docker compose'
alias nwnew='nightwire new'
alias nwdoctor='nightwire doctor'
alias nwupdate='nightwire update'
alias nwlabs='nightwire labs'

mkcd() { mkdir -p "$1" && cd "$1" || return; }

# Modern CLI replacements when present (icons need the installed Nerd Font).
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -alF --group-directories-first --icons --git'
  alias la='eza -a --group-directories-first --icons'
  alias lt='eza --tree --level=2 --icons'
fi
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# fzf: history (Ctrl-R), file (Ctrl-T) and directory (Alt-C) fuzzy pickers.
if command -v fdfind >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'
elif command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
fi
[[ -n "${FZF_DEFAULT_COMMAND:-}" ]] && export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="--height 45% --layout=reverse --border --info=inline --color=bg+:#1f2a33,fg+:#e5e9f0,hl:#88c0d0,hl+:#8fbcbb,info:#ebcb8b,prompt:#81a1c1,pointer:#bf616a,marker:#a3be8c,border:#4c566a"
if command -v fzf >/dev/null 2>&1; then
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
  else
    for _nw_f in /usr/share/doc/fzf/examples/key-bindings.zsh /usr/share/fzf/key-bindings.zsh; do
      [[ -r "$_nw_f" ]] && source "$_nw_f" && break
    done
    for _nw_f in /usr/share/doc/fzf/examples/completion.zsh /usr/share/fzf/completion.zsh; do
      [[ -r "$_nw_f" ]] && source "$_nw_f" && break
    done
    unset _nw_f
  fi
fi

# fzf-tab: render tab completion through an fzf menu (after compinit/fzf,
# before the autosuggestion and highlighter widgets).
if [[ -r "$ZNW_CUSTOM/plugins/fzf-tab/fzf-tab.plugin.zsh" ]]; then
  source "$ZNW_CUSTOM/plugins/fzf-tab/fzf-tab.plugin.zsh"
  zstyle ':fzf-tab:*' use-fzf-default-opts yes
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 --color=always -- "$realpath" 2>/dev/null'
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# zsh-autosuggestions: fish-style suggestions drawn from history + completion.
if ! typeset -f _zsh_autosuggest_start >/dev/null 2>&1; then
  for _nw_f in /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh "$ZNW_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"; do
    [[ -r "$_nw_f" ]] && source "$_nw_f" && break
  done
  unset _nw_f
fi
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
(( ${+widgets[autosuggest-accept]} )) && bindkey '^ ' autosuggest-accept

# zsh-syntax-highlighting: must be the last plugin sourced.
if ! typeset -f _zsh_highlight >/dev/null 2>&1; then
  for _nw_f in /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh "$ZNW_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; do
    [[ -r "$_nw_f" ]] && source "$_nw_f" && break
  done
  unset _nw_f
fi

# Context banner for interactive login shells (kept out of every tmux pane).
if [[ -o interactive && -o login ]] && command -v nightwire >/dev/null 2>&1; then
  nightwire banner
fi
EOF

  ctf_append_marker_block_root "$zshrc" "zsh-console" "$block" "$owner"
  ctf_write_starship_config
}

ctf_install_oh_my_zsh() {
  if [[ -d "$TARGET_HOME/.oh-my-zsh" ]]; then
    ctf_info "Oh My Zsh is already installed for $TARGET_USER."
    return 0
  fi

  # Clone the framework directly instead of piping the upstream installer to a
  # shell. Our managed .zshrc sources it explicitly, so no template is needed.
  ctf_install_packages git
  ctf_warn "Cloning Oh My Zsh (no remote install script is executed)."
  ctf_user_clone ohmyzsh https://github.com/ohmyzsh/ohmyzsh.git "$TARGET_HOME/.oh-my-zsh"
}

# Install the Exegol-style Zsh plugin set: autosuggestions and
# syntax-highlighting (from apt where available, otherwise git), plus
# zsh-completions and fzf-tab (git only).
ctf_install_zsh_plugins() {
  local pkgs=()
  ctf_package_available zsh-autosuggestions && pkgs+=(zsh-autosuggestions)
  ctf_package_available zsh-syntax-highlighting && pkgs+=(zsh-syntax-highlighting)
  ((${#pkgs[@]})) && ctf_install_packages "${pkgs[@]}"

  ctf_try_user_shell 'mkdir -p "$HOME/.oh-my-zsh/custom/plugins"'
  ctf_ensure_zsh_plugin zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions.git /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  ctf_ensure_zsh_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  ctf_ensure_zsh_plugin zsh-completions https://github.com/zsh-users/zsh-completions.git
  ctf_ensure_zsh_plugin fzf-tab https://github.com/Aloxaf/fzf-tab.git
}

# Clone a Zsh plugin into Oh My Zsh's custom directory unless it is already
# present there or available through a system path candidate.
ctf_ensure_zsh_plugin() {
  local name="$1"
  local url="$2"
  shift 2

  local candidate
  for candidate in "$@"; do
    if [[ -e "$candidate" ]]; then
      ctf_info "Zsh plugin available via system path: $name"
      return 0
    fi
  done

  ctf_user_clone "$name" "$url" "$TARGET_HOME/.oh-my-zsh/custom/plugins/$name"
}

ctf_write_starship_config() {
  local config_dir="$TARGET_HOME/.config"
  local config_path="$config_dir/starship.toml"
  local owner="$TARGET_USER:$(id -gn "$TARGET_USER")"

  if [[ -f "$config_path" ]]; then
    ctf_info "Existing Starship config preserved: $config_path"
    return 0
  fi

  local content
  read -r -d '' content <<'EOF' || true
# Nightwire Bootstrap Starship profile.
# Uses Nerd Font glyphs (installed by the bootstrapper). If your terminal is not
# set to a Nerd Font, set its font to "Hack Nerd Font" or remove this file.
add_newline = false
format = "${custom.vpn}$directory$git_branch$git_status$python$nodejs$rust$golang$cmd_duration$line_break$character"

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
vimcmd_symbol = "[❮](bold blue)"

[directory]
style = "bold cyan"
truncation_length = 4
truncate_to_repo = false

[git_branch]
style = "bold purple"

[git_status]
style = "bold yellow"

[cmd_duration]
min_time = 750
format = " took [$duration]($style)"
style = "yellow"

# Live VPN (tun0) indicator, shown only while connected.
[custom.vpn]
command = "nightwire _ip tun0"
when = "ip -o link show tun0"
description = "Show the tun0 VPN address"
format = "[vpn $output](bold red) "
shell = ["bash", "--noprofile", "--norc"]
EOF

  ctf_run_root install -d -m 0755 -o "$TARGET_USER" -g "$(id -gn "$TARGET_USER")" "$config_dir"
  ctf_write_root_file "$config_path" "$content" 0644 "$owner"
}

ctf_configure_tmux() {
  ctf_install_tpm

  local tmux_conf="$TARGET_HOME/.tmux.conf"
  local owner="$TARGET_USER:$(id -gn "$TARGET_USER")"
  local block
  read -r -d '' block <<'EOF' || true
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc,xterm-256color:Tc,alacritty:Tc"
set -g mouse on
set -g history-limit 100000
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -s escape-time 10
set -g focus-events on
setw -g mode-keys vi
set -g status-interval 5
set -g status-style bg=colour236,fg=colour250
set -g status-left '#[fg=colour81,bold] #S #[default]'
set -g status-right '#[fg=colour203]#(nightwire _tmux-status) #[fg=colour246]%Y-%m-%d #[fg=colour81]%H:%M '
bind r source-file ~/.tmux.conf \; display-message "tmux config reloaded"
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind -r h select-pane -L
bind -r j select-pane -D
bind -r k select-pane -U
bind -r l select-pane -R

# Session persistence across reboots/snapshots (tpm + resurrect + continuum).
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @resurrect-capture-pane-contents 'on'
set -g @continuum-restore 'on'
if "test -d ~/.tmux/plugins/tpm" "run '~/.tmux/plugins/tpm/tpm'"
EOF

  ctf_append_marker_block_root "$tmux_conf" "tmux-console" "$block" "$owner"
}

# Install the tmux plugin manager and pre-fetch the configured plugins so they
# work on first launch (tpm normally needs an interactive prefix + I).
ctf_install_tpm() {
  if [[ -d "$TARGET_HOME/.tmux/plugins/tpm" ]]; then
    ctf_info "tmux plugin manager already installed."
    return 0
  fi

  ctf_install_packages git tmux
  ctf_user_clone tpm https://github.com/tmux-plugins/tpm "$TARGET_HOME/.tmux/plugins/tpm"
  ctf_try_user_shell '[ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ] && "$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null 2>&1 || true'
}

ctf_maybe_set_login_shell() {
  local shell_name="$1"
  local shell_path
  shell_path="$(command -v "$shell_name" || true)"
  [[ -z "$shell_path" ]] && ctf_warn "Cannot set login shell; $shell_name not found." && return 0
  [[ "$TARGET_USER" == "root" ]] && ctf_warn "Skipping login shell change for root." && return 0

  local current_shell
  current_shell="$(getent passwd "$TARGET_USER" | awk -F: '{print $7}')"
  if [[ "$current_shell" == "$shell_path" ]]; then
    ctf_info "$TARGET_USER already uses $shell_path."
    return 0
  fi

  if ((YES)); then
    ctf_run_root chsh -s "$shell_path" "$TARGET_USER"
    LOGIN_SHELL_CHANGED=1
    return 0
  fi

  printf '\nChange login shell for %s to %s? [y/N] ' "$TARGET_USER" "$shell_path"
  local answer
  read -r answer
  case "$answer" in
    y | Y | yes | YES)
      ctf_run_root chsh -s "$shell_path" "$TARGET_USER"
      LOGIN_SHELL_CHANGED=1
      ;;
    *) ctf_info "Login shell unchanged." ;;
  esac
}
