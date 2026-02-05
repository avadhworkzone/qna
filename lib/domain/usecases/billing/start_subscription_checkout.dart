import '../../repositories/billing_repository.dart';

class StartSubscriptionCheckout {
  final BillingRepository repository;
  StartSubscriptionCheckout(this.repository);

  Future<String> call({
    required String priceId,
    required String successUrl,
    required String cancelUrl,
  }) {
    return repository.startCheckout(priceId, successUrl, cancelUrl);
  }
}

class ConfirmCheckout {
  final BillingRepository repository;
  ConfirmCheckout(this.repository);

  Future<Map<String, dynamic>> call({required String sessionId}) {
    return repository.confirmCheckout(sessionId);
  }
}
