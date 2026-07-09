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

