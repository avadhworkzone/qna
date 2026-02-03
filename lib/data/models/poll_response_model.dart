import '../../domain/entities/poll_response.dart';

class PollResponseModel extends PollResponse {
  const PollResponseModel({
    required super.id,
    required super.sessionId,
    required super.userId,
    required super.selectedOption,
    required super.createdAt,
  });

  factory PollResponseModel.fromFirestore(Map<String, dynamic> data, String id) {
    return PollResponseModel(
      id: id,
      sessionId: data['sessionId'] ?? '',
      userId: data['userId'] ?? '',
      selectedOption: data['selectedOption'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['createdAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'selectedOption': selectedOption,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
