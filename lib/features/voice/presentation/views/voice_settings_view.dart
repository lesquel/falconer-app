import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/molecules/mosh_tile.dart';
import '../../../../shared/ui/organisms/thumb_page.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
import '../../domain/entities/language_names.dart';
import '../../domain/entities/voice_model.dart';
import '../controllers/voice_models_controller.dart';

/// `487 MB`, `1.2 GB`.
String formatBytes(int bytes) {
  const mb = 1000 * 1000;
  if (bytes >= 1000 * mb) return '${(bytes / (1000 * mb)).toStringAsFixed(1)} GB';
  return '${(bytes / mb).round()} MB';
}

/// Settings → Voice input: pick, download and delete speech models, and the
/// spoken language.
class VoiceSettingsView extends StatelessWidget {
  const VoiceSettingsView({
    super.key,
    required this.models,
    required this.state,
    required this.selectedId,
    required this.language,
    required this.onDownload,
    required this.onCancel,
    required this.onDelete,
    required this.onSelect,
    required this.onLanguage,
    required this.onAddCustom,
    this.onBack,
  });

  final List<VoiceModel> models;
  final VoiceModelsState state;
  final String? selectedId;

  /// Empty for automatic.
  final String language;
  final ValueChanged<VoiceModel> onDownload;
  final ValueChanged<String> onCancel;
  final ValueChanged<VoiceModel> onDelete;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onLanguage;
  final VoidCallback onAddCustom;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = MoshColors.of(context);
    final selected = models.where((m) => m.id == selectedId).firstOrNull;
    final installed = state.installed ?? const <String>{};
    return ThumbPage(
      title: Text(l.voiceTitle),
      onBack: onBack,
      backTooltip: l.back,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(l.voiceIntro, style: TextStyle(color: c.muted)),
        ),
        if (selected != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MoshTile(
              key: const Key('voice_language'),
              child: _LanguagePicker(model: selected, language: language, onChanged: onLanguage),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(l.voiceModels, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        for (final m in models)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ModelTile(
              model: m,
              installed: installed.contains(m.id) && m.files.isNotEmpty,
              selected: m.id == selectedId,
              download: state.downloads[m.id],
              onDownload: () => onDownload(m),
              onCancel: () => onCancel(m.id),
              onDelete: () => onDelete(m),
              onSelect: () => onSelect(m.id),
            ),
          ),
        OutlinedButton.icon(
          key: const Key('voice_add_custom'),
          icon: const Icon(Icons.add),
          label: Text(l.voiceAddCustom),
          onPressed: onAddCustom,
        ),
      ],
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.model, required this.language, required this.onChanged});
  final VoiceModel model;
  final String language;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = MoshColors.of(context);
    final options = model.selectableLanguages;
    final title = Text(l.voiceLanguage, style: const TextStyle(fontWeight: FontWeight.w700));
    if (options.isEmpty) {
      return Row(
        children: [
          const Icon(Icons.translate, size: 20),
          const SizedBox(width: 8),
          Expanded(child: title),
          Flexible(
            child: Text(
              model.englishOnly ? l.voiceEnglishOnly : l.voiceLanguageAutoOnly,
              textAlign: TextAlign.end,
              style: TextStyle(color: c.muted),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        const Icon(Icons.translate, size: 20),
        const SizedBox(width: 8),
        Expanded(child: title),
        DropdownButton<String>(
          key: const Key('voice_language_dropdown'),
          value: options.contains(language) ? language : '',
          underline: const SizedBox.shrink(),
          borderRadius: BorderRadius.circular(MoshRadii.key),
          menuMaxHeight: 420,
          items: [
            DropdownMenuItem(value: '', child: Text(l.voiceLanguageAuto)),
            for (final code in options)
              DropdownMenuItem(value: code, child: Text(languageName(code))),
          ],
          onChanged: (v) => v == null ? null : onChanged(v),
        ),
      ],
    );
  }
}

class _ModelTile extends StatelessWidget {
  const _ModelTile({
    required this.model,
    required this.installed,
    required this.selected,
    required this.download,
    required this.onDownload,
    required this.onCancel,
    required this.onDelete,
    required this.onSelect,
  });

  final VoiceModel model;
  final bool installed;
  final bool selected;
  final ModelDownload? download;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = MoshColors.of(context);
    final m = model;
    final langs = m.englishOnly
        ? l.voiceEnglishOnly
        : m.languages.isEmpty
        ? null
        : m.languages.length <= 5
        ? m.languages.map(languageName).join(', ')
        : l.voiceLanguagesCount(m.languages.length);
    final facts = [?(m.sizeBytes == null ? null : formatBytes(m.sizeBytes!)), ?langs].join(' · ');
    final d = download;
    return MoshTile(
      key: Key('voice_model_${m.id}'),
      selected: selected,
      onTap: installed && !selected ? onSelect : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  m.name,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              if (m.recommended) _Badge(l.voiceRecommended),
              if (m.custom) _Badge(l.voiceCustomBadge),
            ],
          ),
          if (facts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(facts, style: TextStyle(color: c.muted, fontSize: 13)),
            ),
          const SizedBox(height: 10),
          if (d != null) ...[
            LinearProgressIndicator(value: d.unpacking ? null : d.fraction),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    d.unpacking
                        ? l.voiceUnpacking
                        : [
                            formatBytes(d.received),
                            if (d.total != null) formatBytes(d.total!),
                          ].join(' / '),
                    style: TextStyle(color: c.muted, fontSize: 13),
                  ),
                ),
                TextButton(
                  key: Key('voice_cancel_${m.id}'),
                  onPressed: d.unpacking ? null : onCancel,
                  child: Text(l.voiceCancelDownload),
                ),
              ],
            ),
          ] else if (installed)
            Row(
              children: [
                if (selected)
                  Chip(avatar: const Icon(Icons.check, size: 18), label: Text(l.voiceInUse))
                else
                  FilledButton.tonal(
                    key: Key('voice_use_${m.id}'),
                    onPressed: onSelect,
                    child: Text(l.voiceUse),
                  ),
                const Spacer(),
                IconButton(
                  key: Key('voice_delete_${m.id}'),
                  tooltip: l.voiceDelete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            )
          else
            Row(
              children: [
                FilledButton.icon(
                  key: Key('voice_download_${m.id}'),
                  icon: const Icon(Icons.download),
                  label: Text(
                    m.sizeBytes == null
                        ? l.voiceDownload
                        : '${l.voiceDownload} · ${formatBytes(m.sizeBytes!)}',
                  ),
                  onPressed: onDownload,
                ),
                const Spacer(),
                if (m.custom)
                  IconButton(
                    key: Key('voice_delete_${m.id}'),
                    tooltip: l.voiceDelete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(99)),
      child: Text(
        text,
        style: TextStyle(color: c.onAccent, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
