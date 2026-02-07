import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/web_redirect.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/billing/billing_cubit.dart';
import '../../bloc/billing/billing_state.dart';
import '../../widgets/glass_card.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/usecases/billing/start_subscription_checkout.dart';

class BillingPage extends StatelessWidget {
  const BillingPage({super.key});

  static String? _lastHandledSessionId;

  String _planDescription(String key) {
    switch (key) {
      case 'growth':
        return 'Best for weekly Q&A sessions and small launches.';
      case 'pro':
        return 'Designed for creators running frequent sessions.';
      case 'starter':
      default:
        return 'Perfect for a single Q&A or one-off launch.';
    }
  }

  String _planHighlight(String key) {
    switch (key) {
      case 'growth':
        return 'Most popular';
      case 'pro':
        return 'Best value';
      case 'starter':
      default:
        return 'Try it once';
    }
  }

  List<Color> _planGradient(String key) {
    switch (key) {
      case 'growth':
        return const [Color(0xFFF59E0B), Color(0xFFFCD34D)];
      case 'pro':
        return const [Color(0xFF38BDF8), Color(0xFF22D3EE)];
      case 'starter':
      default:
        return const [Color(0xFF22C55E), Color(0xFF86EFAC)];
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      final params = Uri.base.queryParameters;
      final status = params['status'];
      final sessionId = params['session_id'];
      if (status == 'success' &&
          (sessionId == null || sessionId != _lastHandledSessionId)) {
        _lastHandledSessionId = sessionId;
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment received. Updating credits...')),
        );
        if (sessionId != null && sessionId.isNotEmpty) {
          try {
            final result = await sl<ConfirmCheckout>().call(sessionId: sessionId);
            final ok = result['ok'] == true;
            final added = result['creditsAdded'];
            final plan = result['plan'];
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ok
                    ? 'Credits updated: +$added ($plan).'
                    : 'Payment received, but credits are pending.'),
              ),
            );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Credit update failed: $e')),
            );
          }
        }
        if (!context.mounted) return;
        await context.read<AuthCubit>().refreshProfile();
        if (!context.mounted) return;
        context.go('/billing');
      } else if (status == 'cancel') {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment cancelled.')),
        );
        if (!context.mounted) return;
        context.go('/billing');
      }
    });

    final user = context.watch<AuthCubit>().state.user;
    final credits = user?.sessionCredits ?? 0;
    final freeCreditsRemaining = user?.freeCreditsRemaining ?? 0;
    final hasFreeCredits = freeCreditsRemaining > 0;

    return BlocListener<BillingCubit, BillingState>(
        listener: (context, state) async {
          if (state.checkoutUrl != null) {
            if (kIsWeb) {
              WebRedirect.go(state.checkoutUrl!);
            } else {
              final url = Uri.parse(state.checkoutUrl!);
              final launched =
                  await launchUrl(url, mode: LaunchMode.externalApplication);
              if (!launched) {
                WebRedirect.go(state.checkoutUrl!);
              }
            }
          } else if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Billing', style: Theme.of(context).textTheme.displaySmall),
                    const SizedBox(height: 6),
                    Text(
                      'Buy session credits and manage purchases.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Credits',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              credits.toString(),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            if (hasFreeCredits) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.teal.withOpacity(0.35),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.card_giftcard, size: 14),
                                    const SizedBox(width: 6),
                                    Text('$freeCreditsRemaining free'),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width > 1200 ? 3 : width > 860 ? 2 : 1;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.6,
                  children: AppConstants.subscriptionPlans.entries.map((entry) {
                    final plan = entry.value;
                    final planKey = entry.key;
                    final description = _planDescription(planKey);
                    final highlight = _planHighlight(planKey);
                    return BlocBuilder<BillingCubit, BillingState>(
                      builder: (context, billingState) {
                        final isLoading = billingState.isLoading;
                        return GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: LinearGradient(
                                    colors: _planGradient(planKey),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(plan['name'],
                                      style: Theme.of(context).textTheme.titleMedium),
                                  Text(
                                    '\$${plan['price']}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('${plan['sessions']} sessions',
                                  style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 6),
                              Text(
                                description,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  highlight,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: 140,
                                child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () {
                              final origin = Uri.base.origin;
                              debugPrint(
                                'Subscribe clicked: priceId=${plan['priceId']} origin=$origin',
                              );
                              context.read<BillingCubit>().startCheckout(
                                    priceId: plan['priceId'],
                                    successUrl: '$origin/billing?status=success',
                                    cancelUrl: '$origin/billing?status=cancel',
                                  );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Buy Credits'),
                          ),
                          ),
                        ],
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
