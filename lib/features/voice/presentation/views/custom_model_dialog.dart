import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../domain/entities/custom_model.dart';
import '../../domain/entities/voice_model.dart';

String familyLabel(ModelFamily f) => switch (f) {
  ModelFamily.whisper => 'Whisper',
  ModelFamily.nemoTransducer => 'NeMo transducer (Parakeet)',
  ModelFamily.transducer => 'Zipformer transducer',
  ModelFamily.moonshine => 'Moonshine',
  ModelFamily.senseVoice => 'SenseVoice',
};

/// "Add a model": returns the validated entry, or null when cancelled. It
/// only saves the entry; the download is a separate tap.
class CustomModelDialog extends StatefulWidget {
  const CustomModelDialog({super.key, required this.newId});
  final String Function() newId;

  @override
  State<CustomModelDialog> createState() => _CustomModelDialogState();
}

class _CustomModelDialogState extends State<CustomModelDialog> {
  final _name = TextEditingController();
  final _url = TextEditingController();
  final _sha = TextEditingController();
  final _langs = TextEditingController();
  var _family = ModelFamily.whisper;
  Set<CustomModelError> _errors = const {};

  @override
  void dispose() {
    for (final c in [_name, _url, _sha, _langs]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final r = buildCustomModel(
      name: _name.text,
      url: _url.text,
      sha256: _sha.text,
      family: _family,
      languages: _langs.text,
      newId: widget.newId,
    );
    switch (r) {
      case CustomModelOk(:final model):
        Navigator.of(context).pop(model);
      case CustomModelInvalid(:final errors):
        setState(() => _errors = errors);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String? err(CustomModelError e, String text) => _errors.contains(e) ? text : null;
    return AlertDialog(
      title: Text(l.voiceAddCustom),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.voiceAddCustomBody),
          const SizedBox(height: 12),
          TextField(
            key: const Key('custom_name'),
            controller: _name,
            decoration: InputDecoration(
              labelText: l.voiceCustomName,
              errorText: err(CustomModelError.name, l.voiceErrName),
            ),
          ),
          TextField(
            key: const Key('custom_url'),
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l.voiceCustomUrl,
              errorText: err(CustomModelError.url, l.voiceErrUrl),
            ),
          ),
          TextField(
            key: const Key('custom_sha'),
            controller: _sha,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l.voiceCustomSha,
              errorText: err(CustomModelError.sha256, l.voiceErrSha),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<ModelFamily>(
            key: const Key('custom_family'),
            initialValue: _family,
            decoration: InputDecoration(labelText: l.voiceCustomFamily),
            items: [
              for (final f in ModelFamily.values)
                DropdownMenuItem(value: f, child: Text(familyLabel(f))),
            ],
            onChanged: (v) => setState(() => _family = v ?? _family),
          ),
          TextField(
            key: const Key('custom_languages'),
            controller: _langs,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l.voiceCustomLanguages,
              errorText: err(CustomModelError.languages, l.voiceErrLanguages),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.cancel)),
        FilledButton(key: const Key('custom_save'), onPressed: _submit, child: Text(l.save)),
      ],
    );
  }
}
