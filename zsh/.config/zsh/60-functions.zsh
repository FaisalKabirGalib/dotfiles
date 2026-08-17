# =============================================================================
# CUSTOM FUNCTIONS
# =============================================================================
# This file contains custom functions and advanced tool wrappers

# === Claude Code Z.AI Endpoint Helper ===
# Uses pass for secure API key storage
_ccz_env() {
  ANTHROPIC_AUTH_TOKEN="$(pass ApiKey/ZAi/primary | head -n1)" \
  ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic" \
  API_TIMEOUT_MS="3000000" \
  CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 \
  "$@"
}


# === Shorebird Token Management ===
# Function to load Shorebird token only when needed
load_shorebird_token() {
    if [[ -z "$SHOREBIRD_TOKEN" ]]; then
        echo "Loading Shorebird token..."
        export SHOREBIRD_TOKEN=$(pass show shorebird/token 2>/dev/null || echo "")
        if [[ -n "$SHOREBIRD_TOKEN" ]]; then
            echo "✅ Shorebird token loaded for this session"
        else
            echo "❌ Failed to load Shorebird token"
            return 1
        fi
    else
        echo "✅ Shorebird token already loaded"
    fi
}

# Wrapper function for shorebird command that auto-loads token
shorebird() {
    if [[ -z "$SHOREBIRD_TOKEN" ]]; then
        echo "🔐 Shorebird token not loaded. Loading now..."
        load_shorebird_token || return 1
    fi
    command shorebird "$@"
}

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# === Directory Change Hooks ===
autoload -Uz add-zsh-hook

function auto_venv() {
  if [[ -n "$VIRTUAL_ENV" && "$PWD" != *"${VIRTUAL_ENV:h}"* ]]; then
    deactivate 2>/dev/null
    return
  fi

  [[ -n "$VIRTUAL_ENV" ]] && return

  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.venv/bin/activate" ]]; then
      source "$dir/.venv/bin/activate"
      return
    fi
    dir="${dir:h}"
  done
}

add-zsh-hook chpwd auto_venv

# === YouTube (yt) ===
# Search YouTube from the shell, preview thumbnails inline in fzf, then either
# stream via mpv or download via yt-dlp.
#
# Thumbnails use chafa's Kitty graphics protocol, so they only render in a
# terminal that speaks it -- ghostty and kitty do, alacritty does not (it
# degrades to a text placeholder). Inside tmux they additionally require
# `set -g allow-passthrough on`, which tmux/.config/tmux/tmux.conf sets.

# Cache a cookie jar so age-gated/consent-walled videos resolve. Refreshed
# every 6h. Override the source browser with YT_COOKIES_BROWSER.
_yt_cookies() {
  local f="$HOME/.cache/yt-cookies.txt"
  mkdir -p "${f:h}"
  if [[ ! -f "$f" || -n "$(find "$f" -mmin +360 2>/dev/null)" ]]; then
    local b
    for b in "${YT_COOKIES_BROWSER:-}" chromium firefox; do
      [[ -z "$b" ]] && continue
      echo "🔑 Extracting cookies from $b…" >&2
      if yt-dlp --cookies-from-browser "$b" --cookies "$f" \
                --flat-playlist --skip-download --no-warnings \
                "ytsearch1:x" >/dev/null 2>&1; then
        break
      fi
    done
    chmod 600 "$f" 2>/dev/null
  fi
  print -r -- "$f"
}

