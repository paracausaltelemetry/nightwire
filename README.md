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

## Terminal & Evidence Logging

Built for long engagements where every command may end up in a report:

- **Every tmux pane is recorded.** Start a session with `nw` (`tmux new -A -s nightwire`). Each new pane is logged, ANSI-stripped and timestamped per line, to `<workspace>/_logs/YYYY-MM-DD/`. Panes being logged show a red **● REC** badge in their border.
  - `prefix + L` toggles logging for the current pane; `prefix + H` saves its full scrollback.
  - `nightwire log status|on|off|dir`, and `nightwire log grep PATTERN` to search every log.
- **Timestamped prompt.** Starship leads each prompt with the date and time, the VPN address, and the pinned target, so screenshots carry their own evidence.
- **Engagement variables.** `$IP` and `$TARGET` follow `nightwire target IP HOST`, and `$LHOST` follows `tun0`, refreshed at every prompt. Export your own value to override; unset it to follow Nightwire again.
- **tmux extras.** `prefix + S` types into all panes at once, `prefix + g` opens a scratch popup shell, and tmux-yank copies selections to the system clipboard.
- **History.** Bash and Zsh both keep timestamped history (100k entries), and man pages render through `bat`.
- **Notes.** The `cpts` kit installs CherryTree; `nightwire obsidian install` adds Obsidian (flatpak) and `nightwire obsidian open` opens the workspace as a vault.

The prompt and Alacritty configs are only written when absent. To pick up the new defaults on an existing box, move `~/.config/starship.toml` aside and run `nightwire reconfigure`.

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

### HTB CPTS build

For the Hack The Box Certified Penetration Testing Specialist path, use the
CPTS preset on Kali (best package coverage):

```bash
./install.sh --config examples/cpts.yml --yes
```

It installs the standard base plus three kits:

- `cpts`: service footprinting clients (SMB/NFS/FTP, SNMP/IPMI, LDAP/Kerberos,
  MySQL/MSSQL/Oracle, SMTP, DNS, RDP/WinRM), web discovery and CMS scanners,
  password crackers, and tunnelling helpers.
- `ad`: Active Directory tooling, including BloodHound CE and its Python
  collector.
- `web`: web application testing.

Workspaces default to `~/cpts`. Each `nightwire new NAME` workspace now also
gets `checklist.md` (per-host methodology), `creds.md` (credential log), and
`report-outline.md` (commercial report structure). For the exam report itself,
SysReptor has ready-made HTB certification templates.

Preview without changing the system:

```bash
./install.sh --profile full --shell both --desktop auto --dry-run
```

## Options

```text
--profile light|standard|full
--config <path>
--extras web,pwn,rev,forensics,osint,wireless,bugbounty,cloud,ad,malware,cpts,all
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
nightwire update --latest
nightwire log status
nightwire obsidian open
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
- Ships modern, actively maintained tooling on top of the distro metapackages — privesc/pivoting (pspy, chisel, ligolo-ng, sshuttle), recon (gowitness, puredns, x8, kiterunner), and modern AD (bloodyAD, Coercer, ldeep).
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

### CI

`.github/workflows/ci.yml` runs on every push, pull request, and weekly:

- `bash -n` and `shellcheck` across every script.
- `tools/check-packages.sh` inside Kali rolling, Debian trixie, and Ubuntu 24.04 containers. It resolves every profile and extra and reports packages with no install candidate. On Kali it fails the build for missing `cpts` packages and also checks that every pipx name exists on PyPI and every pinned Go module version exists on the Go proxy.
- A `--dry-run` of the CPTS preset.

Run the same check locally inside a container of the distro you care about:

```bash
tools/check-packages.sh --strict-extras cpts --remote
```

Packages that are expected to be missing on a distro can be listed, one per line, in `tools/package-allowlist/<family>.txt`.

### Pinned versions

Go tools are pinned to exact module versions so every build installs the same code. `nightwire update` reinstalls those pins; `nightwire update --latest` moves them to upstream `@latest`. The stegseek `.deb` is SHA-256 verified (override with `STEGSEEK_SHA256`).

## Packer

`packer/kali-vmware.pkr.hcl` builds a VMware Kali VM with the CPTS preset by default. Override `install_args` for a different build (for example `--profile full --extras all --yes --no-reboot`), and set `guest_os_type` to a newer identifier such as `debian13-64` if your VMware release lists it. The build grants passwordless sudo only for its own duration and removes it during shutdown, so the build password never appears on a command line.
