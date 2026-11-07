# openmosh-app — Architecture

Clean Architecture organized by feature. Global rules: dependencies point inward (`domain` imports no framework or I/O), features never import
another feature's adapters, and wiring happens only in the composition root.

## Layout

```text
lib/
├── main.dart                     # composition root: ProviderScope, router, overrides
├── app/                          # app shell: router, theme, bootstrap
├── shared/
│   ├── domain/                   # Result/Failure types, shared value objects (HostId, EventId)
│   ├── ui/                       # design system (atomic design)
│   │   ├── atoms/                # buttons, key caps, badges
│   │   ├── molecules/            # extra-keys row, host tile
│   │   └── organisms/            # extra-keys bar, inbox list
│   └── bridge/                   # generated flutter_rust_bridge bindings (do not edit)
└── features/
    └── <feature>/
        ├── domain/
        │   ├── entities/         # pure Dart, no Flutter imports
        │   ├── repositories/     # abstract ports
        │   └── usecases/         # one class per use case, call()
        ├── data/
        │   ├── datasources/      # Rust bridge, drift, secure storage, UnifiedPush
        │   ├── models/           # DTOs + mappers to entities
        │   └── repositories/     # port implementations
        └── presentation/
            ├── controllers/      # Riverpod Notifiers (state + intents)
            ├── containers/       # widgets that read providers and pass data down
            └── views/            # presentational widgets: props in, callbacks out
rust/
└── src/
    ├── api/                      # FRB-exposed functions (thin, per feature)
    ├── ssh/                      # russh session, PTY channel, reconnect
    ├── sftp/                     # uploads
    └── crypto/                   # X25519 + XChaCha20-Poly1305 for push payloads
test/                             # mirrors lib/features/<feature>/...
integration_test/                 # app ↔ sshd container
```

## Features

| Feature | Responsibility | Main ports |
|---|---|---|
| `hosts` | CRUD of saved hosts | `HostRepository` |
| `keys` | Generate/import Ed25519 keys, biometric unlock | `KeyStore` |
| `terminal` | Open session, stream I/O, resize, reconnect | `TerminalSession`, `TerminalEmulator` |
| `keyboard` | Extra-keys bar, shortcut presets (tmux, Herdr) | `KeyPresetRepository` |
| `sessions` | List and attach Herdr/tmux sessions | `SessionCatalog` |
| `inbox` | Receive/decrypt pushes, list events, approve/deny | `PushReceiver`, `InboxRepository`, `HookClient` |
| `pairing` | Device key + `openmosh-hook pair` over SSH | `PairingGateway` |
| `uploads` | Pick file/image, SFTP upload, paste path | `FileTransfer` |
| `settings` | Theme, font, retention | `SettingsRepository` |

## Rules

1. `domain/` imports only Dart core and `shared/domain`. No `package:flutter`, no Riverpod.
2. A feature talks to another feature only through its domain port, never its `data/`.
3. Views are presentational: no providers, no I/O, testable with golden/widget tests.
4. Containers wire providers to views. Controllers hold state and call use cases.
5. All Rust access goes through `data/datasources/*_bridge.dart`. Nothing else imports `shared/bridge`.
6. Riverpod overrides in tests replace data sources. Use cases are tested with fakes, test-first.
