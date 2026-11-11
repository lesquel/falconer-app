#!/usr/bin/env bash
# Cross-platform setup for openmosh-app (macOS, Linux, WSL; Git Bash is detected
# and redirected to WSL2). Checks every dependency for the chosen build targets,
# fixes what is missing after a single confirmation, then builds and installs
# the app on a connected device.
#
# Usage: scripts/setup.sh [options]
#   --platforms ios,macos,android   skip the target picker
#   --yes                           no confirmation (and no gum installation offer)
#   --check                         only print the checklist
#   --no-tui                        plain text UI (default when not on a terminal)
#   --force                         continue on Git Bash/MSYS (unsupported)
#   -h, --help
#
# Network installers used: Homebrew packages on macOS; on Linux the official
# rustup installer (https://sh.rustup.rs, -y --no-modify-path) and the distro
# package manager; Google's Android command-line tools zip.

# shellcheck disable=SC2016,SC2018,SC2019  # literal $ in rc-file text; ASCII-only case folding is intended
set -u

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/development/flutter}"
ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
LOG="$APP_DIR/build/setup.log"

MODE=install        # install | check
ASSUME_YES=0
NO_TUI=0
FORCE=0
PLATFORMS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --yes|-y) ASSUME_YES=1 ;;
    --check) MODE=check ;;
    --no-tui) NO_TUI=1 ;;
    --force) FORCE=1 ;;
    --platforms)
      [ $# -ge 2 ] || { echo "--platforms needs a value (ios,macos,android)" >&2; exit 2; }
      PLATFORMS="$2"; shift ;;
    --platforms=*) PLATFORMS="${1#--platforms=}" ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1 (see --help)" >&2; exit 2 ;;
  esac
  shift
done

if ! { mkdir -p "$APP_DIR/build" && : >"$LOG"; } 2>/dev/null; then
  LOG="${TMPDIR:-/tmp}/openmosh-setup.log"   # read-only checkout
  : >"$LOG"
fi

# --- Requirements read from the repo (with fallbacks) --------------------------
ci_file="$APP_DIR/.github/workflows/ci.yml"
FLUTTER_VERSION="$(sed -n 's/.*flutter-version: *\([0-9.]*\).*/\1/p' "$ci_file" 2>/dev/null | head -1)"
FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.9}"
JDK_VERSION="$(sed -n 's/.*java-version: *"\{0,1\}\([0-9][0-9]*\)"\{0,1\}.*/\1/p' "$ci_file" 2>/dev/null | head -1)"
JDK_VERSION="${JDK_VERSION:-17}"
ANDROID_RUST_TARGETS="$(sed -n 's/.*--target \([a-z0-9_-]*android[a-z0-9_,-]*\).*/\1/p' "$ci_file" 2>/dev/null | head -1 | tr ',' ' ')"
ANDROID_RUST_TARGETS="${ANDROID_RUST_TARGETS:-aarch64-linux-android armv7-linux-androideabi x86_64-linux-android}"
# compileSdk of the app and of the Rust plugin (both platforms must be installed).
APP_SDK="$(sed -n 's/^ *compileSdk *= *\([0-9][0-9]*\).*/\1/p' "$APP_DIR/android/app/build.gradle.kts" 2>/dev/null | head -1)"
PLUGIN_SDK="$(sed -n 's/^ *compileSdkVersion *\([0-9][0-9]*\).*/\1/p' "$APP_DIR/rust_builder/android/build.gradle" 2>/dev/null | head -1)"
SDK_PLATFORMS="${APP_SDK:-37} ${PLUGIN_SDK:-36}"
# AGP 9.1 default build tools; Gradle fetches any other it needs (once the licenses are accepted).
BUILD_TOOLS="${ANDROID_BUILD_TOOLS:-36.0.0}"
# The NDK is `flutter.ndkVersion` (android/app/build.gradle.kts): defined by the pinned Flutter.
ndk_version() {
  v="$(sed -n 's/.*val ndkVersion: String = "\([^"]*\)".*/\1/p' \
    "$FLUTTER_HOME/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt" 2>/dev/null | head -1)"
  echo "${v:-28.2.13676358}"
}
IOS_RUST_TARGETS="aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios"
MACOS_RUST_TARGETS="aarch64-apple-darwin x86_64-apple-darwin"

# --- Platform detection ---------------------------------------------------------
UNAME="$(uname -s)"; ARCH="$(uname -m)"
case "$UNAME" in
  Darwin) OS=macos; OS_LABEL="macOS $ARCH" ;;
  Linux)
    if grep -qi microsoft /proc/version 2>/dev/null; then OS=wsl; OS_LABEL="Linux (WSL) $ARCH"
    else OS=linux; OS_LABEL="Linux $ARCH"; fi ;;
  MINGW*|MSYS*|CYGWIN*) OS=windows; OS_LABEL="Windows (Git Bash)" ;;
  *) OS=unknown; OS_LABEL="$UNAME $ARCH" ;;
esac
RUSTUP_BIN=""
[ "$OS" = macos ] && RUSTUP_BIN="/opt/homebrew/opt/rustup/bin"
export PATH="${RUSTUP_BIN:+$RUSTUP_BIN:}$HOME/.cargo/bin:$FLUTTER_HOME/bin:$PATH"

has() { command -v "$1" >/dev/null 2>&1; }

PM=none
if [ "$OS" = macos ] || has brew; then has brew && PM=brew; fi
if [ "$OS" != macos ]; then
  for p in apt-get dnf yum pacman zypper; do has "$p" && { PM="$p"; break; }; done
fi

