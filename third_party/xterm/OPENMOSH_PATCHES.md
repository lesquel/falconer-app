# Vendored xterm 4.0.0

Copied from pub.dev `xterm` 4.0.0 (MIT, see `LICENSE`) and used through
`dependency_overrides` in the app's `pubspec.yaml`.

Patches:

1. `lib/src/ui/scroll_handler.dart`: use `localPosition` instead of the global
   `position` when converting a scroll gesture to a terminal cell, so mouse
   wheel events in alternate-screen apps (Herdr, tmux, TUIs) land under the
   finger.

Drop this copy when upstream ships the fix.
