import 'package:flutter/widgets.dart';

import '../models/vehicle.dart';
import '../theme/stark_tokens.dart';

/// DESIGN.md "Status": coloured dot + word, never colour alone.
/// shortcut: Available and In use share green until Phase 9 reworks the statuses.
Color statusColor(VehicleStatus s) => switch (s) {
      VehicleStatus.available || VehicleStatus.inUse => StarkColors.green,
      VehicleStatus.maintenance => StarkColors.amber,
      VehicleStatus.inactive => StarkColors.inactiveDot,
    };

class StatusMark extends StatelessWidget {
  const StatusMark(this.status, {super.key, this.size = 14});

  final VehicleStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final word = status == VehicleStatus.inactive ? StarkColors.muted : statusColor(status);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: statusColor(status), shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Text(status.label,
            maxLines: 1, overflow: TextOverflow.ellipsis, style: StarkText.body(size, weight: FontWeight.w600, color: word)),
      ),
    ]);
  }
}
