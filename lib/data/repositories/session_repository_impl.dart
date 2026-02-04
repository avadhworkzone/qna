import '../../domain/entities/session.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/session_remote_data_source.dart';

class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl(this._remote);

  final SessionRemoteDataSource _remote;

  @override
  Stream<List<Session>> watchSessions(String influencerId) {
    return _remote.watchSessions(influencerId);
  }

  @override
  Future<List<Session>> loadSessions(String influencerId) {
    return _remote.loadSessions(influencerId);
  }

  @override
  Future<Session> createSession(Session session) {
    return _remote.createSession(session);
  }

  @override
  Future<void> updateSession(Session session) {
    return _remote.updateSession(session);
  }

  @override
  Future<void> endSession(String sessionId) {
    return _remote.endSession(sessionId);
  }

  @override
  Future<void> softDeleteSession(String sessionId) {
    return _remote.softDeleteSession(sessionId);
  }

  @override
  Future<Session?> getSessionByPublicLink(String publicLink) {
    return _remote.getSessionByPublicLink(publicLink);
  }

  @override
  Future<Session?> getSessionById(String sessionId) {
    return _remote.getSessionById(sessionId);
  }
}
