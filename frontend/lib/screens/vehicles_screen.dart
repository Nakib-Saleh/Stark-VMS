import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../models/page_response.dart';
import '../models/vehicle.dart';
import '../providers/vehicle_providers.dart';
import '../theme/stark_tokens.dart';
import '../widgets/number_plate.dart';
import '../widgets/register_pagination.dart';
import '../widgets/stark_page.dart';
import '../widgets/vehicle_status.dart';
import 'vehicle_urls.dart';

/// `/vehicles`: the register (DESIGN.md "Register"). Page, search and status filter come from
/// the URL; the detail panel and the forms open on top of this page as their own URLs.
class VehiclesScreen extends ConsumerStatefulWidget {
  const VehiclesScreen({super.key, required this.query});

  final VehicleQuery query;

  @override
  ConsumerState<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends ConsumerState<VehiclesScreen> {
  final _scroll = ScrollController();
  late final _search = TextEditingController(text: widget.query.q ?? '');
  Timer? _debounce;
  Timer? _afterLeave;

  VehicleQuery get query => widget.query;

  @override
  void didUpdateWidget(VehiclesScreen old) {
    super.didUpdateWidget(old);
    // The URL changed from outside the field (Clear, Back): show what the URL says.
    if ((query.q ?? '') != _search.text.trim()) _search.text = query.q ?? '';
    // A new page starts at the top of the list (DESIGN.md rule 9).
    if (old.query.page != query.page && _scroll.hasClients) {
      final d = motion(context, StarkMotion.base);
      d == Duration.zero ? _scroll.jumpTo(0) : _scroll.animateTo(0, duration: d, curve: StarkMotion.ease);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _afterLeave?.cancel();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _go(VehicleQuery q) => context.go(vehiclesUrl(q));

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final t = text.trim();
      if (!mounted || t == (query.q ?? '')) return;
      // A new search starts at page 1 (DESIGN.md rule 9).
      _go((page: 0, q: t.isEmpty ? null : t, status: query.status));
    });
  }

  void _clearAll() {
    _search.clear();
    _go(firstPage);
  }

  @override
  Widget build(BuildContext context) {
    // A removed row slides away first, then everything reloads and the list closes up.
    ref.listen(rowMarkProvider.select((m) => m.leaving), (_, id) {
      if (id == null) return;
      _afterLeave?.cancel();
      _afterLeave = Timer(motion(context, StarkMotion.rowLeave), () {
        if (!mounted) return;
        refreshVehicles(ref);
        ref.read(rowMarkProvider.notifier).clear();
      });
    });

    final width = MediaQuery.sizeOf(context).width;
    final gutter = width < 600 ? 16.0 : 28.0;
    final pageAsync = ref.watch(vehiclePageProvider(query));

    return SingleChildScrollView(
      controller: _scroll,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120 + 56),
          child: Padding(
            padding: EdgeInsets.fromLTRB(gutter, 28, gutter, 48),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _Header(onRegister: () => context.go(vehiclesUrl(query, path: '/vehicles/new'))),
              const SizedBox(height: 24),
              _Toolbar(
                search: _search,
                onSearchChanged: _onSearchChanged,
                onClearSearch: () {
                  _search.clear();
                  _go((page: 0, q: null, status: query.status));
                },
                query: query,
                onStatus: (s) => _go((page: 0, q: query.q, status: s)),
              ),
              const SizedBox(height: 16),
              switch (pageAsync) {
                AsyncData(:final value) => _Loaded(
                    page: value,
                    query: query,
                    onPage: (p) => _go((page: p - 1, q: query.q, status: query.status)),
                    onClear: _clearAll,
                    onRegister: () => context.go('/vehicles/new'),
                  ),
                AsyncError(:final error) => _Message(
                    title: "The vehicles didn't load",
                    body: '$error',
                    action: ShadButton(
                      onPressed: () => ref.invalidate(vehiclePageProvider(query)),
                      child: const Text('Try again'),
                    ),
                  ),
                _ => const _RegisterSkeleton(),
              },
            ]),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRegister});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 16,
      runSpacing: 14,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Semantics(
            header: true,
            child: Text('Vehicles', style: StarkText.display(30, weight: FontWeight.w700, width: 112, color: StarkColors.ink)),
          ),
          const SizedBox(height: 4),
          Text('Every vehicle in the Stark Group fleet, newest first.', style: StarkText.body(15, color: StarkColors.muted)),
        ]),
        ShadButton(
          onPressed: onRegister,
          height: 40,
          leading: const Icon(LucideIcons.plus, size: 16),
          child: const Text('Register vehicle'),
        ),
      ],
    );
  }
}

