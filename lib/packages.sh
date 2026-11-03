#!/usr/bin/env bash

LIGHT_PACKAGES=(
  apt-transport-https ca-certificates curl wget git gnupg lsb-release sudo bash-completion
  build-essential make cmake pkg-config gcc g++ file binutils patchelf strace ltrace
  python3 python3-pip python3-venv pipx ruby perl default-jdk
  tmux zsh vim neovim nano less man-db unzip zip p7zip-full 7zip xz-utils bzip2 tar gzip
  jq yq fzf ripgrep fd-find bat tree htop btop zoxide eza tealdeer
  net-tools iproute2 iputils-ping dnsutils bind9-dnsutils whois traceroute tcpdump nmap masscan openvpn
  netcat-openbsd socat openssh-client rsync smbclient ftp tftp-hpa sqlite3 postgresql-client redis-tools rlwrap
  docker.io docker-compose docker-compose-v2
  alacritty rofi flameshot xclip xsel wl-clipboard dconf-cli dbus-x11 libnss3-tools
  fonts-firacode fonts-hack papirus-icon-theme arc-theme
)

STANDARD_PACKAGES=(
  seclists wordlists exploitdb
  sqlmap nikto whatweb wafw00f gobuster ffuf feroxbuster dirb wfuzz
  hydra john hashcat hashid hashcat-utils crunch cewl
  enum4linux enum4linux-ng smbmap snmp onesixtyone responder impacket-scripts python3-impacket amass
  bloodhound neo4j ldap-utils krb5-user
  gdb gdbserver gdb-multiarch radare2 rizin ghidra nasm yasm gcc-multilib g++-multilib
  libc6-i386 qemu-user qemu-user-static python3-pwntools ropper checksec
  binwalk foremost libimage-exiftool-perl steghide pngcheck
  ffmpeg imagemagick exiv2 sleuthkit testdisk bulk-extractor scalpel yara
  tor proxychains4 torsocks
  burpsuite zaproxy firefox-esr chromium
  golang-go rustc cargo ruby-full ruby-dev ruby-bundler ruby-rubygems
  libssl-dev libpcap-dev libcurl4-openssl-dev zlib1g-dev libxml2-dev libxslt1-dev
  nodejs npm
  wireshark tshark tcpflow
  wpscan
  chisel ligolo-ng sshuttle
)

WEB_PACKAGES=(
  zaproxy burpsuite ffuf feroxbuster gobuster dirsearch arjun dalfox wafw00f whatweb nikto
  massdns
)

PWN_PACKAGES=(
  gdb gdbserver gdb-multiarch python3-pwntools ropgadget ropper checksec nasm yasm
  gcc-multilib g++-multilib libc6-i386 seccomp libseccomp-dev
)

REV_PACKAGES=(
  ghidra cutter radare2 rizin apktool jadx dex2jar binwalk strace ltrace file jwt-tool
)

REV_PIPX_TOOLS=(
  name-that-hash
  git+https://github.com/RsaCtfTool/RsaCtfTool.git
)

FORENSICS_PACKAGES=(
  autopsy sleuthkit testdisk foremost scalpel bulk-extractor
  plaso-tools yara libimage-exiftool-perl pngcheck steghide
)

FORENSICS_PIPX_TOOLS=(
  volatility3
)

OSINT_PACKAGES=(
  theharvester sherlock tor torsocks proxychains4 whois dnsutils
)

WIRELESS_PACKAGES=(
  aircrack-ng reaver bully hcxtools hcxdumptool wifite kismet wireshark tshark
)

BUGBOUNTY_PACKAGES=(
  seclists nuclei ffuf feroxbuster rustscan amass jq yq chromium firefox-esr
)

CLOUD_PACKAGES=(
  awscli s3cmd azure-cli google-cloud-cli kubectl kubernetes-client terraform
)

AD_PACKAGES=(
  bloodhound neo4j evil-winrm kerbrute ldapdomaindump python3-impacket impacket-scripts
  responder smbmap enum4linux-ng freerdp3-x11 freerdp2-x11 certipy-ad netexec sliver
  bloodhound-ce-python
)

