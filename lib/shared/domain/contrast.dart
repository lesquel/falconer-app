/// WCAG 2.2 contrast math on ARGB integers (alpha is ignored).
library;

import 'dart:math' as math;

double _channel(int c) {
  final v = c / 255;
  return v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
}

/// Relative luminance of an opaque color, 0 (black) to 1 (white).
double relativeLuminance(int argb) =>
    0.2126 * _channel((argb >> 16) & 0xFF) +
    0.7152 * _channel((argb >> 8) & 0xFF) +
    0.0722 * _channel(argb & 0xFF);

/// Contrast ratio between two colors, 1 to 21. WCAG AA body text needs 4.5.
double contrastRatio(int a, int b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}
