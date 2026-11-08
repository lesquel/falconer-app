import 'package:flutter/material.dart';

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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Pair with ${c.ip}', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'The host proves itself with the key in the code; its name and SSH host key '
          'fingerprint are pinned from its encrypted reply.',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Name for this phone'),
        ),
        const SizedBox(height: 8),
        const Text(
          'This creates an SSH key on this phone, authorizes it on the host only from your '
          'tailnet, and registers encrypted notifications.',
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: widget.busy ? null : () => widget.onPair(_name.text),
          child: Text(widget.busy ? 'Pairing…' : 'Pair'),
        ),
        TextButton(onPressed: widget.busy ? null : widget.onCancel, child: const Text('Cancel')),
        if (widget.busy) const LinearProgressIndicator(),
      ],
    );
  }
}
