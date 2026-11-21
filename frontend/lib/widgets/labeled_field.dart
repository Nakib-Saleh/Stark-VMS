import 'package:flutter/widgets.dart';

import '../theme/stark_tokens.dart';

/// A form field with its label above and its error, in plain words, right under it (DESIGN.md rule 4).
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child, this.error, this.hint});

  final String label;
  final Widget child;
  final String? error;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: StarkText.body(14, weight: FontWeight.w600, color: StarkColors.ink)),
        const SizedBox(height: 6),
        child,
        if (error != null) ...[
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            child: Text(error!, style: StarkText.body(13, weight: FontWeight.w500, color: StarkColors.red)),
          ),
        ] else if (hint != null) ...[
          const SizedBox(height: 6),
          Text(hint!, style: StarkText.body(13, color: StarkColors.muted)),
        ],
      ],
    );
  }
}
