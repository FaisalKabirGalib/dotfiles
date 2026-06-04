# Dotfiles task runner. Run `just` or `just --list` to see all commands.
# Install just with: sudo pacman -S just  (or it's in scripts/packages.txt)

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

# Health check: stow conflicts, broken symlinks, missing PACKAGE.md markers
doctor:
    @bash scripts/doctor.sh

# Lint all shell scripts with shellcheck (no-op if not installed)
lint:
    @command -v shellcheck >/dev/null 2>&1 \
        && git ls-files '*.sh' stowup stowDown install.sh bin/ | xargs -r shellcheck \
        && echo "shellcheck: clean" \
        || echo "shellcheck not installed (pacman -S shellcheck)"

# Format all shell scripts with shfmt (tabs, no-op if not installed)
fmt:
    @command -v shfmt >/dev/null 2>&1 \
        && shfmt -w -i 0 $(git ls-files '*.sh' stowup stowDown install.sh) \
        && echo "shfmt: formatted" \
        || echo "shfmt not installed (pacman -S shfmt)"

# Scan working tree for committed secrets (no-op if gitleaks not installed)
secrets:
    @command -v gitleaks >/dev/null 2>&1 \
        && gitleaks detect --no-banner --source . \
        || echo "gitleaks not installed (pacman -S gitleaks)"

# Install the pre-commit hook (gitleaks + shellcheck) into .git/hooks
install-hooks:
    @git config core.hooksPath .githooks && echo "Hooks enabled (.githooks)"
