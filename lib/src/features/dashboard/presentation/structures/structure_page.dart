import 'package:flutter/material.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';

/// Add Structure list (WCR StructuresPage equivalent). Details later.
class StructurePage extends StatelessWidget {
  const StructurePage({super.key});

  static const String routeName = 'structure';
  static const String routePath = '/structure';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Structure')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          GlobalDialog.info(
            'Add Structure form will open here next.',
            title: 'Add Structure',
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Structure'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Structure list will be connected next.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
