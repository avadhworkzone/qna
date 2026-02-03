import '../entities/user.dart';

abstract class AuthRepository {
  Stream<User?> authStateChanges();
  Future<User?> getCurrentUser();
  Future<User> signInWithGoogle();
  Future<User> signInWithApple();
  Future<void> signOut();
  Future<User> ensureUserProfile(UserRole role);
}
