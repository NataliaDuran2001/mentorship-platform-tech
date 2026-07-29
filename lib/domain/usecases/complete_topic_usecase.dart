// Domain layer: Use case encapsulating one business rule of the app.
//
// Completing a topic is what advances the path: GetRoadmapTreeUseCase derives
// what is unlocked from the completed topics, so this is the only writer that
// moves the sequence forward (issue #47).
//
// It lives in `domain` and not in the lab screen because the rule —what
// counts as finishing a topic— has to hold for every screen that can close
// one, not only for the interactive labs.

import '../repositories/roadmap_repository.dart';

class CompleteTopicUseCase {
  const CompleteTopicUseCase(this.repository);

  final RoadmapRepository repository;

  /// Marks the topic as completed for the signed-in user.
  ///
  /// Idempotent: calling it again on an already completed topic is a no-op,
  /// which is what lets a user replay a lab without breaking their progress.
  Future<void> call(String topicId) => repository.markTopicCompleted(topicId);
}
