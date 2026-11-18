# falconer-app — Architecture

Clean Architecture organized by feature. Dependencies point inward (`domain` imports no
framework or I/O), features never import another feature's adapters, and concrete adapters are
named only in the composition root.

## Layout

```text
lib/
├── main.dart                     # starts the push pipeline; stops there for --unifiedpush-bg
├── app/
│   ├── di.dart                   # composition root: every Riverpod provider and adapter choice
│   ├── push_runtime.dart         # push pipeline shared by the UI and background engines
│   ├── router.dart               # go_router routes (ids in paths are validated; platform start routes ignored)
│   ├── home_shell.dart, app.dart, theme.dart
├── l10n/                         # English and Spanish ARB files and generated localizations
├── shared/
│   ├── domain/                   # failures, POSIX quoting, b64u, IPv4/tailnet rules, label cleaning
│   ├── crypto/                   # X25519 / HKDF / XChaCha20-Poly1305 (pure Dart)
│   ├── hook/domain/              # falconer-hook commands, envelope parser, HookClient (exec `sh -s`, script on stdin)
│   ├── ssh/domain/               # SshConnector / SshConnection / ShellChannel ports
│   ├── ssh/data/datasources/     # ssh_bridge.dart: the only user of the Rust SSH API
│   ├── data/                     # drift database (hosts, key metadata, inbox, settings)
│   ├── logging/                  # redacting logger (the only logging entry point)
│   ├── ui/{atoms,molecules,organisms}/ # UI-G widgets: FalconLogo, MoshTile, ThumbPage, KeyCap…
│   ├── ui/tokens/                # MoshColors theme extension (UI-G colors) and radii
│   └── bridge/                   # generated flutter_rust_bridge bindings (do not edit)
└── features/<feature>/
    ├── domain/{entities,repositories,usecases}/
    ├── data/{datasources,models,repositories}/
    └── presentation/{controllers,containers,views}/
rust/src/
├── api/                          # FRB-exposed surface: keys.rs, ssh.rs (opaque SshClient/ShellSession)
├── keys/                         # Ed25519 generation/import, SHA256 fingerprints
├── ssh/                          # pinned-host-key client, PTY shell, output batcher, exec
├── sftp/                         # uploads into ~/.falconer/uploads
└── error.rs                      # `<code>: <detail>` errors mapped to Dart failures
test/                             # mirrors lib/; test/fixtures/vectors holds the hook's vectors
```

Push crypto is in Dart (not Rust) because it must run in the background engine that the
UnifiedPush connector starts without the Rust library loaded.

## Features

| Feature | Responsibility | Main ports / use cases |
|---|---|---|
| `hosts` | CRUD of pinned hosts, connection pool, paired devices (list/revoke) | `HostRepository`, `HostConnections`, `ManageHosts`, `PairedDevices` |
| `keys` | Ed25519 keys, biometric unlock, push key, eager v0.1 key move | `KeyVault`, `UserAuthenticator`, `PushKeyStore`, `MigratingAuthenticator` |
| `lock` | Optional app lock (cold start, > 60 s in background) | `AppLock`, `AppLockGate` |
| `terminal` | PTY session, reconnect/backoff, re-attach | `TerminalEmulator`, `TerminalRunner`, `BackoffPolicy` |
| `keyboard` | Extra keys, sticky modifiers, tmux/Herdr presets, saved shortcuts | `KeyPresets`, `ModifierState` |
| `sessions` | Herdr/tmux sessions and agents via the hook | `SessionCatalog` |
| `inbox` | Push receive/decrypt, freshness and replay guard, inbox state machine, answers | `PushEndpointSource`, `PushOpener`, `SyncCursorStore`, `InboxRepository`, `EventNotifier`, `HandlePushMessage`, `RespondToEvent`, `SyncInbox` |
| `pairing` | QR pairing (TCP, v1 wire contract) and SSH pairing | `PairingGateway`, `PairWithQr`, `PairOverSsh`, `SyncPushEndpoint` |
| `uploads` | Pick file, SFTP upload, paste path | `FileSource`, `UploadFile` |
| `settings` | Previews, app lock, app theme, language, accent, terminal scheme, font, presets, notification hours | `SettingsRepository`, `AccentColor`, `TerminalScheme`, `NotificationHours` |
| `usage` | Agent token usage and plan limits per host, from `falconer-hook usage` | `LoadAgentUsage`, `UsageReport` |
| `herdr` | Herdr navigator: workspaces, tabs and panes, agent start, long-poll snapshots | `HerdrRepository`, `HerdrAction`, `HerdrSnapshot` |
| `agent_view` | Graphic view of a pane: parses the screen into prompts, replies, tool runs and choice menus | `AgentDetector` (one per agent), `ParseAgentScreen`, `ScreenHistory` |
| `voice` | On-device dictation: model catalog, downloads with size and SHA-256 checks, recognition | `ModelStore`, `NativeDownloader`, `VoiceRecorder`, `SpeechRecognizer` |
| `webpush` | Web notifications: a pasted code from the web app, confirmed, then sent to every paired host | `WebPushStore`, `WebPushSync`, `WebPushRegistration` |

