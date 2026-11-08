import 'package:flutter/material.dart';

/// Topo, the OpenMosh mole: goggles in the accent color, coming out of its
/// tunnel (the SSH connection) with a prompt bubble.
///
/// Drawn with a [CustomPainter] on a 200 × 200 grid, from the approved design.
class MoleLogo extends StatelessWidget {
  const MoleLogo({
    super.key,
    this.size = 160,
    this.goggles = const Color(0xFF6B93FF),
    this.ground = const Color(0xFF262626),
    this.bubble = const Color(0xFFFAFAFA),
    this.bubbleInk = const Color(0xFF1F4FD8),
    this.showBubble = true,
    this.semanticLabel = 'OpenMosh mole',
  });

  final double size;
  final Color goggles;
  final Color ground;
  final Color bubble;
  final Color bubbleInk;
  final bool showBubble;

  /// Read by screen readers; `null` hides the drawing from them (decorative use).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final paint = CustomPaint(
      size: Size.square(size),
      painter: MolePainter(
        goggles: goggles,
        ground: ground,
        bubble: bubble,
        bubbleInk: bubbleInk,
        showBubble: showBubble,
      ),
    );
    final label = semanticLabel;
    return label == null
        ? ExcludeSemantics(child: paint)
        : Semantics(label: label, image: true, child: paint);
  }
}

class MolePainter extends CustomPainter {
  const MolePainter({
    required this.goggles,
    required this.ground,
    required this.bubble,
    required this.bubbleInk,
    required this.showBubble,
  });

  final Color goggles;
  final Color ground;
  final Color bubble;
  final Color bubbleInk;
  final bool showBubble;

  static const _fur = Color(0xFF5A4636);
  static const _belly = Color(0xFF7A6250);
  static const _dirt = Color(0xFF3A3A3A);
  static const _black = Color(0xFF0A0A0A);
  static const _pink = Color(0xFFE9A6A6);
  static const _nose = Color(0xFFC9737A);
  static const _ink = Color(0xFF2B2018);
  static const _white = Color(0xFFFAFAFA);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 200);
    Paint fill(Color c) => Paint()..color = c;
    Paint line(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void oval(double cx, double cy, double rx, double ry, Color c) => canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
      fill(c),
    );

    // Ground, dirt mounds and the tunnel.
    oval(100, 176, 96, 22, ground);
    canvas.drawPath(
      Path()
        ..moveTo(22, 176)
        ..quadraticBezierTo(24, 150, 44, 146)
        ..quadraticBezierTo(60, 150, 64, 164)
        ..close()
        ..moveTo(136, 164)
        ..quadraticBezierTo(140, 150, 156, 146)
        ..quadraticBezierTo(176, 150, 178, 176)
        ..close(),
      fill(_dirt),
    );
    oval(100, 168, 58, 14, Colors.black);

    // Body, belly and head.
    canvas.drawPath(
      Path()
        ..moveTo(48, 168)
        ..quadraticBezierTo(44, 104, 74, 78)
        ..quadraticBezierTo(100, 60, 126, 78)
        ..quadraticBezierTo(156, 104, 152, 168)
        ..close(),
      fill(_fur),
    );
    canvas.drawPath(
      Path()
        ..moveTo(62, 168)
        ..quadraticBezierTo(60, 120, 82, 98)
        ..quadraticBezierTo(100, 86, 118, 98)
        ..quadraticBezierTo(140, 120, 138, 168)
        ..close(),
      fill(_belly),
    );
    oval(100, 104, 40, 30, _fur);

    // Goggles.
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(58, 86, 84, 10), const Radius.circular(5)),
      fill(_black),
    );
    for (final x in [82.0, 118.0]) {
      canvas.drawCircle(Offset(x, 94), 15, fill(_black));
      canvas.drawCircle(Offset(x, 94), 10, fill(goggles));
      canvas.drawCircle(Offset(x - 4, 90), 3.4, fill(_white));
    }

    // Snout, nose, whiskers, mouth and tooth.
    oval(100, 122, 14, 10, _pink);
    oval(100, 117, 8, 5.5, _nose);
    final whisker = line(_ink, 2);
    for (final (a, b) in const [
      (Offset(86, 124), Offset(66, 120)),
      (Offset(86, 128), Offset(66, 132)),
      (Offset(114, 124), Offset(134, 120)),
      (Offset(114, 128), Offset(134, 132)),
    ]) {
      canvas.drawLine(a, b, whisker);
    }
    canvas.drawPath(
      Path()
        ..moveTo(96, 132)
        ..quadraticBezierTo(100, 136, 104, 132),
      line(_ink, 2.2),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(96, 132, 8, 7), const Radius.circular(1.5)),
      fill(_white),
    );

    // Digging paws with claws.
    canvas.drawPath(
      Path()
        ..moveTo(52, 150)
        ..quadraticBezierTo(36, 146, 30, 156)
        ..quadraticBezierTo(38, 166, 54, 164)
        ..close(),
      fill(_pink),
    );
    canvas.drawPath(
      Path()
        ..moveTo(148, 150)
        ..quadraticBezierTo(164, 146, 170, 156)
        ..quadraticBezierTo(162, 166, 146, 164)
        ..close(),
      fill(_pink),
    );
    final claw = line(_white, 3);
    for (final (a, b) in const [
      (Offset(30, 156), Offset(22, 152)),
      (Offset(31, 160), Offset(22, 160)),
      (Offset(34, 164), Offset(27, 169)),
      (Offset(170, 156), Offset(178, 152)),
      (Offset(169, 160), Offset(178, 160)),
      (Offset(166, 164), Offset(173, 169)),
    ]) {
      canvas.drawLine(a, b, claw);
    }

    // Prompt bubble.
    if (showBubble) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(130, 34, 44, 28), const Radius.circular(6)),
        fill(bubble),
      );
      canvas.drawPath(
        Path()
          ..moveTo(134, 62)
          ..lineTo(128, 72)
          ..lineTo(142, 62)
          ..close(),
        fill(bubble),
      );
      canvas.drawPath(
        Path()
          ..moveTo(138, 43)
          ..lineTo(144, 48)
          ..lineTo(138, 53),
        line(bubbleInk, 3),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(148, 51, 16, 3.4), const Radius.circular(1.7)),
        fill(bubbleInk),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(MolePainter old) =>
      old.goggles != goggles ||
      old.ground != ground ||
      old.bubble != bubble ||
      old.bubbleInk != bubbleInk ||
      old.showBubble != showBubble;
}
