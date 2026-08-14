// Atomic Design (Organism): the explanation step of a lab.
//
// It is the only challenge type with nothing to answer. The learner reads it
// and acknowledges it, which is what lets a topic alternate between explaining
// and practising instead of opening with an exercise nobody was taught to
// solve.
//
// It stays a plain renderer: the blocks arrive already typed from the domain
// and it decides nothing about them beyond how each kind is painted.

import 'package:flutter/material.dart';

import '../../../domain/entities/lab_challenge.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class LabTheory extends StatelessWidget {
  const LabTheory({super.key, required this.challenge});

  final TheoryChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The label tells the learner up front that this one is a read, not a
        // test. Without it the "Got it" button at the bottom reads like a way
        // to skip something.
        Row(
          children: [
            const Icon(
              Icons.menu_book_outlined,
              size: AppConstants.iconSizeSm,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Text(
              'CONCEPT',
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingSm),
        Text(challenge.question, style: textTheme.headlineMedium),
        if (challenge.description != null) ...[
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            challenge.description!,
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppConstants.spacingLg),
        for (final block in challenge.blocks)
          Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
            child: _Block(block: block),
          ),
        if (challenge.keyTakeaway != null) ...[
          const SizedBox(height: AppConstants.spacingSm),
          _KeyTakeaway(text: challenge.keyTakeaway!),
        ],
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.block});

  final TheoryBlock block;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    switch (block.type) {
      case TheoryBlockType.paragraph:
        return Text(
          block.text ?? '',
          style: textTheme.bodyLarge?.copyWith(height: 1.6),
        );

      case TheoryBlockType.list:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in block.items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      // Nudges the dot onto the first line's baseline.
                      padding: const EdgeInsets.only(top: 7.0),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingMd),
                    Expanded(
                      child: Text(
                        item,
                        style: textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );

      case TheoryBlockType.code:
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (block.language != null)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppConstants.spacingMd,
                    right: AppConstants.spacingMd,
                    top: AppConstants.spacingSm,
                  ),
                  child: Text(
                    block.language!.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              // Code does not wrap: a broken line is harder to read than a
              // scrollbar, and these samples are deliberately short.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                child: Text(
                  block.text ?? '',
                  style: textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _KeyTakeaway extends StatelessWidget {
  const _KeyTakeaway({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            size: AppConstants.iconSizeSm,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