Cross-feature use goes through domain types only (for example `pairing` uses `hosts`, `keys` and
`inbox` ports; every feature that talks to a host uses `HostConnections`).

## Key flows

```text
QR code ─► PairPayload.parse (version, expiry, tailnet IP, field sizes)
        ─► KeyVault.ensureDeviceKey + PushKeyStore.publicKey + PushEndpointSource.currentEndpoint
        ─► TcpPairingGateway: one sealed JSON line to ip:port, one reply line
        ─► Host saved with pinned ssh_fp, hpk, device_id

HostConnections.connection(host) ─► KeyVault.unlockPrivate (Keystore auth-bound read: hardware prompt;
        v0.1 keys: app prompt, then re-wrapped once) ─► Rust connect(pin)
        ─► post-connect: resolve hook path, re-send rotated push endpoint

UnifiedPush message ─► kid → host ─► PushCrypto.open ─► ts within 24 h / +5 min, seq > highest
        ─► InboxEvent merge ─► notification
Host screen ─► devices list ─► Revoke ─► confirm ─► verify user ─► hook devices revoke
Startup ─► KeyVault.hasLegacyKeys ─► next successful verification ─► migrateLegacyKeys (once)
App start / resume after > 60 s ─► AppLock (if on) ─► LockView ─► verify user
Notification action ─► /inbox/<host>/<event> + SuggestedAnswer (navigation extra, never a URL)
        ─► confirm ─► verify user ─► hook respond (partial_delivery: resolved, never retried)
Settings paste ─► WebPushCode (extra) ─► confirm screen shows the push service host ─► WebPushSync

TerminalRunner: connect ─► openShell ─► write attach command ─► stream output
        connection lost ─► backoff 0.5 s … 8 s ─► reconnect (new unlock) ─► re-attach
        shell exited on a live connection ─► session ended; mismatch/cancel/auth ─► stop
```

## External input

The app opens no external links. Android has no `VIEW` intent-filter and
`MainActivity.getInitialRoute` always returns `/`; iOS and macOS register no URL scheme and set
`FlutterDeepLinkingEnabled` to false; `buildRouter` sets `overridePlatformDefaultLocation`, so
go_router starts at `/` (or at the app's own notification that launched it). Values that change
what a screen does, such as a preselected answer (`SuggestedAnswer`) or a Web Push code
(`WebPushCode`), travel as navigation `extra`, which only in-app code can set.

Hardware-keyboard copy and paste on the terminal use the app's shortcuts
(`terminalShortcuts` in `terminal_screen_view.dart`) instead of the vendored xterm defaults: copy
goes through `SecureClipboard`, paste through `sanitizePaste`.

## Theme

`app/theme.dart` builds Material themes from `MoshColors` (light and dark, one accent from
`settings/domain/entities/appearance.dart`); widgets read `MoshColors.of(context)`. Appearance
choices are ARGB integers in the domain, so contrast is unit-tested without Flutter
(`shared/domain/contrast.dart`). The terminal maps `TerminalScheme` to xterm's `TerminalTheme` in
`terminal/presentation/views/terminal_palette.dart`. Settings are key/value rows (the inbox sync
keeps one `sync_cursor:<host id>` row per host; old `push_seq:<device id>` rows are ignored); the `theme` key
replaced the boolean `dark` key, which is still read (migration) and still written (so an older
build installed over a newer one keeps the choice). The Android launcher icon and splash are
vector drawables under `android/app/src/main/res/` (`ic_launcher_foreground`,
`mipmap-anydpi-v26`, `values-v31` for the Android 12+ splash).

## Rules

1. `domain/` imports only Dart core, `shared/domain`, other features' `domain/` and shared ports.
   No `package:flutter`, no Riverpod, no plugins.
2. A feature never imports another feature's `data/` or `presentation/`.
3. Views are presentational (props in, callbacks out) and are widget-tested; containers read
   providers; controllers are Riverpod `Notifier`s that call use cases.
4. All Rust access goes through `data/datasources/*_bridge.dart`.
5. Concrete adapters are chosen only in `lib/app/di.dart` (and platform objects in `main.dart`).
   Tests use fakes for ports (`test/support/fakes.dart`).
6. Legacy `openmosh` names (the Dart package, `dev.openmosh.*` ids and channels, the
   `openmosh://pair` link, the `openmosh-hook` fallback) are kept for compatibility with
   installed apps and paired hosts; new code uses Falconer names.
7. Logs go through `shared/logging/redacting_logger.dart`; never log terminal bytes, prompts,
   payloads, tokens, keys or endpoints.
