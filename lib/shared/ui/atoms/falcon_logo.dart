import 'package:flutter/material.dart';

/// The Falconer logo: a falcon head on a rounded night tile, its iris in the
/// accent color.
///
/// Drawn with a [CustomPainter] on the 100 × 100 grid of
/// `assets/branding/falconer.svg`, the master artwork.
class FalconLogo extends StatelessWidget {
  const FalconLogo({
    super.key,
    this.size = 160,
    this.iris = defaultIris,
    this.semanticLabel = 'Falconer logo',
  });

  /// Iris color of the master artwork.
  static const defaultIris = Color(0xFF6B93FF);

  final double size;
  final Color iris;

  /// Read by screen readers; `null` hides the drawing from them (decorative use).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final paint = CustomPaint(
      size: Size.square(size),
      painter: FalconPainter(iris: iris),
    );
    final label = semanticLabel;
    return label == null
        ? ExcludeSemantics(child: paint)
        : Semantics(label: label, image: true, child: paint);
  }
}

class FalconPainter extends CustomPainter {
  const FalconPainter({required this.iris});

  final Color iris;

  static const _tileLight = Color(0xFF1B2645);
  static const _tileDark = Color(0xFF0A0E1A);
  static const _face = Color(0xFFF4F1EA);
  static const _plumage = Color(0xFF2B3348);
  static const _feather = Color(0xFF3E4A6A);
  static const _beak = Color(0xFFF2C14E);
  static const _lowerBeak = Color(0xFF46526F);
  static const _pupil = Color(0xFF0A0E1A);
  static const _white = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    Paint fill(Color c) => Paint()..color = c;

    // Rounded tile; the falcon runs off its bottom edge.
    final tile = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 100, 100),
      const Radius.circular(22),
    );
    canvas.clipRRect(tile);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0.2, -0.2),
          radius: 0.65,
          colors: [_tileLight, _tileDark],
        ).createShader(const Rect.fromLTWH(0, 0, 100, 100)),
    );

    // Face and throat.
    canvas.drawPath(
      Path()
        ..moveTo(30, 100)
        ..cubicTo(28, 82, 26, 66, 30, 54)
        ..cubicTo(33, 36, 46, 24, 60, 24)
        ..cubicTo(70, 24, 77, 29, 80, 36)
        ..lineTo(86, 40)
        ..cubicTo(90, 43, 91, 49, 89, 54)
        ..cubicTo(88, 58, 85, 61, 81, 62)
        ..cubicTo(82, 58, 82, 55, 80, 53)
        ..cubicTo(77, 55, 73, 56, 70, 56)
        ..cubicTo(68, 66, 68, 80, 72, 100)
        ..close(),
      fill(_face),
    );

    // Crown, nape and the dark malar stripe.
    canvas.drawPath(
      Path()
        ..moveTo(30, 100)
        ..cubicTo(28, 82, 26, 66, 30, 54)
        ..cubicTo(33, 36, 46, 24, 60, 24)
        ..cubicTo(70, 24, 77, 29, 80, 36)
        ..lineTo(76, 40)
        ..cubicTo(72, 38, 68, 38, 64, 40)
        ..cubicTo(58, 44, 56, 52, 56, 62)
        ..cubicTo(56, 68, 52, 70, 49, 66)
        ..cubicTo(47, 62, 46, 56, 44, 52)
        ..cubicTo(40, 58, 38, 70, 40, 100)
        ..close(),
      fill(_plumage),
    );

    // Feather lines.
    canvas.drawPath(
      Path()
        ..moveTo(35, 76)
        ..cubicTo(37, 68, 39, 62, 42, 57)
        ..moveTo(32, 92)
        ..cubicTo(33, 85, 34, 79, 36, 73)
        ..moveTo(44, 32)
        ..cubicTo(50, 28, 56, 27, 62, 28),
      Paint()
        ..color = _feather
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );

    // Beak.
    canvas.drawCircle(const Offset(66, 43), 7.4, fill(_plumage));
    canvas.drawPath(
      Path()
        ..moveTo(75, 35.5)
        ..cubicTo(79.5, 36.5, 83, 39, 85.5, 42.5)
        ..lineTo(80, 47.5)
        ..cubicTo(79, 43.5, 77, 41, 73.5, 39.5)
        ..close(),
      fill(_beak),
    );
    canvas.drawPath(
      Path()
        ..moveTo(85.5, 42.5)
        ..cubicTo(89.5, 45, 91, 49.5, 89, 54.5)
        ..cubicTo(88, 58, 85, 61, 81, 62)
        ..cubicTo(82, 58, 82, 55, 80, 52.5)
        ..lineTo(80, 47.5)
        ..close(),
      fill(_lowerBeak),
    );

    // Eye: yellow ring, accent iris, pupil and catchlight.
    canvas.drawCircle(const Offset(66, 43), 5.6, fill(_beak));
    canvas.drawCircle(const Offset(66, 43), 4.2, fill(iris));
    canvas.drawCircle(const Offset(66.6, 43.4), 2.3, fill(_pupil));
    canvas.drawCircle(const Offset(64.6, 41.4), 1, fill(_white));
    canvas.restore();
  }

  @override
  bool shouldRepaint(FalconPainter old) => old.iris != iris;
}
