import '../entities/lab_challenge.dart';

/// Abstract repository for fetching learning lab challenges.
abstract class LabRepository {
  /// Fetches a list of challenges associated with a given [topicId].
  Future<List<LabChallenge>> getChallengesForTopic(String topicId);
}
