/// Port for the terminal emulator/renderer (xterm today, swappable).
library;

abstract interface class TerminalEmulator {
  int get cols;
  int get rows;

  /// Raw bytes from the host (UTF-8, possibly split mid-character).
  void feed(List<int> bytes);

  /// Local status line written by the app, never sent to the host.
  void notice(String text);

  /// Clears the screen and modes a previous session left (alternate
  /// screen, mouse reporting), before a reconnect re-attaches.
  void reset();

  /// Keystrokes typed into the emulator.
  Stream<String> get input;
  Stream<(int, int)> get resizes;
}
