#!/usr/bin/env bash

ctf_setup_desktop() {
  if [[ "$SELECTED_DESKTOP" == "none" ]]; then
    ctf_info "Desktop customization skipped."
    return 0
  fi

  ctf_info "Applying desktop customization for: $SELECTED_DESKTOP"
  ctf_install_packages alacritty rofi flameshot xclip xsel wl-clipboard papirus-icon-theme arc-theme fonts-firacode fonts-hack
  ctf_configure_alacritty
  ctf_configure_rofi

  case "$SELECTED_DESKTOP" in
    xfce) ctf_customize_xfce ;;
    gnome) ctf_customize_gnome ;;
    kde) ctf_customize_kde ;;
    mate) ctf_customize_mate ;;
    *) ctf_warn "Unsupported desktop '$SELECTED_DESKTOP'; skipping visual customization." ;;
  esac
}

ctf_wallpaper_or_empty() {
  ctf_default_wallpaper_path 2>/dev/null || true
}

# Install the Nordic GTK theme (and Nordzy cursors) into the user's home so the
# desktop matches Nightwire's nord-ish palette. Best-effort and cache-aware; the
# desktop customizers fall back to the stock dark theme if this did not land.
ctf_install_nordic_theme() {
  ctf_install_packages git
  ctf_try_user_shell 'mkdir -p "$HOME/.themes" "$HOME/.icons"'
  ctf_user_clone nordic-theme https://github.com/EliverLara/Nordic.git "$TARGET_HOME/.themes/Nordic"

  if [[ ! -d "$TARGET_HOME/.icons/Nordzy-cursors" && ! -d "$TARGET_HOME/.local/share/icons/Nordzy-cursors" ]]; then
    ctf_warn "Installing the Nordzy cursor theme."
    ctf_try_user_shell "set -e
tmp=\"\$(mktemp -d)\"
trap 'rm -rf \"\$tmp\"' EXIT
if [ -d '$CACHE_DIR/repos/nordzy-cursors' ]; then
  cp -a '$CACHE_DIR/repos/nordzy-cursors' \"\$tmp/nz\"
else
  git clone --depth 1 https://github.com/alvatip/Nordzy-cursors.git \"\$tmp/nz\"
fi
cd \"\$tmp/nz\"
./install.sh >/dev/null 2>&1 || true"
  fi
}

ctf_customize_xfce() {
  local wallpaper
  wallpaper="$(ctf_wallpaper_or_empty)"

  ctf_install_packages xfconf xfce4-terminal
  ctf_install_nordic_theme
  ctf_configure_xfce_terminal

  if [[ -n "$wallpaper" ]]; then
    # Set the image plus its sibling image-style (5 = zoomed) and image-show on
    # every backdrop; without a non-zero style Xfce keeps the image hidden.
    ctf_try_user_shell "if command -v xfconf-query >/dev/null 2>&1; then xfconf-query -c xfce4-desktop -lv | awk '/last-image/ {print \$1}' | while read -r prop; do base=\"\${prop%/last-image}\"; xfconf-query -c xfce4-desktop -p \"\$prop\" -s '$wallpaper' || true; xfconf-query -c xfce4-desktop -p \"\$base/image-style\" -s 5 || true; xfconf-query -c xfce4-desktop -p \"\$base/image-show\" -s true || true; done; fi"
  fi

  local command
  read -r -d '' command <<'EOF' || true
if command -v xfconf-query >/dev/null 2>&1; then
  theme=Nordic
  { [ -d "$HOME/.themes/Nordic" ] || [ -d /usr/share/themes/Nordic ]; } || theme=Arc-Dark
  cursor=Nordzy-cursors
  { [ -d "$HOME/.icons/Nordzy-cursors" ] || [ -d "$HOME/.local/share/icons/Nordzy-cursors" ] || [ -d /usr/share/icons/Nordzy-cursors ]; } || cursor=Adwaita
  xfconf-query -c xsettings -p /Net/ThemeName -s "$theme" || true
  xfconf-query -c xsettings -p /Net/IconThemeName -s Papirus-Dark || true
  xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "$cursor" || true
  xfconf-query -c xfwm4 -p /general/theme -s "$theme" 2>/dev/null || true
  xfconf-query -c xsettings -p /Gtk/FontName -s 'Hack 10' || true
fi
EOF
  ctf_try_user_shell "$command"
}

