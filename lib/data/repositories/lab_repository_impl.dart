import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../domain/entities/lab_challenge.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/lab_repository.dart';

class LabRepositoryImpl implements LabRepository {
  const LabRepositoryImpl(this._client);

  final sb.SupabaseClient _client;
  static const String _table = 'lab_challenges';

  @override
  Future<List<LabChallenge>> getChallengesForTopic(String topicId) async {
    try {
      final rows = await _client
          .from(_table)
          .select()
          .eq('topic_id', topicId)
          .order('sort_order');

      return rows.map((row) {
        final String type = row['challenge_type'] as String;
        final String id = row['id'] as String;
        final String tId = row['topic_id'] as String;
        final String question = row['question'] as String;
        final String? description = row['description'] as String?;
        final Map<String, dynamic> content = row['content'] as Map<String, dynamic>;

        switch (type) {
          case 'theory':
            return TheoryChallenge(
              id: id,
              topicId: tId,
              question: question,
              description: description,
              blocks: _theoryBlocks(content['blocks'] as List?),
              keyTakeaway: content['keyTakeaway'] as String?,
            );
          case 'multiple_choice':
            return MultipleChoiceChallenge(
              id: id,
              topicId: tId,
              question: question,
              description: description,
              options: Map<String, String>.from(content['options'] as Map),
              correctOptionId: content['correctOptionId'] as String,
            );
          case 'fill_blank':
            return FillBlankChallenge(
              id: id,
              topicId: tId,
              question: question,
              description: description,
              codeSnippet: content['codeSnippet'] as String,
              correctAnswers: Map<String, String>.from(content['correctAnswers'] as Map),
              availableOptions: (content['availableOptions'] as List?)?.cast<String>(),
            );
          case 'order_logic':
            return OrderLogicChallenge(
              id: id,
              topicId: tId,
              question: question,
              description: description,
              blocks: Map<String, String>.from(content['blocks'] as Map),
              correctOrder: (content['correctOrder'] as List).cast<String>(),
            );
          default:
            throw Exception('Unknown challenge type: $type');
        }
      }).toList(growable: false);
    } on sb.PostgrestException catch (e) {
      throw AuthFailure(AuthFailureKind.unknown, technicalDetail: e.message);
    } catch (e) {
      throw AuthFailure(AuthFailureKind.unknown, technicalDetail: e.toString());
    }
  }

  /// Maps the `blocks` array of a theory challenge.
  ///
  /// A block whose `type` is not one this version knows about is dropped
  /// instead of throwing: the content lives in the database and can gain new
  /// kinds of block before an app release is out, and losing one paragraph is
  /// better than an unreadable topic.
  static List<TheoryBlock> _theoryBlocks(List? raw) {
    if (raw == null) return const <TheoryBlock>[];

    final blocks = <TheoryBlock>[];
    for (final entry in raw) {
      final map = (entry as Map).cast<String, dynamic>();
      final type = switch (map['type'] as String?) {
        'paragraph' => TheoryBlockType.paragraph,
        'code' => TheoryBlockType.code,
        'list' => TheoryBlockType.list,
        _ => null,
      };
      if (type == null) continue;

      blocks.add(
        TheoryBlock(
          type: type,
          text: map['text'] as String?,
          items: (map['items'] as List?)?.cast<String>() ?? const <String>[],
          language: map['language'] as String?,
        ),
      );
    }
    return List<TheoryBlock>.unmodifiable(blocks);
  }
}
