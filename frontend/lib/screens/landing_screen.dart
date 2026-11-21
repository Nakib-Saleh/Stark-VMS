import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../auth/auth_controller.dart';
import '../theme/stark_tokens.dart';
import '../widgets/stark_page.dart';
import '../widgets/brand.dart';
import '../widgets/number_plate.dart';

/// Public front page (`/`). Uses example vehicles from the seed data; it never calls the API.
class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

typedef _Sample = ({String plate, String vehicle, String company, String driver});

const List<_Sample> _fleet = [
  (plate: 'CTG-METRO-GA-11-9001', vehicle: 'Toyota Axio Hybrid', company: 'Stark Logistics', driver: 'Faruk Ahmed'),
  (plate: 'DHA-METRO-BA-23-7002', vehicle: 'Ashok Leyland Viking', company: 'Stark Group HQ', driver: 'Mizanur Rahman'),
  (plate: 'SYL-METRO-GA-11-9004', vehicle: 'BYD Atto 3', company: 'Stark Pharma', driver: 'Zahidul Islam'),
  (plate: 'DHA-METRO-LA-25-8002', vehicle: 'Bajaj Pulsar 150', company: 'Stark Foods', driver: 'Sajid Khan'),
  (plate: 'CTG-METRO-GHA-13-9003', vehicle: 'Hyundai Tucson', company: 'Stark Pharma', driver: 'Imran Hossain'),
  (plate: 'DHA-METRO-NA-21-6002', vehicle: 'Toyota Hilux', company: 'Stark Logistics', driver: 'Anwar Hossain'),
];