# Service footprinting and enumeration clients that back the HTB CPTS path.
# Combine with the ad and web extras (see examples/cpts.yml).
CPTS_PACKAGES=(
  nmap rustscan masscan seclists wordlists
  smbclient cifs-utils nfs-common rpcbind ftp lftp tnftp
  snmp snmp-mibs-downloader onesixtyone braa
  default-mysql-client freetds-bin odat
  ipmitool ldap-utils krb5-user
  dnsutils bind9-dnsutils dnsenum dnsrecon fierce
  smtp-user-enum swaks
  freerdp3-x11 freerdp2-x11 remmina rdesktop
  evil-winrm netexec enum4linux-ng smbmap
  ffuf feroxbuster gobuster wfuzz whatweb wafw00f nikto sqlmap
  wpscan joomscan cewl
  hashcat john hydra medusa crowbar
  proxychains4 sshuttle socat rlwrap chisel ligolo-ng
  cherrytree flameshot
)

CPTS_PIPX_TOOLS=(
  droopescan
)

MALWARE_PACKAGES=(
  yara clamav clamav-daemon inetsim radare2 rizin ghidra binwalk
  libimage-exiftool-perl oletools python3-pefile python3-yara
)

KALI_FULL_METAPACKAGES=(
  kali-tools-top10 kali-tools-web kali-tools-passwords kali-tools-forensics
  kali-tools-reverse-engineering kali-tools-exploitation kali-tools-information-gathering
  kali-tools-vulnerability kali-tools-crypto-stego kali-tools-post-exploitation
  kali-linux-large
)

PARROT_FULL_METAPACKAGES=(
  parrot-tools-full parrot-tools-pwn parrot-tools-web parrot-tools-forensics
  parrot-tools-reversing parrot-tools-infogathering parrot-tools-crypto
)

FULL_DEBIAN_UBUNTU_PACKAGES=(
  aircrack-ng bettercap ettercap-text-only medusa ncrack macchanger
  apktool dex2jar jadx
  foremost recoverjpeg safecopy
)

STANDARD_PIPX_TOOLS=(
  frida-tools
  ropper
  updog
)

STANDARD_CARGO_TOOLS=(
  "rustscan|rustscan"
  "feroxbuster|feroxbuster"
)

# Go tools are pinned to exact module versions so every build is reproducible.
# `nightwire update --latest` moves them to upstream @latest deliberately.
STANDARD_GO_TOOLS=(
  "subfinder|github.com/projectdiscovery/subfinder/v2/cmd/subfinder@v2.17.0"
  "httpx|github.com/projectdiscovery/httpx/cmd/httpx@v1.12.0"
  "nuclei|github.com/projectdiscovery/nuclei/v3/cmd/nuclei@v3.11.1"
  "katana|github.com/projectdiscovery/katana/cmd/katana@v1.8.0"
  "naabu|github.com/projectdiscovery/naabu/v2/cmd/naabu@v2.7.0"
  "anew|github.com/tomnomnom/anew@v0.1.1"
  "gau|github.com/lc/gau/v2/cmd/gau@v2.2.4"
  "waybackurls|github.com/tomnomnom/waybackurls@v0.1.0"
  "pspy|github.com/DominicBreuker/pspy@v1.2.1"
)

STANDARD_GEM_TOOLS=(
  wpscan
  zsteg
)

WEB_PIPX_TOOLS=(
  arjun
  dirsearch
)

PWN_PIPX_TOOLS=(
  angr
)

OSINT_PIPX_TOOLS=(
  maigret
  holehe
  socialscan
)

WEB_GO_TOOLS=(
  "dalfox|github.com/hahwul/dalfox/v2@v2.13.0"
  "hakrawler|github.com/hakluke/hakrawler@v0.0.0-20260805040537-52a16fe61bd1"
  "qsreplace|github.com/tomnomnom/qsreplace@v0.0.3"
  "kxss|github.com/Emoe/kxss@v0.0.0-20260531193025-acb2dc76e840"
  "gowitness|github.com/sensepost/gowitness@v0.0.0-20261011045312-601c84367aaf"
  "gospider|github.com/jaeles-project/gospider@v1.1.6"
  "unfurl|github.com/tomnomnom/unfurl@v0.4.3"
  "gf|github.com/tomnomnom/gf@v0.0.0-20200618134122-dcd4c361f9f5"
  "puredns|github.com/d3mondev/puredns/v2@v2.1.1"
  "kr|github.com/assetnote/kiterunner/cmd/kr@v1.0.2"
)

