import 'package:flutter/material.dart';

/// Western Railways Works categories (web reference).
class WorkCategoryItem {
  const WorkCategoryItem({
    required this.id,
    required this.title,
    required this.icon,
  });

  final String id;
  final String title;
  final IconData icon;

  static const List<WorkCategoryItem> catalog = <WorkCategoryItem>[
    WorkCategoryItem(
      id: 'new_line',
      title: 'New Line',
      icon: Icons.train_outlined,
    ),
    WorkCategoryItem(
      id: 'doubling_multitracking',
      title: 'Doubling/Multitracking',
      icon: Icons.compare_arrows_outlined,
    ),
    WorkCategoryItem(
      id: 'gauge_conversion',
      title: 'Gauge Conversion',
      icon: Icons.swap_horiz_rounded,
    ),
    WorkCategoryItem(
      id: 'station_redevelopment',
      title: 'Station Redevelopment',
      icon: Icons.apartment_outlined,
    ),
  ];
}
