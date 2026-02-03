import '../entities/question.dart';

class QuestionScoringService {
  double score(Question question) {
    final repeatScore = question.repeatCount * 0.4;
    final likeScore = question.likeCount * 0.3;
    final recentScore = _recencyScore(question.createdAt) * 0.2;
    final priorityScore = (question.isPriority ? 1 : 0) * 0.1;
    return repeatScore + likeScore + recentScore + priorityScore;
  }

  double _recencyScore(DateTime createdAt) {
    final hours = DateTime.now().difference(createdAt).inHours;
    if (hours <= 1) return 10;
    if (hours <= 6) return 6;
    if (hours <= 24) return 3;
    return 1;
  }
}
