import 'package:flutter/material.dart';

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
  final _name = TextEditingController(text: 'Android phone');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.code;
    final muted = MoshColors.of(context).muted;
    return ThumbPage(
      eyebrow: 'New computer',
      title: Text('Pair with ${c.ip}'),
      subtitle:
          'The host proves itself with the key in the code; its name and SSH host key '
          'fingerprint are pinned from its encrypted reply.',
      children: [
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Name for this phone'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 16),
          child: Text(
            'This creates an SSH key on this phone, authorizes it on the host only from your '
            'tailnet, and registers encrypted notifications.',
            style: TextStyle(color: muted),
          ),
        ),
        if (widget.busy) ...[const LinearProgressIndicator(), const SizedBox(height: 10)],
        FilledButton(
          onPressed: widget.busy ? null : () => widget.onPair(_name.text),
          child: Text(widget.busy ? 'Pairing…' : 'Pair'),
        ),
        const SizedBox(height: 4),
        TextButton(onPressed: widget.busy ? null : widget.onCancel, child: const Text('Cancel')),
      ],
    );
  }
}
