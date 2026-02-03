import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/poll_response.dart';
import '../../../domain/repositories/poll_repository.dart';
import '../../../domain/usecases/polls/submit_poll_response.dart';
import 'polls_state.dart';

class PollsCubit extends Cubit<PollsState> {
  PollsCubit(
    this._submitPollResponse,
    this._repository,
  ) : super(const PollsState(isLoading: true));

  final SubmitPollResponse _submitPollResponse;
  final PollRepository _repository;
  StreamSubscription<List<PollResponse>>? _subscription;

  Future<void> watchResponses(String sessionId) async {
    emit(state.copyWith(isLoading: true));
    await _subscription?.cancel();
    _subscription = _repository.watchResponses(sessionId).listen(
      (responses) => emit(state.copyWith(isLoading: false, responses: responses)),
      onError: (error) => emit(state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      )),
    );
  }

  Future<bool> submit(PollResponse response) async {
    try {
      await _submitPollResponse(response);
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