# --- UI: plain helpers (always available) ----------------------------------------
B=$'\033[1m'; D=$'\033[2m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; C=$'\033[36m'; X=$'\033[0m'
trap 'printf "\033[?25h"' EXIT
trap 'printf "\n"; exit 130' INT

IS_TTY=0; { [ -t 0 ] && [ -t 1 ]; } && IS_TTY=1
USE_GUM=0

line_ok()   { printf '\r\033[K  %s✔%s %s %s%s%s\n' "$G" "$X" "$1" "$D" "${2:-}" "$X"; }
line_todo() { printf '\r\033[K  %s○%s %s %s%s%s\n' "$Y" "$X" "$1" "$D" "${2:-}" "$X"; }
line_fail() { printf '\r\033[K  %s✘%s %s %s%s%s\n' "$R" "$X" "$1" "$D" "${2:-}" "$X"; }
line_skip() { printf '\r\033[K  %s–%s %s%s %s%s\n' "$D" "$X" "$D" "$1" "${2:-}" "$X"; }

header() {
  if [ "$USE_GUM" = 1 ]; then printf '\n'; gum style --bold --foreground 212 "$1"
  else printf '\n%s%s%s\n' "$B" "$1" "$X"; fi
}
# box <color> <title> <lines...>
box() {
  color="$1"; title="$2"; shift 2
  if [ "$USE_GUM" = 1 ]; then
    gum style --border rounded --border-foreground "$color" --padding "0 2" --margin "1 0" \
      "$(gum style --bold --foreground "$color" "$title")" "" "$@"
  else
    printf '\n%s%s%s\n' "$B" "$title" "$X"
    for l in "$@"; do printf '  %s\n' "$l"; done
  fi
}

# --- gum bootstrap ----------------------------------------------------------------
install_gum() {
  case "$PM" in
    brew) brew install gum ;;
    apt-get)
      sudo mkdir -p /etc/apt/keyrings &&
        curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/charm.gpg &&
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list >/dev/null &&
        sudo apt-get update && sudo apt-get install -y gum ;;
    dnf|yum|zypper)
      printf '[charm]\nname=Charm\nbaseurl=https://repo.charm.sh/yum/\nenabled=1\ngpgcheck=1\ngpgkey=https://repo.charm.sh/yum/gpg.key\n' |
        sudo tee /etc/yum.repos.d/charm.repo >/dev/null &&
        sudo rpm --import https://repo.charm.sh/yum/gpg.key &&
        if [ "$PM" = zypper ]; then sudo zypper refresh && sudo zypper install -y gum
        else sudo "$PM" install -y gum; fi ;;
    pacman) sudo pacman -S --noconfirm gum ;;
    *)
      if has winget; then winget install charmbracelet.gum
      elif has scoop; then scoop install charm-gum
      else return 1; fi ;;
  esac
}

bootstrap_gum() {
  [ "$NO_TUI" = 1 ] && return
  [ "$IS_TTY" = 1 ] || return
  if ! has gum; then
    [ "$ASSUME_YES" = 1 ] || [ "$MODE" = check ] && return
    printf '%sgum%s (charmbracelet/gum) gives this installer a nicer interface. Install it? [y/N] ' "$B" "$X"
    read -r ans </dev/tty || ans=""
    case "$ans" in y|Y|yes|YES) ;; *) return ;; esac
    if [ "$OS" = windows ]; then echo "  (Git Bash: try 'winget install charmbracelet.gum' or 'scoop install charm-gum')"; fi
    if ! install_gum; then
      echo "gum could not be installed; continuing with the plain UI."
      return
    fi
  fi
  has gum && USE_GUM=1
}

# Asks for a yes/no. Plain: Enter = yes.
confirm() {
  if [ "$USE_GUM" = 1 ]; then gum confirm --default=true "$1"
  else
    printf '  %s %s[Enter = yes · Ctrl+C = cancel]%s ' "$1" "$D" "$X"
    read -r _ </dev/tty
  fi
}

# Asks for a yes/no where the safe answer is no: only an explicit "y"/"yes" counts.
confirm_no() {
  if [ "$USE_GUM" = 1 ]; then gum confirm --default=false "$1"
  else
    printf '  %s %s[y/N]%s ' "$1" "$D" "$X"
    read -r ans </dev/tty
    case "$ans" in y|Y|yes|YES|Yes) return 0 ;; *) return 1 ;; esac
  fi
}

# --- Windows / Git Bash ---------------------------------------------------------------
if [ "$OS" = windows ] && [ "$FORCE" = 0 ]; then
  bootstrap_gum
  box 214 "Git Bash detected" \
    "Android builds on Windows are most reliable inside WSL2." \
    "  1. wsl --install -d Ubuntu     (PowerShell, as admin)" \
    "  2. Open Ubuntu, clone the repo there and run scripts/setup.sh" \
    "  3. USB devices need usbipd-win, or use wireless debugging (adb pair)." \
    "Re-run with --force to try anyway (nothing is auto-installed on Windows)."
  exit 0
fi
if [ "$OS" = unknown ]; then echo "Unsupported OS: $UNAME" >&2; exit 1; fi

bootstrap_gum

