import '../../domain/entities/question.dart';

class QuestionModel extends Question {
  const QuestionModel({
    required super.id,
    required super.sessionId,
    required super.userId,
    required super.questionText,
    super.duplicateGroupId,
    super.likeCount,
    super.repeatCount,
    super.rankingScore,
    required super.createdAt,
    super.isPriority,
    super.isAnswered,
    super.answer,
    super.createdByName,
    super.createdByEmail,
    super.createdByPhotoUrl,
    super.askers,
  });

  factory QuestionModel.fromFirestore(Map<String, dynamic> data, String id) {
    return QuestionModel(
      id: id,
      sessionId: data['sessionId'] ?? '',
      userId: data['userId'] ?? '',
      questionText: data['questionText'] ?? '',
      duplicateGroupId: data['duplicateGroupId'],
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      repeatCount: (data['repeatCount'] as num?)?.toInt() ?? 1,
      rankingScore: (data['rankingScore'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['createdAt'] as num?)?.toInt() ?? 0,
      ),
      isPriority: data['isPriority'] ?? false,
      isAnswered: data['isAnswered'] ?? false,
      answer: data['answer'],
      createdByName: data['createdByName'],
      createdByEmail: data['createdByEmail'],
      createdByPhotoUrl: data['createdByPhotoUrl'],
      askers: (data['askers'] as List<dynamic>?)
              ?.map((e) => QuestionAsker.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'questionText': questionText,
      'duplicateGroupId': duplicateGroupId,
      'likeCount': likeCount,
      'repeatCount': repeatCount,
      'rankingScore': rankingScore,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isPriority': isPriority,
      'isAnswered': isAnswered,
      'answer': answer,
      'createdByName': createdByName,
      'createdByEmail': createdByEmail,
      'createdByPhotoUrl': createdByPhotoUrl,
      'askers': askers.map((e) => e.toMap()).toList(),
    };
  }
}
