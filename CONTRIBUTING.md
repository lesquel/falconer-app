# Contributing

Thanks for helping. Falconer is maintained by [lesquel](https://github.com/lesquel).
Everyone taking part follows the [Code of Conduct](./CODE_OF_CONDUCT.md).

## Issues first

- **Bug:** open an issue with the *Bug report* template: what you did, what you expected, what
  happened, versions (`falconer-hook version`, app version from Settings) and logs with secrets
  removed.
- **Feature:** open an issue with the *Feature request* template before writing code, so we agree
  on the behavior first.
- **Security problem:** do not open a public issue. Follow [`SECURITY.md`](./SECURITY.md) and use
  GitHub's [private vulnerability reporting](https://github.com/lesquel/falconer-app/security/advisories/new)
  so it stays private until it is fixed.

## Development setup

See *Development* in the [README](./README.md#development): `scripts/setup.sh` installs and checks
the toolchain, or follow the manual requirements there. The code layout and its rules are in
[`ARCHITECTURE.md`](./ARCHITECTURE.md).

## Pull requests

1. Fork, then branch from `main` (`fix/...`, `feat/...`).
2. Keep one change per PR, with its tests and docs.
3. Before pushing, run:
   ```sh
   # Format check, as CI runs it (generated files and third_party/ excluded)
   git ls-files '*.dart' | grep -v '^lib/shared/bridge/' | grep -v '\.g\.dart$' \
     | grep -v '^rust_builder/' | grep -v '^third_party/' \
     | xargs dart format --output=none --set-exit-if-changed
   flutter analyze
   flutter test
   (cd rust && cargo test && cargo clippy -- -D warnings)   # when rust/ changed
   ```
   CI runs the same checks and must be green. User-facing text goes in `lib/l10n/app_en.arb` and
   `lib/l10n/app_es.arb`; run `flutter gen-l10n` and commit the generated files.
4. Keep secrets and personal data out of the change: no real IPs, host names, keys or tokens in
   code, test fixtures, logs or screenshots. Use values like `100.88.77.66` or
   `host.tailnet-example.ts.net`.
5. Use [Conventional Commits](https://www.conventionalcommits.org/) (`fix:`, `feat:`, `docs:`…).
6. Open the PR against `main` and fill in the template. The maintainer reviews and merges.

By contributing you agree that your contribution is licensed under this repository's license.

## Releases

Nothing reaches users until it has been tested on a real device:

1. Merged work waits on `main`.
2. The maintainer tags a **release candidate**, `vX.Y.Z-rc.N`. Tags with a `-` are published
   as GitHub **pre-releases**: the installer's default ("latest") and the Releases page's
   "Latest" badge ignore them.
3. Testers install the pre-release APK on a phone and report problems as issues.
4. When the candidate works, the same commit is tagged `vX.Y.Z`: that is the release everyone
   gets.
