import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
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

const getStripe = () => {
  const key = stripeSecret.value();
  if (!key) {
    throw new HttpsError(
      'failed-precondition',
      'Stripe secret missing. Set STRIPE_SECRET_KEY.',
    );
  }
  return new Stripe(key, {
    apiVersion: '2024-06-20',
  });
};

const getPriceMap = (): Record<string, { plan: string; sessions: number; amount: number }> => ({
  [priceStarter.value() || '']: { plan: 'starter', sessions: 1, amount: 9 },
  [priceGrowth.value() || '']: { plan: 'growth', sessions: 5, amount: 49 },
  [pricePro.value() || '']: { plan: 'pro', sessions: 10, amount: 99 },
});

export const createCheckoutSession = onCall(
  {
    invoker: 'public',
    secrets: [stripeSecret, priceStarter, priceGrowth, pricePro],
  },
  async (request) => {
  try {
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

    const stripe = getStripe();
    const PRICE_TO_PLAN = getPriceMap();
    if (!priceStarter.value() || !priceGrowth.value() || !pricePro.value()) {
      throw new HttpsError(
        'failed-precondition',
        'Stripe price secrets missing. Set STRIPE_PRICE_STARTER/GROWTH/PRO.',
      );
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

    const plan = PRICE_TO_PLAN[priceId];
    if (!plan) {
      throw new HttpsError('invalid-argument', 'Unknown price');
    }

    const price = await stripe.prices.retrieve(priceId);
    if (price.recurring) {
      throw new HttpsError(
        'failed-precondition',
        'Price must be one-time (non-recurring). Update the price in Stripe.',
      );
    }

    const successWithSessionId =
      successUrl.includes('?')
        ? `${successUrl}&session_id={CHECKOUT_SESSION_ID}`
        : `${successUrl}?session_id={CHECKOUT_SESSION_ID}`;

    const session = await stripe.checkout.sessions.create({
      mode: 'payment',
      customer: customerId,
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: successWithSessionId,
      cancel_url: cancelUrl,
      metadata: {
        firebaseUid: request.auth.uid,
        priceId,
        plan: plan.plan,
        sessions: String(plan.sessions),
      },
    });

    return { url: session.url };
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    const message =
      err instanceof Error ? err.message : `Unknown error: ${String(err)}`;
    console.error('createCheckoutSession_error', message, err);
    throw new HttpsError('internal', 'Stripe error', { message });
  }
});

export const debugCheckout = onCall(
  {
    invoker: 'public',
    secrets: [stripeSecret, priceStarter, priceGrowth, pricePro],
  },
  (request) => {
    return {
      auth: !!request.auth,
      uid: request.auth?.uid ?? null,
      stripeSecret: !!stripeSecret.value(),
      priceStarter: !!priceStarter.value(),
      priceGrowth: !!priceGrowth.value(),
      pricePro: !!pricePro.value(),
      projectId: process.env.GCLOUD_PROJECT ?? null,
    };
  },
);

export const debugCheckoutHttp = onRequest(
  {
    invoker: 'public',
    secrets: [stripeSecret, priceStarter, priceGrowth, pricePro],
  },
  (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    try {
      res.json({
        stripeSecret: !!stripeSecret.value(),
        priceStarter: !!priceStarter.value(),
        priceGrowth: !!priceGrowth.value(),
        pricePro: !!pricePro.value(),
        projectId: process.env.GCLOUD_PROJECT ?? null,
      });
    } catch (err) {
      res.status(500).json({
        error: 'debugCheckoutHttp_failed',
        message: err instanceof Error ? err.message : String(err),
      });
    }
  },
);

export const createCheckoutHttp = onRequest(
  {
    invoker: 'public',
    secrets: [stripeSecret, priceStarter, priceGrowth, pricePro],
  },
  async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    try {
      const authHeader = req.headers.authorization || '';
      const token = authHeader.startsWith('Bearer ')
        ? authHeader.substring('Bearer '.length)
        : '';
      if (!token) {
        res.status(401).json({ error: 'unauthenticated' });
        return;
      }
      const decoded = await getAuth().verifyIdToken(token);
      const uid = decoded.uid;

      const body =
        typeof req.body === 'string' ? JSON.parse(req.body) : (req.body ?? {});
      const { priceId, successUrl, cancelUrl } = body as {
        priceId?: string;
        successUrl?: string;
        cancelUrl?: string;
      };
      if (!priceId || !successUrl || !cancelUrl) {
        res.status(400).json({ error: 'missing_params' });
        return;
      }

      const stripe = getStripe();
      const PRICE_TO_PLAN = getPriceMap();
      if (!priceStarter.value() || !priceGrowth.value() || !pricePro.value()) {
        res.status(500).json({ error: 'missing_price_secrets' });
        return;
      }

      const userRef = db.collection('users').doc(uid);
      const userSnap = await userRef.get();
      const userData = userSnap.data() || {};
      let customerId = userData.stripeCustomerId as string | undefined;
      if (!customerId) {
        const customer = await stripe.customers.create({
          email: userData.email || decoded.email,
          metadata: { firebaseUid: uid },
        });
        customerId = customer.id;
        await userRef.set({ stripeCustomerId: customerId }, { merge: true });
      }

      const plan = PRICE_TO_PLAN[priceId];
      if (!plan) {
        res.status(400).json({ error: 'unknown_price' });
        return;
      }

      const price = await stripe.prices.retrieve(priceId);
      if (price.recurring) {
        res.status(400).json({ error: 'price_recurring' });
        return;
      }

      const successWithSessionId =
        successUrl.includes('?')
          ? `${successUrl}&session_id={CHECKOUT_SESSION_ID}`
          : `${successUrl}?session_id={CHECKOUT_SESSION_ID}`;

      const session = await stripe.checkout.sessions.create({
        mode: 'payment',
        customer: customerId,
        line_items: [{ price: priceId, quantity: 1 }],
        success_url: successWithSessionId,
        cancel_url: cancelUrl,
        metadata: {
          firebaseUid: uid,
          priceId,
          plan: plan.plan,
          sessions: String(plan.sessions),
        },
      });

      res.json({ url: session.url });
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      res.status(500).json({ error: 'stripe_error', message });
    }
  },
);

