import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../theme/stark_tokens.dart';

/// DESIGN.md "Toast": navy, bottom-right, 3.2s, repeats the button's verb ("Registered …").
void showStarkToast(BuildContext context, String text) {
  ShadToaster.maybeOf(context)?.show(ShadToast(
    description: Semantics(liveRegion: true, child: Text(text)),
    descriptionStyle: StarkText.body(14, weight: FontWeight.w500, color: StarkColors.paper),
    backgroundColor: StarkColors.navy,
    border: ShadBorder.all(color: StarkColors.navy),
    radius: BorderRadius.circular(StarkRadius.control),
    alignment: Alignment.bottomRight,
    duration: StarkMotion.toast,
  ));
}