class _Toolbar extends ConsumerWidget {
  const _Toolbar({
    required this.search,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.query,
    required this.onStatus,
  });

  final TextEditingController search;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VehicleQuery query;
  final ValueChanged<VehicleStatus?> onStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Counts follow the search text, so the chips agree with "Showing … of N" below.
    final counts = ref.watch(statusCountsProvider(query.q)).value;
    final total = counts?.values.fold<int>(0, (a, b) => a + b);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Semantics(
          label: 'Search vehicles',
          textField: true,
          child: ValueListenableBuilder(
            valueListenable: search,
            builder: (context, value, _) => ShadInput(
              controller: search,
              placeholder: const Text('Search plate, brand, model, company or driver'),
              leading: const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(LucideIcons.search, size: 16, color: StarkColors.muted),
              ),
              trailing: value.text.isEmpty
                  ? null
                  : Semantics(
                      label: 'Clear search',
                      button: true,
                      excludeSemantics: true,
                      child: ShadButton.ghost(
                        onPressed: onClearSearch,
                        width: 28,
                        height: 28,
                        padding: EdgeInsets.zero,
                        child: const Icon(LucideIcons.x, size: 16),
                      ),
                    ),
              onChanged: onSearchChanged,
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _Chip(label: 'All', count: total, selected: query.status == null, onPressed: () => onStatus(null)),
        for (final s in VehicleStatus.values)
          _Chip(label: s.label, count: counts?[s], selected: query.status == s, onPressed: () => onStatus(s)),
      ]),
    ]);
  }
}

/// DESIGN.md "Filter chip": pill, selected = navy fill; shows its count.
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.count, required this.selected, required this.onPressed});

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? StarkColors.paper : StarkColors.ink;
    return Semantics(
      selected: selected,
      button: true,
      label: count == null ? label : '$label, $count',
      excludeSemantics: true,
      child: ShadButton.outline(
        onPressed: onPressed,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        backgroundColor: selected ? StarkColors.navy : StarkColors.paper,
        hoverBackgroundColor: selected ? StarkColors.navy : StarkColors.rowHover,
        foregroundColor: fg,
        hoverForegroundColor: fg,
        decoration: ShadDecoration(
          border: ShadBorder.all(
            color: selected ? StarkColors.navy : StarkColors.line,
            radius: BorderRadius.circular(StarkRadius.chip),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: StarkText.body(14, weight: FontWeight.w500, color: fg)),
          if (count != null) ...[
            const SizedBox(width: 6),
            Text('$count',
                style: StarkText.body(13, color: selected ? StarkColors.onNavyMuted : StarkColors.muted)
                    .copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
          ],
        ]),
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.page, required this.query, required this.onPage, required this.onClear, required this.onRegister});

  final PageResponse<Vehicle> page;
  final VehicleQuery query;
  final ValueChanged<int> onPage;
  final VoidCallback onClear;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final filtered = query.q != null || query.status != null;
    if (page.totalElements == 0 && !filtered) {
      return _Message(
        title: 'No vehicles yet',
        body: 'Register the first vehicle and it will appear here with its plate.',
        action: ShadButton(onPressed: onRegister, child: const Text('Register vehicle')),
      );
    }
    if (page.totalElements == 0) {
      final what = [
        if (query.q != null) '"${query.q}"',
        if (query.status != null) 'with the status ${query.status!.label}',
      ].join(' ');
      return _Message(
        title: 'No vehicles match',
        body: 'Nothing in the register matches $what. Try other words, or show every vehicle.',
        action: ShadButton.outline(onPressed: onClear, child: const Text('Clear search and filter')),
      );
    }
    if (page.content.isEmpty) {
      return _Message(
        title: 'There is no page ${query.page + 1}',
        body: 'The register has ${page.totalPages} ${page.totalPages == 1 ? 'page' : 'pages'}.',
        action: ShadButton.outline(onPressed: () => onPage(page.totalPages), child: Text('Go to page ${page.totalPages}')),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Register(vehicles: page.content, query: query),
      const SizedBox(height: 14),
      RegisterPagination(
        page: page.number + 1,
        totalPages: page.totalPages,
        pageSize: page.size,
        totalElements: page.totalElements,
        shownOnPage: page.content.length,
        onPage: onPage,
      ),
    ]);
  }
}

