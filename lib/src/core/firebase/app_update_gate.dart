import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wr_pmis_mobile/src/core/firebase/remote_config_service.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';

class AppUpdateGate {
  const AppUpdateGate._();

  static bool _shownThisSession = false;

  static Future<void> checkAndPrompt(AppUpdateInfo info) async {
    if (!info.requiresUpdate || _shownThisSession) {
      return;
    }
    final BuildContext? context = GlobalDialog.navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      return;
    }
    _shownThisSession = true;

    final String body = [
      info.message,
      '',
      'Installed: ${info.installedVersion}',
      'Latest: ${info.latestVersion}',
      if (info.currentVersion.isNotEmpty &&
          info.currentVersion != info.latestVersion)
        'Current: ${info.currentVersion}',
    ].join('\n');

    if (info.isForce) {
      await _showForceDialog(context, info: info, body: body);
      return;
    }

    await AppDialog.show(
      context: context,
      title: info.title,
      message: body,
      type: AppDialogType.info,
      leadingIcon: Icons.system_update_rounded,
      barrierDismissible: true,
      actions: <AppDialogAction>[
        const AppDialogAction(label: 'Later'),
        AppDialogAction(
          label: 'Update',
          isPrimary: true,
          onPressed: () => _openStore(info.storeUrl),
        ),
      ],
    );
  }

  static Future<void> _showForceDialog(
    BuildContext context, {
    required AppUpdateInfo info,
    required String body,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            backgroundColor: colorScheme.surface,
            surfaceTintColor: colorScheme.surfaceTint,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Icon(
                      Icons.system_update_rounded,
                      color: colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      info.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () => _openStore(info.storeUrl),
                      child: const Text('Update Now'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> _openStore(String storeUrl) async {
    final String trimmed = storeUrl.trim();
    if (trimmed.isEmpty) {
      await GlobalDialog.info(
        'Store link is not configured yet. Please update the app from the store.',
        title: 'Update',
      );
      return;
    }
    final Uri? uri = Uri.tryParse(trimmed);
    if (uri == null) {
      await GlobalDialog.error('Invalid store link.');
      return;
    }
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      await GlobalDialog.error('Unable to open the store link.');
    }
  }
}
