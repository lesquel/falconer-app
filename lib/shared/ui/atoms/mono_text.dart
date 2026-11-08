import 'package:flutter/material.dart';

/// Selectable monospace text for fingerprints and paths.
class MonoText extends StatelessWidget {
  const MonoText(this.text, {super.key, this.size = 13});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => SelectableText(
    text,
    style: TextStyle(fontFamily: 'monospace', fontSize: size),
  );
}
