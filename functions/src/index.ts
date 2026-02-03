import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { onCall, onRequest, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import Stripe from 'stripe';

initializeApp();

const db = getFirestore();
const stripeSecret = defineSecret('STRIPE_SECRET_KEY');
const webhookSecret = defineSecret('STRIPE_WEBHOOK_SECRET');
const priceStarter = defineSecret('STRIPE_PRICE_STARTER');
const priceGrowth = defineSecret('STRIPE_PRICE_GROWTH');
const pricePro = defineSecret('STRIPE_PRICE_PRO');

const stripe = new Stripe(stripeSecret.value() || '', {
  apiVersion: '2024-06-20',
});

const PRICE_TO_PLAN: Record<string, { plan: string; sessions: number }> = {
  [priceStarter.value() || '']: { plan: 'starter', sessions: 1 },
  [priceGrowth.value() || '']: { plan: 'growth', sessions: 5 },
  [pricePro.value() || '']: { plan: 'pro', sessions: 10 },
};

export const createCheckoutSession = onCall(
  {
    secrets: [stripeSecret, priceStarter, priceGrowth, pricePro],
  },
  async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Authentication required');
  }
  const { priceId, successUrl, cancelUrl } = request.data as {
    priceId: string;
    successUrl: string;
    cancelUrl: string;
  };
  if (!priceId || !successUrl || !cancelUrl) {
    throw new HttpsError('invalid-argument', 'Missing required parameters');
  }

  const userRef = db.collection('users').doc(request.auth.uid);
  const userSnap = await userRef.get();
  const userData = userSnap.data() || {};
  let customerId = userData.stripeCustomerId as string | undefined;

  if (!customerId) {
    const customer = await stripe.customers.create({
      email: userData.email || request.auth.token.email,
      metadata: { firebaseUid: request.auth.uid },
    });
    customerId = customer.id;
    await userRef.set({ stripeCustomerId: customerId }, { merge: true });
  }

  const session = await stripe.checkout.sessions.create({
    mode: 'subscription',
    customer: customerId,
    line_items: [{ price: priceId, quantity: 1 }],
    success_url: successUrl,
    cancel_url: cancelUrl,
    subscription_data: {
      metadata: { firebaseUid: request.auth.uid },
    },
  });

  return { url: session.url };
});

export const createCustomerPortalSession = onCall(
  {
    secrets: [stripeSecret],
  },
  async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Authentication required');
  }
  const { returnUrl } = request.data as { returnUrl: string };
  const userSnap = await db.collection('users').doc(request.auth.uid).get();
  const customerId = userSnap.data()?.stripeCustomerId;
  if (!customerId) {
    throw new HttpsError('failed-precondition', 'No Stripe customer');
  }
  const portal = await stripe.billingPortal.sessions.create({
    customer: customerId,
    return_url: returnUrl,
  });
  return { url: portal.url };
});

export const stripeWebhook = onRequest(
  {
    secrets: [stripeSecret, webhookSecret, priceStarter, priceGrowth, pricePro],
  },
  async (req, res) => {
  const signature = req.headers['stripe-signature'];
  if (!signature) {
    res.status(400).send('Missing signature');
    return;
  }
  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(
      req.rawBody,
      signature,
      webhookSecret.value() || '',
    );
  } catch (err) {
    res.status(400).send(`Webhook Error: ${(err as Error).message}`);
    return;
  }

  const handleSubscription = async (subscription: Stripe.Subscription) => {
    const firebaseUid = subscription.metadata.firebaseUid;
    if (!firebaseUid) return;
    const priceId = subscription.items.data[0]?.price.id || '';
    const plan = PRICE_TO_PLAN[priceId];
    await db.collection('users').doc(firebaseUid).set(
      {
        subscriptionPlan: plan?.plan || 'unknown',
        sessionCredits: plan?.sessions || 0,
      },
      { merge: true },
    );
  };

  switch (event.type) {
    case 'checkout.session.completed': {
      const session = event.data.object as Stripe.Checkout.Session;
      if (session.subscription) {
        const subscription = await stripe.subscriptions.retrieve(
          session.subscription as string,
        );
        await handleSubscription(subscription);
      }
      break;
    }
    case 'customer.subscription.updated':
    case 'customer.subscription.created': {
      const subscription = event.data.object as Stripe.Subscription;
      await handleSubscription(subscription);
      break;
    }
    case 'customer.subscription.deleted': {
      const subscription = event.data.object as Stripe.Subscription;
      const firebaseUid = subscription.metadata.firebaseUid;
      if (firebaseUid) {
        await db.collection('users').doc(firebaseUid).set(
          {
            subscriptionPlan: 'canceled',
            sessionCredits: 0,
          },
          { merge: true },
        );
      }
      break;
    }
    default:
      break;
  }

  res.json({ received: true });
});

export const onQuestionCreated = onDocumentCreated(
  'questions/{questionId}',
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    const question = snapshot.data();
    const sessionId = question.sessionId as string;
    if (!sessionId) return;
    await db.collection('sessions').doc(sessionId).set(
      {
        totalQuestions: FieldValue.increment(1),
      },
      { merge: true },
    );
  },
);
