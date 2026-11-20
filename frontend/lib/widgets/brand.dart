import 'package:flutter/widgets.dart';

import '../theme/stark_tokens.dart';

/// "S" plate mark + "Stark VMS".
class Brand extends StatelessWidget {
  const Brand({super.key, required this.onNavy});

  final bool onNavy;

  @override
  Widget build(BuildContext context) {
    final color = onNavy ? StarkColors.paper : StarkColors.ink;
    return Semantics(
      label: 'Stark VMS',
      excludeSemantics: true,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 30,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(StarkRadius.plate),
          ),
          child: Text('S',
              style: TextStyle(fontFamily: StarkFonts.plate, fontWeight: FontWeight.w700, fontSize: 13, color: color, height: 1)),
        ),
        const SizedBox(width: 10),
        // Rigid on purpose: callers wrap it in FittedBox(scaleDown) where space is tight.
        Text('Stark VMS', maxLines: 1, style: StarkText.display(17, weight: FontWeight.w700, width: 110, color: color)),
      ]),
    );
  }
}
