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
import '../widgets/labeled_field.dart';
import '../widgets/number_plate.dart';
import '../widgets/stark_page.dart';
import '../widgets/stark_toast.dart';
import 'vehicle_urls.dart';

/// `/vehicles/new` and `/vehicles/:id/edit`: one form, with a live plate preview (DESIGN.md rule 10).
class VehicleFormPage extends ConsumerWidget {
  const VehicleFormPage({super.key, this.id, required this.query, this.editing = false});

  final int? id;
  final VehicleQuery query;

  /// True on `/vehicles/:id/edit`, even when the id in the address is unusable.
  final bool editing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!editing) return _FormLayout(query: query);
    final back = id == null ? vehiclesUrl(query) : vehiclesUrl(query, path: '/vehicles/$id');
    if (id == null) return _Gone(back: vehiclesUrl(query));
    return switch (ref.watch(vehicleProvider(id!))) {
      AsyncData(:final value) => _FormLayout(query: query, initial: value),
      AsyncError(:final error) when error is VehicleApiException && error.isNotFound => _Gone(back: vehiclesUrl(query)),
      AsyncError(:final error) => _Shell(
          title: 'Edit vehicle',
          back: back,
          backLabel: 'Back to the vehicle',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("The vehicle didn't load. $error", style: StarkText.body(15, color: StarkColors.ink)),
            const SizedBox(height: 14),
            ShadButton(onPressed: () => ref.invalidate(vehicleProvider(id!)), child: const Text('Try again')),
          ]),
        ),
      _ => Semantics(
          label: 'Loading vehicle',
          liveRegion: true,
          child: ExcludeSemantics(child: Skeletonizer(child: _FormLayout(query: query, skeleton: true))),
        ),
    };
  }
}

/// Page title, back link and the white form card.
class _Shell extends StatelessWidget {
  const _Shell({required this.title, required this.back, required this.backLabel, required this.child, this.aside});

  final String title;
  final String back;
  final String backLabel;
  final Widget child;
  final Widget? aside;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final gutter = width < 600 ? 16.0 : 28.0;
    final wide = width >= 1100;
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: StarkColors.paper,
        borderRadius: BorderRadius.circular(StarkRadius.surface),
        border: Border.all(color: StarkColors.line),
      ),
      child: Padding(padding: EdgeInsets.all(width < 600 ? 16 : 24), child: child),
    );
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120 + 56),
          child: Padding(
            padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 48),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ShadButton.link(
                padding: EdgeInsets.zero,
                onPressed: () => context.go(back),
                leading: const Icon(LucideIcons.chevronLeft, size: 18),
                child: Text(backLabel),
              ),
              const SizedBox(height: 8),
              Semantics(
                header: true,
                child: Text(title, style: StarkText.display(30, weight: FontWeight.w700, width: 112, color: StarkColors.ink)),
              ),
              const SizedBox(height: 20),
              if (aside == null)
                card
              else if (wide)
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: card),
                  const SizedBox(width: 24),
                  SizedBox(width: 300, child: aside),
                ])
              else ...[
                aside!,
                const SizedBox(height: 16),
                card,
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _Gone extends StatelessWidget {
  const _Gone({required this.back});

  final String back;

  @override
  Widget build(BuildContext context) => _Shell(
        title: 'Edit vehicle',
        back: back,
        backLabel: 'Back to vehicles',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("This vehicle isn't in the register", style: StarkText.body(17, weight: FontWeight.w600, color: StarkColors.ink)),
          const SizedBox(height: 6),
          Text('It may have been removed. Go back to the vehicles to find the one you want.',
              style: StarkText.body(15, color: StarkColors.muted)),
        ]),
      );
}

/// Bangladeshi plate class letters, as written in Latin on registration papers.
const _classes = [
  'KA', 'KHA', 'GA', 'GHA', 'CHA', 'CHHA', 'JA', 'JHA', 'TA', 'THA', 'DA', 'DHA', //
  'NA', 'PA', 'FA', 'BA', 'BHA', 'MA', 'LA', 'SHA', 'SA', 'HA',
];

final _plateNumber = RegExp(r'^\d{2}-\d{4}$');

/// Digits only; the dash goes in by itself after the first two (DESIGN.md rule 10).
class _PlateNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 6) digits = digits.substring(0, 6);
    final text = digits.length > 2 ? '${digits.substring(0, 2)}-${digits.substring(2)}' : digits;
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

