import '../../repositories/question_repository.dart';

class UpdateQuestionText {
  final QuestionRepository repository;
  UpdateQuestionText(this.repository);

  Future<void> call(String questionId, String newText) {
    return repository.updateQuestionText(questionId, newText);
  }
}
