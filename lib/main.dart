import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/foundation.dart';
import 'package:url_strategy/url_strategy.dart';
import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kIsWeb) {
    setPathUrlStrategy();
  }

  await setupServiceLocator();
  
  if (!kIsWeb) {
    Stripe.publishableKey = AppConstants.stripePublishableKey;
  }
  
  runApp(const QASaaSApp());
}
