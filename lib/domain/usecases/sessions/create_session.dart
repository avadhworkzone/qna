import '../../entities/session.dart';
import '../../repositories/session_repository.dart';

class CreateSession {
  final SessionRepository repository;
  CreateSession(this.repository);

  Future<Session> call(Session session) {
    return repository.createSession(session);
  }
}
