# Dotfiles task runner. Run `just` or `just --list` to see all commands.
# just is mise-managed (`mise use -g just`), installed by scripts/setup-mise.sh.
# On a machine with neither, bootstrap with `./install.sh` instead.

# Show available commands
default:
    @just --list

# Full setup: system packages, AUR, stow, shell, neovim
install:
    ./install.sh

# Stow packages (all if none given, e.g. `just stow nvim zsh`)
stow *pkgs:
    ./stowup {{pkgs}}

# Unstow packages (all if none given, e.g. `just unstow nvim`)
unstow *pkgs:
    ./stowDown {{pkgs}}

# Restow packages without conflicts (default: nvim opencode)
sync *pkgs:
    bin/dotfiles-sync {{pkgs}}

# Install pacman packages from scripts/packages.txt
packages:
    bash scripts/install-packages.sh

# Install AUR packages from scripts/aur-packages.txt
aur:
    bash scripts/install-aur.sh

# Install the mise toolchain from mise/.config/mise/config.toml
tools:
    bash scripts/setup-mise.sh

# Upgrade every mise-managed tool and refresh generated shell completions
tools-upgrade:
    mise upgrade
    @rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/_bun"

# Show mise-managed tools with a newer release available
tools-outdated:
    @mise outdated

# Health check: stow conflicts, broken symlinks, missing PACKAGE.md markers
doctor:
    @bash scripts/doctor.sh

# Repository-only validation: shell syntax plus dotfile health checks
validate:
    @bash -n $(git ls-files '*.sh' stowup stowDown install.sh)
    @bash scripts/doctor.sh

# Lint all shell scripts with shellcheck (no-op if not installed)
lint:
    @if command -v shellcheck >/dev/null 2>&1; then \
        shellcheck -x --severity=error $(git ls-files '*.sh' 'bin/.local/bin/*' 'bin/.local/script/*' stowup stowDown install.sh) scripts/stow-common.sh \
            && echo "shellcheck: clean"; \
    else echo "shellcheck not installed (mise use -g shellcheck)"; fi

# Format all shell scripts with shfmt (tabs, no-op if not installed)
fmt:
    @if command -v shfmt >/dev/null 2>&1; then \
        shfmt -w -i 0 $(git ls-files '*.sh' stowup stowDown install.sh) scripts/stow-common.sh \
            && echo "shfmt: formatted"; \
    else echo "shfmt not installed (mise use -g shfmt)"; fi

# Scan working tree for committed secrets (no-op if gitleaks not installed)
secrets:
    @if command -v gitleaks >/dev/null 2>&1; then \
        gitleaks detect --no-banner --source .; \
    else echo "gitleaks not installed (mise use -g gitleaks)"; fi

# Install the pre-commit hook (gitleaks + shellcheck) into .git/hooks
install-hooks:
    @git config core.hooksPath .githooks && echo "Hooks enabled (.githooks)"
