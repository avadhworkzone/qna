import '../entities/question.dart';

abstract class QuestionRepository {
  Stream<List<Question>> watchQuestions(String sessionId);
  Future<List<Question>> loadQuestions(String sessionId);
  Future<Question> createQuestion(Question question);
  Future<void> likeQuestion(String questionId);
  Future<void> mergeDuplicateQuestions(String duplicateGroupId, String primaryId);
  Future<void> updateQuestionText(String questionId, String newText);
}
