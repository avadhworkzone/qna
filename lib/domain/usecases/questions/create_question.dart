import '../../entities/question.dart';
import '../../repositories/question_repository.dart';

class CreateQuestion {
  final QuestionRepository repository;
  CreateQuestion(this.repository);

  Future<Question> call(Question question) {
    return repository.createQuestion(question);
  }
}
