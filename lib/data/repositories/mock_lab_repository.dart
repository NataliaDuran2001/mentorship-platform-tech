import '../../domain/entities/lab_challenge.dart';
import '../../domain/repositories/lab_repository.dart';

/// A mock repository that returns hardcoded challenges for testing the UI.
class MockLabRepository implements LabRepository {
  @override
  Future<List<LabChallenge>> getChallengesForTopic(String topicId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // For any topic, return a mix of challenges to test the engine
    return [
      MultipleChoiceChallenge(
        id: 'c1',
        topicId: topicId,
        question: '¿Qué es Flutter?',
        description: 'Selecciona la definición más precisa.',
        options: {
          'o1': 'Un lenguaje de programación creado por Google.',
          'o2': 'Un SDK de interfaz de usuario para crear aplicaciones compiladas de forma nativa.',
          'o3': 'Una base de datos NoSQL en tiempo real.',
        },
        correctOptionId: 'o2',
      ),
      FillBlankChallenge(
        id: 'c2',
        topicId: topicId,
        question: 'Completa la función main',
        description: 'Arrastra o escribe la palabra correcta para que la aplicación inicie.',
        codeSnippet: 'void {{0}}() {\n  {{1}}(const MyApp());\n}',
        correctAnswers: {
          '0': 'main',
          '1': 'runApp',
        },
        availableOptions: ['main', 'runApp', 'start', 'initApp'],
      ),
      OrderLogicChallenge(
        id: 'c3',
        topicId: topicId,
        question: 'Ordena la lógica de un StatefulWidget',
        description: 'Coloca los pasos en el orden correcto de su ciclo de vida inicial.',
        blocks: {
          'b1': 'build(BuildContext context)',
          'b2': 'initState()',
          'b3': 'createState()',
        },
        correctOrder: ['b3', 'b2', 'b1'],
      ),
    ];
  }
}
