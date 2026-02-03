class PollResponse {
  final String id;
  final String sessionId;
  final String userId;
  final String selectedOption;
  final DateTime createdAt;

  const PollResponse({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.selectedOption,
    required this.createdAt,
  });

  PollResponse copyWith({
    String? id,
    String? sessionId,
    String? userId,
    String? selectedOption,
    DateTime? createdAt,
  }) {
    return PollResponse(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      selectedOption: selectedOption ?? this.selectedOption,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}