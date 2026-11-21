import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/stark_tokens.dart';

/// Root of every new-design page. New code doesn't import Material (deprecated since Flutter
/// 3.47, and shadcn_ui still uses the old copy), so this gives the page its background and the
/// default body text style a Material Scaffold used to provide.
class StarkPage extends StatelessWidget {
  const StarkPage({super.key, required this.child, this.color = StarkColors.tarmac});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: color,
        child: DefaultTextStyle(style: StarkText.body(15, color: StarkColors.ink), child: child),
      );
}

/// A DESIGN.md motion duration, or zero when the OS asks for reduced motion.
Duration motion(BuildContext context, Duration d) => MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;

/// Small spinner for buttons that are busy ("Signing in").
class Spinner extends StatefulWidget {
  const Spinner({super.key, this.size = 14, this.color = StarkColors.paper});

  final double size;
  final Color color;

  @override
  State<Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<Spinner> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
        turns: _controller,
        child: CustomPaint(size: Size.square(widget.size), painter: _ArcPainter(widget.color)),
      );
}

class _ArcPainter extends CustomPainter {
  _ArcPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final rect = Offset.zero & size;
    canvas.drawArc(rect.deflate(1), 0, math.pi * 2, false, paint..color = color.withValues(alpha: 0.35));
    canvas.drawArc(rect.deflate(1), -math.pi / 2, math.pi / 2, false, paint..color = color);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.color != color;
}

/// A 1px rule in the line colour.
class Rule extends StatelessWidget {
  const Rule({super.key, this.color = StarkColors.line});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(height: 1, width: double.infinity, child: ColoredBox(color: color));
}