ctf_configure_xfce_terminal() {
  local terminal_dir="$TARGET_HOME/.config/xfce4/terminal"
  local terminalrc="$terminal_dir/terminalrc"
  local owner="$TARGET_USER:$(id -gn "$TARGET_USER")"
  local block
  read -r -d '' block <<'EOF' || true
ColorForeground=#d8dee9
ColorBackground=#0b0f14
ColorCursor=#88c0d0
ColorPalette=#1b2229;#bf616a;#a3be8c;#ebcb8b;#81a1c1;#b48ead;#88c0d0;#e5e9f0;#4c566a;#bf616a;#a3be8c;#ebcb8b;#81a1c1;#b48ead;#8fbcbb;#eceff4
BackgroundMode=TERMINAL_BACKGROUND_TRANSPARENT
BackgroundDarkness=0.820000
FontName=Hack Nerd Font 10
MiscBell=FALSE
MiscMouseAutohide=TRUE
MiscMenubarDefault=FALSE
MiscToolbarDefault=FALSE
MiscDefaultGeometry=120x34
ScrollingBar=TERMINAL_SCROLLBAR_NONE
EOF

  ctf_run_root install -d -m 0755 -o "$TARGET_USER" -g "$(id -gn "$TARGET_USER")" "$terminal_dir"
  ctf_append_marker_block_root "$terminalrc" "xfce-terminal" "$block" "$owner"
}

# Install GNOME and make it the default session when the box is not already on
# GNOME (e.g. a fresh Xfce Kali). On an existing GNOME spin this is a no-op.
ctf_ensure_gnome() {
  if command -v gnome-shell >/dev/null 2>&1 || [[ "$DETECTED_DESKTOP" == "gnome" ]]; then
    ctf_info "GNOME is already present; theming the existing session."
    return 0
  fi

  ctf_warn "GNOME not detected; installing kali-desktop-gnome + gdm3 (large download)."
  ctf_install_packages kali-desktop-gnome gdm3

  if command -v systemctl >/dev/null 2>&1; then
    ctf_try_root sh -c 'echo "gdm3 shared/default-x-display-manager select gdm3" | debconf-set-selections'
    ctf_run_root sh -c 'echo /usr/sbin/gdm3 >/etc/X11/default-display-manager'
    ctf_try_root systemctl enable gdm3
    ctf_try_root systemctl set-default graphical.target
    DESKTOP_SWITCHED=1
    ctf_warn "Display manager switched to GDM3; reboot to land in GNOME."
  fi
}

ctf_customize_gnome() {
  local wallpaper
  wallpaper="$(ctf_wallpaper_or_empty)"

  ctf_ensure_gnome
  ctf_install_packages gnome-terminal
  ctf_install_nordic_theme
  ctf_configure_gnome_terminal

  if [[ -n "$wallpaper" ]]; then
    # picture-options must be a scaling mode or GNOME ignores the URI and shows
    # a blank/solid background, so set it alongside the light/dark image URIs.
    ctf_try_user_shell "if command -v gsettings >/dev/null 2>&1; then gsettings set org.gnome.desktop.background picture-uri 'file://$wallpaper'; gsettings set org.gnome.desktop.background picture-uri-dark 'file://$wallpaper' || true; gsettings set org.gnome.desktop.background picture-options 'zoom' || true; fi"
  fi

  local command
  read -r -d '' command <<'EOF' || true
if command -v gsettings >/dev/null 2>&1; then
  theme=Nordic
  { [ -d "$HOME/.themes/Nordic" ] || [ -d /usr/share/themes/Nordic ]; } || theme=Adwaita-dark
  cursor=Nordzy-cursors
  { [ -d "$HOME/.icons/Nordzy-cursors" ] || [ -d "$HOME/.local/share/icons/Nordzy-cursors" ] || [ -d /usr/share/icons/Nordzy-cursors ]; } || cursor=Adwaita
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark || true
  gsettings set org.gnome.desktop.interface gtk-theme "$theme" || true
  gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark || true
  gsettings set org.gnome.desktop.interface cursor-theme "$cursor" || true
  gsettings set org.gnome.desktop.interface monospace-font-name 'Hack Nerd Font 10' || true
fi
EOF
  ctf_try_user_shell "$command"

  ctf_enable_gnome_shell_theme
}