class _FormLayout extends ConsumerStatefulWidget {
  const _FormLayout({required this.query, this.initial, this.skeleton = false});

  final VehicleQuery query;
  final Vehicle? initial;
  final bool skeleton;

  @override
  ConsumerState<_FormLayout> createState() => _FormLayoutState();
}

class _FormLayoutState extends ConsumerState<_FormLayout> {
  late final Vehicle? v = widget.initial;
  late final (String, String, String)? _savedPlate = _parse(v?.vehicleNumber);

  late String? _city = _savedPlate?.$1 ?? (v == null ? 'DHA' : null);
  late String? _class = _savedPlate?.$2;
  late final _number = TextEditingController(text: _savedPlate?.$3 ?? '');
  late VehicleType? _type = v?.vehicleType;
  late FuelType? _fuel = v?.fuelType;
  late VehicleStatus _status = v?.status ?? VehicleStatus.available;
  late final _brand = TextEditingController(text: v?.brand ?? '');
  late final _model = TextEditingController(text: v?.model ?? '');
  late final _year = TextEditingController(text: v?.manufacturingYear?.toString() ?? '');
  late final _color = TextEditingController(text: v?.color ?? '');
  late final _seats = TextEditingController(text: v?.seatingCapacity?.toString() ?? '');
  late final _company = TextEditingController(text: v?.company ?? '');
  late final _driverName = TextEditingController(text: v?.driverName ?? '');
  late final _driverPhone = TextEditingController(text: v?.driverPhone ?? '');

  Map<String, String> _errors = {};
  String? _general;
  int? _existingId; // the vehicle that already has this plate (409)

  bool get _editing => v != null;

  /// `DHA-METRO-GA-11-9001` → (DHA, GA, 11-9001); null when the saved number has another shape.
  static (String, String, String)? _parse(String? raw) {
    final m = RegExp(r'^([A-Z]+)-METRO-([A-Z]+)-(\d{2}-\d{4})$').firstMatch(raw ?? '');
    if (m == null || !NumberPlate.cities.containsKey(m[1]) || !_classes.contains(m[2])) return null;
    return (m[1]!, m[2]!, m[3]!);
  }

