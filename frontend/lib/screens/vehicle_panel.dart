import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../models/vehicle.dart';
import '../providers/vehicle_providers.dart';
import '../repositories/vehicle_repository.dart';
import '../theme/stark_tokens.dart';
import '../widgets/number_plate.dart';
import '../widgets/stark_page.dart';
import '../widgets/stark_toast.dart';
import '../widgets/vehicle_status.dart';
import 'vehicle_urls.dart';

/// `/vehicles/:id`: the detail panel over the register (DESIGN.md "Detail panel").
/// The route is transparent, so the register stays where it was underneath.
class VehiclePanel extends ConsumerWidget {
  const VehiclePanel({super.key, required this.id, required this.query});

  /// Null when the address has no usable id (`/vehicles/abc`).
  final int? id;
  final VehicleQuery query;

  void _close(BuildContext context) => context.go(vehiclesUrl(query));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anim = ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation;
    final curved = CurvedAnimation(parent: anim, curve: StarkMotion.ease);
    final width = MediaQuery.sizeOf(context).width;
    final async = id == null ? null : ref.watch(vehicleProvider(id!));

    final Widget body = switch (async) {
      null => _NotThere(onClose: () => _close(context)),
      AsyncData(:final value) => _Details(vehicle: value, query: query, onClose: () => _close(context)),
      AsyncError(:final error) when error is VehicleApiException && error.isNotFound =>
        _NotThere(onClose: () => _close(context)),
      AsyncError(:final error) => _Problem(
          message: '$error',
          onRetry: () => ref.invalidate(vehicleProvider(id!)),
          onClose: () => _close(context),
        ),
      _ => const _DetailsSkeleton(),
    };

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): () => _close(context)},
      child: Focus(
        autofocus: true,
        child: Stack(children: [
          // Scrim: fades with the panel; clicking it closes the panel.
          Positioned.fill(
            child: FadeTransition(
              opacity: curved,
              child: GestureDetector(
                onTap: () => _close(context),
                child: ColoredBox(color: StarkColors.navy.withValues(alpha: 0.28)),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: AnimatedBuilder(
              animation: curved,
              builder: (context, child) => Opacity(
                opacity: curved.value,
                child: Transform.translate(offset: Offset(40 * (1 - curved.value), 0), child: child),
              ),
              child: Semantics(
                scopesRoute: true,
                explicitChildNodes: true,
                namesRoute: true,
                label: 'Vehicle details',
                child: Container(
                  width: width < 500 ? width : 460,
                  decoration: BoxDecoration(
                    color: StarkColors.paper,
                    boxShadow: [BoxShadow(color: StarkColors.navy.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(-4, 0))],
                  ),
                  child: StarkPage(color: StarkColors.paper, child: body),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 14, 0),
        child: Row(children: [
          Expanded(child: Text('Vehicle details', style: StarkText.body(14, weight: FontWeight.w600, color: StarkColors.muted))),
          ShadButton.ghost(
            onPressed: onClose,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            leading: const Icon(LucideIcons.x, size: 16),
            child: const Text('Close'),
          ),
        ]),
      );
}

class _Details extends ConsumerWidget {
  const _Details({required this.vehicle, required this.query, required this.onClose, this.interactive = true});

  final Vehicle vehicle;
  final VehicleQuery query;
  final VoidCallback? onClose;
  final bool interactive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = vehicle;
    String date(DateTime? d) => d == null ? '' : '${d.day} ${_months[d.month - 1]} ${d.year}';
    final facts = <(String, String?)>[
      ('Type', v.vehicleType.label),
      ('Fuel', v.fuelType.label),
      ('Brand', v.brand),
      ('Model', v.model),
      ('Year made', v.manufacturingYear?.toString()),
      ('Colour', v.color),
      ('Seats', v.seatingCapacity?.toString()),
      ('Company', v.company),
      ('Driver', v.driverName),
      ('Driver phone', v.driverPhone),
      ('Registered on', date(v.createdAt)),
      ('Last changed', date(v.updatedAt)),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _TopBar(onClose: onClose ?? () {}),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            NumberPlate(v.vehicleNumber, size: PlateSize.lg),
            const SizedBox(height: 14),
            Semantics(
              header: true,
              child: Text('${v.brand} ${v.model}', style: StarkText.display(19, weight: FontWeight.w700, width: 112, color: StarkColors.ink)),
            ),
            const SizedBox(height: 6),
            StatusMark(v.status, size: 15),
            const SizedBox(height: 22),
            LayoutBuilder(builder: (context, c) {
              final cell = (c.maxWidth - 20) / 2;
              return Wrap(spacing: 20, runSpacing: 14, children: [
                for (final (label, value) in facts)
                  SizedBox(
                    width: cell,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(label, style: StarkText.body(13, color: StarkColors.muted)),
                      Text(value == null || value.isEmpty ? 'Not recorded' : value,
                          style: StarkText.body(15,
                              color: value == null || value.isEmpty ? StarkColors.muted : StarkColors.ink)),
                    ]),
                  ),
              ]);
            }),
            const SizedBox(height: 24),
            const Rule(color: StarkColors.rowLine),
            const SizedBox(height: 16),
            Text('Papers', style: StarkText.body(15, weight: FontWeight.w600, color: StarkColors.ink)),
            const SizedBox(height: 4),
            // Placeholder a later phase wires up (Phases 13 and 14), labelled honestly.
            Text('Not tracked yet. Registration, fitness and tax papers come in a later update.',
                style: StarkText.body(14, color: StarkColors.muted)),
          ]),
        ),
      ),
      const Rule(),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 24, 14),
        child: Row(children: [
          ShadButton.ghost(
            onPressed: interactive ? () => _remove(context, ref) : null,
            foregroundColor: StarkColors.red,
            hoverForegroundColor: StarkColors.red,
            leading: const Icon(LucideIcons.trash2, size: 16),
            child: const Text('Remove'),
          ),
          const Spacer(),
          ShadButton(
            onPressed: interactive ? () => context.go(vehiclesUrl(query, path: '/vehicles/${v.id}/edit')) : null,
            leading: const Icon(LucideIcons.pencil, size: 16),
            child: const Text('Edit vehicle'),
          ),
        ]),
      ),
    ]);
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final removed = await showShadDialog<bool>(
      context: context,
      builder: (_) => _RemoveDialog(vehicle: vehicle),
    );
    if (removed != true || !context.mounted) return;
    showStarkToast(context, 'Removed ${NumberPlate.spoken(vehicle.vehicleNumber)}');
    ref.read(rowMarkProvider.notifier).leaving(vehicle.id!);
    context.go(vehiclesUrl(query));
  }
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// DESIGN.md rule 5: shows the plate; "Keep vehicle" is focused, "Remove vehicle" is red.
class _RemoveDialog extends ConsumerStatefulWidget {
  const _RemoveDialog({required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<_RemoveDialog> createState() => _RemoveDialogState();
}

class _RemoveDialogState extends ConsumerState<_RemoveDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(vehicleRepositoryProvider).deleteVehicle(widget.vehicle.id!);
      if (mounted) Navigator.of(context).pop(true);
    } on VehicleApiException catch (e) {
      // Already gone counts as removed: the register just needs to catch up.
      if (e.isNotFound) {
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog.alert(
      title: const Text('Remove this vehicle?'),
      description: const Text("It will be taken off the register. This can't be undone."),
      actions: [
        ShadButton.outline(
          autofocus: true,
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Keep vehicle'),
        ),
        ShadButton.destructive(
          onPressed: _busy ? null : _confirm,
          leading: _busy ? const Spinner() : null,
          child: Text(_busy ? 'Removing' : 'Remove vehicle'),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          NumberPlate(widget.vehicle.vehicleNumber, size: PlateSize.lg),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(_error!, style: StarkText.body(14, weight: FontWeight.w500, color: StarkColors.red)),
            ),
          ],
        ]),
      ),
    );
  }
}

