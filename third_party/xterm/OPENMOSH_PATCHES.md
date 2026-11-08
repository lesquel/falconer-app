# Vendored xterm 4.0.0

Copied from pub.dev `xterm` 4.0.0 (MIT, see `LICENSE`) and used through
`dependency_overrides` in the app's `pubspec.yaml`.

Patches:

1. `lib/src/ui/scroll_handler.dart`: use `localPosition` instead of the global
   `position` when converting a scroll gesture to a terminal cell, so mouse
   wheel events in alternate-screen apps (Herdr, tmux, TUIs) land under the
   finger.
2. `lib/src/core/mouse/button.dart`: wheel buttons are reported as 64-67
   (up, down, left, right). Upstream sent 68-71, which applications decode as
   Shift+wheel, so panes that scroll only on a plain wheel (Herdr agent panes)
   did not move.
3. `lib/src/core/mouse/reporter.dart`: legacy (non-SGR) mouse reports used
   row + 2 instead of row + 1.

Drop this copy when upstream ships the fixes.