  @override
  void dispose() {
    for (final c in [_number, _brand, _model, _year, _color, _seats, _company, _driverName, _driverPhone]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _blank(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Map<String, String> _validate() {
    final e = <String, String>{};
    final nextYear = DateTime.now().year + 1;
    if (_city == null) e['city'] = 'Pick the city on the plate';
    if (_class == null) e['class'] = 'Pick the class letters on the plate';
    if (!_plateNumber.hasMatch(_number.text)) {
      e['vehicleNumber'] = 'Enter the number as two digits, a dash, then four digits, like 11-9001.';
    }
    if (_type == null) e['vehicleType'] = 'Pick the vehicle type';
    if (_fuel == null) e['fuelType'] = 'Pick the fuel type';
    void text(String key, TextEditingController c, String label, int max, {String? required}) {
      final t = c.text.trim();
      if (t.isEmpty && required != null) {
        e[key] = required;
      } else if (t.length > max) {
        e[key] = '$label must be $max characters or fewer';
      }
    }

    text('brand', _brand, 'Brand', 100, required: 'Enter the brand, like Toyota');
    text('model', _model, 'Model', 100, required: 'Enter the model, like Corolla');
    text('color', _color, 'Colour', 50);
    text('company', _company, 'Company', 100);
    text('driverName', _driverName, 'Driver name', 100);
    text('driverPhone', _driverPhone, 'Driver phone', 20);
    final year = _blank(_year);
    final y = year == null ? null : int.tryParse(year);
    if (year != null && (y == null || y < 1900 || y > nextYear)) {
      e['manufacturingYear'] = 'Enter a year from 1900 to $nextYear, like 2022';
    }
    final seats = _blank(_seats);
    final s = seats == null ? null : int.tryParse(seats);
    if (seats != null && (s == null || s < 1 || s > 100)) {
      e['seatingCapacity'] = 'Enter the number of seats, from 1 to 100';
    }
    return e;
  }

  String get _composedNumber => '$_city-METRO-$_class-${_number.text}';

  Future<void> _submit() async {
    final form = ref.read(vehicleFormProvider.notifier);
    if (ref.read(vehicleFormProvider).isSubmitting) return;
    setState(() {
      _errors = _validate();
      _general = _errors.isEmpty ? null : 'Some fields need fixing. Each one says what to change.';
      _existingId = null;
    });
    if (_errors.isNotEmpty) return;

    final number = _composedNumber;
    final saved = await form.submit(
      existingId: v?.id,
      vehicle: Vehicle(
        vehicleNumber: number,
        vehicleType: _type!,
        company: _blank(_company),
        brand: _brand.text.trim(),
        model: _model.text.trim(),
        manufacturingYear: int.tryParse(_year.text.trim()),
        color: _blank(_color),
        fuelType: _fuel!,
        seatingCapacity: int.tryParse(_seats.text.trim()),
        driverName: _blank(_driverName),
        driverPhone: _blank(_driverPhone),
        status: _status,
      ),
    );
    if (!mounted) return;

    if (saved == null) {
      // Input survives a failed save (DESIGN.md rule 3); the server's words go next to their fields.
      final state = ref.read(vehicleFormProvider);
      setState(() {
        _errors = {...state.fieldErrors, if (state.vehicleNumberError != null) 'vehicleNumber': state.vehicleNumberError!};
        _general = state.isConflict ? null : state.generalError;
      });
      if (state.isConflict) _findExisting(number);
      return;
    }

    refreshVehicles(ref);
    ref.read(rowMarkProvider.notifier).fresh(saved.id!);
    final plate = NumberPlate.spoken(saved.vehicleNumber);
    showStarkToast(context, _editing ? 'Saved $plate' : 'Registered $plate');
    // A new vehicle is newest, so it shows on page 1 of the whole register.
    final listQuery = _editing ? widget.query : firstPage;
    context.go(vehiclesUrl(listQuery, path: '/vehicles/${saved.id}'));
  }

  Future<void> _findExisting(String number) async {
    try {
      final page = await ref.read(vehicleRepositoryProvider).getVehicles(q: number, size: 5);
      final match = page.content.where((x) => x.vehicleNumber.toUpperCase() == number.toUpperCase()).firstOrNull;
      if (mounted && match?.id != null) setState(() => _existingId = match!.id);
    } on VehicleApiException {
      // The message under the field still says what's wrong; the link is a convenience.
    }
  }

  void _changed(String key) {
    if (_errors.containsKey(key)) setState(() => _errors = {..._errors}..remove(key));
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(vehicleFormProvider.select((s) => s.isSubmitting));
    final enabled = !busy && !widget.skeleton;
    final wide = MediaQuery.sizeOf(context).width >= 760;

    Widget input(String key, String label, TextEditingController c,
            {String? hint, TextInputType? keyboard, List<TextInputFormatter>? formatters, String? placeholder}) =>
        LabeledField(
          label: label,
          error: _errors[key],
          hint: hint,
          child: ShadInput(
            controller: c,
            enabled: enabled,
            keyboardType: keyboard,
            inputFormatters: formatters,
            placeholder: placeholder == null ? null : Text(placeholder),
            onChanged: (_) => _changed(key),
            onSubmitted: (_) => _submit(),
          ),
        );

    Widget select<T>(String key, String label, T? value, List<(T, String)> options, ValueChanged<T> onPick,
            {String placeholder = 'Pick one'}) =>
        LabeledField(
          label: label,
          error: _errors[key],
          child: LayoutBuilder(
            builder: (context, c) => ShadSelect<T>(
              minWidth: c.maxWidth,
              maxWidth: c.maxWidth,
              enabled: enabled,
              initialValue: value,
              placeholder: Text(placeholder),
              options: [for (final (v, l) in options) ShadOption<T>(value: v, child: Text(l))],
              selectedOptionBuilder: (context, v) => Text(options.firstWhere((o) => o.$1 == v).$2),
              onChanged: (v) {
                if (v == null) return;
                setState(() => onPick(v));
                _changed(key);
              },
            ),
          ),
        );

    Widget pair(Widget a, Widget b) => wide
        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: a),
            const SizedBox(width: 16),
            Expanded(child: b),
          ])
        : Column(children: [a, const SizedBox(height: 16), b]);

    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(title, style: StarkText.body(17, weight: FontWeight.w600, color: StarkColors.ink)),
        );

    const gap = SizedBox(height: 16);
    final savedOddNumber = _editing && _savedPlate == null;

