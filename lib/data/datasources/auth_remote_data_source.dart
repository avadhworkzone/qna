import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/user_model.dart';
import '../../domain/entities/user.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._auth, this._firestore);

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<fb.User?> authStateChanges() => _auth.authStateChanges();

  fb.User? getCurrentUser() => _auth.currentUser;

  Future<fb.UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = fb.GoogleAuthProvider();
      return _auth.signInWithPopup(provider);
    }
    final googleUser = await GoogleSignIn().signIn();
    final googleAuth = await googleUser?.authentication;
    if (googleAuth == null) {
      throw StateError('Google sign-in canceled');
    }
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<fb.UserCredential> signInWithApple() async {
    final result = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final credential = fb.OAuthProvider('apple.com').credential(
      idToken: result.identityToken,
      accessToken: result.authorizationCode,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() => _auth.signOut();

  Future<UserModel> ensureUserProfile(UserRole role) async {
    final current = _auth.currentUser;
    if (current == null) {
      throw StateError('No authenticated user');
    }
    final docRef = _firestore.collection(FirestorePaths.users).doc(current.uid);
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      final data = snapshot.data() ?? {};
      final currentRole = data['role'] ?? UserRole.user.name;
      final updates = <String, dynamic>{
        'lastLoginAt': DateTime.now().millisecondsSinceEpoch,
      };
      if (currentRole != role.name && role == UserRole.influencer) {
        updates['role'] = role.name;
      }
      await docRef.update(updates);
      return UserModel.fromFirestore({...data, ...updates}, snapshot.id);
    }
    final userModel = UserModel(
      id: current.uid,
      name: current.displayName ?? 'User',
      email: current.email ?? '',
      photoUrl: current.photoURL,
      role: role,
      subscriptionPlan: null,
      sessionCredits: role == UserRole.influencer ? 0 : 0,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    await docRef.set(userModel.toFirestore());
    return userModel;
  }
}
