# openmosh-app

Mobile client of [OpenMosh](https://github.com/lesquel/OpenMosh): an SSH terminal designed for
AI coding agents, with encrypted push notifications and one-tap approvals. **Android first.**

> Status: v0.1 in development.

## Stack

- Flutter (stable) + Riverpod + go_router + drift
- Rust core (`rust/`) via `flutter_rust_bridge` v2: SSH/SFTP (`russh`), push crypto
- Terminal: `xterm` package behind a `TerminalEmulator` port
- Push: UnifiedPush (ntfy distributor), no Google services

## Architecture

Clean Architecture by feature. See [`ARCHITECTURE.md`](./ARCHITECTURE.md).

## Development (once scaffolded)

```sh
flutter pub get
flutter_rust_bridge_codegen generate
flutter test
flutter run
```

Requirements: Flutter SDK, Rust toolchain (`rustup`), Android SDK + NDK.

## License

Proposed GPL-3.0 (pending confirmation).
