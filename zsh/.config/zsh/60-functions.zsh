# =============================================================================
# CUSTOM FUNCTIONS
# =============================================================================
# This file contains custom functions and advanced tool wrappers

# === Claude Code Z.AI Endpoint Helper ===
# Uses pass for secure API key storage
_ccz_env() {
  ANTHROPIC_AUTH_TOKEN="$(pass ApiKey/ZAi/claude | head -n1)" \
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
