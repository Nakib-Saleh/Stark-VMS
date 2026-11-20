import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../auth/auth_controller.dart';
import '../theme/stark_tokens.dart';
import 'brand.dart';
import 'stark_page.dart';

/// The signed-in frame (DESIGN.md "Side menu"): navy menu on the left, the page on the right.
/// Under 820px wide the menu becomes a top bar.
class AppFrame extends ConsumerWidget {
  const AppFrame({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _items = [
    _NavItem(label: 'Dashboard', icon: LucideIcons.layoutGrid, soon: true),
    _NavItem(label: 'Vehicles', icon: LucideIcons.car, path: '/vehicles'),
    _NavItem(label: 'Drivers', icon: LucideIcons.user, soon: true),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = ref.watch(authProvider.select((s) => s.username)) ?? '';
    final wide = MediaQuery.sizeOf(context).width >= 820;

    Widget signOut() => _SignOutButton(onPressed: () async {
          await ref.read(authProvider.notifier).signOut();
          if (context.mounted) context.go('/');
        });

    if (!wide) {
      return StarkPage(
        child: Column(children: [
          ColoredBox(
            color: StarkColors.navy,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(children: [
                  // Brand and menu take the free space as one group, so Sign out sits at the right edge.
                  Expanded(
                    child: Row(children: [
                      const Flexible(
                        child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Brand(onNavy: true)),
                      ),
                      const SizedBox(width: 12),
                      for (final item in _items.where((i) => !i.soon)) _NavTile(item: item, location: location, compact: true),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  signOut(),
                ]),
              ),
            ),
          ),
          Expanded(child: child),
        ]),
      );
    }

    return StarkPage(
      child: Row(children: [
        ColoredBox(
          color: StarkColors.navy,
          child: SizedBox(
            width: 232,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(10, 4, 10, 22),
                  child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Brand(onNavy: true)),
                ),
                for (final item in _items) _NavTile(item: item, location: location),
                const Spacer(),
                const Rule(color: StarkColors.navDivider),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 14, 10, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text.rich(
                      TextSpan(children: [
                        const TextSpan(text: 'Signed in as '),
                        TextSpan(
                          text: username,
                          style: StarkText.body(14, weight: FontWeight.w600, color: StarkColors.paper),
                        ),
                      ]),
                      style: StarkText.body(14, color: StarkColors.onNavyMuted),
                    ),
                    const SizedBox(height: 6),
                    signOut(),
                  ]),
                ),
              ]),
            ),
          ),
        ),
        Expanded(child: child),
      ]),
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.icon, this.path, this.soon = false});

  final String label;
  final IconData icon;
  final String? path;

  /// A later phase builds this page. Shown, labelled "Soon", and not clickable.
  final bool soon;
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.location, this.compact = false});

  final _NavItem item;
  final String location;
  final bool compact;

  static const _idle = Color(0xFFC8D4E8);

  @override
  Widget build(BuildContext context) {
    final active = item.path != null && location.startsWith(item.path!);
    final fg = active ? StarkColors.paper : _idle;
    final label = Row(mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max, children: [
      Icon(item.icon, size: 18, color: fg),
      const SizedBox(width: 10),
      // "Soon" rows sit in the menu's fixed width, so their label may flex and ellipsize. Clickable
      // rows live inside a ShadButton, which gives its content unbounded width: no flex there.
      if (item.soon) ...[
        Expanded(
          child: Text(item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: StarkText.body(15, weight: FontWeight.w500, color: fg)),
        ),
        const SizedBox(width: 8),
        Text('Soon', style: StarkText.body(11, color: const Color(0xFF8FA3C4))),
      ] else
        Text(item.label, maxLines: 1, style: StarkText.body(15, weight: active ? FontWeight.w600 : FontWeight.w500, color: fg)),
    ]);

    if (item.soon) {
      return Semantics(
        label: '${item.label}, coming soon',
        enabled: false,
        excludeSemantics: true,
        child: Opacity(
          opacity: 0.55,
          child: Padding(padding: const EdgeInsets.fromLTRB(10, 9, 10, 13), child: label),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 0 : 4),
      child: Semantics(
        selected: active,
        child: ShadButton.ghost(
          onPressed: () => context.go(item.path!),
          width: compact ? null : double.infinity,
          height: compact ? 34 : 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          mainAxisAlignment: MainAxisAlignment.start,
          backgroundColor: active ? StarkColors.navy2 : null,
          hoverBackgroundColor: StarkColors.navy2,
          decoration: active && !compact
              ? const ShadDecoration(
                  border: ShadBorder(left: ShadBorderSide(color: StarkColors.navActiveBar, width: 3)),
                )
              : null,
          child: label,
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ShadButton.link(
        onPressed: onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        height: 28,
        foregroundColor: const Color(0xFF9FB6DE),
        hoverForegroundColor: StarkColors.paper,
        child: const Text('Sign out'),
      );
}
