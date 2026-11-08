# openmosh-app — Architecture

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
│   ├── router.dart               # go_router routes (ids in paths are validated)
│   ├── home_shell.dart, app.dart, theme.dart
├── shared/
│   ├── domain/                   # failures, POSIX quoting, b64u, IPv4/tailnet rules, label cleaning
│   ├── crypto/                   # X25519 / HKDF / XChaCha20-Poly1305 (pure Dart)
│   ├── hook/domain/              # openmosh-hook commands, envelope parser, HookClient
│   ├── ssh/domain/               # SshConnector / SshConnection / ShellChannel ports
│   ├── ssh/data/datasources/     # ssh_bridge.dart: the only user of the Rust SSH API
│   ├── data/                     # drift database (hosts, key metadata, inbox, settings)
│   ├── logging/                  # redacting logger (the only logging entry point)
│   ├── platform/                 # FLAG_SECURE control
│   ├── ui/{atoms,molecules,organisms}/
│   └── bridge/                   # generated flutter_rust_bridge bindings (do not edit)
└── features/<feature>/
    ├── domain/{entities,repositories,usecases}/
    ├── data/{datasources,models,repositories}/
    └── presentation/{controllers,containers,views}/
rust/src/
├── api/                          # FRB-exposed surface: keys.rs, ssh.rs (opaque SshClient/ShellSession)
├── keys/                         # Ed25519 generation/import, SHA256 fingerprints
├── ssh/                          # pinned-host-key client, PTY shell, output batcher, exec
├── sftp/                         # uploads into ~/.openmosh/uploads
└── error.rs                      # `<code>: <detail>` errors mapped to Dart failures
test/                             # mirrors lib/; test/fixtures/vectors holds the hook's vectors
```

Push crypto is in Dart (not Rust) because it must run in the background engine that the
UnifiedPush connector starts without the Rust library loaded.

## Features

| Feature | Responsibility | Main ports / use cases |
|---|---|---|
| `hosts` | CRUD of pinned hosts, connection pool | `HostRepository`, `HostConnections`, `ManageHosts` |
| `keys` | Ed25519 keys, biometric unlock, push key | `KeyVault`, `UserAuthenticator`, `PushKeyStore` |
| `terminal` | PTY session, reconnect/backoff, re-attach | `TerminalEmulator`, `TerminalRunner`, `BackoffPolicy` |
| `keyboard` | Extra keys, sticky modifiers, tmux/Herdr presets | `KeyPresets`, `ModifierState` |
| `sessions` | Herdr/tmux sessions and agents via the hook | `SessionCatalog` |
| `inbox` | Push receive/decrypt, inbox state machine, answers | `PushEndpointSource`, `PushOpener`, `InboxRepository`, `EventNotifier`, `HandlePushMessage`, `RespondToEvent`, `SyncInbox` |
| `pairing` | QR pairing (TCP, v1 wire contract) and SSH pairing | `PairingGateway`, `PairWithQr`, `PairOverSsh`, `SyncPushEndpoint` |
| `uploads` | Pick file, SFTP upload, paste path | `FileSource`, `UploadFile` |
| `settings` | Previews, theme, font, presets | `SettingsRepository` |

Cross-feature use goes through domain types only (for example `pairing` uses `hosts`, `keys` and
`inbox` ports; every feature that talks to a host uses `HostConnections`).

## Key flows

```text
QR code ─► PairPayload.parse (version, expiry, tailnet IP, field sizes)
        ─► KeyVault.ensureDeviceKey + PushKeyStore.publicKey + PushEndpointSource.currentEndpoint
        ─► TcpPairingGateway: one sealed JSON line to ip:port, one reply line
        ─► Host saved with pinned ssh_fp, hpk, device_id

HostConnections.connection(host) ─► KeyVault.unlockPrivate (biometric) ─► Rust connect(pin)
        ─► post-connect: resolve hook path, re-send rotated push endpoint

UnifiedPush message ─► kid → host ─► PushCrypto.open ─► InboxEvent merge ─► notification
Notification action ─► /inbox/<host>/<event>?action= ─► confirm ─► verify user ─► hook respond

TerminalRunner: connect ─► openShell ─► write attach command ─► stream output
        connection lost ─► backoff 0.5 s … 8 s ─► reconnect (new unlock) ─► re-attach
        shell exited on a live connection ─► session ended; mismatch/cancel/auth ─► stop
```

## Rules

1. `domain/` imports only Dart core, `shared/domain`, other features' `domain/` and shared ports.
   No `package:flutter`, no Riverpod, no plugins.
2. A feature never imports another feature's `data/` or `presentation/`.
3. Views are presentational (props in, callbacks out) and are widget-tested; containers read
   providers; controllers are Riverpod `Notifier`s that call use cases.
4. All Rust access goes through `data/datasources/*_bridge.dart`.
5. Concrete adapters are chosen only in `lib/app/di.dart` (and platform objects in `main.dart`).
   Tests use fakes for ports (`test/support/fakes.dart`).
6. Logs go through `shared/logging/redacting_logger.dart`; never log terminal bytes, prompts,
   payloads, tokens, keys or endpoints.
