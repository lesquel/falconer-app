import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

/// A sensitive identifier (address, key, fingerprint) shown masked until the
/// eye button reveals it. The revealed state lives in this widget, so it
/// resets whenever the screen is left. Masked text cannot be selected.
class SensitiveText extends StatefulWidget {
  const SensitiveText(
    this.value, {
    super.key,
    required this.masked,
    this.format,
    this.style,
    this.maxLines,
    this.overflow,
    this.revealLabel,
    this.textAlign,
  });

  /// The real value, shown only when revealed.
  final String value;

  /// What is shown while hidden.
  final String masked;

  /// Wraps the shown value in a sentence (`Pair with {ip}`).
  final String Function(String shown)? format;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  /// Tooltip of the eye while hidden; defaults to the localized "Show".
  final String? revealLabel;

  @override
  State<SensitiveText> createState() => _SensitiveTextState();
}

class _SensitiveTextState extends State<SensitiveText> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final shown = _revealed ? widget.value : widget.masked;
    final text = widget.format?.call(shown) ?? shown;
    final Widget body = _revealed
        ? SelectableText(
            text,
            style: widget.style,
            maxLines: widget.maxLines,
            textAlign: widget.textAlign,
          )
        : Text(
            text,
            style: widget.style,
            maxLines: widget.maxLines,
            overflow: widget.overflow,
            textAlign: widget.textAlign,
          );
    return Row(
      children: [
        Flexible(child: body),
        IconButton(
          tooltip: _revealed ? l.hideSensitive : (widget.revealLabel ?? l.showSensitive),
          icon: Icon(_revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          iconSize: 20,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          onPressed: () => setState(() => _revealed = !_revealed),
        ),
      ],
    );
  }
}
