import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../theme/stark_tokens.dart';

/// DESIGN.md "Pagination". [page] is 1-based like the URL. "Showing x–y of z" and the page
/// numbers come from the same server response, so they always agree.
class RegisterPagination extends StatelessWidget {
  const RegisterPagination({
    super.key,
    required this.page,
    required this.totalPages,
    required this.pageSize,
    required this.totalElements,
    required this.shownOnPage,
    required this.onPage,
  });

  final int page;
  final int totalPages;
  final int pageSize;
  final int totalElements;
  final int shownOnPage;
  final ValueChanged<int> onPage;

  /// `1 … 4 [5] 6 … 12`; null is a gap.
  static List<int?> pageNumbers(int current, int total) {
    if (total <= 7) return [for (var i = 1; i <= total; i++) i];
    final from = (current - 1).clamp(2, total - 3);
    final to = (current + 1).clamp(4, total - 1);
    return [1, if (from > 2) null, for (var i = from; i <= to; i++) i, if (to < total - 1) null, total];
  }

  @override
  Widget build(BuildContext context) {
    final first = shownOnPage == 0 ? 0 : (page - 1) * pageSize + 1;
    final last = shownOnPage == 0 ? 0 : first + shownOnPage - 1;
    final noun = totalElements == 1 ? 'vehicle' : 'vehicles';
    final showing = Text(
      shownOnPage == 0 ? '$totalElements $noun' : 'Showing $first–$last of $totalElements $noun',
      style: StarkText.body(14, color: StarkColors.muted).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    );
    if (totalPages <= 1) return showing;

    final phone = MediaQuery.sizeOf(context).width < 600;
    final prev = _Quiet(
      label: '‹ Previous',
      semantics: 'Previous page',
      onPressed: page > 1 ? () => onPage(page - 1) : null,
    );
    final next = _Quiet(
      label: 'Next ›',
      semantics: 'Next page',
      onPressed: page < totalPages ? () => onPage(page + 1) : null,
    );

    if (phone) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        showing,
        const SizedBox(height: 10),
        Row(children: [
          prev,
          Expanded(
            child: Text('Page $page of $totalPages',
                textAlign: TextAlign.center, style: StarkText.body(14, weight: FontWeight.w600, color: StarkColors.ink)),
          ),
          next,
        ]),
      ]);
    }

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 10,
      spacing: 16,
      children: [
        showing,
        Row(mainAxisSize: MainAxisSize.min, children: [
          prev,
          for (final n in pageNumbers(page, totalPages))
            n == null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('…', style: StarkText.body(14, color: StarkColors.muted)),
                  )
                : _PageNumber(n: n, current: n == page, onPressed: () => onPage(n)),
          next,
        ]),
      ],
    );
  }
}

class _Quiet extends StatelessWidget {
  const _Quiet({required this.label, required this.semantics, required this.onPressed});

  final String label;
  final String semantics;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        label: semantics,
        button: true,
        enabled: onPressed != null,
        excludeSemantics: true,
        // Disabled, not hidden, at the ends (DESIGN.md).
        child: ShadButton.ghost(
          onPressed: onPressed,
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label),
        ),
      );
}

class _PageNumber extends StatelessWidget {
  const _PageNumber({required this.n, required this.current, required this.onPressed});

  final int n;
  final bool current;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Semantics(
          label: current ? 'Page $n, current page' : 'Page $n',
          selected: current,
          button: true,
          excludeSemantics: true,
          child: ShadButton.ghost(
            onPressed: current ? () {} : onPressed,
            width: 34,
            height: 34,
            padding: EdgeInsets.zero,
            backgroundColor: current ? StarkColors.navy : null,
            hoverBackgroundColor: current ? StarkColors.navy : null,
            foregroundColor: current ? StarkColors.paper : null,
            hoverForegroundColor: current ? StarkColors.paper : null,
            child: Text('$n', style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
          ),
        ),
      );
}
