import 'package:flutter/material.dart';

/// The Falconer logo: the peregrine falcon on its rounded night tile.
///
/// Renders `assets/branding/falconer.png`, the same artwork as the launcher icon.
class FalconLogo extends StatelessWidget {
  const FalconLogo({super.key, this.size = 160, this.semanticLabel = 'Falconer logo'});

  /// Bundled artwork, 512 × 512 with transparent rounded corners.
  static const asset = 'assets/branding/falconer.png';

  final double size;

  /// Read by screen readers; `null` hides the image from them (decorative use).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final label = semanticLabel;
    return Image.asset(
      asset,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      semanticLabel: label,
      excludeFromSemantics: label == null,
    );
  }
}
