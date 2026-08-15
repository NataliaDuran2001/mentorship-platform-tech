// Atomic Design (Atom): Irreducible component.
//
// The "About you" / "About the job" pill shown on an interview question and
// on its feedback card. Was defined twice, verbatim, in
// interview_question_card.dart and interview_feedback_card.dart — pulled
// out here so both stay visually identical by construction instead of by
// discipline.

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/translate.dart';

class InterviewCategoryTag extends StatelessWidget {
  const InterviewCategoryTag({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final label = category == 'behavioral'
        ? tr('About you', 'Sobre ti')
        : tr('About the job', 'Sobre el puesto');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onPrimaryFixed,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
