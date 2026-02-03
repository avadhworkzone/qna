import '../entities/session.dart';

abstract class SessionRepository {
  Stream<List<Session>> watchSessions(String influencerId);
  Future<List<Session>> loadSessions(String influencerId);
  Future<Session> createSession(Session session);
  Future<void> updateSession(Session session);
  Future<void> endSession(String sessionId);
  Future<Session?> getSessionByPublicLink(String publicLink);
  Future<Session?> getSessionById(String sessionId);
}
