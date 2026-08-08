#!/usr/bin/env bash

ctf_setup_assets() {
  ctf_run_root install -d -m 0755 "$ASSET_INSTALL_DIR"

  if [[ -n "$ASSETS_URL" ]]; then
    ctf_install_remote_assets "$ASSETS_URL"
  elif [[ -d "$ASSET_SOURCE_DIR" ]]; then
    ctf_install_local_assets
  fi
}

ctf_asset_url_mode() {
  local url="$1"
  case "$url" in
    *.tar.gz | *.tgz) printf 'archive\n' ;;
    *) printf 'base\n' ;;
  esac
}

ctf_install_local_assets() {
  if [[ ! -f "$ASSET_SOURCE_DIR/manifest.sha256" ]]; then
    ctf_warn "Local asset manifest missing; skipping bundled assets."
    return 0
  fi

  ctf_info "Installing bundled assets from $ASSET_SOURCE_DIR"
  if command -v sha256sum >/dev/null 2>&1; then
    (cd "$ASSET_SOURCE_DIR" && sha256sum -c manifest.sha256)
  else
    ctf_warn "sha256sum unavailable; bundled asset verification skipped."
  fi

  ctf_run_root install -d -m 0755 "$ASSET_INSTALL_DIR"
  ctf_run_root cp -a "$ASSET_SOURCE_DIR/." "$ASSET_INSTALL_DIR/"
}

ctf_install_remote_assets() {
  local url="$1"
  local mode
  mode="$(ctf_asset_url_mode "$url")"

  ctf_install_packages curl ca-certificates

  if ((DRY_RUN)); then
    ctf_info "Would download remote assets from $url using mode: $mode"
    return 0
  fi

  local tmp
  tmp="$(mktemp -d)"
  ctf_info "Downloading assets from $url"

  if [[ "$mode" == "archive" ]]; then
    ctf_download_asset_archive "$url" "$tmp"
  else
    ctf_download_asset_manifest "$url" "$tmp"
  fi

  rm -rf "$tmp"
}

ctf_download_asset_archive() {
  local url="$1"
  local tmp="$2"
  local archive="$tmp/assets.tar.gz"
  local checksum="$tmp/assets.tar.gz.sha256"

  ctf_run curl -fsSL "$url" -o "$archive"
  if curl -fsSL "$url.sha256" -o "$checksum"; then
    (cd "$tmp" && sha256sum -c "$(basename "$checksum")")
  else
    ctf_warn "No archive checksum found at $url.sha256; continuing without remote asset verification."
  fi

  ctf_run_root tar -xzf "$archive" -C "$ASSET_INSTALL_DIR"
}

ctf_download_asset_manifest() {
  local base_url="${1%/}"
  local tmp="$2"
  local manifest="$tmp/manifest.sha256"

  ctf_run curl -fsSL "$base_url/manifest.sha256" -o "$manifest"

  local checksum file
  while read -r checksum file; do
    [[ -z "${checksum:-}" || "${checksum:0:1}" == "#" ]] && continue
    [[ "$file" == /* || "$file" == *".."* ]] && ctf_die "Unsafe asset path in manifest: $file"
    mkdir -p "$tmp/$(dirname "$file")"
    ctf_run curl -fsSL "$base_url/$file" -o "$tmp/$file"
  done <"$manifest"

  (cd "$tmp" && sha256sum -c manifest.sha256)
  ctf_run_root cp -a "$tmp/." "$ASSET_INSTALL_DIR/"
}

ctf_default_wallpaper_path() {
  local wallpaper="$ASSET_INSTALL_DIR/wallpapers/nightwire.png"
  if [[ -f "$wallpaper" ]]; then
    printf '%s\n' "$wallpaper"
    return 0
  fi
  return 1
}