    final form = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      section('Number plate'),
      pair(
        select<String>('city', 'City', _city, [for (final e in NumberPlate.cities.entries) (e.key, e.value)], (x) => _city = x,
            placeholder: 'Pick a city'),
        select<String>('class', 'Class', _class, [for (final c in _classes) (c, c)], (x) => _class = x,
            placeholder: 'Pick the letters'),
      ),
      gap,
      input(
        'vehicleNumber',
        'Number',
        _number,
        keyboard: TextInputType.number,
        formatters: [_PlateNumberFormatter()],
        placeholder: '11-9001',
        hint: savedOddNumber
            ? 'Saved as "${v!.vehicleNumber}". Pick the city and class and type the number to save it in the usual shape.'
            : 'Two digits, a dash, then four digits. The dash goes in by itself.',
      ),
      if (_existingId != null)
        Align(
          alignment: Alignment.centerLeft,
          child: ShadButton.link(
            padding: const EdgeInsets.only(top: 4),
            onPressed: () => context.go('/vehicles/$_existingId'),
            child: const Text('Open the vehicle with this plate'),
          ),
        ),
      const SizedBox(height: 28),
      section('Vehicle'),
      pair(
        select<VehicleType>('vehicleType', 'Type', _type, [for (final t in VehicleType.values) (t, t.label)], (x) => _type = x),
        select<FuelType>('fuelType', 'Fuel', _fuel, [for (final f in FuelType.values) (f, f.label)], (x) => _fuel = x),
      ),
      gap,
      pair(input('brand', 'Brand', _brand, placeholder: 'Toyota'), input('model', 'Model', _model, placeholder: 'Corolla Axio')),
      gap,
      pair(
        input('manufacturingYear', 'Year made (optional)', _year, keyboard: TextInputType.number, placeholder: '2022'),
        input('seatingCapacity', 'Seats (optional)', _seats, keyboard: TextInputType.number, placeholder: '5'),
      ),
      gap,
      pair(
        input('color', 'Colour (optional)', _color, placeholder: 'Silver'),
        input('company', 'Company (optional)', _company, placeholder: 'Stark Logistics'),
      ),
      const SizedBox(height: 28),
      section('Driver and status'),
      pair(
        input('driverName', 'Driver name (optional)', _driverName),
        input('driverPhone', 'Driver phone (optional)', _driverPhone, keyboard: TextInputType.phone, placeholder: '+8801711000000'),
      ),
      gap,
      pair(
        select<VehicleStatus>('status', 'Status', _status, [for (final s in VehicleStatus.values) (s, s.label)], (x) => _status = x),
        const SizedBox.shrink(),
      ),
      const SizedBox(height: 28),
      if (_general != null) ...[
        Semantics(
          liveRegion: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: StarkColors.errorTint,
              borderRadius: BorderRadius.circular(StarkRadius.control),
              border: Border.all(color: StarkColors.errorBorder),
            ),
            child: Text(_general!, style: StarkText.body(14, color: StarkColors.red)),
          ),
        ),
        const SizedBox(height: 16),
      ],
      Wrap(alignment: WrapAlignment.end, spacing: 12, runSpacing: 10, children: [
        ShadButton.outline(
          onPressed: enabled ? () => context.go(_backUrl) : null,
          child: const Text('Cancel'),
        ),
        ShadButton(
          onPressed: enabled ? _submit : null,
          leading: busy ? const Spinner() : null,
          child: Text(busy ? (_editing ? 'Saving' : 'Registering') : (_editing ? 'Save changes' : 'Register vehicle')),
        ),
      ]),
    ]);

    final preview = ListenableBuilder(
      listenable: _number,
      builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Plate preview', style: StarkText.body(14, weight: FontWeight.w600, color: StarkColors.muted)),
        const SizedBox(height: 10),
        NumberPlate.preview(
          top: '${NumberPlate.cities[_city] ?? 'CITY'} METRO-${_class ?? '?'}',
          number: _number.text.isEmpty ? '00-0000' : _number.text,
        ),
        const SizedBox(height: 8),
        Text('Updates as you type.', style: StarkText.body(13, color: StarkColors.muted)),
      ]),
    );

    return _Shell(
      title: _editing || widget.skeleton ? 'Edit vehicle' : 'Register a vehicle',
      back: _backUrl,
      backLabel: _editing || widget.skeleton ? 'Back to the vehicle' : 'Back to vehicles',
      aside: preview,
      child: form,
    );
  }

  String get _backUrl => _editing ? vehiclesUrl(widget.query, path: '/vehicles/${v!.id}') : vehiclesUrl(widget.query);
}