/// The white register surface with its header row (DESIGN.md: one surface, `line` border, no shadow).
class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: StarkColors.paper,
          borderRadius: BorderRadius.circular(StarkRadius.surface),
          border: Border.all(color: StarkColors.line),
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(StarkRadius.surface), child: child),
      );
}

bool _wide(BuildContext context) => MediaQuery.sizeOf(context).width >= 960;

class _Register extends ConsumerWidget {
  const _Register({required this.vehicles, required this.query, this.interactive = true});

  final List<Vehicle> vehicles;
  final VehicleQuery query;
  final bool interactive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = _wide(context);
    final mark = ref.watch(rowMarkProvider);
    return _Surface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (wide) const _HeaderRow(),
        for (final (i, v) in vehicles.indexed) ...[
          if (i > 0 || wide) const Rule(color: StarkColors.rowLine),
          _Row(
            key: ValueKey(v.id),
            vehicle: v,
            wide: wide,
            fresh: interactive && mark.fresh == v.id,
            leaving: interactive && mark.leaving == v.id,
            onOpen: interactive ? () => context.go(vehiclesUrl(query, path: '/vehicles/${v.id}')) : null,
            onEdit: interactive ? () => context.go(vehiclesUrl(query, path: '/vehicles/${v.id}/edit')) : null,
            onFreshDone: () => ref.read(rowMarkProvider.notifier).clear(),
          ),
        ],
      ]),
    );
  }
}

// Column widths shared by the header and the rows.
const _plateW = 160.0;
const _statusW = 140.0;
const _actionsW = 76.0;

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    Text h(String t) => Text(t, style: StarkText.body(13, weight: FontWeight.w600, color: StarkColors.muted));
    return ColoredBox(
      color: StarkColors.registerHead,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(children: [
          SizedBox(width: _plateW, child: h('Plate')),
          Expanded(flex: 3, child: h('Vehicle')),
          Expanded(flex: 3, child: h('Driver')),
          SizedBox(width: _statusW, child: h('Status')),
          SizedBox(width: _actionsW, child: Semantics(label: 'Actions', child: const SizedBox.shrink())),
        ]),
      ),
    );
  }
}

class _Row extends StatefulWidget {
  const _Row({
    super.key,
    required this.vehicle,
    required this.wide,
    required this.fresh,
    required this.leaving,
    required this.onOpen,
    required this.onEdit,
    required this.onFreshDone,
  });

