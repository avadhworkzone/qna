import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/session_model.dart';
import '../../domain/entities/session.dart';

class SessionRemoteDataSource {
  SessionRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  Stream<List<Session>> watchSessions(String influencerId) {
    return _firestore
        .collection(FirestorePaths.sessions)
        .where('influencerId', isEqualTo: influencerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SessionModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<List<Session>> loadSessions(String influencerId) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.sessions)
        .where('influencerId', isEqualTo: influencerId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => SessionModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<Session> createSession(Session session) async {
    final docRef = _firestore.collection(FirestorePaths.sessions).doc();
    final publicLink = _uuid.v4();
    final model = SessionModel(
      id: docRef.id,
      influencerId: session.influencerId,
      title: session.title,
      description: session.description,
      type: session.type,
      publicLink: publicLink,
      createdAt: DateTime.now(),
      startTime: session.startTime,
      expiryTime: session.expiryTime,
      status: session.status,
      isAnonymous: session.isAnonymous,
      totalQuestions: 0,
      totalParticipants: 0,
      pollOptions: session.pollOptions,
      influencerName: session.influencerName,
      influencerPhotoUrl: session.influencerPhotoUrl,
      allowMultipleQuestions: session.allowMultipleQuestions,
      deletedAt: session.deletedAt,
    );
    await docRef.set(model.toFirestore());
    return model;
  }

  Future<void> updateSession(Session session) {
    return _firestore
        .collection(FirestorePaths.sessions)
        .doc(session.id)
        .update(SessionModel(
          id: session.id,
          influencerId: session.influencerId,
          title: session.title,
          description: session.description,
          type: session.type,
          publicLink: session.publicLink,
          createdAt: session.createdAt,
          startTime: session.startTime,
          expiryTime: session.expiryTime,
          status: session.status,
          isAnonymous: session.isAnonymous,
          totalQuestions: session.totalQuestions,
          totalParticipants: session.totalParticipants,
          pollOptions: session.pollOptions,
          influencerName: session.influencerName,
          influencerPhotoUrl: session.influencerPhotoUrl,
          allowMultipleQuestions: session.allowMultipleQuestions,
          deletedAt: session.deletedAt,
        ).toFirestore());
  }

  Future<void> softDeleteSession(String sessionId) {
    return _firestore.collection(FirestorePaths.sessions).doc(sessionId).update({
      'status': SessionStatus.ended.name,
      'deletedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> endSession(String sessionId) {
    return _firestore
        .collection(FirestorePaths.sessions)
        .doc(sessionId)
        .update({'status': SessionStatus.ended.name});
  }

  Future<Session?> getSessionByPublicLink(String publicLink) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.sessions)
        .where('publicLink', isEqualTo: publicLink)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    final session = SessionModel.fromFirestore(doc.data(), doc.id);
    if (session.deletedAt != null) return null;
    return session;
  }

  Future<Session?> getSessionById(String sessionId) async {
    final doc = await _firestore.collection(FirestorePaths.sessions).doc(sessionId).get();
    if (!doc.exists) return null;
    return SessionModel.fromFirestore(doc.data()!, doc.id);
  }
}