# Install + enable the user-themes extension and apply the Nordic GNOME Shell
# theme (top bar / overview). Takes effect on next login; under Wayland the shell
# cannot be reloaded live.
ctf_enable_gnome_shell_theme() {
  ctf_install_packages gnome-shell-extensions

  local command
  read -r -d '' command <<'EOF' || true
command -v gsettings >/dev/null 2>&1 || exit 0
uuid="user-theme@gnome-shell-extensions.gcampax.github.com"

if command -v gnome-extensions >/dev/null 2>&1; then
  gnome-extensions enable "$uuid" 2>/dev/null || true
fi

# Ensure the extension is in the enabled list even if the CLI could not act
# (e.g. it is not yet loaded in the running Wayland session).
cur="$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null || echo '@as []')"
case "$cur" in
  *"$uuid"*) : ;;
  "@as []" | "[]") gsettings set org.gnome.shell enabled-extensions "['$uuid']" 2>/dev/null || true ;;
  *) gsettings set org.gnome.shell enabled-extensions "${cur%]}, '$uuid']" 2>/dev/null || true ;;
esac

# Apply Nordic to the shell only if the theme ships a gnome-shell variant.
if [ -d "$HOME/.themes/Nordic/gnome-shell" ] || [ -d /usr/share/themes/Nordic/gnome-shell ]; then
  gsettings set org.gnome.shell.extensions.user-theme name "Nordic" 2>/dev/null || true
fi
EOF
  ctf_try_user_shell "$command"
  ctf_info "GNOME Shell theme applies after the next logout (Wayland cannot reload the shell live)."
}

ctf_customize_kde() {
  local wallpaper
  wallpaper="$(ctf_wallpaper_or_empty)"

  ctf_install_packages konsole
  ctf_configure_konsole

  ctf_try_user_shell "if command -v lookandfeeltool >/dev/null 2>&1; then lookandfeeltool -a org.kde.breezedark.desktop || true; fi"

  if [[ -n "$wallpaper" ]]; then
    ctf_try_user_shell "if command -v qdbus >/dev/null 2>&1; then qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \"var allDesktops = desktops(); for (i=0;i<allDesktops.length;i++) { d = allDesktops[i]; d.wallpaperPlugin = 'org.kde.image'; d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General'); d.writeConfig('Image', 'file://$wallpaper'); }\" || true; fi"
  fi
}