yt() {
  [[ -z "$1" ]] && { echo "Usage: yt <youtube-url | search terms>"; return 1; }

  local ck; ck=$(_yt_cookies) || return

  local url
  if [[ "$1" == http*://* ]]; then
    url="$1"
  else
    echo "🔎 Searching YouTube: $*"
    local pick
    pick=$(yt-dlp --cookies "$ck" --flat-playlist --no-warnings \
             --print $'%(id)s\t%(title)s\t%(duration_string)s\t%(uploader)s\t%(view_count)s' \
             "ytsearch15:$*" 2>/dev/null \
           | fzf --delimiter='\t' --with-nth=2,3,4 --reverse --height=90% \
                 --prompt="Select video: " \
                 --preview='pt=none; [ -n "$TMUX" ] && pt=tmux; L=${FZF_PREVIEW_LINES:-20}; C=${FZF_PREVIEW_COLUMNS:-40}; printf "\033[1m%s\033[0m\n\033[2m%s  •  %s  •  %s views\033[0m\n" {2} {4} {3} {5}; { curl -fsL --max-time 6 https://i.ytimg.com/vi/{1}/maxresdefault.jpg 2>/dev/null || curl -sL --max-time 6 https://i.ytimg.com/vi/{1}/mqdefault.jpg 2>/dev/null; } | chafa --format=kitty --passthrough=$pt --size=${C}x$((L-3)) --animate=off - 2>/dev/null || echo "(thumbnail unavailable — sudo pacman -S chafa)"; yes "" | head -n "$L"' \
                 --preview-window='right,55%,border-left') || return
    [[ -z "$pick" ]] && { echo "❌ Nothing selected"; return 1; }
    url="https://www.youtube.com/watch?v=${pick%%$'\t'*}"
  fi

  local action
  action=$(printf '▶  Watch (stream)\n⬇  Download' \
           | fzf --reverse --height=20% --prompt="Action: ") || return
  case "$action" in
    *Watch*)    _yt_watch    "$url" "$ck" ;;
    *Download*) _yt_download "$url" "$ck" ;;
    *) return 1 ;;
  esac
}

_yt_watch() {
  local url="$1" ck="$2" choice fmt
  choice=$(printf 'Best available\n4320 (8K)\n2160 (4K)\n1440 (2K)\n1080\n720\n480' \
           | fzf --reverse --height=30% --prompt="Resolution: ") || return
  [[ -z "$choice" ]] && return 1
  if [[ "$choice" == Best* ]]; then
    fmt="bestvideo[vcodec^=vp9]+bestaudio/bestvideo+bestaudio/best"
  else
    local h="${choice%% *}"   # leading number
    fmt="bestvideo[vcodec^=vp9][height<=$h]+bestaudio/bestvideo[height<=$h]+bestaudio/best"
  fi
  # VP9 first: this box is Intel Iris Xe (Tiger Lake), which decodes VP9 in
  # hardware via VA-API. AV1 decode exists on Tiger Lake too but is patchier.
  echo "▶  Streaming ($choice)…"
  mpv --hwdec=vaapi --vo=gpu-next \
      --ytdl-raw-options=cookies="$ck" \
      --ytdl-format="$fmt" "$url"
}

_yt_download() {
  local url="$1" ck="$2" dldir="$HOME/Downloads" choice
  choice=$(printf '%s\n' \
      '🎬 Best video+audio (mp4)' \
      '🎯 Pick exact format…' \
      '🎵 Audio only (m4a)' \
      '🎵 Audio only (mp3)' \
    | fzf --reverse --height=30% --prompt="Download: ") || return
  [[ -z "$choice" ]] && return 1

  local -a args=(--cookies "$ck" --no-warnings -o "$dldir/%(title)s.%(ext)s")
  case "$choice" in
    *'Best video'*) args+=(-f 'bv*+ba/b' --merge-output-format mp4) ;;
    *'exact format'*|*'Pick exact'*)
      local fid
      fid=$(yt-dlp --cookies "$ck" -F "$url" 2>/dev/null \
            | fzf --reverse --height=80% --prompt="Format id: " | awk '{print $1}')
      [[ -z "$fid" ]] && { echo "❌ No format picked"; return 1; }
      args+=(-f "${fid}+bestaudio/${fid}") ;;
    *m4a*) args+=(-f 'ba[ext=m4a]/ba' -x --audio-format m4a) ;;
    *mp3*) args+=(-x --audio-format mp3 --audio-quality 0) ;;
  esac
  echo "⬇  Downloading to $dldir …"
  yt-dlp "${args[@]}" "$url" && echo "✅ Saved to $dldir"
}