export const debugCreateCheckoutHttp = onRequest(
  {
    invoker: 'public',
    secrets: [stripeSecret, priceStarter, priceGrowth, pricePro],
  },
  async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    try {
      const stripe = getStripe();
      const priceId = priceStarter.value() || '';
      if (!priceId) {
        res.status(400).json({ error: 'missing_price' });
        return;
      }
      const price = await stripe.prices.retrieve(priceId);
      const session = await stripe.checkout.sessions.create({
        mode: 'payment',
        line_items: [{ price: priceId, quantity: 1 }],
        success_url: 'https://my-qna-hub.web.app/billing?status=success',
        cancel_url: 'https://my-qna-hub.web.app/billing?status=cancel',
      });
      res.json({
        price: {
          id: price.id,
          type: price.type,
          recurring: !!price.recurring,
          active: price.active,
          currency: price.currency,
        },
        sessionUrl: session.url,
      });
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      res.status(500).json({ error: 'stripe_error', message });
    }
  },
);

export const confirmCheckoutHttp = onRequest(
  {
    invoker: 'public',
    secrets: [stripeSecret, priceStarter, priceGrowth, pricePro],
  },
  async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    try {
      const authHeader = req.headers.authorization || '';
      const token = authHeader.startsWith('Bearer ')
        ? authHeader.substring('Bearer '.length)
        : '';
      if (!token) {
        res.status(401).json({ error: 'unauthenticated' });
        return;
      }
      const decoded = await getAuth().verifyIdToken(token);
      const uid = decoded.uid;
      const body =
        typeof req.body === 'string' ? JSON.parse(req.body) : (req.body ?? {});
      const sessionId = (body?.sessionId as string | undefined) || '';
      if (!sessionId) {
        res.status(400).json({ error: 'missing_session_id' });
        return;
      }

      const stripe = getStripe();
      const session = await stripe.checkout.sessions.retrieve(sessionId);
      if (session.payment_status !== 'paid') {
        res.status(400).json({ error: 'not_paid', status: session.payment_status });
        return;
      }
      const priceId = session.metadata?.priceId || '';
      const firebaseUid = session.metadata?.firebaseUid;
      if (firebaseUid !== uid) {
        res.status(403).json({ error: 'uid_mismatch' });
        return;
      }

      const PRICE_TO_PLAN = getPriceMap();
      const plan = PRICE_TO_PLAN[priceId];
      if (!plan) {
        res.status(400).json({ error: 'unknown_price' });
        return;
      }

      await db.runTransaction(async (tx) => {
        const userRef = db.collection('users').doc(uid);
        const userSnap = await tx.get(userRef);
        const paymentRef = db.collection('payments').doc(session.id);
        const paymentSnap = await tx.get(paymentRef);
        if (paymentSnap.exists) return;
        const credits = (userSnap.data()?.sessionCredits as number | undefined) || 0;
        tx.set(
          userRef,
          {
            subscriptionPlan: plan.plan,
            sessionCredits: credits + plan.sessions,
          },
          { merge: true },
        );
        tx.set(paymentRef, {
          userId: uid,
          priceId,
          planName: plan.plan,
          creditsAdded: plan.sessions,
          amount: session.amount_total ? session.amount_total / 100 : plan.amount,
          currency: session.currency ?? 'usd',
          status: session.payment_status ?? 'paid',
          checkoutSessionId: session.id,
          paymentIntentId:
            typeof session.payment_intent === 'string'
              ? session.payment_intent
              : session.payment_intent?.id ?? null,
          customerId: session.customer?.toString() ?? null,
          createdAt: Date.now(),
        });
      });

      res.json({
        ok: true,
        plan: plan.plan,
        creditsAdded: plan.sessions,
        priceId,
      });
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      res.status(500).json({ error: 'confirm_failed', message });
    }
  },
);

