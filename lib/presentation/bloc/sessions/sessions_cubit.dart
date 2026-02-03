import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/session.dart';
import '../../../domain/repositories/session_repository.dart';
import '../../../domain/usecases/sessions/create_session.dart';
import '../../../domain/usecases/sessions/load_sessions.dart';
import 'sessions_state.dart';

class SessionsCubit extends Cubit<SessionsState> {
  SessionsCubit(
    this._loadSessions,
    this._createSession,
    this._repository,
  ) : super(const SessionsState(isLoading: true));

  final LoadSessions _loadSessions;
  final CreateSession _createSession;
  final SessionRepository _repository;
  StreamSubscription<List<Session>>? _subscription;

  Future<void> watchSessions(String influencerId) async {
    emit(state.copyWith(isLoading: true));
    await _subscription?.cancel();
    _subscription = _repository.watchSessions(influencerId).listen(
      (sessions) => emit(state.copyWith(isLoading: false, sessions: sessions)),
      onError: (error) => emit(state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      )),
    );
  }

  Future<void> loadSessions(String influencerId) async {
    emit(state.copyWith(isLoading: true));
    try {
      final sessions = await _loadSessions(influencerId);
      emit(state.copyWith(isLoading: false, sessions: sessions));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<Session?> create(Session session) async {
    emit(state.copyWith(isLoading: true));
    try {
      final created = await _createSession(session);
      return created;
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      return null;
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
