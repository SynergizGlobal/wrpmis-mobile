import 'package:flutter/material.dart';

/// Compact pagination footer matching WCR table screens.
class AppTablePaginationFooter extends StatelessWidget {
  const AppTablePaginationFooter({
    super.key,
    required this.total,
    required this.startIndex,
    required this.endIndex,
    required this.currentPage,
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
    this.pageSize,
    this.pageSizeOptions = const <int>[5, 10, 25, 50],
    this.onPageSizeChanged,
  });

  final int total;
  final int startIndex;
  final int endIndex;
  final int currentPage;
  final int pageCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final int? pageSize;
  final List<int> pageSizeOptions;
  final ValueChanged<int>? onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextStyle? meta = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        );
    final String summary = total == 0
        ? '0 of 0'
        : '${startIndex + 1}-$endIndex of $total';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            if (pageSize != null && onPageSizeChanged != null) ...<Widget>[
              Text('Show', style: meta),
              const SizedBox(width: 4),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: pageSize,
                  isDense: true,
                  style: meta,
                  items: pageSizeOptions
                      .map(
                        (int size) => DropdownMenuItem<int>(
                          value: size,
                          child: Text('$size'),
                        ),
                      )
                      .toList(),
                  onChanged: (int? value) {
                    if (value != null) {
                      onPageSizeChanged!(value);
                    }
                  },
                ),
              ),
            ],
            const Spacer(),
            Text(summary, style: meta),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                label: const Text('Prev'),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Page ${currentPage + 1} of $pageCount',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                label: const Text('Next'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
