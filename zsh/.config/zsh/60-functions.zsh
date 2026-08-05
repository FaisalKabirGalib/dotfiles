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

# === Pi Coding Agent Wrapper ===
# Checks if the apfel server is running (port 11434), starts it if not, then runs pi
pi() {
	if ! nc -z 127.0.0.1 11434 &>/dev/null; then
		echo "Starting apfel server on port 11434..."
		apfel --serve >/dev/null 2>&1 &

		# Wait for the server to be ready
		local count=0
		while ! nc -z 127.0.0.1 11434 &>/dev/null; do
			sleep 0.1
			((count++))
			if ((count > 50)); then
				echo "❌ Failed to start apfel server"
				return 1
			fi
		done
		echo "✅ apfel server started successfully"
	fi

	command pi "$@"
}

# === Local-model helpers (apfel / bonsai via pi -p) ===
# Maps $AI_MODEL keyword -> pi provider+model flags. Default: apfel (Apple Intelligence).
# Switch with: export AI_MODEL=bonsai   (start its server on 11436 first)
# NOTE: pi needs --provider and --model as SEPARATE flags; the combined
# "provider/id" form silently returns empty. Callers split with ${=...}.
_ai_model() {
	case "${AI_MODEL:-apfel}" in
	bonsai) echo "--provider bonsai --model Bonsai-8B-Q1_0.gguf" ;;
	*) echo "--provider apfel --model apple-foundationmodel" ;;
	esac
}

# Type a QUOTED phrase at the prompt -> shell command staged on your next line
# (via print -z, never auto-run). A real typo (no space in the name) errors normally.
command_not_found_handler() {
	if [[ "$1" == *" "* ]]; then # quoted natural-language phrase, not a typo
		local out
		out=$(pi -p -nt -ne -ns -np -nc --no-session \
			${=$(_ai_model)} \
			--system-prompt 'Output ONLY one shell command for macOS zsh that does what is asked. No prose, no markdown, no code fences.' \
			"$*" 2>/dev/null)
		# ponytail: small models wrap output in ```bash fences — strip fences,
		# a leading language-tag line, and surrounding whitespace. Tune here if needed.
		out="${out//\`\`\`/}"
		out="${out#"${out%%[![:space:]]*}"}" # trim leading whitespace
		case "${out%%$'\n'*}" in             # drop a leading "bash"/"sh"/"zsh" line
		bash | sh | zsh | shell) out="${out#*$'\n'}" ;;
		esac
		out="${out#"${out%%[![:space:]]*}"}" # trim leading whitespace again
		out="${out%"${out##*[![:space:]]}"}" # trim trailing whitespace
		if [[ -n "$out" ]]; then
			print -z "$out"
		else
			echo "no command produced" >&2
		fi
	else
		echo "zsh: command not found: $1" >&2
		return 127
	fi
}

# pp "rough idea" -> one tight, small-model-friendly prompt printed for reuse
pp() {
	pi -p -nt -ne -ns -np -nc --no-session \
		${=$(_ai_model)} \
		--system-prompt 'Rewrite the user request into ONE tight prompt for a small (4-8B) local LLM: single task, explicit output format, no multi-step "and then", minimal context. Output only the rewritten prompt.' \
		"$*"
}

