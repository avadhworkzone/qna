import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:string_similarity/string_similarity.dart';

import '../../core/constants/firestore_paths.dart';
import '../../domain/entities/question.dart';
import '../models/question_model.dart';

class QuestionRemoteDataSource {
  QuestionRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<Question>> watchQuestions(String sessionId) {
    return _firestore
        .collection(FirestorePaths.questions)
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QuestionModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<List<Question>> loadQuestions(String sessionId) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.questions)
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => QuestionModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<Question> createQuestion(Question question) async {
    final questionsRef = _firestore.collection(FirestorePaths.questions);

    QuerySnapshot<Map<String, dynamic>> recentSnapshot;
    try {
      recentSnapshot = await questionsRef
          .where('sessionId', isEqualTo: question.sessionId)
          .orderBy('createdAt', descending: true)
          .limit(25)
          .get();
    } catch (_) {
      // If the index isn't ready yet, skip duplicate detection to avoid blocking.
      recentSnapshot = await questionsRef
          .where('sessionId', isEqualTo: question.sessionId)
          .limit(25)
          .get();
    }

    final asker = QuestionAsker(
      userId: question.userId,
      name: question.createdByName,
      email: question.createdByEmail,
      photoUrl: question.createdByPhotoUrl,
    ).toMap();

    String? duplicateGroupId;
    String? primaryQuestionId;
    for (final doc in recentSnapshot.docs) {
      final data = doc.data();
      final existingText = (data['questionText'] ?? '').toString();
      final similarity = StringSimilarity.compareTwoStrings(
        existingText.toLowerCase(),
        question.questionText.toLowerCase(),
      );
      if (similarity >= 0.86) {
        duplicateGroupId = data['duplicateGroupId'] ?? doc.id;
        primaryQuestionId = doc.id;
        break;
      }
    }

    return _firestore.runTransaction((tx) async {
      if (primaryQuestionId != null) {
        tx.update(questionsRef.doc(primaryQuestionId), {
          'repeatCount': FieldValue.increment(1),
          'rankingScore': FieldValue.increment(1),
          'askers': FieldValue.arrayUnion([asker]),
        });
      }

      final docRef = questionsRef.doc();
      final model = QuestionModel(
        id: docRef.id,
        sessionId: question.sessionId,
        userId: question.userId,
        questionText: question.questionText,
        duplicateGroupId: duplicateGroupId,
        likeCount: 0,
        repeatCount: 1,
        rankingScore: question.calculateRankingScore(),
        createdAt: DateTime.now(),
        isPriority: question.isPriority,
        isAnswered: false,
        answer: null,
        createdByName: question.createdByName,
        createdByEmail: question.createdByEmail,
        createdByPhotoUrl: question.createdByPhotoUrl,
        askers: [
          QuestionAsker(
            userId: question.userId,
            name: question.createdByName,
            email: question.createdByEmail,
            photoUrl: question.createdByPhotoUrl,
          ),
        ],
      );
      tx.set(docRef, model.toFirestore());
      return model;
    });
  }

  Future<void> likeQuestion(String questionId) async {
    final docRef = _firestore.collection(FirestorePaths.questions).doc(questionId);
    await docRef.update({'likeCount': FieldValue.increment(1)});
  }

  Future<void> updateQuestionText(String questionId, String newText) async {
    final docRef = _firestore.collection(FirestorePaths.questions).doc(questionId);
    await docRef.update({'questionText': newText});
  }

  Future<void> mergeDuplicateQuestions(String duplicateGroupId, String primaryId) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.questions)
        .where('duplicateGroupId', isEqualTo: duplicateGroupId)
        .get();
    for (final doc in snapshot.docs) {
      if (doc.id == primaryId) continue;
      await doc.reference.update({'duplicateGroupId': primaryId});
    }
  }
}
