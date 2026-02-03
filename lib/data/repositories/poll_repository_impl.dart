import '../../domain/entities/poll_response.dart';
import '../../domain/repositories/poll_repository.dart';
import '../datasources/poll_remote_data_source.dart';

class PollRepositoryImpl implements PollRepository {
  PollRepositoryImpl(this._remote);

  final PollRemoteDataSource _remote;

  @override
  Stream<List<PollResponse>> watchResponses(String sessionId) {
    return _remote.watchResponses(sessionId);
  }

  @override
  Future<void> submitResponse(PollResponse response) {
    return _remote.submitResponse(response);
  }

  @override
  Future<bool> hasUserVoted(String sessionId, String userId) {
    return _remote.hasUserVoted(sessionId, userId);
  }
}
