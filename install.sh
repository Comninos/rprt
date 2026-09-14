#!/usr/bin/env bash
# Install rprt: copy script, ensure PATH, optionally hook interactive shells.
#
#   curl -fsSL https://raw.githubusercontent.com/Comninos/rprt/master/install.sh | bash
#   curl -fsSL …/install.sh | bash -s -- --hook
#   curl -fsSL …/install.sh | sudo bash -s -- --system
#   ./install.sh
#   ./install.sh --no-hook   # default when non-interactive
#   ./install.sh --hook

set -euo pipefail

RAW_BASE="${RPRT_RAW_BASE:-https://raw.githubusercontent.com/Comninos/rprt/master}"
SYSTEM="${RPRT_SYSTEM:-0}"
# unset = ask when possible; 0/1 = explicit
HOOK="${RPRT_HOOK:-}"
ASSUME_YES=0

say() { printf '%s\n' "$*"; }
warn() { printf 'rprt install: %s\n' "$*" >&2; }
die() { printf 'rprt install: %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<'EOF'
Usage: install.sh [options]

  --hook       Run rprt automatically in new interactive shells
  --no-hook    Do not auto-run (default when non-interactive)
  --system     Install to /usr/local/bin (requires root)
  -y, --yes    Skip prompts; use defaults / explicit flags
  -h, --help   Show this help

Env: RPRT_SYSTEM=1  RPRT_HOOK=0|1  RPRT_RAW_BASE=<url>
EOF
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "need '$1'"
}

# Native Windows (Git Bash / MSYS / Cygwin) is unsupported. WSL is fine.
case "${OSTYPE:-}" in
    msys*|cygwin*|mingw*) die "Windows is not supported (use Linux, macOS, or WSL)" ;;
esac
case "$(uname -s 2>/dev/null || true)" in
    MINGW*|MSYS*|CYGWIN*) die "Windows is not supported (use Linux, macOS, or WSL)" ;;
esac

# Prompt on the real terminal even when stdin is a pipe (curl | bash).
can_prompt() {
    [[ "$ASSUME_YES" -eq 0 ]] && [[ -r /dev/tty ]] && [[ -w /dev/tty ]]
}

ask_yn() {
    local q="$1" default="${2:-n}" ans prompt
    if [[ "$default" == "y" ]]; then prompt="[Y/n]"; else prompt="[y/N]"; fi
    if ! can_prompt; then
        [[ "$default" == "y" ]]
        return
    fi
    printf '%s %s ' "$q" "$prompt" >/dev/tty
    # shellcheck disable=SC2162
    read -r ans </dev/tty || ans=""
    ans="${ans:-$default}"
    case "$ans" in
        y|Y|yes|YES) return 0 ;;
        *) return 1 ;;
    esac
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --hook) HOOK=1 ;;
        --no-hook) HOOK=0 ;;
        --system) SYSTEM=1 ;;
        -y|--yes) ASSUME_YES=1 ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown option: $1 (try --help)" ;;
    esac
    shift
done

src_file=""
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    _here="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"
    if [[ -n "${_here}" && -f "${_here}/rprt.sh" ]]; then
        src_file="${_here}/rprt.sh"
    fi
fi

fetch_script() {
    local dest="$1"
    if [[ -n "$src_file" ]]; then
        cp "$src_file" "$dest"
        return
    fi
    need_cmd curl
    curl -fsSL "${RAW_BASE}/rprt.sh" -o "$dest"
}

path_has_dir() {
    case ":${PATH}:" in
        *":$1:"*) return 0 ;;
        *) return 1 ;;
    esac
}

ensure_path_session() {
    local dir="$1"
    path_has_dir "$dir" && return 0
    export PATH="${dir}:${PATH}"
    say "added ${dir} to PATH for this session"
}

# Idempotent PATH export in a shell rc (separate from the auto-run hook).
append_path_export() {
    local rc="$1" dir="$2"
    local marker_begin="# >>> rprt path >>>"
    local marker_end="# <<< rprt path >>>"
    if [[ -f "$rc" ]] && grep -qF "$marker_begin" "$rc" 2>/dev/null; then
        say "PATH export already present in ${rc}"
        return
    fi
    mkdir -p "$(dirname "$rc")"
    if [[ -f "$rc" && -s "$rc" ]]; then
        printf '\n' >>"$rc"
    fi
    cat >>"$rc" <<EOF
${marker_begin}
case ":\$PATH:" in *":${dir}:"*) ;; *) export PATH="${dir}:\$PATH" ;; esac
${marker_end}
EOF
    say "added PATH export to ${rc}"
}

