// Tests of the score-to-band mapping shown on the interview-practice
// results screen: locks down the 4 gradations (item 3/5 of the internal
// feedback round) and their boundaries.

import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/presentation/utils/app_colors.dart';
import 'package:aspire_app/presentation/utils/interview_score_bands.dart';

void main() {
  group('interviewScoreBand', () {
    test('bands the full 0-100 range without gaps or overlaps', () {
      expect(interviewScoreBand(0).label, 'Keep practicing');
      expect(interviewScoreBand(39).label, 'Keep practicing');
      expect(interviewScoreBand(40).label, 'Getting there');
      expect(interviewScoreBand(64).label, 'Getting there');
      expect(interviewScoreBand(65).label, 'Good');
      expect(interviewScoreBand(84).label, 'Good');
      expect(interviewScoreBand(85).label, 'Excellent');
      expect(interviewScoreBand(100).label, 'Excellent');
    });

    test('a low score never carries a celebratory color', () {
      final band = interviewScoreBand(22);
      expect(band.label, 'Keep practicing');
      expect(band.containerColor, AppColors.errorContainer);
      expect(band.color, AppColors.onErrorContainer);
    });
  });
}
