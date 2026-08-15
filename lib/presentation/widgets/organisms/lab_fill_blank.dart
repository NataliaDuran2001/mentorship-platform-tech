import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/entities/content_translation.dart';
import '../../../domain/entities/lab_challenge.dart';
import '../../../core/theme/app_theme.dart';
import '../../state/lab_state.dart';
import '../../state/lab_actions.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/translate.dart';

class LabFillBlank extends StatelessWidget {
  const LabFillBlank({super.key, required this.challenge, this.translation});

  final FillBlankChallenge challenge;

  /// AI-translated overlay for [challenge]'s question/description only.
  /// `codeSnippet`, `correctAnswers` and `availableOptions` are literal
  /// code, never language, and are never translated — always rendered from
  /// [challenge] itself.
  final ExerciseTranslation? translation;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final parts = _parseSnippet(challenge.codeSnippet);
    final question = translation?.question ?? challenge.question;
    final description = translation?.description ?? challenge.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(question, style: textTheme.headlineMedium),
        if (description != null) ...[
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            description,
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppConstants.spacingXl),
        
        // Code area
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppConstants.radiusDefault),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: parts.map((part) {
              if (part.isMarker) {
                return _BlankInput(markerIndex: part.text);
              }
              return Text(
                part.text,
                style: AppTheme.code,
              );
            }).toList(),
          ),
        ),

        // Available options (if any)
        if (challenge.availableOptions != null) ...[
          const SizedBox(height: AppConstants.spacingXl),
          Text(
            tr('Options (tap to copy):', 'Opciones (toca para copiar):'),
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Wrap(
            spacing: AppConstants.spacingSm,
            runSpacing: AppConstants.spacingSm,
            children: challenge.availableOptions!.map((opt) {
              return ActionChip(
                label: Text(opt, style: AppTheme.code),
                onPressed: () {
                  // Find first empty blank and fill it
                  for (final key in challenge.correctAnswers.keys) {
                    if (labSelectedAnswers.value[key] == null ||
                        labSelectedAnswers.value[key]!.isEmpty) {
                      setLabAnswer(key, opt);
                      break;
                    }
                  }
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  List<_SnippetPart> _parseSnippet(String snippet) {
    final List<_SnippetPart> parts = [];
    final regex = RegExp(r'\{\{(\d+)\}\}');
    int lastEnd = 0;

    for (final match in regex.allMatches(snippet)) {
      if (match.start > lastEnd) {
        parts.add(_SnippetPart(
          text: snippet.substring(lastEnd, match.start),
          isMarker: false,
        ));
      }
      parts.add(_SnippetPart(text: match.group(1)!, isMarker: true));
      lastEnd = match.end;
    }

    if (lastEnd < snippet.length) {
      parts.add(_SnippetPart(
        text: snippet.substring(lastEnd),
        isMarker: false,
      ));
    }

    return parts;
  }
}

class _SnippetPart {
  final String text;
  final bool isMarker;
  _SnippetPart({required this.text, required this.isMarker});
}

class _BlankInput extends StatelessWidget {
  const _BlankInput({required this.markerIndex});

  final String markerIndex;

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final answer = labSelectedAnswers.value[markerIndex] ?? '';
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 100, // Fixed width for simplicity in this iteration
          height: 32,
          child: TextField(
            controller: TextEditingController.fromValue(
              TextEditingValue(
                text: answer,
                selection: TextSelection.collapsed(offset: answer.length),
              ),
            ),
            onChanged: (val) => setLabAnswer(markerIndex, val),
            style: AppTheme.code,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.outline),
                borderRadius: BorderRadius.circular(4),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.outline),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      }
    );
  }
}
