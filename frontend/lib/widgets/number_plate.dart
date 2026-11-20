import 'package:flutter/widgets.dart';

import '../theme/stark_tokens.dart';

enum PlateSize { sm, lg, xl }

/// A Bangladeshi number plate: city and class on top, the number below (DESIGN.md signature).
/// `DHA-METRO-GA-11-9001` reads as `DHAKA METRO-GA` over `11-9001`. Anything that doesn't
/// match that shape is shown as one line, so a plate is never hidden.
class NumberPlate extends StatelessWidget {
  const NumberPlate(this.vehicleNumber, {super.key, this.size = PlateSize.sm});

  final String vehicleNumber;
  final PlateSize size;

  static const _cities = {
    'DHA': 'DHAKA',
    'CTG': 'CHATTA',
    'SYL': 'SYLHET',
    'RAJ': 'RAJSHAHI',
    'KHU': 'KHULNA',
    'BAR': 'BARISHAL',
    'RAN': 'RANGPUR',
    'MYM': 'MYMENSINGH',
  };

  /// (top line, number) or null when the text isn't in the usual shape.
  static (String, String)? split(String raw) {
    final m = RegExp(r'^([A-Z]+)-METRO-([A-Z]+)-(\d{2}-\d{4})$').firstMatch(raw.trim().toUpperCase());
    if (m == null) return null;
    final city = _cities[m.group(1)] ?? m.group(1)!;
    return ('$city METRO-${m.group(2)}', m.group(3)!);
  }

  @override
  Widget build(BuildContext context) {
    final parts = split(vehicleNumber);
    final (topSize, numSize, border, radius, pad) = switch (size) {
      PlateSize.sm => (10.0, 19.0, 1.5, StarkRadius.plate, const EdgeInsets.fromLTRB(9, 2, 9, 3)),
      PlateSize.lg => (13.0, 32.0, 2.0, StarkRadius.plate, const EdgeInsets.fromLTRB(16, 6, 16, 8)),
      PlateSize.xl => (26.0, 88.0, 4.0, StarkRadius.plateXl, const EdgeInsets.fromLTRB(34, 12, 34, 16)),
    };
    TextStyle style(double s, FontWeight w, double spacing) => TextStyle(
          fontFamily: StarkFonts.plate,
          fontSize: s,
          fontWeight: w,
          height: 1.0,
          letterSpacing: s * spacing,
          color: StarkColors.plateInk,
          fontFeatures: const [FontFeature.tabularFigures()],
        );

    final content = parts == null
        ? Text(vehicleNumber, style: style(numSize * 0.7, FontWeight.w700, 0.04))
        : Column(mainAxisSize: MainAxisSize.min, children: [
            Text(parts.$1, style: style(topSize, FontWeight.w600, 0.06)),
            SizedBox(height: size == PlateSize.xl ? 4 : 1),
            Text(parts.$2, style: style(numSize, FontWeight.w700, 0.05)),
          ]);

    return Semantics(
      label: 'Plate ${parts == null ? vehicleNumber : '${parts.$1} ${parts.$2}'}',
      excludeSemantics: true,
      child: Container(
        padding: size == PlateSize.xl ? const EdgeInsets.all(5) : pad,
        decoration: BoxDecoration(
          color: StarkColors.paper,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: StarkColors.plateInk, width: border),
        ),
        child: size == PlateSize.xl
            // The thin inner rule real plates have.
            ? Container(
                padding: pad,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius - 3),
                  border: Border.all(color: StarkColors.plateInk, width: 1.5),
                ),
                child: FittedBox(fit: BoxFit.scaleDown, child: content),
              )
            : FittedBox(fit: BoxFit.scaleDown, child: content),
      ),
    );
  }
}
