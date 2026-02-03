import '../../domain/entities/question.dart';
import '../../domain/repositories/question_repository.dart';
import '../datasources/question_remote_data_source.dart';

class QuestionRepositoryImpl implements QuestionRepository {
  QuestionRepositoryImpl(this._remote);

  final QuestionRemoteDataSource _remote;

  @override
  Stream<List<Question>> watchQuestions(String sessionId) {
    return _remote.watchQuestions(sessionId);
  }

  @override
  Future<List<Question>> loadQuestions(String sessionId) {
    return _remote.loadQuestions(sessionId);
  }

  @override
  Future<Question> createQuestion(Question question) {
    return _remote.createQuestion(question);
  }

  @override
  Future<void> likeQuestion(String questionId) {
    return _remote.likeQuestion(questionId);
  }

  @override
  Future<void> mergeDuplicateQuestions(String duplicateGroupId, String primaryId) {
    return _remote.mergeDuplicateQuestions(duplicateGroupId, primaryId);
  }

  @override
  Future<void> updateQuestionText(String questionId, String newText) {
    return _remote.updateQuestionText(questionId, newText);
  }
}