WEB_CARGO_TOOLS=(
  "x8|x8"
)

BUGBOUNTY_GO_TOOLS=(
  "dnsx|github.com/projectdiscovery/dnsx/cmd/dnsx@v1.3.1"
  "tlsx|github.com/projectdiscovery/tlsx/cmd/tlsx@v1.4.4"
  "uncover|github.com/projectdiscovery/uncover/cmd/uncover@v1.2.1"
  "asnmap|github.com/projectdiscovery/asnmap/cmd/asnmap@v1.2.0"
  "alterx|github.com/projectdiscovery/alterx/cmd/alterx@v0.1.0"
  "interactsh-client|github.com/projectdiscovery/interactsh/cmd/interactsh-client@v1.4.1"
  "notify|github.com/projectdiscovery/notify/cmd/notify@v1.0.7"
  "chaos|github.com/projectdiscovery/chaos-client/cmd/chaos@v0.5.2"
)

PWN_CARGO_TOOLS=(
  "pwninit|pwninit"
)

PWN_GEM_TOOLS=(
  one_gadget
  seccomp-tools
)

AD_PIPX_TOOLS=(
  git+https://github.com/Pennyw0rth/NetExec.git
  bloodhound-ce
  certipy-ad
  ldapdomaindump
  bloodyAD
  coercer
  ldeep
  adidnsdump
)

# kerbrute is not packaged on every distro (Kali rolling dropped it).
AD_GO_TOOLS=(
  "kerbrute|github.com/ropnop/kerbrute@v1.0.3"
)

MALWARE_PIPX_TOOLS=(
  oletools
  flare-floss
  vivisect
  malduck
  volatility3
  flare-capa
)

ctf_resolve_profile_packages() {
  local profile="$1"
  PROFILE_PACKAGES=("${LIGHT_PACKAGES[@]}")
  PIPX_TOOLS=()
  CARGO_TOOLS=()
  GO_TOOLS=()
  GEM_TOOLS=()

  if [[ "$profile" == "standard" || "$profile" == "full" ]]; then
    PROFILE_PACKAGES+=("${STANDARD_PACKAGES[@]}")
    PIPX_TOOLS+=("${STANDARD_PIPX_TOOLS[@]}")
    CARGO_TOOLS+=("${STANDARD_CARGO_TOOLS[@]}")
    GO_TOOLS+=("${STANDARD_GO_TOOLS[@]}")
    GEM_TOOLS+=("${STANDARD_GEM_TOOLS[@]}")
  fi

  ctf_apply_extra_profiles "$EXTRA_PROFILES"
  ctf_apply_manifest_profile light
  if [[ "$profile" == "full" ]]; then
    ctf_apply_manifest_profile standard
  fi
  ctf_apply_manifest_profile "$profile"
  ctf_apply_manifest_extras "$EXTRA_PROFILES"

  if [[ "$profile" == "full" ]]; then
    if ctf_is_kali; then
      PROFILE_PACKAGES+=("${KALI_FULL_METAPACKAGES[@]}")
    elif ctf_is_parrot; then
      PROFILE_PACKAGES+=("${PARROT_FULL_METAPACKAGES[@]}")
    else
      PROFILE_PACKAGES+=("${FULL_DEBIAN_UBUNTU_PACKAGES[@]}")
    fi
  fi

  ctf_dedupe_array PROFILE_PACKAGES
  ctf_dedupe_array PIPX_TOOLS
  ctf_dedupe_array CARGO_TOOLS
  ctf_dedupe_array GO_TOOLS
  ctf_dedupe_array GEM_TOOLS
}

ctf_apply_extra_profiles() {
  local profiles="$1"
  [[ -z "$profiles" ]] && return 0

  local profile
  local -a selected_profiles
  IFS=',' read -r -a selected_profiles <<<"$profiles"
  for profile in "${selected_profiles[@]}"; do
    if [[ "$profile" == "all" ]]; then
      ctf_apply_one_extra_profile web
      ctf_apply_one_extra_profile pwn
      ctf_apply_one_extra_profile rev
      ctf_apply_one_extra_profile forensics
      ctf_apply_one_extra_profile osint
      ctf_apply_one_extra_profile wireless
      ctf_apply_one_extra_profile bugbounty
      ctf_apply_one_extra_profile cloud
      ctf_apply_one_extra_profile ad
      ctf_apply_one_extra_profile malware
      ctf_apply_one_extra_profile cpts
    else
      ctf_apply_one_extra_profile "$profile"
    fi
  done
}