# --- Target picker ------------------------------------------------------------------------
pick_targets() {
  if [ -n "$PLATFORMS" ]; then
    SEL="$(echo "$PLATFORMS" | tr ',' ' ' | tr 'A-Z' 'a-z')"
  else
    if [ "$OS" = macos ]; then avail="iOS macOS Android"; defaults="iOS"
    else avail="Android"; defaults="Android"; fi
    if [ "$IS_TTY" = 1 ] && [ "$ASSUME_YES" = 0 ]; then
      if [ "$OS" != macos ]; then
        printf '  %s– iOS      requires a Mac%s\n  %s– macOS    requires a Mac%s\n' "$D" "$X" "$D" "$X"
      fi
      if [ "$USE_GUM" = 1 ]; then
        # shellcheck disable=SC2086
        picked="$(gum choose --no-limit --header "Build targets (space = toggle, enter = confirm, j/k = move)" \
          --cursor-prefix "[ ] " --selected-prefix "[x] " --unselected-prefix "[ ] " \
          --selected "$(echo "$defaults" | tr ' ' ',')" $avail)" || exit 130
        SEL="$(echo "$picked" | tr 'A-Z' 'a-z' | tr '\n' ' ')"
      else
        printf '  Targets (%s) [%s]: ' "$(echo "$avail" | tr ' ' ',')" "$(echo "$defaults" | tr ' ' ',')"
        read -r ans </dev/tty || ans=""
        SEL="$(echo "${ans:-$defaults}" | tr ',' ' ' | tr 'A-Z' 'a-z')"
      fi
    else
      SEL="$(echo "$defaults" | tr 'A-Z' 'a-z')"
    fi
  fi
  WANT_IOS=0; WANT_MACOS=0; WANT_ANDROID=0
  for t in $SEL; do
    case "$t" in
      ios) WANT_IOS=1 ;;
      macos) WANT_MACOS=1 ;;
      android) WANT_ANDROID=1 ;;
      *) echo "unknown platform: $t (use ios, macos, android)" >&2; exit 2 ;;
    esac
  done
  if [ "$OS" != macos ] && [ $((WANT_IOS + WANT_MACOS)) -gt 0 ]; then
    echo "iOS and macOS builds require a Mac." >&2; exit 2
  fi
  if [ $((WANT_IOS + WANT_MACOS + WANT_ANDROID)) -eq 0 ]; then echo "No target selected." >&2; exit 2; fi
}

# --- Task runners ------------------------------------------------------------------------------
FRAMES='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

# Runs a command in the background with a spinner; output goes to the log.
task() {
  label="$1"; shift
  printf '\n### %s\n$ %s\n' "$label" "$*" >>"$LOG"
  start=$(date +%s)
  "$@" >>"$LOG" 2>&1 &
  pid=$!
  i=0
  printf '\033[?25l'
  while kill -0 "$pid" 2>/dev/null; do
    printf '\r\033[K  %s%s%s %s %s%ss%s' "$C" "${FRAMES:$((i % 10)):1}" "$X" "$label" "$D" "$(($(date +%s) - start))" "$X"
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
    box 196 "Failed: $label" "$(tail -n 25 "$LOG")" "" "Full log: $LOG"
    exit 1
  fi
}

# Waits until a check passes, with a spinner and no keypress.
wait_for() {
  label="$1"; shift
  i=0
  printf '\033[?25l'
  until "$@"; do
    for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
      printf '\r\033[K  %s%s%s %s' "$C" "${FRAMES:$((i % 10)):1}" "$X" "$label"
      i=$((i + 1))
      sleep 0.1
    done
  done
  printf '\033[?25h'
}