class _LandingScreenState extends ConsumerState<LandingScreen> {
  final _howItWorks = GlobalKey();
  Timer? _timer;
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    // The only ambient motion in the product; stopped when the OS asks for reduced motion.
    if (!MediaQuery.disableAnimationsOf(context)) {
      _timer = Timer.periodic(StarkMotion.heroCycle, (_) => setState(() => _index++));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scrollToHow() {
    final ctx = _howItWorks.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: StarkMotion.base * 2, curve: StarkMotion.ease);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 820;
    final gutter = width < 480 ? 16.0 : 32.0;

    return StarkPage(

      child: SingleChildScrollView(
        child: Column(children: [
          // ---------- hero ----------
          ColoredBox(
            color: StarkColors.navy,
            child: _Width(
              gutter: gutter,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Row(children: [
                    // Takes all the free space (so the button sits at the right edge) and shrinks
                    // rather than overflows on very narrow phones. One flexible child only: a second
                    // one (a Spacer) would split the space and pull the button inwards.
                    const Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(fit: BoxFit.scaleDown, child: Brand(onNavy: true)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _GhostOnNavy(
                      label: auth.isSignedIn ? (width < 480 ? 'Open app' : 'Open the register') : 'Sign in',
                      onPressed: () => context.go(auth.isSignedIn ? '/vehicles' : '/login'),
                    ),
                  ]),
                ),
                if (auth.notice != null && !auth.isSignedIn)
                  _NoticeOnNavy(text: auth.notice!, onClose: () => ref.read(authProvider.notifier).clearNotice()),
                Padding(
                  padding: EdgeInsets.only(top: wide ? 48 : 24, bottom: 72),
                  child: Flex(
                    direction: wide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    verticalDirection: wide ? VerticalDirection.down : VerticalDirection.up,
                    children: [
                      _flexible(wide, 10, _HeroText(
                        signedIn: auth.isSignedIn,
                        onPrimary: () => context.go(auth.isSignedIn ? '/vehicles' : '/login'),
                        onHow: _scrollToHow,
                        width: width,
                      )),
                      SizedBox(width: wide ? 48 : 0, height: wide ? 0 : 36),
                      _flexible(wide, 11, _PlateStage(sample: _fleet[_index % _fleet.length])),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          // ---------- how it works ----------
          _Width(
            key: _howItWorks,
            gutter: gutter,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 72),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Semantics(
                  header: true,
                  child: Text('One record per vehicle, kept current.',
                      style: StarkText.display(width < 480 ? 26 : 34, weight: FontWeight.w700, width: 112, color: StarkColors.ink)),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Text(
                    'Every vehicle in the Stark Group fleet has one record: its plate, what it is, which company it '
                    'works for, who drives it, and whether it is on the road.',
                    style: StarkText.body(17, color: StarkColors.muted),
                  ),
                ),
                const SizedBox(height: 40),
                Flex(
                  direction: wide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _flexible(wide, 9, const _Jobs()),
                    SizedBox(width: wide ? 56 : 0, height: wide ? 0 : 32),
                    _flexible(wide, 11, const _RecordCard()),
                  ],
                ),
              ]),
            ),
          ),
          const Rule(),
          _Width(
            gutter: gutter,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 8,
                spacing: 24,
                children: [
                  Text('Stark VMS, built for the Datavvy Academy full-stack course.',
                      style: StarkText.body(14, color: StarkColors.muted)),
                  Text('Source: github.com/Nakib-Saleh/Stark-VMS',
                      style: StarkText.body(14, color: StarkColors.muted)),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  static Widget _flexible(bool wide, int flex, Widget child) => wide ? Expanded(flex: flex, child: child) : child;
}

/// Centres content at the landing page's max width with a side gutter.
class _Width extends StatelessWidget {
  const _Width({super.key, required this.child, required this.gutter});

  final Widget child;
  final double gutter;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Padding(padding: EdgeInsets.symmetric(horizontal: gutter), child: child),
        ),
      );
}

class _HeroText extends StatelessWidget {
  const _HeroText({required this.signedIn, required this.onPrimary, required this.onHow, required this.width});

  final bool signedIn;
  final VoidCallback onPrimary;
  final VoidCallback onHow;
  final double width;

  @override
  Widget build(BuildContext context) {
    final size = width < 480 ? 36.0 : (width < 1100 ? 48.0 : 60.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Semantics(
        header: true,
        child: Text('The fleet register for Stark Group.',
            style: StarkText.display(size, weight: FontWeight.w800, width: 118, color: StarkColors.onNavyText)),
      ),
      const SizedBox(height: 18),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Text('Look up any vehicle by its plate, see who drives it and which company it works for, '
            'and keep its record current.',
            style: StarkText.body(18, color: StarkColors.onNavyMuted)),
      ),
      const SizedBox(height: 28),
      Wrap(spacing: 12, runSpacing: 12, children: [
        ShadButton(
          onPressed: onPrimary,
          height: 42,
          backgroundColor: StarkColors.paper,
          hoverBackgroundColor: const Color(0xFFDFE6F2),
          foregroundColor: StarkColors.navy,
          hoverForegroundColor: StarkColors.navy,
          child: Text(signedIn ? 'Open the register' : 'Sign in to the register'),
        ),
        _GhostOnNavy(label: 'How it works', onPressed: onHow, height: 42),
      ]),
    ]);
  }
}

class _GhostOnNavy extends StatelessWidget {
  const _GhostOnNavy({required this.label, required this.onPressed, this.height = 38});

  final String label;
  final VoidCallback onPressed;
  final double height;

  @override
  Widget build(BuildContext context) => ShadButton.outline(
        onPressed: onPressed,
        height: height,
        backgroundColor: const Color(0x00000000),
        hoverBackgroundColor: StarkColors.navy2,
        foregroundColor: StarkColors.onNavyText,
        hoverForegroundColor: StarkColors.paper,
        decoration: ShadDecoration(
          border: ShadBorder.all(color: StarkColors.ghostBorderOnNavy, radius: BorderRadius.circular(StarkRadius.control)),
        ),
        child: Text(label),
      );
}

class _NoticeOnNavy extends StatelessWidget {
  const _NoticeOnNavy({required this.text, required this.onClose});

  final String text;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
          decoration: BoxDecoration(
            color: StarkColors.navy2,
            borderRadius: BorderRadius.circular(StarkRadius.control),
          ),
          child: Row(children: [
            const Icon(LucideIcons.circleCheck, size: 16, color: Color(0xFF5FD39A)),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: StarkText.body(14, weight: FontWeight.w500, color: StarkColors.onNavyText))),
            Semantics(
              label: 'Dismiss',
              button: true,
              excludeSemantics: true,
              child: ShadButton.ghost(
                onPressed: onClose,
                width: 32,
                height: 32,
                padding: EdgeInsets.zero,
                hoverBackgroundColor: StarkColors.navy,
                child: const Icon(LucideIcons.x, size: 16, color: StarkColors.onNavyMuted),
              ),
            ),
          ]),
        ),
      );
}