ctf_apply_manifest_extras() {
  local profiles="$1"
  [[ -z "$profiles" ]] && return 0

  local profile
  local -a selected_profiles
  IFS=',' read -r -a selected_profiles <<<"$profiles"
  for profile in "${selected_profiles[@]}"; do
    if [[ "$profile" == "all" ]]; then
      ctf_apply_manifest_profile web
      ctf_apply_manifest_profile pwn
      ctf_apply_manifest_profile rev
      ctf_apply_manifest_profile forensics
      ctf_apply_manifest_profile osint
      ctf_apply_manifest_profile wireless
      ctf_apply_manifest_profile bugbounty
      ctf_apply_manifest_profile cloud
      ctf_apply_manifest_profile ad
      ctf_apply_manifest_profile malware
      ctf_apply_manifest_profile cpts
    else
      ctf_apply_manifest_profile "$profile"
    fi
  done
}

ctf_apply_one_extra_profile() {
  local profile="$1"
  case "$profile" in
    web)
      PROFILE_PACKAGES+=("${WEB_PACKAGES[@]}")
      PIPX_TOOLS+=("${WEB_PIPX_TOOLS[@]}")
      GO_TOOLS+=("${WEB_GO_TOOLS[@]}")
      CARGO_TOOLS+=("${WEB_CARGO_TOOLS[@]}")
      ;;
    pwn)
      PROFILE_PACKAGES+=("${PWN_PACKAGES[@]}")
      PIPX_TOOLS+=("${PWN_PIPX_TOOLS[@]}")
      CARGO_TOOLS+=("${PWN_CARGO_TOOLS[@]}")
      GEM_TOOLS+=("${PWN_GEM_TOOLS[@]}")
      ;;
    rev)
      PROFILE_PACKAGES+=("${REV_PACKAGES[@]}")
      PIPX_TOOLS+=("${REV_PIPX_TOOLS[@]}")
      ;;
    forensics)
      PROFILE_PACKAGES+=("${FORENSICS_PACKAGES[@]}")
      PIPX_TOOLS+=("${FORENSICS_PIPX_TOOLS[@]}")
      ;;
    osint)
      PROFILE_PACKAGES+=("${OSINT_PACKAGES[@]}")
      PIPX_TOOLS+=("${OSINT_PIPX_TOOLS[@]}")
      ;;
    wireless)
      PROFILE_PACKAGES+=("${WIRELESS_PACKAGES[@]}")
      ;;
    bugbounty)
      PROFILE_PACKAGES+=("${BUGBOUNTY_PACKAGES[@]}")
      GO_TOOLS+=("${BUGBOUNTY_GO_TOOLS[@]}")
      ;;
    cloud)
      PROFILE_PACKAGES+=("${CLOUD_PACKAGES[@]}")
      ;;
    ad)
      PROFILE_PACKAGES+=("${AD_PACKAGES[@]}")
      PIPX_TOOLS+=("${AD_PIPX_TOOLS[@]}")
      GO_TOOLS+=("${AD_GO_TOOLS[@]}")
      ;;
    malware)
      PROFILE_PACKAGES+=("${MALWARE_PACKAGES[@]}")
      PIPX_TOOLS+=("${MALWARE_PIPX_TOOLS[@]}")
      ;;
    cpts)
      PROFILE_PACKAGES+=("${CPTS_PACKAGES[@]}")
      PIPX_TOOLS+=("${CPTS_PIPX_TOOLS[@]}")
      ;;
  esac
}

ctf_apply_manifest_profile() {
  local profile="$1"
  [[ -f "$MANIFEST_FILE" ]] || return 0

  local line kind value
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" == *"\"profile\":\"$profile\""* ]] || continue
    kind="$(printf '%s\n' "$line" | sed -n 's/.*"kind":"\([^"]*\)".*/\1/p')"
    value="$(printf '%s\n' "$line" | sed -n 's/.*"value":"\([^"]*\)".*/\1/p')"
    [[ -z "$kind" || -z "$value" ]] && continue
    case "$kind" in
      apt) PROFILE_PACKAGES+=("$value") ;;
      pipx) PIPX_TOOLS+=("$value") ;;
      cargo) CARGO_TOOLS+=("$value") ;;
      go) GO_TOOLS+=("$value") ;;
      gem) GEM_TOOLS+=("$value") ;;
    esac
  done <"$MANIFEST_FILE"
}