# --- Environment (re-evaluated after each fix) -------------------------------------------------------
jdk_home() {
  if [ "$PM" = brew ] && [ -d "$(brew --prefix "openjdk@$JDK_VERSION" 2>/dev/null)/libexec/openjdk.jdk/Contents/Home" ]; then
    echo "$(brew --prefix "openjdk@$JDK_VERSION")/libexec/openjdk.jdk/Contents/Home"; return
  fi
  for d in /usr/lib/jvm/*"$JDK_VERSION"*; do
    [ -x "$d/bin/javac" ] && { echo "$d"; return; }
  done
}
refresh_env() {
  jh="$(jdk_home)"
  if [ -n "$jh" ]; then export JAVA_HOME="$jh"; PATH="$jh/bin:$PATH"; fi
  if [ -d "$ANDROID_HOME" ]; then
    export ANDROID_HOME ANDROID_SDK_ROOT="$ANDROID_HOME"
    PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
  fi
  export PATH
}

# --- Checks (0 = satisfied) ------------------------------------------------------------------------------
chk_brew()     { has brew; }
chk_xcode()    { xcodebuild -version >/dev/null 2>&1; }
chk_license()  { xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; }
chk_pods()     { has pod; }
chk_base()     { has git && has curl && has unzip && has zip; }
chk_cc()       { has cc || has gcc; }
chk_rustup()   { has rustup; }
# An interrupted download leaves a toolchain without its manifest.
chk_rust()     { has rustup && rustc --version >/dev/null 2>&1 && rustup target list --installed >/dev/null 2>&1; }
chk_targets()  {
  chk_rust || return 1
  installed="$(rustup target list --installed)"
  for t in $RUST_TARGETS; do echo "$installed" | grep -qx "$t" || return 1; done
}
chk_flutter()  { has flutter && [ "$(flutter --version 2>/dev/null | head -1 | awk '{print $2}')" = "$FLUTTER_VERSION" ]; }
chk_engine()   {
  [ "$WANT_IOS" = 1 ] && { [ -d "$FLUTTER_HOME/bin/cache/artifacts/engine/ios-release" ] || return 1; }
  [ "$WANT_MACOS" = 1 ] && { [ -d "$FLUTTER_HOME/bin/cache/artifacts/engine/darwin-x64-release" ] || return 1; }
  [ "$WANT_ANDROID" = 1 ] && { [ -d "$FLUTTER_HOME/bin/cache/artifacts/engine/android-arm64-release" ] || return 1; }
  return 0
}
chk_path()     {
  [ -f "$RC_FILE" ] || return 1
  grep -qF "$FLUTTER_HOME/bin" "$RC_FILE" || return 1
  [ "$WANT_ANDROID" = 0 ] || grep -qF "ANDROID_HOME" "$RC_FILE"
}
chk_project()  {
  [ "$WANT_IOS" = 0 ] || [ -d "$APP_DIR/ios" ] || return 1
  [ "$WANT_MACOS" = 0 ] || [ -d "$APP_DIR/macos" ] || return 1
  [ "$WANT_ANDROID" = 0 ] || [ -d "$APP_DIR/android" ]
}
PLIST="$APP_DIR/ios/Runner/Info.plist"
USAGE_KEYS="NSCameraUsageDescription NSMicrophoneUsageDescription NSPhotoLibraryUsageDescription NSFaceIDUsageDescription"
chk_plist()    {
  [ -f "$PLIST" ] || return 1
  for k in $USAGE_KEYS; do /usr/libexec/PlistBuddy -c "Print :$k" "$PLIST" >/dev/null 2>&1 || return 1; done
}
SIGNING_FILE="$APP_DIR/apple/Signing.local.xcconfig"
chk_signing()  {
  grep -Eq '^DEVELOPMENT_TEAM *= *[A-Z0-9]{10}' "$SIGNING_FILE" 2>/dev/null \
    && ! grep -q 'DEVELOPMENT_TEAM *= *YOURTEAMID' "$SIGNING_FILE"
}
# "TEAMID<TAB>certificate name" per Apple Development identity (one per team).
signing_teams() {
  security find-identity -v -p codesigning 2>/dev/null \
    | sed -n 's/^ *[0-9]*) [0-9A-F]* "\(Apple Development: .*\)"$/\1/p' | sort -u \
    | while IFS= read -r name; do
        team="$(security find-certificate -c "$name" -p 2>/dev/null | openssl x509 -noout -subject 2>/dev/null \
          | sed -n 's/.*OU *= *\([A-Z0-9]\{10\}\).*/\1/p' | head -1)"
        [ -n "$team" ] && printf '%s\t%s\n' "$team" "$name"
      done | sort -u -t "$(printf '\t')" -k1,1
}
chk_identity() { [ -n "$(signing_teams)" ]; }
chk_jdk()      { [ -n "$(jdk_home)" ]; }
chk_cmdtools() { [ -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; }
chk_licenses() { [ -f "$ANDROID_HOME/licenses/android-sdk-license" ]; }
chk_sdkpkgs()  {
  [ -d "$ANDROID_HOME/platform-tools" ] || return 1
  [ -d "$ANDROID_HOME/build-tools/$BUILD_TOOLS" ] || return 1
  [ -d "$ANDROID_HOME/ndk/$(ndk_version)" ] || return 1
  for p in $SDK_PLATFORMS; do [ -d "$ANDROID_HOME/platforms/android-$p" ] || return 1; done
}
chk_fluttercfg() {
  for f in "$HOME/.config/flutter/settings" "$HOME/.flutter_settings"; do
    [ -f "$f" ] && grep -qF "$ANDROID_HOME" "$f" && grep -q '"jdk-dir"' "$f" && return 0
  done
  return 1
}

ios_device_id() {
  flutter devices --machine 2>/dev/null | /usr/bin/python3 -c 'import json,sys
for d in json.load(sys.stdin):
    if d.get("targetPlatform") == "ios" and not d.get("emulator"):
        print(d["id"] + "\t" + d["name"]); break' 2>/dev/null
}
android_device_id() {
  id="$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device" {print $1; exit}')"
  [ -n "$id" ] || return 0
  name="$(adb -s "$id" shell getprop ro.product.model 2>/dev/null | tr -d '\r')"
  printf '%s\t%s\n' "$id" "${name:-$id}"
}
chk_device_ios()     { [ -n "$(ios_device_id)" ]; }
chk_device_android() { [ -n "$(android_device_id)" ]; }

# --- Fixes ---------------------------------------------------------------------------------------------------
as_root() { if [ "$(id -u)" = 0 ]; then "$@"; else sudo -n "$@"; fi; }

# pm_install <logical names...>: maps names to the package manager's packages.
pm_install() {
  pkgs=""
  for n in "$@"; do
    case "$PM:$n" in
      brew:jdk) pkgs="$pkgs openjdk@$JDK_VERSION" ;;
      apt-get:jdk) pkgs="$pkgs openjdk-$JDK_VERSION-jdk" ;;
      dnf:jdk|yum:jdk|zypper:jdk) pkgs="$pkgs java-$JDK_VERSION-openjdk-devel" ;;
      pacman:jdk) pkgs="$pkgs jdk$JDK_VERSION-openjdk" ;;
      apt-get:cc) pkgs="$pkgs build-essential" ;;
      pacman:cc) pkgs="$pkgs base-devel" ;;
      *:cc) pkgs="$pkgs gcc" ;;
      *) pkgs="$pkgs $n" ;;
    esac
  done
  # shellcheck disable=SC2086
  case "$PM" in
    brew) brew install $pkgs ;;
    apt-get) as_root apt-get update -qq && as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y $pkgs ;;
    dnf|yum) as_root "$PM" install -y $pkgs ;;
    pacman) as_root pacman -S --needed --noconfirm $pkgs ;;
    zypper) as_root zypper install -y $pkgs ;;
    *) echo "No supported package manager found; install manually: $pkgs" >&2; return 1 ;;
  esac
}
fix_base()     { pm_install git curl unzip zip; }
fix_cc()       { pm_install cc; }
fix_jdk()      { pm_install jdk; }
fix_license()  { sudo -n xcodebuild -runFirstLaunch && sudo -n xcodebuild -license accept; }
fix_rustup()   {
  if [ "$OS" = macos ]; then brew install rustup
  else curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile minimal --default-toolchain none; fi
}
fix_rust()     {
  # Installing over an existing toolchain updates it in place; nothing is removed here.
  rustup toolchain install stable --profile minimal && rustup default stable
}
# A "stable" toolchain that is installed but unusable can only be repaired by removing it.
# That deletes the user's toolchain, so it is never done without an explicit yes (default no).
rust_repair() {
  rustup toolchain list 2>/dev/null | grep -q '^stable' || return 0
  chk_rust && return 0
  if [ "$IS_TTY" = 0 ]; then
    line_fail "Rust stable toolchain is broken" "not a terminal, so it cannot ask before removing it"
    echo "    Repair it yourself: rustup toolchain uninstall stable   (then re-run this script)"
    exit 1
  fi
  header "Rust toolchain"
  echo "  The installed 'stable' Rust toolchain is not working."
  echo "  Repairing it means uninstalling it (rustup toolchain uninstall stable) and installing it again."
  if confirm_no "Uninstall the Rust 'stable' toolchain and reinstall it?"; then
    rustup toolchain uninstall stable || { line_fail "Could not uninstall the Rust toolchain"; exit 1; }
  else
    line_fail "Rust stable toolchain left untouched" "repair it yourself, then re-run"
    exit 1
  fi
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
fix_engine()   {
  args=""
  [ "$WANT_IOS" = 1 ] && args="$args --ios"
  [ "$WANT_MACOS" = 1 ] && args="$args --macos"
  [ "$WANT_ANDROID" = 1 ] && args="$args --android"
  # shellcheck disable=SC2086
  flutter precache $args
}
fix_path()     {
  mkdir -p "$(dirname "$RC_FILE")"
  {
    printf '\n# openmosh-app toolchain\n'
    printf 'export PATH="%s$HOME/.cargo/bin:%s/bin:$PATH"\n' "${RUSTUP_BIN:+$RUSTUP_BIN:}" "$FLUTTER_HOME"
    if [ "$WANT_ANDROID" = 1 ]; then
      printf 'export ANDROID_HOME="%s"\nexport ANDROID_SDK_ROOT="$ANDROID_HOME"\n' "$ANDROID_HOME"
      [ -n "$(jdk_home)" ] && printf 'export JAVA_HOME="%s"\n' "$(jdk_home)"
      printf 'export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$JAVA_HOME/bin:$PATH"\n'
    fi
  } >>"$RC_FILE"
}
fix_project()  {
  plats=""
  [ "$WANT_IOS" = 1 ] && [ ! -d "$APP_DIR/ios" ] && plats="$plats,ios"
  [ "$WANT_MACOS" = 1 ] && [ ! -d "$APP_DIR/macos" ] && plats="$plats,macos"
  [ "$WANT_ANDROID" = 1 ] && [ ! -d "$APP_DIR/android" ] && plats="$plats,android"
  cd "$APP_DIR" && flutter create --platforms="${plats#,}" --org dev.openmosh --project-name openmosh .
}
fix_plist()    {
  # iOS kills the app when it uses these without a usage description.
  add() { /usr/libexec/PlistBuddy -c "Print :$1" "$PLIST" >/dev/null 2>&1 || /usr/libexec/PlistBuddy -c "Add :$1 string $2" "$PLIST"; }
  add NSCameraUsageDescription "OpenMosh uses the camera to scan pairing QR codes." &&
    add NSMicrophoneUsageDescription "OpenMosh uses the microphone for on-device voice input." &&
    add NSPhotoLibraryUsageDescription "OpenMosh lets you attach images from your library." &&
    add NSFaceIDUsageDescription "OpenMosh uses Face ID to unlock the app."
}
# Android command-line tools: pinned build, verified against the SHA-256 that Google publishes at
# https://developer.android.com/studio#command-line-tools-only before anything is extracted.
# To bump: copy the new build number and checksums from that page (never from the download itself).
CMDTOOLS_BUILD="${ANDROID_CMDTOOLS_BUILD:-15859902}"
cmdtools_pin() {
  case "$OS:$ARCH" in
    macos:arm64)   CMDTOOLS_FILE="commandlinetools-mac_arm64-${CMDTOOLS_BUILD}_latest.zip"
                   CMDTOOLS_SHA256=835b62a26162b229b441d1f6d4680383815a270809eb33522c0d480fa5002c4e ;;
    macos:*)       CMDTOOLS_FILE="commandlinetools-mac_x86_64-${CMDTOOLS_BUILD}_latest.zip"
                   CMDTOOLS_SHA256=c5a6378ab5cf7e0d5701921405115befff13e9ff7417fb588389338f8bd050f3 ;;
    *)             CMDTOOLS_FILE="commandlinetools-linux-${CMDTOOLS_BUILD}_latest.zip"
                   CMDTOOLS_SHA256=4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583 ;;
  esac
  if [ "$CMDTOOLS_BUILD" != 15859902 ]; then
    echo "ANDROID_CMDTOOLS_BUILD overrides the pinned build, but no checksum is pinned for it." >&2
    return 1
  fi
}
sha256_of() {
  if has sha256sum; then sha256sum "$1" | cut -d' ' -f1; else shasum -a 256 "$1" | cut -d' ' -f1; fi
}
fix_cmdtools() {
  cmdtools_pin || return 1
  tmp="$(mktemp -d)" || return 1
  if ! mkdir -p "$ANDROID_HOME/cmdline-tools" ||
     ! curl -fsSL -o "$tmp/cmdline.zip" "https://dl.google.com/android/repository/$CMDTOOLS_FILE"; then
    rm -rf "$tmp"; return 1
  fi
  got="$(sha256_of "$tmp/cmdline.zip")"
  if [ "$got" != "$CMDTOOLS_SHA256" ]; then
    echo "SHA-256 mismatch for $CMDTOOLS_FILE: expected $CMDTOOLS_SHA256, got $got. Aborting; nothing was extracted." >&2
    rm -rf "$tmp"; return 1
  fi
  unzip -q "$tmp/cmdline.zip" -d "$tmp" &&
    rm -rf "$ANDROID_HOME/cmdline-tools/latest" &&
    mv "$tmp/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
  rc=$?; rm -rf "$tmp"; return $rc
}
# Licenses are never auto-accepted: sdkmanager shows each one and the user answers it.
fix_licenses() {
  if [ "$IS_TTY" = 0 ]; then
    echo "  Android SDK licenses must be read and accepted by you. Run in a terminal:"
    echo "    $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --sdk_root=$ANDROID_HOME --licenses"
    return 1
  fi
  echo "  Read each Android SDK license and answer y to accept it (n to refuse)."
  "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$ANDROID_HOME" --licenses </dev/tty
  [ -f "$ANDROID_HOME/licenses/android-sdk-license" ]
}
fix_sdkpkgs()  {
  pk="platform-tools build-tools;$BUILD_TOOLS ndk;$(ndk_version)"
  for p in $SDK_PLATFORMS; do pk="$pk platforms;android-$p"; done
  # shellcheck disable=SC2086
  "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$ANDROID_HOME" $pk
}
fix_fluttercfg() { flutter config --android-sdk "$ANDROID_HOME" --jdk-dir "$(jdk_home)"; }