ctf_customize_mate() {
  local wallpaper
  wallpaper="$(ctf_wallpaper_or_empty)"

  ctf_install_packages mate-terminal
  ctf_install_nordic_theme
  ctf_configure_mate_terminal

  if [[ -n "$wallpaper" ]]; then
    # draw-background + a scaling picture-options are needed or MATE leaves the
    # image set but unrendered behind the solid desktop color.
    ctf_try_user_shell "if command -v gsettings >/dev/null 2>&1; then gsettings set org.mate.background draw-background true || true; gsettings set org.mate.background picture-filename '$wallpaper' || true; gsettings set org.mate.background picture-options 'zoom' || true; fi"
  fi

  local command
  read -r -d '' command <<'EOF' || true
if command -v gsettings >/dev/null 2>&1; then
  theme=Nordic
  { [ -d "$HOME/.themes/Nordic" ] || [ -d /usr/share/themes/Nordic ]; } || theme=Arc-Dark
  cursor=Nordzy-cursors
  { [ -d "$HOME/.icons/Nordzy-cursors" ] || [ -d "$HOME/.local/share/icons/Nordzy-cursors" ] || [ -d /usr/share/icons/Nordzy-cursors ]; } || cursor=Adwaita
  gsettings set org.mate.interface gtk-theme "$theme" || true
  gsettings set org.mate.interface icon-theme Papirus-Dark || true
  gsettings set org.mate.peripherals-mouse cursor-theme "$cursor" || true
  gsettings set org.mate.interface monospace-font-name 'Hack Nerd Font 10' || true
fi
EOF
  ctf_try_user_shell "$command"
}

ctf_configure_alacritty() {
  local config_dir="$TARGET_HOME/.config/alacritty"
  local config_path="$config_dir/alacritty.toml"
  local owner="$TARGET_USER:$(id -gn "$TARGET_USER")"

  if [[ -f "$config_path" ]]; then
    ctf_info "Existing Alacritty config preserved: $config_path"
    return 0
  fi

  local content
  read -r -d '' content <<'EOF' || true
[window]
opacity = 0.88
decorations = "Full"
dynamic_title = true
padding = { x = 10, y = 8 }

[font]
size = 10.5
normal = { family = "Hack Nerd Font", style = "Regular" }
bold = { family = "Hack Nerd Font", style = "Bold" }
italic = { family = "Hack Nerd Font", style = "Italic" }

[selection]
save_to_clipboard = true

[colors.primary]
background = "#0b0f14"
foreground = "#d8dee9"

[colors.cursor]
text = "#0b0f14"
cursor = "#88c0d0"

[colors.normal]
black = "#1b2229"
red = "#bf616a"
green = "#a3be8c"
yellow = "#ebcb8b"
blue = "#81a1c1"
magenta = "#b48ead"
cyan = "#88c0d0"
white = "#e5e9f0"

[colors.bright]
black = "#4c566a"
red = "#bf616a"
green = "#a3be8c"
yellow = "#ebcb8b"
blue = "#81a1c1"
magenta = "#b48ead"
cyan = "#8fbcbb"
white = "#eceff4"
EOF

  ctf_run_root install -d -m 0755 -o "$TARGET_USER" -g "$(id -gn "$TARGET_USER")" "$config_dir"
  ctf_write_root_file "$config_path" "$content" 0644 "$owner"
}

ctf_configure_rofi() {
  local config_dir="$TARGET_HOME/.config/rofi"
  local config_path="$config_dir/config.rasi"
  local owner="$TARGET_USER:$(id -gn "$TARGET_USER")"

  if [[ -f "$config_path" ]]; then
    ctf_info "Existing Rofi config preserved: $config_path"
    return 0
  fi

  local content
  read -r -d '' content <<'EOF' || true
configuration {
  modi: "drun,run,window,ssh";
  show-icons: true;
  terminal: "alacritty";
  display-drun: "apps";
  display-run: "run";
  display-window: "win";
}

* {
  background: #0b0f14ee;
  foreground: #d8dee9ff;
  accent: #88c0d0ff;
  urgent: #bf616aff;
  selected: #1f2a33f2;
}

window {
  transparency: "real";
  width: 42%;
  border: 1px;
  border-color: @accent;
  border-radius: 8px;
  background-color: @background;
}

mainbox {
  padding: 14px;
  spacing: 8px;
}

inputbar {
  padding: 10px;
  border-radius: 6px;
  background-color: #131b22f2;
}

entry {
  text-color: @foreground;
}

listview {
  lines: 9;
  columns: 1;
  fixed-height: true;
  spacing: 4px;
}

element {
  padding: 8px;
  border-radius: 6px;
}

element selected {
  background-color: @selected;
  text-color: @foreground;
}
EOF

  ctf_run_root install -d -m 0755 -o "$TARGET_USER" -g "$(id -gn "$TARGET_USER")" "$config_dir"
  ctf_write_root_file "$config_path" "$content" 0644 "$owner"
}

