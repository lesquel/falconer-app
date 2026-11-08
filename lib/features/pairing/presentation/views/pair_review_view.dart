import 'package:flutter/material.dart';

import '../../../../shared/ui/molecules/fingerprint_card.dart';
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
        Text('Pair with ${c.alias}', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('${c.sshUser}@${c.ip}:${c.sshPort}'),
        const SizedBox(height: 12),
        FingerprintCard(label: 'SSH host key that will be pinned', fingerprint: c.sshFingerprint),
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