# --- Step registry: id|label|check|fix ("" fix = handled interactively) ---------------------------------------
STEPS=""
step() { STEPS="$STEPS$1|$2|$3|$4
"; }

build_steps() {
  RUST_TARGETS=""; TARGET_LABEL=""
  [ "$WANT_IOS" = 1 ] && { RUST_TARGETS="$RUST_TARGETS $IOS_RUST_TARGETS"; TARGET_LABEL="$TARGET_LABEL iOS"; }
  [ "$WANT_MACOS" = 1 ] && { RUST_TARGETS="$RUST_TARGETS $MACOS_RUST_TARGETS"; TARGET_LABEL="$TARGET_LABEL macOS"; }
  [ "$WANT_ANDROID" = 1 ] && { RUST_TARGETS="$RUST_TARGETS $ANDROID_RUST_TARGETS"; TARGET_LABEL="$TARGET_LABEL Android"; }
  TARGET_LABEL="$(echo "$TARGET_LABEL" | sed 's/^ *//; s/ /, /g')"
  RUST_TARGETS="${RUST_TARGETS# }"

  case "$(basename "${SHELL:-zsh}")" in
    bash) if [ "$OS" = macos ]; then RC_FILE="$HOME/.bash_profile"; else RC_FILE="$HOME/.bashrc"; fi ;;
    *) RC_FILE="$HOME/.zshrc" ;;
  esac
  # shellcheck disable=SC2088  # display text only
  RC_NAME="~/$(basename "$RC_FILE")"

  if [ "$OS" = macos ]; then
    step brew "Homebrew" chk_brew ""
    if [ $((WANT_IOS + WANT_MACOS)) -gt 0 ]; then
      step xcode "Xcode" chk_xcode ""
      step license "Xcode license & first launch" chk_license fix_license
      step pods "CocoaPods" chk_pods "brew install cocoapods"
    fi
    step rustup "rustup" chk_rustup "brew install rustup"
  else
    step base "git, curl, unzip, zip" chk_base fix_base
    step cc "C compiler" chk_cc fix_cc
    step rustup "rustup" chk_rustup fix_rustup
  fi
  step rust "Rust stable toolchain" chk_rust fix_rust
  step targets "Rust targets" chk_targets "rustup target add $RUST_TARGETS"
  step flutter "Flutter $FLUTTER_VERSION" chk_flutter fix_flutter
  step engine "Flutter engine artifacts" chk_engine fix_engine
  if [ "$WANT_ANDROID" = 1 ]; then
    step jdk "JDK $JDK_VERSION" chk_jdk fix_jdk
    step cmdtools "Android command-line tools" chk_cmdtools fix_cmdtools
    step licenses "Android SDK licenses" chk_licenses fix_licenses
    step sdkpkgs "Android SDK (platforms $(echo "$SDK_PLATFORMS" | tr ' ' '+'), build-tools $BUILD_TOOLS, NDK $(ndk_version))" chk_sdkpkgs fix_sdkpkgs
    step fluttercfg "Flutter knows the Android SDK & JDK" chk_fluttercfg fix_fluttercfg
  fi
  [ "$WANT_ANDROID" = 1 ] && ANDROID_LABEL="/ANDROID_HOME/JAVA_HOME"
  step path "PATH${ANDROID_LABEL:-} in $RC_NAME" chk_path fix_path
  step project "Platform projects" chk_project fix_project
  if [ "$WANT_IOS" = 1 ]; then
    step plist "Privacy permissions (Info.plist)" chk_plist fix_plist
    step device_ios "iPad/iPhone connected" chk_device_ios ""
  fi
  if [ "$WANT_IOS" = 1 ] || [ "$WANT_MACOS" = 1 ]; then
    step signing "Code signing team (apple/Signing.local.xcconfig)" chk_signing ""
  fi
  [ "$WANT_ANDROID" = 1 ] && step device_android "Android phone connected" chk_device_android ""
  return 0
}

