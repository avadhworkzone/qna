import '../entities/poll_response.dart';

abstract class PollRepository {
  Stream<List<PollResponse>> watchResponses(String sessionId);
  Future<void> submitResponse(PollResponse response);
  Future<bool> hasUserVoted(String sessionId, String userId);
}