class _DetailsSkeleton extends StatelessWidget {
  const _DetailsSkeleton();

  static const _fake = Vehicle(
    id: -1,
    vehicleNumber: 'DHA-METRO-GA-11-0000',
    vehicleType: VehicleType.car,
    brand: 'Toyota',
    model: 'Corolla Axio',
    manufacturingYear: 2022,
    color: 'Silver',
    fuelType: FuelType.petrol,
    seatingCapacity: 5,
    company: 'Stark Logistics',
    driverName: 'Driver name',
    driverPhone: '+8801700000000',
  );

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Loading vehicle',
        liveRegion: true,
        child: ExcludeSemantics(
          child: Skeletonizer(
            child: _Details(vehicle: _fake, query: firstPage, onClose: null, interactive: false),
          ),
        ),
      );
}

class _NotThere extends StatelessWidget {
  const _NotThere({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => _Problem(
        title: "This vehicle isn't in the register",
        message: 'It may have been removed. Close this panel to see the vehicles there are.',
        onClose: onClose,
      );
}

class _Problem extends StatelessWidget {
  const _Problem({this.title = "The vehicle didn't load", required this.message, required this.onClose, this.onRetry});

  final String title;
  final String message;
  final VoidCallback onClose;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _TopBar(onClose: onClose),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: StarkText.display(19, weight: FontWeight.w700, width: 112, color: StarkColors.ink)),
            const SizedBox(height: 6),
            Text(message, style: StarkText.body(15, color: StarkColors.muted)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ShadButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ]),
        ),
      ]);
}