# --- Flow ----------------------------------------------------------------------------------------------------------
if [ "$USE_GUM" = 1 ]; then
  gum style --border double --border-foreground 212 --padding "0 3" --margin "1 0" --bold \
    "openmosh-app setup" "$(gum style --faint "$OS_LABEL")"
else
  printf '%sopenmosh-app%s %s· setup · %s%s\n' "$B" "$X" "$D" "$OS_LABEL" "$X"
fi

pick_targets
build_steps
refresh_env
[ "$OS" = wsl ] && echo "  ${D}WSL: USB phones need usbipd-win, or use wireless debugging (adb pair).$X"
if [ "$OS" = linux ] || [ "$OS" = wsl ]; then
  [ "$ARCH" = aarch64 ] && [ "$WANT_ANDROID" = 1 ] &&
    echo "  ${Y}Note: Google ships no Linux arm64 build-tools/NDK; the Android install may fail on this CPU.$X"
fi

# 1. Checklist
header "Checking"
TODO=""; NEEDS_SUDO=0
while IFS='|' read -r id label check fix; do
  [ -n "$id" ] || continue
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
    case "$OS:$id" in
      macos:license|linux:base|linux:cc|linux:jdk|wsl:base|wsl:cc|wsl:jdk) NEEDS_SUDO=1 ;;
    esac
  fi
