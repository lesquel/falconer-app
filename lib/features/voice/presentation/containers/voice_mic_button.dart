import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/l10n.dart';
import '../controllers/dictation_controller.dart';

/// Route of the voice settings screen.
const voiceSettingsRoute = '/voice';

/// The composer's mic. Without a usable model it opens the voice settings
/// (no recording, no permission prompt). Otherwise tap to dictate and tap
/// again to stop; the text goes to [onTranscript], never sent by itself.
class VoiceMicButton extends ConsumerStatefulWidget {
  const VoiceMicButton({super.key, required this.onTranscript});
  final ValueChanged<String> onTranscript;

  @override
  ConsumerState<VoiceMicButton> createState() => _VoiceMicButtonState();
}

class _VoiceMicButtonState extends ConsumerState<VoiceMicButton> {
  Timer? _limit;
  // Read in initState: `ref` is unusable once dispose() starts.
  late final DictationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(dictationControllerProvider.notifier);
  }

  @override
  void dispose() {
    _limit?.cancel();
    unawaited(_controller.cancel());
    super.dispose();
  }

  Future<void> _tap() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l = context.l10n;
    _limit?.cancel();
    final outcome = await _controller.tap();
    if (!mounted) return;
    switch (outcome) {
      case MicNeedsSetup():
        unawaited(context.push(voiceSettingsRoute));
      case MicStarted():
        _limit = Timer(DictationController.maxRecording, () => unawaited(_tap()));
      case MicText(:final text):
        if (text.isNotEmpty) widget.onTranscript(text);
      case MicPermissionDenied():
        messenger?.showSnackBar(SnackBar(content: Text(l.voiceMicDenied)));
      case MicFailed():
        messenger?.showSnackBar(SnackBar(content: Text(l.voiceFailed)));
      case MicBusy():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final phase = ref.watch(dictationControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      key: const Key('chat-mic'),
      tooltip: switch (phase) {
        DictationPhase.idle => l.voiceDictate,
        DictationPhase.recording => l.voiceStop,
        DictationPhase.transcribing => l.voiceTranscribing,
      },
      icon: switch (phase) {
        DictationPhase.idle => const Icon(Icons.mic_none),
        DictationPhase.recording => Icon(Icons.stop_circle, color: scheme.error),
        DictationPhase.transcribing => const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      },
      onPressed: phase == DictationPhase.transcribing ? null : () => unawaited(_tap()),
    );
  }
}
