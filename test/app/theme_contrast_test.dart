import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/app/theme.dart';
import 'package:openmosh/features/settings/domain/entities/appearance.dart';
import 'package:openmosh/shared/domain/contrast.dart';
import 'package:openmosh/shared/ui/tokens/mosh_colors.dart';

/// WCAG 2.2 AA for body text.
const aa = 4.5;

void main() {
  test('contrast math matches known WCAG values', () {
    expect(contrastRatio(0xFF000000, 0xFFFFFFFF), closeTo(21, 0.01));
    expect(contrastRatio(0xFF777777, 0xFFFFFFFF), closeTo(4.48, 0.01));
  });

  for (final brightness in Brightness.values) {
    for (final accent in AccentColor.values) {
      test('${brightness.name} theme with the ${accent.name} accent passes AA', () {
        final c = buildTheme(brightness, accent: accent).extension<MoshColors>()!;
        int v(Color x) => x.toARGB32();
        final surfaces = [c.background, c.surface, c.surfaceHigh];
        for (final bg in surfaces) {
          for (final fg in [c.foreground, c.muted, c.accent, c.danger]) {
            expect(contrastRatio(v(fg), v(bg)), greaterThanOrEqualTo(aa), reason: '$fg on $bg');
          }
        }
        expect(contrastRatio(v(c.onAccent), v(c.accent)), greaterThanOrEqualTo(aa));
        expect(contrastRatio(v(c.onInverse), v(c.inverse)), greaterThanOrEqualTo(aa));
        // The approve button's check mark is drawn in the accent on black/white.
        expect(contrastRatio(v(c.accent), v(c.onAccent)), greaterThanOrEqualTo(aa));
      });
    }
  }

  for (final scheme in TerminalScheme.values) {
    test('${scheme.name} terminal scheme has readable text and 16 ANSI colors', () {
      final p = scheme.palette;
      expect(p.ansi, hasLength(16));
      expect(contrastRatio(p.foreground, p.background), greaterThanOrEqualTo(aa));
      // Colored output (red..white and bright red..bright white) stays readable.
      for (final i in [1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15]) {
        expect(contrastRatio(p.ansi[i], p.background), greaterThanOrEqualTo(aa), reason: 'ansi $i');
      }
    });
  }
}