done <<EOF
$STEPS
EOF

[ "$MODE" = check ] && exit 0

if [ "$IS_TTY" = 0 ] && [ "$ASSUME_YES" = 0 ]; then
  echo "Not a terminal: re-run with --yes to proceed without confirmation (or --check)." >&2
  exit 1
fi
if [ "$NEEDS_SUDO" = 1 ] && [ "$(id -u)" != 0 ] && [ "$OS" != macos ] && ! has sudo; then
  line_fail "sudo is required to install system packages and was not found"; exit 1
fi

# 2. One confirmation
header "Plan"
n_todo="$(echo "$TODO" | wc -w | tr -d ' ')"
if [ "$n_todo" -gt 0 ]; then
  question="Fix $n_todo item(s) and install on $TARGET_LABEL?"
else
  question="Everything is ready. Build and install on $TARGET_LABEL?"
fi
if [ "$ASSUME_YES" = 1 ]; then echo "  $question"
else confirm "$question" || { echo "  Cancelled."; exit 0; }
fi

# One password, only if needed: Mac keychain (codesign) + sudo for the Xcode
# license, or sudo for system packages on Linux. Never stored; unset after use.
ask_password() {
  if [ "$USE_GUM" = 1 ]; then gum input --password --placeholder "$1" </dev/tty
  else printf '  %s%s%s: ' "$B" "$1" "$X" >&2; read -rs pw </dev/tty; echo >&2; printf '%s' "$pw"; fi
}
if [ "$OS" = macos ]; then
  KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"
  KEYCHAIN_MARK="$APP_DIR/build/.keychain-ready"
  need_keychain=0
  { [ "$WANT_IOS" = 1 ] || [ "$WANT_MACOS" = 1 ]; } && [ ! -f "$KEYCHAIN_MARK" ] && need_keychain=1
  if [ "$NEEDS_SUDO" = 1 ] || [ "$need_keychain" = 1 ]; then
    while :; do
      PW="$(ask_password "Mac password (asked once, for signing)")"
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
elif [ "$NEEDS_SUDO" = 1 ] && [ "$(id -u)" != 0 ] && ! sudo -n true 2>/dev/null; then
  tries=0
  while :; do
    PW="$(ask_password "sudo password (asked once, for system packages)")"
    printf '%s\n' "$PW" | sudo -S -v 2>/dev/null && break
    tries=$((tries + 1))
    [ "$tries" -ge 3 ] && { line_fail "sudo rejected the password"; exit 1; }
    line_fail "Wrong password, try again"
  done
  unset PW
fi

# 3. Fix
header "Installing"
while IFS='|' read -r id label check fix; do
  [ -n "$id" ] || continue
  case " $TODO " in *" $id "*) ;; *) continue ;; esac
  case "$id" in
    # Interactive/waited later; or satisfied by earlier fixes.
    signing|device_ios|device_android) continue ;;
  esac
  if $check; then line_ok "$label"; continue; fi
  case "$id" in
    rust) rust_repair ;;
    licenses)
      # Interactive: the user reads and accepts the licenses, so no spinner and no log capture.
      header "Android SDK licenses"
      if fix_licenses; then line_ok "$label"; else line_fail "$label"; exit 1; fi
      refresh_env
      continue ;;
  esac
  # shellcheck disable=SC2086
  task "$label" $fix
  refresh_env
done <<EOF
$STEPS
EOF