# Automated Wireless Mirroring Utility
scrcpy-wireless() {
  local adb_path="/opt/homebrew/share/android-commandlinetools/platform-tools/adb"
  local ip_cache="$HOME/.cache/scrcpy_last_ip"
  
  # Ensure cache directory exists
  mkdir -p "$(dirname "$ip_cache")"

  # Check if there is already an active wireless connection
  local active_wireless=$($adb_path devices | grep -E '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:5555' | grep -v 'offline' | awk '{print $1}')
  
  if [ -n "$active_wireless" ]; then
    echo "⚡ Found active wireless connection: $active_wireless"
    scrcpy -s "$active_wireless"
    return
  fi

  # 1. Try saved IP first
  local cached_ip=""
  if [ -f "$ip_cache" ]; then
    cached_ip=$(cat "$ip_cache")
  fi

  if [ -n "$cached_ip" ]; then
    echo "📡 Checking saved IP: $cached_ip..."
    # Quick check if port 5555 is reachable
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

  # 2. Scan the local network in parallel (since phone IP might have changed)
  local default_iface=$(route -n get default 2>/dev/null | grep interface | awk '{print $2}')
  local mac_ip=""
  if [ -n "$default_iface" ]; then
    mac_ip=$(ipconfig getifaddr "$default_iface" 2>/dev/null)
  fi
  if [ -z "$mac_ip" ]; then
    mac_ip=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
  fi
  local found_ip=""

  if [ -n "$mac_ip" ]; then
    local subnet=$(echo "$mac_ip" | cut -d. -f1-3)
    echo "🔍 Scanning subnet $subnet.* for phone..."
    
    # Create a temp file to store findings
    local temp_file=$(mktemp)
    local pids=()
    
    # Scan the full subnet range in parallel (2..254) with 1s timeout
    for i in {2..254}; do
      (
        if nc -z -w 1 "$subnet.$i" 5555 2>/dev/null; then
          echo "$subnet.$i" > "$temp_file"
        fi
      ) &
      pids+=($!)
    done
    
    # Wait for scan to finish (max 1.2s)
    sleep 1.2
    
    # Kill only the scan processes
    kill "${pids[@]}" 2>/dev/null
    
    found_ip=$(cat "$temp_file" | head -n 1)
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
  local usb_device=""
  usb_device=$($adb_path devices | grep -v 'List of devices' | grep -v '5555' | grep 'device' | awk '{print $1}')

  if [ -z "$usb_device" ]; then
    echo "❌ Error: No USB device detected and could not find phone on local network."
    echo "💡 Please connect your phone via USB once to enable wireless ADB."
    return 1
  fi

  echo "📱 USB device found: $usb_device"
  echo "📡 Fetching phone IP address..."
  local phone_ip=$($adb_path -d shell ip route | grep wlan0 | grep -oE 'src [0-9.]+' | awk '{print $2}')
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

# === YouTube helper: search / watch / download (Chrome cookies) ===
# Usage:  yt <youtube-url>   |   yt <search terms...>
# Deps: yt-dlp, mpv, fzf, deno. Auth via Chrome cookies. No sudo needed.
#
# Chrome cookies are Keychain-encrypted, so reading them per-call prompted for the
# password once per yt-dlp/mpv invocation. Instead we export them ONCE to a cached
# 0600 file and point every call at it — 1 Keychain prompt per ~6h, not 4 per run.
_yt_cookies() {
  local f="$HOME/.cache/yt-cookies.txt"
  mkdir -p "${f:h}"
  if [[ ! -f "$f" || -n "$(find "$f" -mmin +360 2>/dev/null)" ]]; then
    echo "🔑 Unlocking Chrome cookies (one-time Keychain prompt)…" >&2
    yt-dlp --cookies-from-browser chrome --cookies "$f" \
           --flat-playlist --skip-download --no-warnings "ytsearch1:x" >/dev/null 2>&1
    chmod 600 "$f" 2>/dev/null
  fi
  print -r -- "$f"
}

_yt_clear() {
  # Wipe residual fzf preview image (chafa kitty/sixel) + redraw the pane.
  clear
  [[ -z "$TMUX" ]] && printf '\e_Ga=d\e\\'  # kitty graphics: drop floating preview image
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
             "ytsearch30:$*" 2>/dev/null \
           | fzf --delimiter='\t' --with-nth=2,3,4 --reverse --height=90% \
                 --prompt="Select video: " \
                 --preview='fmt=kitty; [ -n "$TMUX" ] && fmt=sixels; L=${FZF_PREVIEW_LINES:-20}; C=${FZF_PREVIEW_COLUMNS:-40}; printf "\033[1m%s\033[0m\n\033[2m%s  •  %s  •  %s views\033[0m\n" {2} {4} {3} {5}; { curl -fsL --max-time 6 https://i.ytimg.com/vi/{1}/maxresdefault.jpg 2>/dev/null || curl -sL --max-time 6 https://i.ytimg.com/vi/{1}/mqdefault.jpg 2>/dev/null; } | chafa --format=$fmt --passthrough=none --size=${C}x$((L-3)) --animate=off - 2>/dev/null || echo "(thumbnail unavailable — brew install chafa)"; yes "" | head -n "$L"' \
                 --preview-window='right,55%,border-left') || return
    [[ -z "$pick" ]] && { echo "❌ Nothing selected"; return 1; }
    url="https://www.youtube.com/watch?v=${pick%%$'\t'*}"
    _yt_clear
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
  echo "▶  Streaming ($choice)…  (VP9 / M2 hwdec, backgrounded — close the window to stop)"
  nohup mpv --hwdec=videotoolbox --vo=gpu-next \
      --ytdl-raw-options=cookies="$ck" \
      --ytdl-format="$fmt" "$url" </dev/null >/dev/null 2>&1 &!
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