  final Vehicle vehicle;
  final bool wide;
  final bool fresh;
  final bool leaving;
  final VoidCallback? onOpen;
  final VoidCallback? onEdit;
  final VoidCallback onFreshDone;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final title = Text('${v.brand} ${v.model}',
        maxLines: 1, overflow: TextOverflow.ellipsis, style: StarkText.body(15, weight: FontWeight.w600, color: StarkColors.ink));
    final about = Text(
      [v.vehicleType.label, if (v.manufacturingYear != null) '${v.manufacturingYear}', if (v.company != null) v.company!].join(', '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: StarkText.body(13, color: StarkColors.muted),
    );
    final driver = v.driverName == null
        ? Text('No driver', style: StarkText.body(14, color: StarkColors.muted))
        : Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(v.driverName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: StarkText.body(14, color: StarkColors.ink)),
            if (v.driverPhone != null) Text(v.driverPhone!, style: StarkText.body(13, color: StarkColors.muted)),
          ]);
    final edit = widget.onEdit == null
        ? const SizedBox.shrink()
        : Semantics(
            label: 'Edit ${NumberPlate.spoken(v.vehicleNumber)}',
            button: true,
            excludeSemantics: true,
            child: ShadButton.ghost(
              onPressed: widget.onEdit,
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: const Text('Edit'),
            ),
          );

    final content = widget.wide
        ? Row(children: [
            SizedBox(width: _plateW, child: Align(alignment: Alignment.centerLeft, child: NumberPlate(v.vehicleNumber))),
            Expanded(
              flex: 3,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, about]),
            ),
            Expanded(flex: 3, child: driver),
            SizedBox(width: _statusW, child: StatusMark(v.status)),
            SizedBox(width: _actionsW, child: Align(alignment: Alignment.centerRight, child: edit)),
          ])
        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [NumberPlate(v.vehicleNumber), const Spacer(), StatusMark(v.status)]),
            const SizedBox(height: 10),
            title,
            about,
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: driver), edit]),
          ]);

    Widget row = AnimatedContainer(
      duration: motion(context, StarkMotion.fast),
      curve: StarkMotion.ease,
      color: _hover ? StarkColors.rowHover : StarkColors.paper,
      foregroundDecoration:
          _focus ? BoxDecoration(border: Border.all(color: StarkColors.blue, width: 2)) : null,
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: widget.wide ? 12 : 14),
      child: content,
    );

    if (widget.fresh) {
      // New or edited row: pale blue that fades out over 1.8s.
      row = TweenAnimationBuilder<Color?>(
        tween: ColorTween(begin: StarkColors.freshRow, end: StarkColors.paper.withValues(alpha: 0)),
        duration: motion(context, StarkMotion.freshFade),
        onEnd: widget.onFreshDone,
        builder: (context, color, child) => Stack(children: [
          child!,
          Positioned.fill(child: IgnorePointer(child: ColoredBox(color: color!.withValues(alpha: color.a * 0.85)))),
        ]),
        child: row,
      );
    }

    if (widget.leaving) {
      // Removed row: slides 16px right and fades, then the list reloads without it.
      row = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: motion(context, StarkMotion.rowLeave),
        curve: StarkMotion.ease,
        builder: (context, t, child) =>
            Opacity(opacity: 1 - t, child: Transform.translate(offset: Offset(16 * t, 0), child: child)),
        child: row,
      );
    }

    if (widget.onOpen == null) return row;
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowHoverHighlight: (h) => setState(() => _hover = h),
      onShowFocusHighlight: (f) => setState(() => _focus = f),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          widget.onOpen!();
          return null;
        }),
      },
      child: Semantics(
        button: true,
        label: 'Open ${NumberPlate.spoken(v.vehicleNumber)}, ${v.brand} ${v.model}, ${v.status.label}',
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onOpen, child: row),
      ),
    );
  }
}

/// Placeholder rows shaped like the register while a page loads (DESIGN.md rule 2).
class _RegisterSkeleton extends StatelessWidget {
  const _RegisterSkeleton();

  static final _fake = List.generate(
    10,
    (i) => Vehicle(
      id: -1 - i,
      vehicleNumber: 'DHA-METRO-GA-11-0000',
      vehicleType: VehicleType.car,
      brand: 'Toyota',
      model: 'Corolla Axio',
      manufacturingYear: 2022,
      fuelType: FuelType.petrol,
      driverName: 'Driver name',
      driverPhone: '+8801700000000',
    ),
  );

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Loading vehicles',
        liveRegion: true,
        child: ExcludeSemantics(
          child: Skeletonizer(child: _Register(vehicles: _fake, query: firstPage, interactive: false)),
        ),
      );
}

/// Empty, no-match and error states: what happened and what to do next.
class _Message extends StatelessWidget {
  const _Message({required this.title, required this.body, required this.action});

  final String title;
  final String body;
  final Widget action;

  @override
  Widget build(BuildContext context) => _Surface(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(children: [
            Text(title, textAlign: TextAlign.center, style: StarkText.display(19, weight: FontWeight.w700, width: 112, color: StarkColors.ink)),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center, style: StarkText.body(15, color: StarkColors.muted)),
            const SizedBox(height: 18),
            action,
          ]),
        ),
      );
}
