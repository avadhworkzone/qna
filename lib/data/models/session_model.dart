import '../../domain/entities/session.dart';

class SessionModel extends Session {
  const SessionModel({
    required super.id,
    required super.influencerId,
    required super.title,
    required super.description,
    required super.type,
    required super.publicLink,
    required super.createdAt,
    super.startTime,
    super.expiryTime,
    super.deletedAt,
    required super.status,
    super.isAnonymous,
    super.totalQuestions,
    super.totalParticipants,
    super.pollOptions,
    super.influencerName,
    super.influencerPhotoUrl,
    super.allowMultipleQuestions,
  });

  factory SessionModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SessionModel(
      id: id,
      influencerId: data['influencerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: SessionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => SessionType.questionBox,
      ),
      publicLink: data['publicLink'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['createdAt'] as num?)?.toInt() ?? 0,
      ),
      startTime: data['startTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['startTime'] as num?)?.toInt() ?? 0,
            )
          : null,
      expiryTime: data['expiryTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['expiryTime'] as num?)?.toInt() ?? 0,
            )
          : null,
      deletedAt: data['deletedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['deletedAt'] as num?)?.toInt() ?? 0,
            )
          : null,
      status: SessionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => SessionStatus.active,
      ),
      isAnonymous: data['isAnonymous'] ?? false,
      totalQuestions: (data['totalQuestions'] as num?)?.toInt() ?? 0,
      totalParticipants: (data['totalParticipants'] as num?)?.toInt() ?? 0,
      pollOptions: data['pollOptions'] as Map<String, dynamic>?,
      influencerName: data['influencerName'],
      influencerPhotoUrl: data['influencerPhotoUrl'],
      allowMultipleQuestions: data['allowMultipleQuestions'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'influencerId': influencerId,
      'title': title,
      'description': description,
      'type': type.name,
      'publicLink': publicLink,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'startTime': startTime?.millisecondsSinceEpoch,
      'expiryTime': expiryTime?.millisecondsSinceEpoch,
      'deletedAt': deletedAt?.millisecondsSinceEpoch,
      'status': status.name,
      'isAnonymous': isAnonymous,
      'totalQuestions': totalQuestions,
      'totalParticipants': totalParticipants,
      'pollOptions': pollOptions,
      'influencerName': influencerName,
      'influencerPhotoUrl': influencerPhotoUrl,
      'allowMultipleQuestions': allowMultipleQuestions,
    };
  }
}
