# Nightwire Bootstrap

A modular Bash bootstrapper for Kali, Parrot, Ubuntu, and Debian CTF virtual machines, tuned for VMware guests.

It installs profile-based tooling, configures a polished Bash/Zsh console with Exegol-style autocomplete (inline autosuggestions, fuzzy completion menus, and syntax highlighting), adds tmux and Starship defaults, installs VMware guest integration, applies translucent terminal/launcher visuals where supported, installs a `nightwire` helper command, prepares local-only Docker labs, and supports repo-hosted assets with checksum verification.

## Autocomplete & Shell

Both shells get a modern, Exegol-like interactive experience out of the box:

- **Zsh** — Oh My Zsh plus `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-completions`, and `fzf-tab` for fuzzy `Tab` menus.
- **Bash** — [`ble.sh`](https://github.com/akinomyoga/ble.sh) for fish-style inline autosuggestions and syntax highlighting, a tuned `~/.inputrc`, and `bash-completion`.
- **Both** — `fzf` history/file/dir pickers (`Ctrl-R`, `Ctrl-T`, `Alt-C`), `zoxide` smart `cd`, `eza` icon listings, a **Nerd Font** Starship prompt with a live VPN indicator, and `fd`/`bat` shims.
- **tmux** — truecolor, vi copy-mode, and tpm + resurrect/continuum so sessions survive reboots and snapshots.

Verify it with `nightwire doctor`.

## Quick Start

```bash
# --depth 1 keeps the download tiny on a low-bandwidth VM.
git clone --depth 1 https://github.com/paracausaltelemetry/nightwire.git
cd nightwire
chmod +x install.sh
./install.sh
```

Run with **no flags** for a guided whiptail wizard (profile, toolkits, shell, desktop) themed to match the cyber-noir palette. Pass flags or `--yes` to skip it and run non-interactively. The run shows colorized, sectioned output with per-section progress bars.

Non-interactive standard install:

```bash
./install.sh --profile standard --shell both --desktop auto --yes
```

Install the broad workstation build:

```bash
./install.sh --profile full --extras all --runtime mise --shell both --desktop auto --yes
./install.sh --config examples/nightwire.yml --yes
```

Preview without changing the system:

```bash
./install.sh --profile full --shell both --desktop auto --dry-run
```

## Options

```text
--profile light|standard|full
--config <path>
--extras web,pwn,rev,forensics,osint,wireless,bugbounty,cloud,ad,malware,all
--shell bash|zsh|both
--desktop auto|xfce|gnome|kde|mate|none
--runtime system|mise|none
--browser proxy|basic|none
--labs local|all|none
--workspace-dir <path>
--assets-url <repo/raw/release-url>
--cache-dir <offline-bundle-dir>
--no-remote-installers
--dry-run
--yes
--no-reboot
--log-file <path>
--only packages,assets,vmware,shell,desktop,validate
--skip packages,assets,vmware,shell,desktop,validate
```

Use `--skip` or `--only` to resume a partially completed VM setup without rerunning every section. Available sections are `runtime`, `packages`, `assets`, `command`, `workspace`, `browser`, `labs`, `vmware`, `shell`, `desktop`, and `validate`.

## nightwire Command

The installer adds `/usr/local/bin/nightwire`:

```bash
nightwire doctor
nightwire doctor --json
nightwire update
nightwire reconfigure
nightwire new box-name
nightwire vpn up htb.ovpn
nightwire target 10.10.11.42 box.htb
nightwire enum 10.10.11.42
nightwire revshell
nightwire ip
nightwire labs up
nightwire browser-proxy
nightwire wordlists raft
nightwire report box-name
nightwire secrets list
nightwire snapshot-note pre-lab
```

`vpn`/`target`/`ip` give you live CTF context: the `tun0` VPN address and pinned
target show up in the tmux status bar and Starship prompt, and a context banner
greets you on login.

The command helpers are for authorized CTF, lab, owned, or explicitly permitted systems only.

## Design Notes

- Kali and Parrot use native packages and native security metapackages where available.
- Ubuntu and Debian use native repositories only; Kali repositories are never mixed into them.
- Every apt package is checked with `apt-cache show` before install.
- Standard/full profiles prefer apt packages, then add user-level Cargo, Go, Ruby Gem, and pipx tools for modern CTF utilities such as RustScan, feroxbuster, ProjectDiscovery tooling, and WPScan.
- Extra profiles let you add focused web, pwn, reversing, forensics, OSINT, wireless, bug bounty, and cloud tooling without making every VM identical.
- Ships modern, actively maintained tooling on top of the distro metapackages — privesc/pivoting (pspy, chisel, ligolo-ng, pwncat-cs, sshuttle), recon (gowitness, puredns, x8, kiterunner), and modern AD (bloodyAD, Coercer, ldeep).
- `--runtime mise` installs a user-level runtime manager for newer Go/Rust/Node/Ruby toolchains when distro packages lag.
- Shell autocomplete plugins prefer apt packages and fall back to git clones; every plugin load is guarded so the managed block is safe on images (Kali/Parrot) that already configure some of them.
- Oh My Zsh is cloned at a pinned ref rather than executed via `curl | sh`; the Nerd Font download is version-pinned, integrity-checked, and optionally checksum-verified (`NERD_FONT_SHA256`). `--no-remote-installers` forbids the remaining `curl | sh` fallbacks (Starship, mise).
- Managed config blocks (`.bashrc`, `.zshrc`, `.inputrc`, `.tmux.conf`) are content-hashed, so re-running the installer — or `nightwire reconfigure` — refreshes them in place only when they changed, without disturbing your own edits.
- `nightwire cache prepare` builds an offline bundle (assets + git mirrors + Nerd Font); `./install.sh --cache-dir DIR --no-remote-installers` then installs fully airgapped.
- User config files (`.bashrc`, `.zshrc`, `.inputrc`, `.tmux.conf`) are backed up once with `.nightwire.bak` before managed blocks are added.
- Desktop customization is best when run from inside the graphical session.

## Validation

Preview a run without changing the system, then exercise the profiles on a
throwaway VM:

```bash
./install.sh --dry-run
./install.sh --profile light --shell both --desktop auto
./install.sh --profile standard --shell both --desktop auto
./install.sh --profile full --shell both --desktop auto
```

Review `/usr/local/share/nightwire/install-report.txt` after each run.
