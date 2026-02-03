import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../domain/entities/poll_response.dart';
import '../models/poll_response_model.dart';

class PollRemoteDataSource {
  PollRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<PollResponse>> watchResponses(String sessionId) {
    return _firestore
        .collection(FirestorePaths.pollResponses)
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PollResponseModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<void> submitResponse(PollResponse response) async {
    final existing = await _firestore
        .collection(FirestorePaths.pollResponses)
        .where('sessionId', isEqualTo: response.sessionId)
        .where('userId', isEqualTo: response.userId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw StateError('User already voted');
    }
    final docRef = _firestore
        .collection(FirestorePaths.pollResponses)
        .doc('${response.sessionId}_${response.userId}');
    final model = PollResponseModel(
      id: docRef.id,
      sessionId: response.sessionId,
      userId: response.userId,
      selectedOption: response.selectedOption,
      createdAt: DateTime.now(),
    );
    await docRef.set(model.toFirestore());
  }

  Future<bool> hasUserVoted(String sessionId, String userId) async {
    final existing = await _firestore
        .collection(FirestorePaths.pollResponses)
        .where('sessionId', isEqualTo: sessionId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return existing.docs.isNotEmpty;
  }
}