ctf_configure_gnome_terminal() {
  local command
  read -r -d '' command <<'EOF' || true
if command -v gsettings >/dev/null 2>&1; then
  profile_id="$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")"
  if [ -n "$profile_id" ]; then
    profile="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile_id/"
    gsettings set "$profile" use-theme-colors false || true
    gsettings set "$profile" foreground-color '#d8dee9' || true
    gsettings set "$profile" background-color '#0b0f14' || true
    gsettings set "$profile" audible-bell false || true
    gsettings set "$profile" font 'Hack Nerd Font 10' || true
    gsettings set "$profile" use-system-font false || true
    if gsettings writable "$profile" use-transparent-background 2>/dev/null | grep -Fxq true; then
      gsettings set "$profile" use-transparent-background true || true
      gsettings set "$profile" background-transparency-percent 22 || true
    fi
  fi
fi
EOF
  ctf_try_user_shell "$command"
}

ctf_configure_konsole() {
  local konsole_dir="$TARGET_HOME/.local/share/konsole"
  local profile_path="$konsole_dir/CTF-Translucent.profile"
  local colors_path="$konsole_dir/CTF-Translucent.colorscheme"
  local owner="$TARGET_USER:$(id -gn "$TARGET_USER")"
  local profile colors

  read -r -d '' profile <<'EOF' || true
[Appearance]
ColorScheme=CTF-Translucent
Font=Hack Nerd Font,10,-1,5,50,0,0,0,0,0

[General]
Name=CTF-Translucent
Parent=FALLBACK/

[Scrolling]
HistoryMode=2
ScrollBarPosition=2
EOF

  read -r -d '' colors <<'EOF' || true
[Background]
Color=11,15,20
Transparency=14

[BackgroundIntense]
Color=27,34,41
Transparency=10

[Foreground]
Color=216,222,233

[Color0]
Color=27,34,41
[Color1]
Color=191,97,106
[Color2]
Color=163,190,140
[Color3]
Color=235,203,139
[Color4]
Color=129,161,193
[Color5]
Color=180,142,173
[Color6]
Color=136,192,208
[Color7]
Color=229,233,240
EOF

  ctf_run_root install -d -m 0755 -o "$TARGET_USER" -g "$(id -gn "$TARGET_USER")" "$konsole_dir"
  ctf_write_root_file "$profile_path" "$profile" 0644 "$owner"
  ctf_write_root_file "$colors_path" "$colors" 0644 "$owner"
  ctf_try_user_shell "if command -v kwriteconfig6 >/dev/null 2>&1; then kwriteconfig6 --file konsolerc --group 'Desktop Entry' --key DefaultProfile CTF-Translucent.profile; elif command -v kwriteconfig5 >/dev/null 2>&1; then kwriteconfig5 --file konsolerc --group 'Desktop Entry' --key DefaultProfile CTF-Translucent.profile; fi"
}

ctf_configure_mate_terminal() {
  local command
  read -r -d '' command <<'EOF' || true
if command -v gsettings >/dev/null 2>&1; then
  profile="org.mate.terminal.profile:/org/mate/terminal/profiles/default/"
  gsettings set "$profile" use-theme-colors false || true
  gsettings set "$profile" foreground-color '#d8dee9' || true
  gsettings set "$profile" background-color '#0b0f14' || true
  gsettings set "$profile" background-type transparent || true
  gsettings set "$profile" background-darkness 0.82 || true
  gsettings set "$profile" font 'Hack Nerd Font 10' || true
  gsettings set "$profile" use-system-font false || true
fi
EOF
  ctf_try_user_shell "$command"
}
