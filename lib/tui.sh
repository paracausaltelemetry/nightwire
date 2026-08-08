#!/usr/bin/env bash

# Interactive configuration via whiptail menus. Falls back to the plain text
# prompts (ctf_interactive_defaults) when whiptail is unavailable, the session is
# non-interactive, or --yes was passed.
#
# IMPORTANT: this must run BEFORE ctf_setup_logging redirects stdout/stderr to
# the log tee, because whiptail draws its UI on the terminal's stderr.

ctf_tui_enabled() {
  ((YES)) && return 1
  [[ -t 0 && -t 1 ]] || return 1
  command -v whiptail >/dev/null 2>&1
}

# Cyber-noir palette for the newt/whiptail widgets.
ctf_tui_palette() {
  export NEWT_COLORS='
root=,black
window=,black
shadow=,black
border=brightcyan,black
title=brightmagenta,black
roottext=brightcyan,black
textbox=brightcyan,black
emptyscale=,black
fullscale=,brightmagenta
listbox=brightcyan,black
actlistbox=black,brightcyan
sellistbox=black,brightcyan
button=black,brightmagenta
actbutton=black,brightcyan
compactbutton=brightcyan,black
checkbox=brightcyan,black
actcheckbox=black,brightcyan
entry=brightcyan,black
label=brightmagenta,black'
}

ctf_menu() {
  # ctf_menu <title> <text> <default> <tag> <desc> [<tag> <desc> ...]
  local title="$1" text="$2" default="$3"
  shift 3
  whiptail --title "$title" --notags --default-item "$default" \
    --menu "$text" 20 78 10 "$@" 3>&1 1>&2 2>&3
}

ctf_checklist() {
  # ctf_checklist <title> <text> <tag> <desc> <on|off> ...
  local title="$1" text="$2"
  shift 2
  whiptail --title "$title" --separate-output \
    --checklist "$text" 22 78 12 "$@" 3>&1 1>&2 2>&3
}

ctf_yesno() {
  whiptail --title "$1" --yesno "$2" "${3:-14}" "${4:-72}"
}

ctf_msgbox() {
  whiptail --title "$1" --msgbox "$2" "${3:-14}" "${4:-72}"
}

ctf_tui_configure() {
  ctf_tui_enabled || return 0
  ctf_tui_palette

  ctf_msgbox "Nightwire" "Cyber-noir CTF workstation bootstrapper.\n\nThis wizard configures your install. Use arrows, Space to toggle, Tab to move to the buttons, Enter to confirm." || return 0

  if [[ -z "$PROFILE" ]]; then
    PROFILE="$(ctf_menu "Package profile" "How much tooling should be installed?" standard \
      light "Core CLI + shell only" \
      standard "Recommended CTF toolset" \
      full "Everything, incl. distro metapackages (large)")" || ctf_die "Setup cancelled."
  fi

  if [[ -z "$EXTRA_PROFILES" ]]; then
    local picks
    picks="$(ctf_checklist "Extra toolkits" "Toggle focused toolkits (Space to select):" \
      web "Web application testing" off \
      pwn "Binary exploitation" off \
      rev "Reverse engineering" off \
      forensics "Forensics / stego" off \
      osint "OSINT" off \
      wireless "Wi-Fi auditing" off \
      bugbounty "Bug-bounty recon" off \
      cloud "Cloud (AWS/Azure/GCP/k8s)" off \
      ad "Active Directory" off \
      malware "Malware analysis" off)" || true
    EXTRA_PROFILES="$(printf '%s' "$picks" | tr '\n' ',' | sed 's/,$//')"
  fi

  if [[ -z "$SHELL_MODE" ]]; then
    SHELL_MODE="$(ctf_menu "Shell" "Which shells get the Exegol-style autocomplete?" both \
      both "Bash + Zsh" \
      bash "Bash only" \
      zsh "Zsh only")" || ctf_die "Setup cancelled."
  fi

  if [[ -z "$DESKTOP_MODE" ]]; then
    DESKTOP_MODE="$(ctf_menu "Desktop" "Desktop environment + cyber-noir theme:" gnome \
      gnome "Install/switch to GNOME and apply the noir theme" \
      auto "Theme whatever desktop is detected" \
      none "Leave the desktop untouched")" || ctf_die "Setup cancelled."
  fi

  local summary
  summary="Profile:  $PROFILE
Extras:   ${EXTRA_PROFILES:-none}
Shell:    $SHELL_MODE
Desktop:  $DESKTOP_MODE
Runtime:  $RUNTIME_MODE

Proceed with the install?"
  if ctf_yesno "Confirm" "$summary"; then
    YES=1
  else
    ctf_die "Setup cancelled."
  fi
}
