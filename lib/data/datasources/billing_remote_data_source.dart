
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BillingRemoteDataSource {
  BillingRemoteDataSource(this._functions, this._auth);

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  Future<String> startCheckout(String priceId, String successUrl, String cancelUrl) async {
    try {
      try {
        final debugCallable = _functions.httpsCallable('debugCheckout');
        final debugResult = await debugCallable.call();
        // ignore: avoid_print
        print('debugCheckout: ${debugResult.data}');
      } catch (e) {
        // ignore: avoid_print
        print('debugCheckout failed: $e');
      }
      try {
        final debugUrl =
            'https://us-central1-my-qna-hub.cloudfunctions.net/debugCheckoutHttp';
        final response = await Dio().get(debugUrl);
        // ignore: avoid_print
        print('debugCheckoutHttp: ${response.data}');
      } catch (e) {
        // ignore: avoid_print
        print('debugCheckoutHttp failed: $e');
      }
      final callable = _functions.httpsCallable('createCheckoutSession');
      final result = await callable.call({
        'priceId': priceId,
        'successUrl': successUrl,
        'cancelUrl': cancelUrl,
      });
      return (result.data as Map)['url'] as String;
    } on FirebaseFunctionsException catch (e) {
      final detail = e.message ??
          (e.details is Map ? jsonEncode(e.details) : e.details?.toString()) ??
          e.code;
      final message = detail.isNotEmpty ? detail : 'Checkout failed';
      if (e.code != 'internal') {
        throw Exception('Functions error: code=${e.code} message=$message');
      }
      // Fallback to HTTP endpoint if callable fails in web.
      final token = await _auth.currentUser?.getIdToken();
      if (token == null) {
        throw Exception('Authentication required');
      }
      final response = await Dio().post(
        'https://us-central1-my-qna-hub.cloudfunctions.net/createCheckoutHttp',
        data: {
          'priceId': priceId,
          'successUrl': successUrl,
          'cancelUrl': cancelUrl,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      final url = (response.data as Map)['url'] as String?;
      if (url == null) {
        throw Exception('Checkout failed');
      }
      return url;
    }
  }

  Future<void> openCustomerPortal(String returnUrl) async {
    try {
      final callable = _functions.httpsCallable('createCustomerPortalSession');
      await callable.call({'returnUrl': returnUrl});
    } on FirebaseFunctionsException catch (e) {
      final detail = e.message ?? e.code;
      throw Exception(detail.isNotEmpty ? detail : 'Portal unavailable');
    }
  }

  Future<Map<String, dynamic>> confirmCheckout(String sessionId) async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw Exception('Authentication required');
    }
    final response = await Dio().post(
      'https://us-central1-my-qna-hub.cloudfunctions.net/confirmCheckoutHttp',
      data: {'sessionId': sessionId},
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        validateStatus: (_) => true,
      ),
    );
    if (response.statusCode != null && response.statusCode! >= 400) {
      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : {'error': response.data.toString()};
      throw Exception('Confirm failed: ${jsonEncode(data)}');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }
}
