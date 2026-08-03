import 'package:flutter/material.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';

/// Technical Assistance (placeholder — details later).
class TechnicalAssistancePage extends StatelessWidget {
  const TechnicalAssistancePage({super.key});

  static const String routeName = 'technical-assistance';
  static const String routePath = '/technical-assistance';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Technical Assistance')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          GlobalDialog.info(
            'Add Technical Assistance form will open here next.',
            title: 'Technical Assistance',
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Technical Assistance list will be connected next.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
