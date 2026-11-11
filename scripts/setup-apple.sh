#!/usr/bin/env bash
# One-shot setup: checks every dependency for building openmosh-app on
# iOS/macOS, fixes what is missing after a single confirmation, then builds
# and installs the app on a connected iPad/iPhone.
#
# Usage:
#   scripts/setup-apple.sh           check, confirm once, fix, install
#   scripts/setup-apple.sh --yes     same, without the confirmation
#   scripts/setup-apple.sh --check   only print the checklist

set -u

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/development/flutter}"
RUSTUP_BIN="/opt/homebrew/opt/rustup/bin"
RUST_TARGETS="aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios aarch64-apple-darwin x86_64-apple-darwin"
LOG="$APP_DIR/build/setup-apple.log"
MODE="${1:-}"

# Flutter version pinned by CI, so local builds match release builds.
FLUTTER_VERSION="$(sed -n 's/.*flutter-version: *\([0-9.]*\).*/\1/p' "$APP_DIR/.github/workflows/ci.yml" | head -1)"
FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.9}"

export PATH="$RUSTUP_BIN:$HOME/.cargo/bin:$FLUTTER_HOME/bin:$PATH"
mkdir -p "$(dirname "$LOG")"
: >"$LOG"

# --- UI ------------------------------------------------------------------------
B=$'\033[1m'; D=$'\033[2m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; C=$'\033[36m'; X=$'\033[0m'
trap 'printf "\033[?25h"' EXIT
trap 'printf "\n"; exit 130' INT

header() { printf '\n%s%s%s\n' "$B" "$1" "$X"; }
line_ok()   { printf '\r\033[K  %s✔%s %s %s%s%s\n' "$G" "$X" "$1" "$D" "${2:-}" "$X"; }
line_todo() { printf '\r\033[K  %s○%s %s %s%s%s\n' "$Y" "$X" "$1" "$D" "${2:-}" "$X"; }
line_fail() { printf '\r\033[K  %s✘%s %s %s%s%s\n' "$R" "$X" "$1" "$D" "${2:-}" "$X"; }

# Runs a command in the background with a spinner; output goes to the log.
task() {
  label="$1"; shift
  printf '\n### %s\n$ %s\n' "$label" "$*" >>"$LOG"
  start=$(date +%s)
  "$@" >>"$LOG" 2>&1 &
  pid=$!
  frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  i=0
  printf '\033[?25l'
  while kill -0 "$pid" 2>/dev/null; do
    printf '\r\033[K  %s%s%s %s %s%ss%s' "$C" "${frames:$((i % 10)):1}" "$X" "$label" "$D" "$(($(date +%s) - start))" "$X"
    i=$((i + 1))
    sleep 0.1
  done
  wait "$pid"; rc=$?
  printf '\033[?25h'
  secs="$(($(date +%s) - start))s"
  if [ "$rc" -eq 0 ]; then
    line_ok "$label" "$secs"
  else
    line_fail "$label" "$secs"
    printf '\n%sLast lines of %s:%s\n' "$D" "$LOG" "$X"
    tail -n 25 "$LOG" | sed 's/^/    /'
    exit 1
  fi
}

# Waits until a check passes, with a spinner and no keypress.
wait_for() {
  label="$1"; shift
  frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  i=0
  printf '\033[?25l'
  until "$@"; do
    for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
      printf '\r\033[K  %s%s%s %s' "$C" "${frames:$((i % 10)):1}" "$X" "$label"
      i=$((i + 1))
      sleep 0.1
    done
  done
  printf '\033[?25h'
}

# --- Checks (0 = satisfied) ----------------------------------------------------
has() { command -v "$1" >/dev/null 2>&1; }
chk_brew()     { has brew; }
chk_xcode()    { xcodebuild -version >/dev/null 2>&1; }
chk_license()  { xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; }
chk_pods()     { has pod; }
chk_rustup()   { has rustup; }
# An interrupted download leaves a toolchain without its manifest.
chk_rust()     { has rustup && rustc --version >/dev/null 2>&1 && rustup target list --installed >/dev/null 2>&1; }
chk_targets()  {
  chk_rust || return 1
  installed="$(rustup target list --installed)"
  for t in $RUST_TARGETS; do echo "$installed" | grep -qx "$t" || return 1; done
}
chk_flutter()  { has flutter && [ "$(flutter --version 2>/dev/null | head -1 | awk '{print $2}')" = "$FLUTTER_VERSION" ]; }
chk_engine()   { [ -d "$FLUTTER_HOME/bin/cache/artifacts/engine/ios-release" ]; }
chk_path()     { grep -qF "$FLUTTER_HOME/bin" "$HOME/.zshrc" 2>/dev/null; }
chk_project()  { [ -d "$APP_DIR/ios" ] && [ -d "$APP_DIR/macos" ]; }
PLIST="$APP_DIR/ios/Runner/Info.plist"
USAGE_KEYS="NSCameraUsageDescription NSMicrophoneUsageDescription NSPhotoLibraryUsageDescription NSFaceIDUsageDescription"
chk_plist()    {
  [ -f "$PLIST" ] || return 1
  for k in $USAGE_KEYS; do /usr/libexec/PlistBuddy -c "Print :$k" "$PLIST" >/dev/null 2>&1 || return 1; done
}
chk_signing()  { grep -q "DEVELOPMENT_TEAM = [A-Z0-9]" "$APP_DIR/ios/Runner.xcodeproj/project.pbxproj" 2>/dev/null; }
device_id() {
  flutter devices --machine 2>/dev/null | /usr/bin/python3 -c 'import json,sys
for d in json.load(sys.stdin):
    if d.get("targetPlatform") == "ios" and not d.get("emulator"):
        print(d["id"] + "\t" + d["name"]); break' 2>/dev/null
}
chk_device()   { [ -n "$(device_id)" ]; }

# --- Fixes ---------------------------------------------------------------------
fix_license()  { sudo -n xcodebuild -runFirstLaunch && sudo -n xcodebuild -license accept; }
fix_rust()     {
  rustup toolchain uninstall stable >/dev/null 2>&1
  rustup toolchain install stable --profile minimal && rustup default stable
}
fix_flutter()  {
  if [ -d "$FLUTTER_HOME/.git" ]; then
    git -C "$FLUTTER_HOME" fetch -q --depth 1 origin tag "$FLUTTER_VERSION" &&
      git -C "$FLUTTER_HOME" checkout -q "$FLUTTER_VERSION"
  else
    mkdir -p "$(dirname "$FLUTTER_HOME")" &&
      git clone -q --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
  fi && flutter --version
}
fix_path()     {
  printf '\n# openmosh-app toolchain\nexport PATH="%s:$HOME/.cargo/bin:%s/bin:$PATH"\n' "$RUSTUP_BIN" "$FLUTTER_HOME" >>"$HOME/.zshrc"
}
fix_project()  { cd "$APP_DIR" && flutter create --platforms=ios,macos --org dev.openmosh --project-name openmosh .; }
fix_plist()    {
  # iOS kills the app when it uses these without a usage description.
  add() { /usr/libexec/PlistBuddy -c "Print :$1" "$PLIST" >/dev/null 2>&1 || /usr/libexec/PlistBuddy -c "Add :$1 string $2" "$PLIST"; }
  add NSCameraUsageDescription "OpenMosh uses the camera to scan pairing QR codes." &&
    add NSMicrophoneUsageDescription "OpenMosh uses the microphone for on-device voice input." &&
    add NSPhotoLibraryUsageDescription "OpenMosh lets you attach images from your library." &&
    add NSFaceIDUsageDescription "OpenMosh uses Face ID to unlock the app."
}

# id | label | check | fix command ("" = handled interactively)
STEPS="brew|Homebrew|chk_brew|
xcode|Xcode|chk_xcode|
license|Xcode license & first launch|chk_license|fix_license
pods|CocoaPods|chk_pods|brew install cocoapods
rustup|rustup|chk_rustup|brew install rustup
rust|Rust stable toolchain|chk_rust|fix_rust
targets|Rust iOS/macOS targets|chk_targets|rustup target add $RUST_TARGETS
flutter|Flutter $FLUTTER_VERSION|chk_flutter|fix_flutter
engine|Flutter iOS/macOS engine|chk_engine|flutter precache --ios --macos
path|PATH in ~/.zshrc|chk_path|fix_path
project|ios/ and macos/ projects|chk_project|fix_project
plist|Privacy permissions (Info.plist)|chk_plist|fix_plist
signing|Code signing team|chk_signing|
device|iPad/iPhone connected|chk_device|"

# --- 1. Checklist ----------------------------------------------------------------
printf '%sopenmosh-app%s %s· iOS & macOS setup%s\n' "$B" "$X" "$D" "$X"
header "Checking"
TODO=""
NEEDS_SUDO=0
while IFS='|' read -r id label check fix; do
  printf '\r\033[K  %s…%s %s' "$D" "$X" "$label"
  if $check; then
    line_ok "$label"
  else
    case "$id" in
      brew|xcode)
        line_fail "$label" "install it manually, then re-run"
        [ "$id" = brew ] && echo "    https://brew.sh"
        [ "$id" = xcode ] && echo "    App Store → Xcode, open it once"
        exit 1 ;;
    esac
    line_todo "$label"
    TODO="$TODO $id"
    [ "$id" = license ] && NEEDS_SUDO=1
  fi
done <<EOF
$STEPS
EOF

[ "$MODE" = "--check" ] && exit 0

# --- 2. One confirmation -----------------------------------------------------------
header "Plan"
if [ -n "$TODO" ]; then
  printf '  Fix %s%d%s item(s), then build and install on your device.\n' "$B" "$(echo $TODO | wc -w | tr -d ' ')" "$X"
else
  printf '  Everything is ready. Build and install on your device.\n'
fi
if [ "$MODE" != "--yes" ]; then
  printf '  %sEnter%s to start · %sCtrl+C%s to cancel ' "$B" "$X" "$B" "$X"
  read -r _ </dev/tty
fi
# Ask for the Mac password once, up front, so nothing stops midway: sudo for
# the Xcode license, and the keychain so codesign stops showing one access
# dialog per framework it signs.
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"
KEYCHAIN_MARK="$APP_DIR/build/.keychain-ready"
if [ "$NEEDS_SUDO" = 1 ] || [ ! -f "$KEYCHAIN_MARK" ]; then
  while :; do
    printf '  %sMac password%s %s(asked once, for signing)%s: ' "$B" "$X" "$D" "$X"
    read -rs PW </dev/tty; echo
    security unlock-keychain -p "$PW" "$KEYCHAIN" 2>/dev/null && break
    line_fail "Wrong password, try again"
  done
  if security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$PW" "$KEYCHAIN" >/dev/null 2>&1; then
    touch "$KEYCHAIN_MARK"
    line_ok "Keychain ready for codesign"
  fi
  if [ "$NEEDS_SUDO" = 1 ]; then
    printf '%s\n' "$PW" | sudo -S -v 2>/dev/null || { line_fail "sudo rejected the password"; exit 1; }
  fi
  unset PW
fi

# --- 3. Fix ------------------------------------------------------------------------
header "Installing"
while IFS='|' read -r id label check fix; do
  case " $TODO " in *" $id "*) ;; *) continue ;; esac
  case "$id" in
    # Earlier fixes may already have satisfied these (e.g. rustup brings Rust).
    signing|device) continue ;;
  esac
  if $check; then line_ok "$label"; continue; fi
  # shellcheck disable=SC2086
  task "$label" $fix
