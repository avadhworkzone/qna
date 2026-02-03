import '../../domain/repositories/billing_repository.dart';
import '../datasources/billing_remote_data_source.dart';

class BillingRepositoryImpl implements BillingRepository {
  BillingRepositoryImpl(this._remote);

  final BillingRemoteDataSource _remote;

  @override
  Future<String> startCheckout(String priceId, String successUrl, String cancelUrl) {
    return _remote.startCheckout(priceId, successUrl, cancelUrl);
  }

  @override
  Future<void> openCustomerPortal(String returnUrl) {
    return _remote.openCustomerPortal(returnUrl);
  }
}
