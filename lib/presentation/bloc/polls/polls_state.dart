import 'package:equatable/equatable.dart';

import '../../../domain/entities/poll_response.dart';

class PollsState extends Equatable {
  const PollsState({
    required this.isLoading,
    this.responses = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final List<PollResponse> responses;
  final String? errorMessage;

  PollsState copyWith({
    bool? isLoading,
    List<PollResponse>? responses,
    String? errorMessage,
  }) {
    return PollsState(
      isLoading: isLoading ?? this.isLoading,
      responses: responses ?? this.responses,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, responses, errorMessage];
}
