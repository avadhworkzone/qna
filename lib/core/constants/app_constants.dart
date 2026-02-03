class AppConstants {
  // App Info
  static const String appName = 'QA SaaS Platform';
  static const String appVersion = '1.0.0';
  static const String publicBaseUrl = 'https://my-qna-hub.web.app/public';
  
  // Stripe Keys (Publishable only; secret must stay on server)
  static const String stripePublishableKey =
      'pk_test_51SwdX1DMxTH0lAxACaRoc07iviW64pO1nMya5djOFzEy5QoEoaSVXO7PbL11JsCNmglYRpVAkcfx8HMyAYNFmo6b00K8M5DxWs';
  
  // Subscription Plans
  static const Map<String, Map<String, dynamic>> subscriptionPlans = {
    'starter': {
      'name': 'Starter',
      'price': 19,
      'sessions': 1,
      'priceId': 'price_starter_plan_id',
    },
    'growth': {
      'name': 'Growth', 
      'price': 89,
      'sessions': 5,
      'priceId': 'price_growth_plan_id',
    },
    'pro': {
      'name': 'Pro',
      'price': 169,
      'sessions': 10,
      'priceId': 'price_pro_plan_id',
    },
  };
  
  // Session Types
  static const List<String> sessionTypes = [
    'Question Box',
    'Poll',
    'Mixed Mode',
  ];
  
  // Question Ranking Weights
  static const double repeatCountWeight = 0.4;
  static const double likesWeight = 0.3;
  static const double recentActivityWeight = 0.2;
  static const double priorityTagWeight = 0.1;
  
  // Rate Limiting
  static const int maxQuestionsPerMinute = 5;
  static const int maxPollVotesPerSession = 1;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double cardElevation = 4.0;
}
