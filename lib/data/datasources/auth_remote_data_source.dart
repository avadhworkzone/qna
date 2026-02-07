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

    // Remote-configurable free credits. Uses manage/setting.freeCredit only.
    // Falls back to 2 if config is missing or unreadable due to rules.
    var freeOrganizerCredits = 2;
    try {
      final legacySnap =
          await _firestore.collection('manage').doc('setting').get();
      final fromLegacy = (legacySnap.data()?['freeCredit'] as num?)?.toInt();
      if (fromLegacy != null) freeOrganizerCredits = fromLegacy;
    } catch (_) {
      // Intentionally ignore and use default.
    }
    final docRef = _firestore.collection(FirestorePaths.users).doc(current.uid);
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      final data = snapshot.data() ?? {};
      final currentRole = data['role'] ?? UserRole.user.name;
      final freeGranted = data['freeCreditsGranted'] == true;
      final existingCredits = (data['sessionCredits'] as num?)?.toInt() ?? 0;
      final existingFreeAmount = (data['freeCreditsAmount'] as num?)?.toInt();
      final existingFreeRemaining =
          (data['freeCreditsRemaining'] as num?)?.toInt();
      final freeApplied = data['freeCreditsApplied'] == true;
      final updates = <String, dynamic>{
        'lastLoginAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Ensure the user doc always has a freeCreditsAmount field for consistent UI.
      if (role == UserRole.influencer && existingFreeAmount == null) {
        updates['freeCreditsAmount'] = freeGranted ? freeOrganizerCredits : 0;
      }
      // Ensure the remaining counter exists so "free" can decrement separately.
      if (role == UserRole.influencer && existingFreeRemaining == null) {
        final amount = existingFreeAmount ?? (freeGranted ? freeOrganizerCredits : 0);
        // Best-effort: remaining cannot exceed total credits.
        updates['freeCreditsRemaining'] =
            amount <= 0 ? 0 : (existingCredits < amount ? existingCredits : amount);
      }

      // One-time: grant the configured free credits to organizers.
      // We track "freeCreditsApplied" separately to repair older accounts that had
      // freeCreditsGranted=true but never received sessionCredits.
      if (role == UserRole.influencer &&
          !freeGranted &&
          freeOrganizerCredits > 0) {
        updates['sessionCredits'] = existingCredits >= freeOrganizerCredits
            ? existingCredits
            : freeOrganizerCredits;
        updates['freeCreditsGranted'] = true;
        updates['freeCreditsAmount'] = freeOrganizerCredits;
        updates['freeCreditsRemaining'] = freeOrganizerCredits;
        updates['freeCreditsApplied'] = true;
      } else if (role == UserRole.influencer &&
          freeGranted &&
          !freeApplied) {
        final amount = existingFreeAmount ?? freeOrganizerCredits;
        if (amount > 0) {
          updates['sessionCredits'] =
              existingCredits >= amount ? existingCredits : amount;
        }
        updates['freeCreditsAmount'] = amount > 0 ? amount : 0;
        updates['freeCreditsRemaining'] =
            amount <= 0 ? 0 : (existingCredits < amount ? existingCredits : amount);
        updates['freeCreditsApplied'] = true;
      }
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
      sessionCredits: role == UserRole.influencer ? freeOrganizerCredits : 0,
      freeCreditsGranted:
          role == UserRole.influencer && freeOrganizerCredits > 0,
      freeCreditsAmount: role == UserRole.influencer ? freeOrganizerCredits : 0,
      freeCreditsRemaining:
          role == UserRole.influencer ? freeOrganizerCredits : 0,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    await docRef.set({
      ...userModel.toFirestore(),
      if (role == UserRole.influencer && freeOrganizerCredits > 0)
        'freeCreditsGranted': true,
      if (role == UserRole.influencer) 'freeCreditsApplied': freeOrganizerCredits > 0,
    });
    return userModel;
  }
}
