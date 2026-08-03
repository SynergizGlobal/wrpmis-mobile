import 'package:flutter/material.dart';

class AppSelectSheetField<T> extends StatelessWidget {
  const AppSelectSheetField({
    super.key,
    required this.label,
    required this.title,
    required this.items,
    required this.itemLabelBuilder,
    required this.value,
    required this.onChanged,
    this.leadingIcon,
    this.enabled = true,
    this.placeholderText = 'Select',
  });

  final String label;
  final String title;
  final List<T> items;
  final String Function(T value) itemLabelBuilder;
  final T? value;
  final ValueChanged<T> onChanged;
  final IconData? leadingIcon;
  final bool enabled;
  final String placeholderText;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool filled = value != null;
    final String selectedLabel =
        value != null ? itemLabelBuilder(value as T) : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: !enabled
            ? null
            : () async {
                final T? selected = await showModalBottomSheet<T>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  builder: (BuildContext context) {
                    final bool isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    final double maxSheetHeight =
                        MediaQuery.of(context).size.height * 0.58;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxSheetHeight),
                        child: Material(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const SizedBox(height: 10),
                              Center(
                                child: Container(
                                  width: 46,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  10,
                                ),
                                child: Text(
                                  title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const Divider(height: 1),
                              Expanded(
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    10,
                                    10,
                                    10,
                                    14,
                                  ),
                                  itemCount: items.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 8),
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final T item = items[index];
                                    final String labelText =
                                        itemLabelBuilder(item);
                                    final bool isSelected = item == value;
                                    final Color tileColor = isSelected
                                        ? colorScheme.primary.withValues(
                                            alpha: 0.22,
                                          )
                                        : colorScheme.surfaceContainerHighest
                                            .withValues(
                                              alpha: isDark ? 0.20 : 0.10,
                                            );
                                    return ListTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      tileColor: tileColor,
                                      title: Text(
                                        labelText,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? Icon(
                                              Icons.check_circle_rounded,
                                              color: colorScheme.primary,
                                            )
                                          : null,
                                      onTap: () =>
                                          Navigator.of(context).pop(item),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
                if (selected != null) {
                  onChanged(selected);
                }
              },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (label.trim().isNotEmpty) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 8),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
            InputDecorator(
              decoration: InputDecoration(
                filled: true,
                enabled: enabled,
                prefixIcon: leadingIcon != null
                    ? Icon(leadingIcon, size: 22)
                    : null,
                suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                filled ? selectedLabel : placeholderText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: filled ? FontWeight.w600 : FontWeight.w500,
                      color: filled
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
