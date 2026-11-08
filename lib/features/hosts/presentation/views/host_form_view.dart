import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../keys/domain/entities/ssh_key_info.dart';
import '../../domain/entities/host_draft.dart';

class HostFormView extends StatefulWidget {
  const HostFormView({
    super.key,
    required this.keys,
    required this.onSubmit,
    this.initial,
    this.initialKeyId,
    this.busy = false,
    this.error,
    this.lockAddress = false,
  });

  final List<SshKeyInfo> keys;
  final HostDraft? initial;
  final String? initialKeyId;
  final bool busy;
  final String? error;
  final bool lockAddress;
  final void Function(HostDraft draft, String? keyId) onSubmit;

  @override
  State<HostFormView> createState() => _HostFormViewState();
}

class _HostFormViewState extends State<HostFormView> {
  late final _alias = TextEditingController(text: widget.initial?.alias);
  late final _address = TextEditingController(text: widget.initial?.address);
  late final _port = TextEditingController(text: '${widget.initial?.port ?? 22}');
  late final _user = TextEditingController(text: widget.initial?.user);
  late String? _keyId = widget.initialKeyId;

  @override
  void dispose() {
    for (final c in [_alias, _address, _port, _user]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _alias,
          decoration: InputDecoration(labelText: l.fieldName),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _address,
          enabled: !widget.lockAddress,
          decoration: InputDecoration(labelText: l.fieldAddress, hintText: 'box.tailnet.ts.net'),
          keyboardType: TextInputType.url,
          autocorrect: false,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _port,
          enabled: !widget.lockAddress,
          decoration: InputDecoration(labelText: l.fieldPort),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _user,
          decoration: InputDecoration(labelText: l.fieldUser),
          autocorrect: false,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          initialValue: _keyId,
          decoration: InputDecoration(labelText: l.fieldKey),
          items: [
            DropdownMenuItem(value: null, child: Text(l.thisDeviceKey)),
            for (final k in widget.keys.where((k) => k.id != SshKeyInfo.deviceKeyId))
              DropdownMenuItem(value: k.id, child: Text(k.label)),
          ],
          onChanged: (v) => setState(() => _keyId = v),
        ),
        if (widget.error != null) ...[
          const SizedBox(height: 12),
          Text(
            l.failureMessage(widget.error!),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: widget.busy
              ? null
              : () => widget.onSubmit(
                  HostDraft(
                    alias: _alias.text,
                    address: _address.text,
                    port: int.tryParse(_port.text) ?? 0,
                    user: _user.text,
                  ),
                  _keyId,
                ),
          child: Text(
            widget.busy ? l.checkingHostKey : (widget.lockAddress ? l.save : l.continueAction),
          ),
        ),
      ],
    );
  }
}