ctf_dedupe_array() {
  local array_name="$1"
  local -n array_ref="$array_name"
  local item
  local -A seen=()
  local -a deduped=()
  for item in "${array_ref[@]}"; do
    [[ -z "$item" ]] && continue
    if [[ -z "${seen[$item]+x}" ]]; then
      seen[$item]=1
      deduped+=("$item")
    fi
  done
  array_ref=("${deduped[@]}")
}

ctf_install_profile() {
  ctf_info "Resolving package profile: $PROFILE"
  ctf_resolve_profile_packages "$PROFILE"
  ctf_info "Profile $PROFILE: ${#PROFILE_PACKAGES[@]} apt, ${#PIPX_TOOLS[@]} pipx, ${#GO_TOOLS[@]} go, ${#CARGO_TOOLS[@]} cargo, ${#GEM_TOOLS[@]} gem tools"
  ctf_install_packages "${PROFILE_PACKAGES[@]}"
  ctf_install_pipx_tools
  ctf_install_cargo_tools
  ctf_install_go_tools
  ctf_install_gem_tools
  if [[ "$PROFILE" == "standard" || "$PROFILE" == "full" ]]; then
    ctf_install_stegseek
  fi
  ctf_configure_docker
}

# stegseek ships only as a release .deb (a much faster steghide cracker).
ctf_install_stegseek() {
  if command -v stegseek >/dev/null 2>&1; then
    ctf_info "stegseek already installed."
    return 0
  fi

  ctf_install_packages curl ca-certificates
  local url="https://github.com/RickdeJager/stegseek/releases/download/v0.6/stegseek_0.6-1.deb"
  local sha256="${STEGSEEK_SHA256:-7218c0e0d0cc81e31678eac6d63d1af46eccd6a0d4a9299e3b68b11e7bfc92f3}"
  local deb="/tmp/nightwire-stegseek.deb"
  ctf_warn "Installing stegseek from its release .deb (fast steghide cracker)."
  if ! ctf_run_root sh -c "curl -fsSL '$url' -o '$deb'"; then
    ctf_warn "Could not download stegseek; skipping."
    return 0
  fi
  if ! ctf_run_root sh -c "printf '%s  %s\n' '$sha256' '$deb' | sha256sum -c -"; then
    ctf_warn "stegseek checksum mismatch; refusing to install it."
    ctf_run_root rm -f "$deb"
    return 0
  fi
  ctf_wait_for_apt_locks
  ctf_try_root sh -c "DEBIAN_FRONTEND=noninteractive apt-get install -y '$deb'"
  ctf_run_root rm -f "$deb"
}

ctf_user_command_exists() {
  local command_name="$1"
  local user_path="$TARGET_HOME/.local/bin:$TARGET_HOME/.cargo/bin:$TARGET_HOME/go/bin:$PATH"
  local check="command -v '$command_name' >/dev/null 2>&1"

  if [[ "$(id -un)" == "$TARGET_USER" ]]; then
    HOME="$TARGET_HOME" PATH="$user_path" bash -lc "$check"
  elif command -v sudo >/dev/null 2>&1; then
    sudo -H -u "$TARGET_USER" env HOME="$TARGET_HOME" PATH="$user_path" bash -lc "$check"
  else
    return 1
  fi
}

