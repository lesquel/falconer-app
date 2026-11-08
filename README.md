# openmosh-app

Mobile client of [OpenMosh](https://github.com/lesquel/OpenMosh): an SSH terminal designed for
AI coding agents, with end-to-end encrypted push notifications and one-tap approvals.
**Android first.**

> Status: v0.1. Everything builds and is unit/widget tested; end-to-end behaviour still needs a
> run on a real phone against a host running `openmosh-hook`.

## What it does

- **Hosts and keys** — add, edit and delete hosts; generate an Ed25519 key on the phone or import
  an existing unencrypted `ssh-ed25519` key; copy the public key. Private keys are encrypted
  under an auth-bound Android Keystore key: every new SSH connection asks for biometrics or the
  device credential, enforced by the hardware. Requires Android 9+ and a screen lock.
- **QR pairing** — scan the code printed by `openmosh-hook pair` (or paste the `openmosh://pair`
  link). The phone creates its keys, registers for UnifiedPush and pairs over a one-shot
  encrypted exchange inside the tailnet. The host's SSH key fingerprint arrives in
  the host's encrypted, token-authenticated reply and is pinned.
- **SSH pairing** — for a host you already reach with your own key: add it manually, confirm its
  host key fingerprint, then *Enable notifications* runs `openmosh-hook pair-ssh` over SSH.
- **Terminal** — full xterm emulation in the chosen color scheme. A grid of six big keys
  (Esc, Tab, Ctrl, *more keys*, Chat, Keyboard) sits under the thumb; *more keys* opens rows with
  Alt, arrows, `|`, `/`, `~`, `-`, text size −/+ and the tmux or Herdr prefix keys. Chat mode
  composes a whole message with image/file attachments before sending it. Automatic reconnect
  with backoff on network change or app resume, re-attaching the Herdr/tmux session; sessions
  stay connected in the background unless disabled in Settings.
- **Sessions** — lists Herdr/tmux sessions and agents through the hook and attaches to one.
- **Paired devices** — the host screen lists every device paired with that host
  (`openmosh-hook devices list`): name, paired date, a stale push endpoint and which one is
  *this phone*. *Revoke* asks for confirmation, then for your fingerprint, face or screen lock,
  and runs `openmosh-hook devices revoke`. Revoking this phone warns first that OpenMosh loses
  access to that host.
- **App lock** — optional, off by default (*Settings → Lock OpenMosh*). When on, OpenMosh asks
  for user verification when it opens and after more than 60 s in the background; until then
  the screen shows only the mole.
- **Inbox** — encrypted pushes are decrypted on the phone; approve, deny or reply from the inbox
  or from a notification (which opens a confirm screen; nothing is sent from the lock screen).
- **Uploads** — pick an image or file, upload it over SFTP to `~/.openmosh/uploads/` and paste
  the path at the cursor.
- **Home** — greets you, says which computer is waiting for an answer and puts the newest
  request in a big card you can open with one thumb; below are your computers with *Terminal*
  and *Sessions* buttons. Tabs (Hosts, Inbox, Keys, Settings) are a dock of big tiles.

## Look and feel

The app follows the "UI-G" one-hand design: black `#0A0A0A` / white `#FAFAFA`, rounded cards
(`#171717` / `#262626` on dark), big actions in the bottom half of the screen and one accent
color. The mascot, **Topo** the mole with accent goggles, is the launcher icon (adaptive, with
an Android 13 themed variant), the splash screen and the empty, loading and pairing-success
states.

**Settings → Colors** chooses:

| Setting | Options | Default |
|---|---|---|
| Accent | Blue `#6B93FF`, Green `#4ADE9E`, Violet `#B69CFF`, Amber `#FFC24D`, Coral `#FF8F7A`, White `#FAFAFA` (darker shades on the light theme) | Blue |
| App theme | System, Light, Dark | System (an older install keeps its dark/light choice) |
| Terminal | Black, Paper, Sepia, High contrast | Black |

Accessibility: every text color passes WCAG 2.2 AA (4.5:1) on every surface of both themes, for
every accent and terminal scheme (`test/app/theme_contrast_test.dart`); touch targets are at
least 44 px; a selected choice, active modifier or selected tab is also marked with a check, dot,
lock or label, never by color alone. The font is Manrope, bundled under the SIL Open Font
License 1.1 (`assets/fonts/Manrope-OFL.txt`, also listed in the app's licenses); no font is
downloaded at runtime.

## Security properties

| Property | How |
|---|---|
| Host key pinning, no override | The Rust core aborts the handshake unless the server key matches the pinned `SHA256:` fingerprint. The mismatch screen has no "continue" button. |
| Keys | Ed25519 generated on the device. SSH private keys are encrypted under an Android Keystore key created with user authentication required (`flutter_secure_storage` `AndroidOptions.biometric`, `enforceBiometrics`, `requireBiometricsPerOperation`): the hardware refuses to decrypt them without a fresh biometric or screen-lock prompt, on every new connection. A screen lock is therefore required, and Android 9+. Keys stored by earlier builds (Keystore-wrapped but not auth-bound) are found at startup and moved to the bound store right after the next successful user verification (or on their first unlock, whichever comes first); new keys are only ever written to the bound store. The push key is not auth-bound because the background engine decrypts notifications without a prompt; it can only read notifications. The private key is never displayed or copied; the clipboard is cleared when the import dialog closes, whether the key was imported or the dialog was cancelled. |
| Push E2EE | X25519 + HKDF-SHA256 + XChaCha20-Poly1305, decrypted in pure Dart. Bodies with a wrong `kid`, version or tag are discarded. Verified against the hook's shared test vectors. |
| Push replay | A decrypted push is dropped when its `ts` is more than 24 h old or more than 5 min in the future, or when the inbox already holds that event id with the same or a later `seq` (pushes can arrive out of order, so there is no per-host high-water mark). Resolved pushes reuse the event id with a new `seq`. The inbox sync over SSH reads from its own cursor (the hook's `last_seq`), so it still brings in anything dropped or lost. |
| Device revocation | Paired devices are listed and revoked in the app (SEC-11); the hook removes the `authorized_keys` line and the push key together. Revoking needs a confirmation and a user verification. |
| App lock | Optional: user verification on a cold start and after more than 60 s in the background. While locked the app content is offstage (not painted, not in accessibility) and `FLAG_SECURE` still blocks screenshots. |
| Lock screen | Previews off by default: notifications say only `<host>: <agent> needs you`. With previews on, notifications are `VISIBILITY_PRIVATE`. |
| Screens | `FLAG_SECURE` on the whole app, always: `MainActivity.onCreate` sets it before the first frame and no screen clears it (no screenshots, screen recording or recents thumbnail of the terminal, keys, pairing, inbox or answer screens). |
| Backups | `allowBackup="false"`, backup and data-extraction rules exclude everything. |
| Network | No HTTP calls from the app. `network_security_config` refuses cleartext except `*.ts.net` (domain configs cannot express the 100.64.0.0/10 range; SSH and pairing use raw TCP inside the tailnet anyway). Pairing refuses codes whose address is outside 100.64.0.0/10. |
| Pairing input | QR codes and host replies are untrusted: `exp` must be a positive integer at most one day ahead, IPv4 octets must be plain decimal, host-sent aliases are limited to 64 characters and stripped of control, bidi, zero-width and separator characters. The pairing TCP exchange has one 15 s deadline and a 16 KiB reply cap. |
| Hook calls | The SSH exec request is always the constant `sh -s`, so the host's login shell (bash, fish, csh…) never parses app-built text. The script goes on the channel's stdin, then EOF: every argument of the `openmosh-hook` command is single-quoted (POSIX), and request JSON for `pair-ssh` is piped in with a quoted `printf '%s' '…' \| …`. |
| Uploads | Random hex prefix, names reduced to `[A-Za-z0-9._-]`, 50 MB limit, directory `0700`, files `0600`. Picked files copied into the app cache (by the app or by `file_picker`) are deleted after the upload, whether it succeeded or failed. |
| No third parties | No Firebase/FCM, Google Play services, ML Kit, analytics or crash SDKs. QR scanning uses zxing-cpp (`flutter_zxing`). Logging goes through a redacting logger. |

## Development

Requirements:

- Flutter stable (3.47+) — run `flutter config --no-analytics` and `dart --disable-analytics`
- Rust stable with Android targets:
  `rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android`
- Android SDK with platform 37 and an NDK
- `cargo install flutter_rust_bridge_codegen --version 2.13.0 --locked`

```sh
flutter pub get
flutter_rust_bridge_codegen generate   # after changing rust/src/api/**
dart run build_runner build            # after changing lib/shared/data/app_database.dart
flutter analyze
flutter test
(cd rust && cargo test && cargo clippy -- -D warnings && cargo deny check)
flutter build apk --debug              # build/app/outputs/flutter-apk/app-debug.apk
```

CI (`.github/workflows/ci.yml`) runs the same steps plus `dart format --set-exit-if-changed`
(100 columns, generated files excluded), `cargo fmt --check` and `cargo audit`. The supply-chain
policy is `rust/deny.toml` (GPL-3.0-compatible license allowlist, crates.io only); ignored
advisories are listed with their reason there and in `rust/.cargo/audit.toml`.

Generated files are committed: `lib/shared/bridge/**`, `rust/src/frb_generated.rs`,
`lib/shared/data/app_database.g.dart`.

### Shared crypto vectors

The wire-contract tests read `test/fixtures/vectors/{push_v1,pair_v1}.json`, copied from
`openmosh-hook` (`hook/tests/vectors/`). When the hook regenerates them, copy them again:

```sh
cp ../hook/tests/vectors/push_v1.json ../hook/tests/vectors/pair_v1.json test/fixtures/vectors/
```

If the files are missing the vector tests are skipped with `vectors pending`.

## Pairing a host

1. Install Tailscale on the host and the phone, signed in with the **same Tailscale account**.
2. Install a UnifiedPush distributor on the phone, for example **ntfy** (F-Droid or GitHub
   releases), and open it once.
3. Install `openmosh-hook` on the host (see the hook's README) and run:
   ```sh
   openmosh-hook pair
   ```
4. In the app: **Hosts → Pair with QR** (or *Scan pairing code* on the empty home), scan the QR, check the host address, choose
   a name for the phone and tap **Pair**. The code is single-use and expires after 5 minutes.
5. Open the host and tap **Shell** or **Load sessions**. The first connection asks for your
   fingerprint/PIN.

Already using SSH keys? Import your key under **Keys**, add the host manually, compare the shown
fingerprint with `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` on the host, then use
**Enable notifications** on the host screen.

## Architecture

Clean Architecture by feature. See [`ARCHITECTURE.md`](./ARCHITECTURE.md).

## License

Proposed GPL-3.0 (pending confirmation).
