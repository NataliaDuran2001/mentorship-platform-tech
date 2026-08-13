// Atomic Design (Page): Navigable placeholder for the chat with the AI mentor.

import 'package:flutter/material.dart';
import '../organisms/destination_placeholder.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DestinationPlaceholder(
      title: 'Chat',
      detail: "Chatting with your AI mentor is coming soon. We're building "
          "it now!",
    );
  }
}