export const createCustomerPortalSession = onCall(
  {
    invoker: 'public',
    secrets: [stripeSecret],
  },
  async (request) => {
  const stripe = getStripe();
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
  const stripe = getStripe();
  const PRICE_TO_PLAN = getPriceMap();

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

  switch (event.type) {
    case 'checkout.session.completed': {
      const session = event.data.object as Stripe.Checkout.Session;
      const firebaseUid = session.metadata?.firebaseUid;
      const priceId = session.metadata?.priceId || '';
      const plan = PRICE_TO_PLAN[priceId];
      if (!firebaseUid || !plan) break;

      await db.runTransaction(async (tx) => {
        const userRef = db.collection('users').doc(firebaseUid);
        const userSnap = await tx.get(userRef);
        const credits = (userSnap.data()?.sessionCredits as number | undefined) || 0;
        tx.set(
          userRef,
          {
            subscriptionPlan: plan.plan,
            sessionCredits: credits + plan.sessions,
          },
          { merge: true },
        );
        const paymentRef = db.collection('payments').doc(session.id);
        tx.set(paymentRef, {
          userId: firebaseUid,
          priceId,
          planName: plan.plan,
          creditsAdded: plan.sessions,
          amount: session.amount_total ? session.amount_total / 100 : plan.amount,
          currency: session.currency ?? 'usd',
          status: session.payment_status ?? 'paid',
          checkoutSessionId: session.id,
          paymentIntentId:
            typeof session.payment_intent === 'string'
              ? session.payment_intent
              : session.payment_intent?.id ?? null,
          customerId: session.customer?.toString() ?? null,
          createdAt: Date.now(),
        });
      });
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
