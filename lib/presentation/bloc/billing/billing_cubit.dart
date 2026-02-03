import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/billing/start_subscription_checkout.dart';
import 'billing_state.dart';

class BillingCubit extends Cubit<BillingState> {
  BillingCubit(this._startCheckout) : super(const BillingState(isLoading: false));

  final StartSubscriptionCheckout _startCheckout;

  Future<void> startCheckout({
    required String priceId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    emit(state.copyWith(isLoading: true));
    try {
      final url = await _startCheckout(
        priceId: priceId,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
      );
      emit(state.copyWith(isLoading: false, checkoutUrl: url));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}
