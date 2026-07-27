// Atomic Design (Page): Navigable placeholder for the chat with the AI mentor.

import 'package:flutter/material.dart';
import '../organisms/destination_placeholder.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DestinationPlaceholder(
      title: 'Chat',
      detail: 'Destination under construction: the chat with the AI mentor '
          'arrives in phases after Module 1.',
    );
  }
}
