import 'package:flutter/material.dart';

/// Single centered overlay used instead of per-field progress bars.
class AppGlobalLoader extends StatelessWidget {
  const AppGlobalLoader({
    super.key,
    this.message,
    this.blocking = true,
  });

  final String? message;
  final bool blocking;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: blocking,
        child: ColoredBox(
          color: scheme.scrim.withValues(alpha: 0.28),
          child: Center(
            child: Material(
              color: scheme.surface,
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: scheme.primary,
                      ),
                    ),
                    if (message != null && message!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        message!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
