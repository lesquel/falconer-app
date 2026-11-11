#!/bin/sh
# openmosh-app one-line installer: clones (or updates) the repo, then runs
# scripts/setup.sh, which checks/installs the toolchain and installs the app.
#
#   curl -fsSL https://raw.githubusercontent.com/lesquel/openmosh-app/main/scripts/install.sh | bash
#
# While the repository is private, anonymous downloads fail: install and log
# in to the GitHub CLI (`gh auth login`) and run
#
#   bash <(gh api -H 'Accept: application/vnd.github.raw' repos/lesquel/openmosh-app/contents/scripts/install.sh)
#
# Options (the rest is passed to scripts/setup.sh: --platforms, --yes, --check,
# --no-tui, --force):
#   --branch <name>   branch to install from (default: main)
#   -h, --help
#
# Environment: OPENMOSH_DIR (default ~/openmosh-app), OPENMOSH_NO_GH=1 (never
# use the GitHub CLI), OPENMOSH_REPO_URL (clone from this URL instead; testing).
#
# Prints every command before running it and never uses sudo itself.
set -eu

REPO="lesquel/openmosh-app"
REPO_URL="${OPENMOSH_REPO_URL:-https://github.com/$REPO.git}"
DIR="${OPENMOSH_DIR:-$HOME/openmosh-app}"
BRANCH="main"

say() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
run() { printf '+ %s\n' "$*"; "$@"; }

[ -n "${HOME:-}" ] || die "HOME is not set"
[ "$(id -u)" -ne 0 ] || die "run this installer as your normal user, not root"

# Leaves the setup arguments in "$@", minus --branch.
n=$#
while [ "$n" -gt 0 ]; do
	a="$1"; shift; n=$((n - 1))
	case "$a" in
	--branch)
		[ "$n" -ge 1 ] || die "--branch needs a name"
		BRANCH="$1"; shift; n=$((n - 1)) ;;
	--branch=*) BRANCH="${a#--branch=}" ;;
	-h | --help) sed -n '2,/^set -eu/p' "$0" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
	*) set -- "$@" "$a" ;;
	esac
done
case "$BRANCH" in
'' | -* | *[!0-9A-Za-z._/-]*) die "invalid branch name: $BRANCH" ;;
esac

case "$(uname -s)" in
Darwin) OS=macos ;;
Linux) OS=linux ;;
MINGW* | MSYS* | CYGWIN*) OS=windows ;;
*) die "unsupported OS: $(uname -s)" ;;
esac
say "openmosh-app installer ($OS), branch $BRANCH, into $DIR"

if ! have git; then
	case "$OS" in
	macos) die "git is missing. Run: xcode-select --install" ;;
	windows) die "git is missing. Install Git for Windows (https://git-scm.com), or use WSL2." ;;
	*) die "git is missing. Install it with your package manager (e.g. sudo apt install git), then re-run." ;;
	esac
fi

# Public repo: plain git works. Private: GitHub CLI with a logged-in account.
USE_GH=0
if ! GIT_TERMINAL_PROMPT=0 git ls-remote --exit-code "$REPO_URL" HEAD >/dev/null 2>&1; then
	[ "${OPENMOSH_NO_GH:-0}" != 1 ] || die "cannot reach $REPO_URL anonymously and OPENMOSH_NO_GH=1"
	[ "$REPO_URL" = "https://github.com/$REPO.git" ] || die "cannot read $REPO_URL"
	if ! have gh; then
		say "The repository is private: the GitHub CLI is needed."
		say "Install it (https://cli.github.com), then run: gh auth login"
		exit 1
	fi
	if ! gh auth status >/dev/null 2>&1; then
		say "The repository is private and the GitHub CLI is not logged in."
		say "Run: gh auth login"
		exit 1
	fi
	USE_GH=1
fi

if [ -e "$DIR" ]; then
	[ -d "$DIR/.git" ] || die "$DIR exists and is not a git clone; set OPENMOSH_DIR to another path"
	origin="$(git -C "$DIR" remote get-url origin 2>/dev/null || true)"
	case "$origin" in
	"$REPO_URL" | */"$REPO" | */"$REPO.git" | *:"$REPO" | *:"$REPO.git") ;;
	*) die "$DIR is a clone of '$origin', not $REPO; set OPENMOSH_DIR to another path" ;;
	esac
	run git -C "$DIR" fetch origin "$BRANCH"
	run git -C "$DIR" checkout "$BRANCH"
	run git -C "$DIR" pull --ff-only origin "$BRANCH" ||
		die "cannot fast-forward $DIR (local changes or diverged history); resolve it, then re-run"
else
	if [ "$USE_GH" = 1 ]; then
		run gh repo clone "$REPO" "$DIR" -- --branch "$BRANCH"
	else
		run git clone --branch "$BRANCH" "$REPO_URL" "$DIR"
	fi
fi

[ -f "$DIR/scripts/setup.sh" ] || die "scripts/setup.sh does not exist on branch '$BRANCH'; try --branch <name>"
have bash || die "bash is required"

# stdin is the curl pipe: give the setup the terminal so prompts and gum work.
cd "$DIR"
printf '+ bash scripts/setup.sh'
for a in "$@"; do printf ' %s' "$a"; done
printf '\n'
if (: </dev/tty) 2>/dev/null; then
	exec bash scripts/setup.sh "$@" </dev/tty
fi
exec bash scripts/setup.sh "$@"
