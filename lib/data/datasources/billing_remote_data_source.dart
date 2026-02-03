
import 'package:cloud_functions/cloud_functions.dart';

class BillingRemoteDataSource {
  BillingRemoteDataSource(this._functions);

  final FirebaseFunctions _functions;

  Future<String> startCheckout(String priceId, String successUrl, String cancelUrl) async {
    final callable = _functions.httpsCallable('createCheckoutSession');
    final result = await callable.call({
      'priceId': priceId,
      'successUrl': successUrl,
      'cancelUrl': cancelUrl,
    });
    return (result.data as Map)['url'] as String;
  }

  Future<void> openCustomerPortal(String returnUrl) async {
    final callable = _functions.httpsCallable('createCustomerPortalSession');
    await callable.call({'returnUrl': returnUrl});
  }
}
