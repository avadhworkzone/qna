import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Stream<User?> authStateChanges() {
    return _remote.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      return _remote.ensureUserProfile(UserRole.user);
    });
  }

  @override
  Future<User?> getCurrentUser() async {
    final fbUser = _remote.getCurrentUser();
    if (fbUser == null) return null;
    return _remote.ensureUserProfile(UserRole.user);
  }

  @override
  Future<User> signInWithGoogle() async {
    await _remote.signInWithGoogle();
    return _remote.ensureUserProfile(UserRole.user);
  }

  @override
  Future<User> signInWithApple() async {
    await _remote.signInWithApple();
    return _remote.ensureUserProfile(UserRole.user);
  }

  @override
  Future<void> signOut() => _remote.signOut();

  @override
  Future<User> ensureUserProfile(UserRole role) async {
    final user = await _remote.ensureUserProfile(role);
    return UserModel.fromEntity(user);
  }
}
