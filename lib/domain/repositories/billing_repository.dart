abstract class BillingRepository {
  Future<String> startCheckout(String priceId, String successUrl, String cancelUrl);
  Future<void> openCustomerPortal(String returnUrl);
}
