import 'package:flutter/material.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';

/// Update Forms → Contracts/Tenders → Contractor (placeholder).
class ContractorPage extends StatelessWidget {
  const ContractorPage({super.key});

  static const String routeName = 'contractors';
  static const String routePath = '/contractors';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contractor')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          GlobalDialog.info(
            'Add Contractor form will open here next.',
            title: 'Contractor',
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Contractor list will be connected next.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
