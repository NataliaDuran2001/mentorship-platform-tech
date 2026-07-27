// Atomic Design (Page): Navigable placeholder for the user's profile.

import 'package:flutter/material.dart';
import '../organisms/destination_placeholder.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DestinationPlaceholder(
      title: 'Profile',
      detail: 'Destination under construction: profile management arrives '
          'with real authentication (#9).',
    );
  }
}
