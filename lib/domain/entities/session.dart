class Session {
  final String id;
  final String influencerId;
  final String title;
  final String description;
  final SessionType type;
  final String publicLink;
  final DateTime createdAt;
  final DateTime? startTime;
  final DateTime? expiryTime;
  final DateTime? deletedAt;
  final SessionStatus status;
  final bool isAnonymous;
  final int totalQuestions;
  final int totalParticipants;
  final Map<String, dynamic>? pollOptions;
  final String? influencerName;
  final String? influencerPhotoUrl;
  final bool allowMultipleQuestions;

  const Session({
    required this.id,
    required this.influencerId,
    required this.title,
    required this.description,
    required this.type,
    required this.publicLink,
    required this.createdAt,
    this.startTime,
    this.expiryTime,
    this.deletedAt,
    required this.status,
    this.isAnonymous = false,
    this.totalQuestions = 0,
    this.totalParticipants = 0,
    this.pollOptions,
    this.influencerName,
    this.influencerPhotoUrl,
    this.allowMultipleQuestions = false,
  });

  Session copyWith({
    String? id,
    String? influencerId,
    String? title,
    String? description,
    SessionType? type,
    String? publicLink,
    DateTime? createdAt,
    DateTime? startTime,
    DateTime? expiryTime,
    DateTime? deletedAt,
    SessionStatus? status,
    bool? isAnonymous,
    int? totalQuestions,
    int? totalParticipants,
    Map<String, dynamic>? pollOptions,
    String? influencerName,
    String? influencerPhotoUrl,
    bool? allowMultipleQuestions,
  }) {
    return Session(
      id: id ?? this.id,
      influencerId: influencerId ?? this.influencerId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      publicLink: publicLink ?? this.publicLink,
      createdAt: createdAt ?? this.createdAt,
      startTime: startTime ?? this.startTime,
      expiryTime: expiryTime ?? this.expiryTime,
      deletedAt: deletedAt ?? this.deletedAt,
      status: status ?? this.status,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      totalParticipants: totalParticipants ?? this.totalParticipants,
      pollOptions: pollOptions ?? this.pollOptions,
      influencerName: influencerName ?? this.influencerName,
      influencerPhotoUrl: influencerPhotoUrl ?? this.influencerPhotoUrl,
      allowMultipleQuestions:
          allowMultipleQuestions ?? this.allowMultipleQuestions,
    );
  }

  bool get isActive => status == SessionStatus.active &&
      (expiryTime == null || DateTime.now().isBefore(expiryTime!));
}

enum SessionType {
  questionBox,
  poll,
  mixedMode,
}

enum SessionStatus {
  active,
  paused,
  ended,
}
