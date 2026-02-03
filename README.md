# QA SaaS Platform

Production-ready SaaS platform for influencer-driven Q&A sessions with public links, polling, analytics, and subscription billing.

## Highlights
- Flutter (web-first, mobile-ready) with Clean Architecture + BLoC
- Firebase Auth, Firestore, Functions, Storage, Analytics
- Stripe subscriptions with webhook-based credit tracking
- Real-time questions, poll results, and engagement metrics

## Project Structure
```
lib/
  core/
    constants/
    di/
    extensions/
    theme/
  data/
    datasources/
    models/
    repositories/
  domain/
    entities/
    repositories/
    services/
    usecases/
  presentation/
    bloc/
    routes/
    screens/
    widgets/
functions/
  src/
```

## Firebase Setup Guide
1. Install Firebase CLI and login.
2. Create a Firebase project and enable:
   - Authentication (Google + Apple)
   - Firestore
   - Storage
   - Functions
   - Analytics
3. Run FlutterFire to generate `lib/firebase_options.dart`.
4. Deploy Firestore rules and indexes:
```
firebase deploy --only firestore
```
5. Deploy storage rules:
```
firebase deploy --only storage
```

## Stripe Setup
1. Create products and monthly prices in Stripe.
2. Set Firebase Functions secrets (v2):
```
firebase functions:secrets:set STRIPE_SECRET_KEY
firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
firebase functions:secrets:set STRIPE_PRICE_STARTER
firebase functions:secrets:set STRIPE_PRICE_GROWTH
firebase functions:secrets:set STRIPE_PRICE_PRO
```
3. Update `AppConstants.subscriptionPlans` with price IDs.
4. Deploy functions:
```
firebase deploy --only functions
```

## Firestore Schema
```
users/{id}
  name, email, role, subscriptionPlan, sessionCredits, createdAt, lastLoginAt

sessions/{id}
  influencerId, title, description, type, publicLink, createdAt, expiryTime,
  status, isAnonymous, totalQuestions, totalParticipants, pollOptions

questions/{id}
  sessionId, userId, questionText, duplicateGroupId, likeCount, repeatCount,
  rankingScore, createdAt, isPriority, isAnswered, answer

pollResponses/{sessionId_userId}
  sessionId, userId, selectedOption, createdAt
```

## Cloud Functions
- `createCheckoutSession` (callable): creates Stripe checkout
- `createCustomerPortalSession` (callable): opens Stripe billing portal
- `stripeWebhook` (HTTP): handles subscription lifecycle
- `onQuestionCreated`: increments session counters

## Security Rules Summary
- Influencers can access and manage their own sessions
- Users can submit questions/votes only to active sessions
- Poll votes are enforced by deterministic document IDs

## Deployment Guide
1. Build Flutter web:
```
flutter build web
```
2. Deploy hosting (optional):
```
firebase deploy --only hosting
```
3. Deploy Firestore + Functions + Storage as needed.

## Notes
- Replace placeholder Stripe publishable key in `lib/core/constants/app_constants.dart`.
- Set success/cancel URLs in `BillingPage` to your domain.
