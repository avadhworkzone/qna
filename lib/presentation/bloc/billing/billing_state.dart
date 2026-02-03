import 'package:equatable/equatable.dart';

class BillingState extends Equatable {
  const BillingState({
    required this.isLoading,
    this.checkoutUrl,
    this.errorMessage,
  });

  final bool isLoading;
  final String? checkoutUrl;
  final String? errorMessage;

  BillingState copyWith({
    bool? isLoading,
    String? checkoutUrl,
    String? errorMessage,
  }) {
    return BillingState(
      isLoading: isLoading ?? this.isLoading,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, checkoutUrl, errorMessage];
}
