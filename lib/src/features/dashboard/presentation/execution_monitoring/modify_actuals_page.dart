import 'package:flutter/material.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';

/// Modify Actuals (placeholder — details later).
class ModifyActualsPage extends StatelessWidget {
  const ModifyActualsPage({super.key});

  static const String routeName = 'modify-actuals';
  static const String routePath = '/modify-actuals';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modify Actuals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          GlobalDialog.info(
            'Modify Actuals form will open here next.',
            title: 'Modify Actuals',
          );
        },
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Modify'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Modify Actuals list will be connected next.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
