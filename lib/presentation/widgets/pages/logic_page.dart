// Atomic Design (Page): Navigable placeholder for logic practice.

import 'package:flutter/material.dart';
import '../organisms/destination_placeholder.dart';

class LogicPage extends StatelessWidget {
  const LogicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DestinationPlaceholder(
      title: 'Logic',
      detail: 'Destination under construction: logic practice arrives with '
          'the topic tree of Module 1 (E1).',
    );
  }
}
