import 'package:flutter/material.dart';

/// Camera scanner plus a paste field for `openmosh://pair?d=…` links.
class PairScanView extends StatefulWidget {
  const PairScanView({
    super.key,
    required this.scanner,
    required this.onSubmit,
    this.error,
    this.onDismissError,
  });

  final Widget scanner;
  final ValueChanged<String> onSubmit;
  final String? error;
  final VoidCallback? onDismissError;

  @override
  State<PairScanView> createState() => _PairScanViewState();
}

class _PairScanViewState extends State<PairScanView> {
  final _link = TextEditingController();

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.error != null)
          MaterialBanner(
            content: Text(widget.error!),
            actions: [
              TextButton(onPressed: widget.onDismissError, child: const Text('Scan again')),
            ],
          ),
        Expanded(child: widget.error == null ? widget.scanner : const SizedBox.shrink()),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _link,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Or paste the pairing link',
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => widget.onSubmit(_link.text),
                icon: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
