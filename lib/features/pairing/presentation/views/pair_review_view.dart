import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/mask.dart';
import '../../../../shared/ui/atoms/sensitive_text.dart';
import '../../../../shared/ui/organisms/thumb_page.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
import '../../domain/entities/pair_payload.dart';

class PairReviewView extends StatefulWidget {
  const PairReviewView({
    super.key,
    required this.code,
    required this.busy,
    required this.onPair,
    required this.onCancel,
  });

  final PairPayload code;
  final bool busy;
  final ValueChanged<String> onPair;
  final VoidCallback onCancel;

  @override
  State<PairReviewView> createState() => _PairReviewViewState();
}

class _PairReviewViewState extends State<PairReviewView> {
  final _name = TextEditingController();
  var _named = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The default name follows the app language; it is set once.
    if (!_named) {
      _name.text = context.l10n.defaultDeviceName;
      _named = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.code;
    final muted = MoshColors.of(context).muted;
    final l = context.l10n;
    return ThumbPage(
      eyebrow: l.newComputer,
      title: SensitiveText(c.ip, masked: maskAddress(c.ip), format: l.pairWith),
      subtitle: l.pairReviewSubtitle,
      children: [
        TextField(
          controller: _name,
          decoration: InputDecoration(labelText: l.nameForThisPhone),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 16),
          child: Text(l.pairReviewNote, style: TextStyle(color: muted)),
        ),
        if (widget.busy) ...[const LinearProgressIndicator(), const SizedBox(height: 10)],
        FilledButton(
          onPressed: widget.busy ? null : () => widget.onPair(_name.text),
          child: Text(widget.busy ? l.pairing : l.pair),
        ),
        const SizedBox(height: 4),
        TextButton(onPressed: widget.busy ? null : widget.onCancel, child: Text(l.cancel)),
      ],
    );
  }
}
