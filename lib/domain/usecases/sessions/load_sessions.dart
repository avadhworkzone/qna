import '../../entities/session.dart';
import '../../repositories/session_repository.dart';

class LoadSessions {
  final SessionRepository repository;
  LoadSessions(this.repository);

  Future<List<Session>> call(String influencerId) {
    return repository.loadSessions(influencerId);
  }
}
