import '../../entities/poll_response.dart';
import '../../repositories/poll_repository.dart';

class SubmitPollResponse {
  final PollRepository repository;
  SubmitPollResponse(this.repository);

  Future<void> call(PollResponse response) {
    return repository.submitResponse(response);
  }
}
