class User {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final UserRole role;
  final String? subscriptionPlan;
  final int sessionCredits;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.role,
    this.subscriptionPlan,
    required this.sessionCredits,
    required this.createdAt,
    this.lastLoginAt,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    UserRole? role,
    String? subscriptionPlan,
    int? sessionCredits,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      sessionCredits: sessionCredits ?? this.sessionCredits,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

enum UserRole {
  influencer,
  user,
}