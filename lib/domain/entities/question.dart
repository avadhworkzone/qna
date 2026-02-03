class Question {
  final String id;
  final String sessionId;
  final String userId;
  final String questionText;
  final String? duplicateGroupId;
  final int likeCount;
  final int repeatCount;
  final double rankingScore;
  final DateTime createdAt;
  final bool isPriority;
  final bool isAnswered;
  final String? answer;
  final String? createdByName;
  final String? createdByEmail;
  final String? createdByPhotoUrl;
  final List<QuestionAsker> askers;

  const Question({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.questionText,
    this.duplicateGroupId,
    this.likeCount = 0,
    this.repeatCount = 1,
    this.rankingScore = 0.0,
    required this.createdAt,
    this.isPriority = false,
    this.isAnswered = false,
    this.answer,
    this.createdByName,
    this.createdByEmail,
    this.createdByPhotoUrl,
    this.askers = const [],
  });

  Question copyWith({
    String? id,
    String? sessionId,
    String? userId,
    String? questionText,
    String? duplicateGroupId,
    int? likeCount,
    int? repeatCount,
    double? rankingScore,
    DateTime? createdAt,
    bool? isPriority,
    bool? isAnswered,
    String? answer,
    String? createdByName,
    String? createdByEmail,
    String? createdByPhotoUrl,
    List<QuestionAsker>? askers,
  }) {
    return Question(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      questionText: questionText ?? this.questionText,
      duplicateGroupId: duplicateGroupId ?? this.duplicateGroupId,
      likeCount: likeCount ?? this.likeCount,
      repeatCount: repeatCount ?? this.repeatCount,
      rankingScore: rankingScore ?? this.rankingScore,
      createdAt: createdAt ?? this.createdAt,
      isPriority: isPriority ?? this.isPriority,
      isAnswered: isAnswered ?? this.isAnswered,
      answer: answer ?? this.answer,
      createdByName: createdByName ?? this.createdByName,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      createdByPhotoUrl: createdByPhotoUrl ?? this.createdByPhotoUrl,
      askers: askers ?? this.askers,
    );
  }

  double calculateRankingScore() {
    const double repeatWeight = 0.4;
    const double likesWeight = 0.3;
    const double recentWeight = 0.2;
    const double priorityWeight = 0.1;

    final double recentScore = _calculateRecentScore();
    final double priorityScore = isPriority ? 1.0 : 0.0;

    return (repeatCount * repeatWeight) +
           (likeCount * likesWeight) +
           (recentScore * recentWeight) +
           (priorityScore * priorityWeight);
  }

  double _calculateRecentScore() {
    final now = DateTime.now();
    final diff = now.difference(createdAt).inHours;
    
    if (diff <= 1) return 1.0;
    if (diff <= 6) return 0.8;
    if (diff <= 24) return 0.5;
    return 0.2;
  }
}

class QuestionAsker {
  final String userId;
  final String? name;
  final String? email;
  final String? photoUrl;

  const QuestionAsker({
    required this.userId,
    this.name,
    this.email,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
    };
  }

  factory QuestionAsker.fromMap(Map<String, dynamic> data) {
    return QuestionAsker(
      userId: data['userId'] ?? '',
      name: data['name'],
      email: data['email'],
      photoUrl: data['photoUrl'],
    );
  }
}