# 4. Devices, build and install per target
SUMMARY=""
note() { SUMMARY="$SUMMARY$1
"; }
cd "$APP_DIR" || exit 1
task "Dart packages" flutter pub get

# Signing: one local, gitignored xcconfig shared by the iOS and macOS projects.
pick_team() {
  list="$1"
  n="$(printf '%s\n' "$list" | wc -l | tr -d ' ')"
  if [ "$n" = 1 ] || [ "$ASSUME_YES" = 1 ]; then
    printf '%s\n' "$list" | head -1; return
  fi
  labels="$(printf '%s\n' "$list" | awk -F'\t' '{printf "%s  (%s)\n", $1, $2}')"
  if [ "$USE_GUM" = 1 ]; then
    chosen="$(printf '%s\n' "$labels" | gum choose --header "Signing team")"
  else
    i=1
    while IFS= read -r l; do printf '  %s) %s\n' "$i" "$l" >&2; i=$((i + 1)); done <<EOT
$labels
EOT
    printf '  Team number [1]: ' >&2
    read -r k </dev/tty
    chosen="$(printf '%s\n' "$labels" | sed -n "${k:-1}p")"
  fi
  [ -n "$chosen" ] || chosen="$(printf '%s\n' "$labels" | head -1)"
  printf '%s\n' "$list" | grep "^${chosen%% *}" | head -1
}

write_signing() {
  mkdir -p "$APP_DIR/apple"
  {
    echo "// Written by scripts/setup.sh. Local to this machine; gitignored."
    echo "DEVELOPMENT_TEAM = $1"
    echo "// macOS: add keychain-access-groups (protected SSH-key storage)."
    echo "OPENMOSH_ENTITLEMENTS_SUFFIX = Keychain"
    echo "CODE_SIGN_IDENTITY[sdk=macosx*] = Apple Development"
    echo "// Free accounts may need a unique bundle id:"
    echo "// PRODUCT_BUNDLE_IDENTIFIER = dev.yourname.openmosh"
  } >"$SIGNING_FILE"
}

if [ "$WANT_IOS" = 1 ] || [ "$WANT_MACOS" = 1 ]; then
  if ! chk_signing; then
    header "Code signing"
    if ! chk_identity && [ "$WANT_IOS" = 1 ]; then
      echo "  No Apple Development certificate found. In Xcode:"
      echo "  1. Xcode → Settings → Accounts → + → your Apple ID"
      echo "  2. Manage Certificates… → + → Apple Development"
      echo "  3. If the bundle ID is taken, set PRODUCT_BUNDLE_IDENTIFIER in apple/Signing.local.xcconfig"
      open -a Xcode 2>/dev/null || true
      wait_for "Waiting for an Apple Development certificate…" chk_identity
    fi
    TEAMS="$(signing_teams)"
    if [ -n "$TEAMS" ]; then
      PICK="$(pick_team "$TEAMS")"
      write_signing "$(printf '%s' "$PICK" | cut -f1)"
      line_ok "Code signing team" "$(printf '%s' "$PICK" | cut -f1) → apple/Signing.local.xcconfig"
    else
      note "macOS: no Apple Development certificate; building unsigned (SSH keys fall back to the legacy keychain). Copy apple/Signing.local.xcconfig.example to apple/Signing.local.xcconfig to sign."
    fi
  fi
fi

if [ "$WANT_IOS" = 1 ]; then
  if ! chk_device_ios; then
    header "iOS device"
    echo "  Connect the iPad by cable, unlock it and tap 'Trust This Computer'."
    echo "  First time: Settings → Privacy & Security → Developer Mode → On."
    wait_for "Waiting for the iPad…" chk_device_ios
  fi
  DEV="$(ios_device_id)"
  line_ok "iOS device" "$(printf '%s' "$DEV" | cut -f2)"
  header "Build iOS"
  task "Build iOS release (Rust compiles on the first run)" flutter build ios --release
  # Install over the existing app: `flutter install` uninstalls first, which
  # wipes paired hosts and keys on every 7-day free-signing reinstall.
  task "Install on $(printf '%s' "$DEV" | cut -f2)" xcrun devicectl device install app --device "$(printf '%s' "$DEV" | cut -f1)" "$APP_DIR/build/ios/iphoneos/Runner.app"
  note "iOS: installed on $(printf '%s' "$DEV" | cut -f2)."
  note "iOS free Apple ID: signing expires after 7 days (re-run to reinstall); if iOS blocks the app, trust your profile in Settings → General → VPN & Device Management."
fi

if [ "$WANT_MACOS" = 1 ]; then
  header "Build macOS"
  if chk_signing; then
    # flutter build does not pass -allowProvisioningUpdates; let Xcode create the profile once.
    task "Provision macOS signing profile" xcodebuild -workspace "$APP_DIR/macos/Runner.xcworkspace" -scheme Runner -configuration Release -allowProvisioningUpdates build
  fi
  task "Build macOS release" flutter build macos --release
  note "macOS: app at build/macos/Build/Products/Release/ (not installed; copy it to /Applications)."
fi

if [ "$WANT_ANDROID" = 1 ]; then
  if ! chk_device_android; then
    header "Android device"
    echo "  Enable Developer options (tap Build number 7 times), then USB debugging."
    echo "  Connect by cable, unlock the phone and accept the 'Allow USB debugging?' prompt."
    [ "$OS" = wsl ] && echo "  WSL: attach the phone with usbipd-win, or use wireless debugging: adb pair <ip:port>."
    wait_for "Waiting for the Android phone…" chk_device_android
  fi
  DEV="$(android_device_id)"
  line_ok "Android device" "$(printf '%s' "$DEV" | cut -f2)"
  header "Build Android"
  # arm64 only: what phones run; the CI release build splits per ABI.
  task "Build Android release APK (Rust compiles on the first run)" flutter build apk --release --target-platform android-arm64
  # `adb install -r` replaces the app and keeps its data (`flutter install`
  # uninstalls first and wipes paired hosts and keys).
  task "Install on $(printf '%s' "$DEV" | cut -f2)" adb -s "$(printf '%s' "$DEV" | cut -f1)" install -r "$APP_DIR/build/app/outputs/flutter-apk/app-release.apk"
  note "Android: installed on $(printf '%s' "$DEV" | cut -f2) (arm64 release build)."
  if [ ! -f "$APP_DIR/android/key.properties" ] && [ -z "${OPENMOSH_KEYSTORE_PATH:-}" ]; then
    note "Android signing: no android/key.properties, so Gradle signed the release APK with the debug key (see android/app/build.gradle.kts). Fine for personal installs; it will not update over an official release APK (uninstall that first)."
  fi
fi

note "Full log: $LOG"
box 42 "✔ OpenMosh is ready ($TARGET_LABEL)" "$SUMMARY"
