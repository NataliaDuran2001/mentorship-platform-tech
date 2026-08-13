// Atomic Design (Page): Navigable placeholder for logic practice.

import 'package:flutter/material.dart';
import '../organisms/destination_placeholder.dart';

class LogicPage extends StatelessWidget {
  const LogicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DestinationPlaceholder(
      title: 'Logic',
      detail: "Logic practice is coming soon. We're building it now!",
    );
  }
}
