#!/usr/bin/env bash
set -Eeuo pipefail

PLUGIN_DIR="${HOME}/.gdb-plugins"
mkdir -p "$PLUGIN_DIR"

clone_or_update() {
  local name="$1"
  local url="$2"
  local dir="$PLUGIN_DIR/$name"
  if [[ -d "$dir/.git" ]]; then
    git -C "$dir" pull --ff-only || true
  else
    git clone --depth 1 "$url" "$dir"
  fi
}

command -v git >/dev/null 2>&1 || {
  printf 'git is required to install debugger helpers.\n' >&2
  exit 1
}

clone_or_update pwndbg https://github.com/pwndbg/pwndbg
if [[ -x "$PLUGIN_DIR/pwndbg/setup.sh" ]]; then
  "$PLUGIN_DIR/pwndbg/setup.sh" || true
fi

mkdir -p "$PLUGIN_DIR/gef"
curl -fsSL https://gef.blah.cat/py -o "$PLUGIN_DIR/gef/gef.py" || true

clone_or_update peda https://github.com/longld/peda

cat <<'EOF'
Installed debugger helpers under ~/.gdb-plugins.

Switch with:
  nightwire pwn-debuggers switch pwndbg
  nightwire pwn-debuggers switch gef
  nightwire pwn-debuggers switch peda
EOF