ctf_install_pipx_tools() {
  if ((${#PIPX_TOOLS[@]} == 0)); then
    return 0
  fi

  if ! command -v pipx >/dev/null 2>&1; then
    ctf_warn "pipx is unavailable after package installation; skipping pipx tools."
    SKIPPED_PIPX_TOOLS+=("${PIPX_TOOLS[@]}")
    return 0
  fi

  ctf_try_user_shell "python3 -m pipx ensurepath"

  local tool check_name
  for tool in "${PIPX_TOOLS[@]}"; do
    # git+https://.../NetExec.git is listed by pipx under its package name.
    check_name="$tool"
    if [[ "$tool" == git+* ]]; then
      check_name="${tool##*/}"
      check_name="${check_name%.git}"
    fi
    if ctf_run_user_shell "pipx list --short 2>/dev/null | awk '{print \$1}' | grep -Fixq '$check_name'"; then
      ctf_info "pipx tool already installed: $tool"
      continue
    fi

    if ctf_run_user_shell "pipx install '$tool'"; then
      INSTALLED_PIPX_TOOLS+=("$tool")
    else
      SKIPPED_PIPX_TOOLS+=("$tool")
    fi
  done
}

ctf_install_cargo_tools() {
  if ((${#CARGO_TOOLS[@]} == 0)); then
    return 0
  fi

  if ! command -v cargo >/dev/null 2>&1 && ! ctf_user_command_exists cargo; then
    ctf_warn "cargo is unavailable after package installation; skipping Rust/Cargo tools."
    SKIPPED_CARGO_TOOLS+=("${CARGO_TOOLS[@]}")
    return 0
  fi

  ctf_try_user_shell "mkdir -p \"\$HOME/.cargo/bin\""

  local entry binary crate
  for entry in "${CARGO_TOOLS[@]}"; do
    binary="${entry%%|*}"
    crate="${entry#*|}"

    if ctf_user_command_exists "$binary"; then
      ctf_info "Cargo-backed tool already available: $binary"
      continue
    fi

    if ctf_run_user_shell "cargo install '$crate'"; then
      INSTALLED_CARGO_TOOLS+=("$binary")
    else
      SKIPPED_CARGO_TOOLS+=("$entry")
      ctf_warn "Failed to install Cargo tool: $entry"
    fi
  done
}

ctf_install_go_tools() {
  if ((${#GO_TOOLS[@]} == 0)); then
    return 0
  fi

  if ! command -v go >/dev/null 2>&1 && ! ctf_user_command_exists go; then
    ctf_warn "go is unavailable after package installation; skipping Go tools."
    SKIPPED_GO_TOOLS+=("${GO_TOOLS[@]}")
    return 0
  fi

  ctf_try_user_shell "mkdir -p \"\$HOME/go/bin\""

  local entry binary module
  for entry in "${GO_TOOLS[@]}"; do
    binary="${entry%%|*}"
    module="${entry#*|}"

    if ctf_user_command_exists "$binary"; then
      ctf_info "Go-backed tool already available: $binary"
      continue
    fi

    if ctf_run_user_shell "GOBIN=\"\$HOME/go/bin\" go install '$module'"; then
      INSTALLED_GO_TOOLS+=("$binary")
    else
      SKIPPED_GO_TOOLS+=("$entry")
      ctf_warn "Failed to install Go tool: $entry"
    fi
  done
}

ctf_install_gem_tools() {
  if ((${#GEM_TOOLS[@]} == 0)); then
    return 0
  fi

  if ! command -v gem >/dev/null 2>&1 && ! ctf_user_command_exists gem; then
    ctf_warn "gem is unavailable after package installation; skipping Ruby gems."
    SKIPPED_GEM_TOOLS+=("${GEM_TOOLS[@]}")
    return 0
  fi

  local gem_name
  for gem_name in "${GEM_TOOLS[@]}"; do
    if ctf_user_command_exists "$gem_name"; then
      ctf_info "Gem-backed tool already available: $gem_name"
      continue
    fi

    if ctf_run_user_shell "gem install --user-install '$gem_name' --no-document"; then
      INSTALLED_GEM_TOOLS+=("$gem_name")
    else
      SKIPPED_GEM_TOOLS+=("$gem_name")
      ctf_warn "Failed to install Ruby gem: $gem_name"
    fi
  done
}

ctf_configure_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    ctf_warn "docker command unavailable; skipping Docker service/group setup."
    return 0
  fi

  ctf_enable_service_if_present docker

  if getent group docker >/dev/null 2>&1 && [[ "$TARGET_USER" != "root" ]]; then
    if id -nG "$TARGET_USER" | tr ' ' '\n' | grep -Fxq docker; then
      ctf_info "$TARGET_USER is already in the docker group."
    else
      ctf_run_root usermod -aG docker "$TARGET_USER"
      DOCKER_GROUP_CHANGED=1
    fi
  fi
}
