import 'package:equatable/equatable.dart';

import '../../../domain/entities/question.dart';

class QuestionsState extends Equatable {
  const QuestionsState({
    required this.isLoading,
    this.questions = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final List<Question> questions;
  final String? errorMessage;

  QuestionsState copyWith({
    bool? isLoading,
    List<Question>? questions,
    String? errorMessage,
  }) {
    return QuestionsState(
      isLoading: isLoading ?? this.isLoading,
      questions: questions ?? this.questions,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, questions, errorMessage];
}
