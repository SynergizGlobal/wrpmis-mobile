import 'package:flutter/material.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';

/// New Activities Update (placeholder — details later).
class NewActivitiesUpdatePage extends StatelessWidget {
  const NewActivitiesUpdatePage({super.key});

  static const String routeName = 'new-activities-update';
  static const String routePath = '/new-activities-update';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Activities Update')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          GlobalDialog.info(
            'Add New Activities Update form will open here next.',
            title: 'New Activities Update',
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'New Activities Update list will be connected next.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
