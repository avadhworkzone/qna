import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/question.dart';
import '../../../domain/repositories/question_repository.dart';
import '../../../domain/usecases/questions/create_question.dart';
import '../../../domain/usecases/questions/like_question.dart';
import '../../../domain/usecases/questions/update_question_text.dart';
import 'questions_state.dart';

class QuestionsCubit extends Cubit<QuestionsState> {
  QuestionsCubit(
    this._createQuestion,
    this._likeQuestion,
    this._updateQuestionText,
    this._repository,
  ) : super(const QuestionsState(isLoading: true));

  final CreateQuestion _createQuestion;
  final LikeQuestion _likeQuestion;
  final UpdateQuestionText _updateQuestionText;
  final QuestionRepository _repository;
  StreamSubscription<List<Question>>? _subscription;

  Future<void> watchQuestions(String sessionId) async {
    emit(state.copyWith(isLoading: true));
    await _subscription?.cancel();
    _subscription = _repository.watchQuestions(sessionId).listen(
      (questions) => emit(state.copyWith(isLoading: false, questions: questions)),
      onError: (error) => emit(state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      )),
    );
  }

  Future<Question?> create(Question question) async {
    try {
      final created = await _createQuestion(question);
      return created;
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
      return null;
    }
  }

  Future<bool> updateText(String questionId, String newText) async {
    try {
      await _updateQuestionText(questionId, newText);
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  Future<void> like(String questionId) async {
    try {
      await _likeQuestion(questionId);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
