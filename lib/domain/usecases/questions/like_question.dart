import '../../repositories/question_repository.dart';

class LikeQuestion {
  final QuestionRepository repository;
  LikeQuestion(this.repository);

  Future<void> call(String questionId) {
    return repository.likeQuestion(questionId);
  }
}