class _PlateStage extends StatelessWidget {
  const _PlateStage({required this.sample});

  final _Sample sample;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          switchInCurve: StarkMotion.ease,
          switchOutCurve: StarkMotion.ease,
          transitionBuilder: (child, animation) => AnimatedBuilder(
            animation: animation,
            child: child,
            // A plate flipping on its horizontal axis, like a departures board.
            builder: (context, child) => Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateX((1 - animation.value) * math.pi / 2),
              child: Opacity(opacity: animation.value, child: child),
            ),
          ),
          child: NumberPlate(sample.plate, key: ValueKey(sample.plate), size: PlateSize.xl),
        ),
      ),
      const SizedBox(height: 18),
      AnimatedSwitcher(
        duration: StarkMotion.base,
        child: Column(key: ValueKey(sample.plate), children: [
          Text(sample.vehicle, style: StarkText.body(15, weight: FontWeight.w600, color: StarkColors.paper)),
          Text('${sample.company}, driven by ${sample.driver}', textAlign: TextAlign.center,
              style: StarkText.body(15, color: StarkColors.onNavyMuted)),
        ]),
      ),
    ]);
  }
}

class _Jobs extends StatelessWidget {
  const _Jobs();

  static const _items = [
    ('Register a vehicle once',
        'Enter the plate as it appears. The register refuses a plate that already exists, in any mix of capitals, '
            'so the same vehicle never appears twice.'),
    ('Find it by its plate',
        'The vehicle list shows every plate the way it looks on the road, with its type, company and driver beside it.'),
    ('Keep the record current',
        'Change a driver, a company or a status in place. Removing a vehicle always asks first.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (final (i, (title, text)) in _items.indexed)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            border: Border(
              top: const BorderSide(color: StarkColors.line),
              bottom: i == _items.length - 1 ? const BorderSide(color: StarkColors.line) : BorderSide.none,
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: StarkText.body(17, weight: FontWeight.w600, color: StarkColors.ink)),
            const SizedBox(height: 4),
            Text(text, style: StarkText.body(15, color: StarkColors.muted)),
          ]),
        ),
    ]);
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard();

  @override
  Widget build(BuildContext context) {
    Widget fact(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: StarkText.body(13, color: StarkColors.muted)),
          Text(value, style: StarkText.body(15, weight: FontWeight.w500, color: StarkColors.ink)),
        ]);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: StarkColors.paper,
        borderRadius: BorderRadius.circular(StarkRadius.surface),
        border: Border.all(color: StarkColors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 18, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          const NumberPlate('DHA-METRO-BA-23-7002', size: PlateSize.lg),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('Ashok Leyland Viking', style: StarkText.body(18, weight: FontWeight.w600, color: StarkColors.ink)),
            Text('Bus, 45 seats, CNG', style: StarkText.body(14, color: StarkColors.muted)),
          ]),
        ]),
        const SizedBox(height: 20),
        Wrap(spacing: 32, runSpacing: 14, children: [
          fact('Company', 'Stark Group HQ'),
          fact('Driver', 'Mizanur Rahman'),
          fact('Status', 'Maintenance'),
          fact('Year', '2018'),
        ]),
      ]),
    );
  }
}