# === Wireless Android Mirroring ===
# Mirror an Android phone over Wi-Fi with scrcpy. Tries, in order: an already
# connected wireless device, the last known IP, a parallel subnet scan, then
# falls back to a USB cable to bootstrap TCP/IP mode.
# Requires: scrcpy, android-tools (adb).
scrcpy-wireless() {
  local adb_path
  adb_path=$(command -v adb) || {
    echo "❌ adb not found. Install it with: sudo pacman -S android-tools"
    return 1
  }
  local ip_cache="$HOME/.cache/scrcpy_last_ip"
  mkdir -p "${ip_cache:h}"

  # Check if there is already an active wireless connection
  local active_wireless
  active_wireless=$($adb_path devices | grep -E '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:5555' | grep -v 'offline' | awk '{print $1}')

  if [ -n "$active_wireless" ]; then
    echo "⚡ Found active wireless connection: $active_wireless"
    scrcpy -s "$active_wireless"
    return
  fi

  # 1. Try saved IP first
  local cached_ip=""
  [ -f "$ip_cache" ] && cached_ip=$(cat "$ip_cache")

  if [ -n "$cached_ip" ]; then
    echo "📡 Checking saved IP: $cached_ip..."
    if nc -z -w 1 "$cached_ip" 5555 2>/dev/null; then
      echo "✅ Saved IP is online. Connecting..."
      $adb_path connect "$cached_ip:5555" >/dev/null 2>&1
      sleep 0.5
      scrcpy -s "$cached_ip:5555"
      return
    else
      echo "⚠️  Saved IP $cached_ip is unreachable. Searching local network..."
    fi
  fi

  # 2. Scan the local network in parallel (phone IP may have changed).
  # Linux: derive the LAN address from the default route rather than macOS's
  # `route -n get default` / `ipconfig getifaddr en0`.
  local default_iface host_ip=""
  default_iface=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')
  if [ -n "$default_iface" ]; then
    host_ip=$(ip -4 -o addr show dev "$default_iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1)
  fi
  [ -z "$host_ip" ] && host_ip=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1)
  local found_ip=""

  if [ -n "$host_ip" ]; then
    local subnet="${host_ip%.*}"
    echo "🔍 Scanning subnet $subnet.* for phone..."

    local temp_file
    temp_file=$(mktemp)
    local pids=()

    for i in {2..254}; do
      (
        if nc -z -w 1 "$subnet.$i" 5555 2>/dev/null; then
          echo "$subnet.$i" > "$temp_file"
        fi
      ) &
      pids+=($!)
    done

    sleep 1.2
    kill "${pids[@]}" 2>/dev/null
    wait 2>/dev/null

    found_ip=$(head -n 1 "$temp_file")
    rm -f "$temp_file"
  fi

  # 3. If found during scan, connect and mirror
  if [ -n "$found_ip" ]; then
    echo "🎉 Found phone online at: $found_ip"
    echo "$found_ip" > "$ip_cache"
    $adb_path connect "$found_ip:5555" >/dev/null 2>&1
    sleep 0.5
    scrcpy -s "$found_ip:5555"
    return
  fi

  # 4. If wireless failed, fall back to USB connection setup
  local usb_device
  usb_device=$($adb_path devices | grep -v 'List of devices' | grep -v '5555' | grep 'device' | awk '{print $1}')

  if [ -z "$usb_device" ]; then
    echo "❌ Error: No USB device detected and could not find phone on local network."
    echo "💡 Please connect your phone via USB once to enable wireless ADB."
    return 1
  fi

  echo "📱 USB device found: $usb_device"
  echo "📡 Fetching phone IP address..."
  local phone_ip
  phone_ip=$($adb_path -d shell ip route | grep wlan0 | grep -oE 'src [0-9.]+' | awk '{print $2}')
  if [ -z "$phone_ip" ]; then
    phone_ip=$($adb_path -d shell ip addr show wlan0 | grep -oE 'inet [0-9.]+' | head -1 | awk '{print $2}')
  fi

  if [ -z "$phone_ip" ]; then
    echo "❌ Error: Could not retrieve IP address. Make sure your phone is connected to Wi-Fi."
    return 1
  fi

  echo "✅ Phone IP detected: $phone_ip"
  echo "$phone_ip" > "$ip_cache"

  echo "🔌 Enabling TCP/IP wireless mode on port 5555..."
  $adb_path -d tcpip 5555
  sleep 1.5

  echo "📡 Connecting wirelessly to $phone_ip:5555..."
  $adb_path connect "$phone_ip:5555"
  sleep 0.5

  echo "🎉 Success! You can now unplug the USB cable. Starting screen mirroring..."
  scrcpy -s "$phone_ip:5555"
}
