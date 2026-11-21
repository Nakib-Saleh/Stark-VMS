import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../network/server_wake.dart';
import '../theme/stark_tokens.dart';
import 'stark_page.dart';

/// DESIGN.md "Waking notice": styled like the toast (navy, bottom-right, rises 10px + fades), but
/// it stays until the server answers. Sits above every page (ShadApp builder in main.dart).
class ServerWakeNotice extends ConsumerWidget {
  const ServerWakeNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wake = ref.watch(serverWakeProvider);
    final visible = wake != ServerWake.answering;
    final d = motion(context, StarkMotion.base);

    return Positioned(
      right: 24,
      bottom: 24,
      // Hidden: no taps, no screen-reader text, and the spinner stops (it would keep frames going).
      child: IgnorePointer(
        ignoring: !visible,
        child: ExcludeSemantics(
          excluding: !visible,
          child: TickerMode(
            enabled: visible,
            child: AnimatedSlide(
              offset: visible ? Offset.zero : const Offset(0, 0.15),
              duration: d,
              curve: StarkMotion.ease,
              child: AnimatedOpacity(
                opacity: visible ? 1 : 0,
                duration: d,
                curve: StarkMotion.ease,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: (MediaQuery.sizeOf(context).width - 48).clamp(0, 380)),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: StarkColors.navy,
                      borderRadius: BorderRadius.circular(StarkRadius.control),
                      // Same floating shadow as the detail panel (DESIGN.md: only floating things get one).
                      boxShadow: [
                        BoxShadow(
                          color: StarkColors.navy.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Semantics(
                      liveRegion: true,
                      child: wake == ServerWake.unreachable
                          ? _Unreachable(onRetry: () => ref.read(serverWakeProvider.notifier).probe())
                          : const _Waking(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Waking extends StatelessWidget {
  const _Waking();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(padding: EdgeInsets.only(top: 4), child: Spinner()),
      const SizedBox(width: 12),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Waking up the server…',
              style: StarkText.body(14, weight: FontWeight.w600, color: StarkColors.onNavyText),
            ),
            const SizedBox(height: 4),
            Text(
              'It sleeps when nobody has used it for a while. This can take up to a minute.',
              style: StarkText.body(13, color: StarkColors.onNavyMuted),
            ),
          ],
        ),
      ),
    ],
  );
}

class _Unreachable extends StatelessWidget {
  const _Unreachable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        "Can't reach the server.",
        style: StarkText.body(14, weight: FontWeight.w600, color: StarkColors.onNavyText),
      ),
      const SizedBox(height: 4),
      Text('Check your connection, then try again.', style: StarkText.body(13, color: StarkColors.onNavyMuted)),
      const SizedBox(height: 12),
      ShadButton.outline(
        onPressed: onRetry,
        height: 32,
        backgroundColor: const Color(0x00000000),
        hoverBackgroundColor: StarkColors.navy2,
        foregroundColor: StarkColors.onNavyText,
        hoverForegroundColor: StarkColors.paper,
        decoration: ShadDecoration(
          border: ShadBorder.all(
            color: StarkColors.ghostBorderOnNavy,
            radius: BorderRadius.circular(StarkRadius.control),
          ),
        ),
        child: const Text('Try again'),
      ),
    ],
  );
}
