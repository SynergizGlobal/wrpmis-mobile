import 'package:flutter/material.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';

/// Update Structure list (WCR StructureFormListPage equivalent). Details later.
class UpdateStructurePage extends StatelessWidget {
  const UpdateStructurePage({super.key});

  static const String routeName = 'update-structure';
  static const String routePath = '/update-structure';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Structure')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Update Structure list will be connected next.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () {
                  GlobalDialog.info(
                    'Update Structure filters and edit flow will open here next.',
                    title: 'Update Structure',
                  );
                },
                child: const Text('Open filters'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
