// Atomic Design (Organism): Placeholder content for a shell destination that
// is not built yet. Keeps the text inside the 800px readable width that the
// design system sets for text views.

import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class DestinationPlaceholder extends StatelessWidget {
  final String title;
  final String detail;

  const DestinationPlaceholder({
    super.key,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: AppConstants.maxReadableWidth),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              detail,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