hook_block() {
    local path="$1"
    cat <<EOF
# >>> rprt >>>
if [[ \$- == *i* ]] && [ -x ${path} ]; then
    ${path}
fi
# <<< rprt <<<
EOF
}

append_hook() {
    local rc="$1" path="$2"
    if [[ -f "$rc" ]] && grep -q '# >>> rprt >>>' "$rc" 2>/dev/null; then
        say "auto-run hook already present in ${rc}"
        return
    fi
    mkdir -p "$(dirname "$rc")"
    if [[ -f "$rc" && -s "$rc" ]]; then
        printf '\n' >>"$rc"
    fi
    hook_block "$path" >>"$rc"
    say "auto-run hooked in ${rc}"
}

user_rcs() {
    local found=0
    if [[ -f "${HOME}/.bashrc" || "${SHELL:-}" == *bash* || ! -f "${HOME}/.zshrc" ]]; then
        printf '%s\n' "${HOME}/.bashrc"
        found=1
    fi
    if [[ -f "${HOME}/.zshrc" || "${SHELL:-}" == *zsh* ]]; then
        printf '%s\n' "${HOME}/.zshrc"
        found=1
    fi
    if [[ "$found" -eq 0 ]]; then
        printf '%s\n' "${HOME}/.bashrc"
    fi
}

# --- resolve options ---

if [[ "$SYSTEM" == "1" ]]; then
    [[ "$(id -u)" -eq 0 ]] || die "--system / RPRT_SYSTEM=1 requires root (try sudo)"
    bin_dir="/usr/local/bin"
    bin_path="${bin_dir}/rprt"
    profile_d="/etc/profile.d/rprt.sh"
else
    bin_dir="${HOME}/.local/bin"
    bin_path="${bin_dir}/rprt"
    profile_d=""
fi

if [[ -z "$HOOK" ]]; then
    say ""
    say "Install rprt to ${bin_path}"
    say ""
    if ask_yn "Run automatically in new interactive shells?" n; then
        HOOK=1
    else
        HOOK=0
    fi
    say ""
fi

# --- install binary ---

mkdir -p "$bin_dir"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
fetch_script "$tmp"
install -m 0755 "$tmp" "$bin_path"
say "installed ${bin_path}"

# --- PATH (required for `rprt` as a command) ---

if [[ "$SYSTEM" == "1" ]]; then
    if ! path_has_dir "$bin_dir"; then
        warn "${bin_dir} is not on PATH in this environment"
        warn "system installs expect ${bin_dir} to be on PATH; fix PATH or open a login shell"
    fi
else
    ensure_path_session "$bin_dir"
    while IFS= read -r rc; do
        append_path_export "$rc" "$bin_dir"
    done < <(user_rcs | sort -u)
fi

# --- optional auto-run hook ---

if [[ "$HOOK" == "1" ]]; then
    if [[ "$SYSTEM" == "1" ]]; then
        cat >"$profile_d" <<EOF
# rprt auto-run
case \$- in *i*) ;; *) return ;; esac
[ -x ${bin_path} ] && ${bin_path}
EOF
        chmod 0644 "$profile_d"
        say "auto-run hooked in ${profile_d}"
    else
        while IFS= read -r rc; do
            append_hook "$rc" "$bin_path"
        done < <(user_rcs | sort -u)
    fi
else
    say "skipped auto-run hook (use --hook to enable)"
fi

# --- verify `rprt` is invokable ---

say ""
if ! command -v rprt >/dev/null 2>&1; then
    warn "file installed at ${bin_path}, but the 'rprt' command is not on PATH"
    warn "open a new shell, or run:  export PATH=\"${bin_dir}:\$PATH\""
    die "install incomplete: 'rprt' not available as a command"
fi

resolved="$(command -v rprt)"
if [[ "$resolved" != "$bin_path" ]]; then
    if ! cmp -s "$resolved" "$bin_path" 2>/dev/null; then
        warn "'rprt' resolves to ${resolved}, not ${bin_path}"
        warn "another rprt may be shadowing this install"
    fi
fi

say "verified: $(command -v rprt)"
say ""
"$bin_path" || true
say ""
say "edit ${bin_path} to change TITLE / fields"
if [[ "$HOOK" != "1" ]]; then
    say "run 'rprt' anytime; reinstall with --hook to auto-run on login"
fi
