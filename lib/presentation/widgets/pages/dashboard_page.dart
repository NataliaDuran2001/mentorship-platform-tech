// Atomic Design (Page): Navigable placeholder for the dashboard. The real
// content (roadmap and progress) arrives with Module 1 (E1).

import 'package:flutter/material.dart';
import '../organisms/destination_placeholder.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DestinationPlaceholder(
      title: 'Dashboard',
      detail: 'Destination under construction: the roadmap summary and your '
          'progress arrive with Module 1 (E1).',
    );
  }
}
