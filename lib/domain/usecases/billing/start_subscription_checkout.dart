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
