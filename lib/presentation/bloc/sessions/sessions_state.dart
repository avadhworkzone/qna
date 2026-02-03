import 'package:equatable/equatable.dart';

import '../../../domain/entities/session.dart';

class SessionsState extends Equatable {
  const SessionsState({
    required this.isLoading,
    this.sessions = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final List<Session> sessions;
  final String? errorMessage;

  SessionsState copyWith({
    bool? isLoading,
    List<Session>? sessions,
    String? errorMessage,
  }) {
    return SessionsState(
      isLoading: isLoading ?? this.isLoading,
      sessions: sessions ?? this.sessions,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, sessions, errorMessage];
}