done <<EOF
$STEPS
EOF

# --- 4. Signing and device (detected automatically, no keypress) -------------------
if ! chk_signing; then
  header "Code signing"
  echo "  Xcode is opening. Sign in and pick a Team:"
  echo "  1. Xcode → Settings → Accounts → + → your Apple ID"
  echo "  2. Runner → target Runner → Signing & Capabilities → pick your Team"
  echo "  3. If the bundle ID is taken, change it (e.g. dev.<you>.openmosh)"
  open "$APP_DIR/ios/Runner.xcworkspace"
  wait_for "Waiting for a Team to be selected in Xcode…" chk_signing
  line_ok "Code signing team"
fi

if ! chk_device; then
  header "Device"
  echo "  Connect the iPad by cable, unlock it and tap 'Trust This Computer'."
  echo "  First time: Settings → Privacy & Security → Developer Mode → On."
  wait_for "Waiting for the iPad…" chk_device
fi
DEVICE="$(device_id)"
DEVICE_ID="$(printf '%s' "$DEVICE" | cut -f1)"
line_ok "Device" "$(printf '%s' "$DEVICE" | cut -f2)"

# --- 5. Build and install -------------------------------------------------------------
header "Build"
cd "$APP_DIR" || exit 1
task "Dart packages" flutter pub get
task "Build iOS release (Rust compiles on the first run)" flutter build ios --release
task "Install on $(printf '%s' "$DEVICE" | cut -f2)" flutter install --release -d "$DEVICE_ID"

printf '\n%s%s✔ OpenMosh is on your device.%s\n' "$B" "$G" "$X"
printf '%s  Free Apple ID: if iOS blocks it, Settings → General → VPN & Device Management → trust your profile.\n' "$D"
printf '  Free signing expires after 7 days; re-run this script to reinstall.\n  Full log: %s%s\n' "$LOG" "$X"
