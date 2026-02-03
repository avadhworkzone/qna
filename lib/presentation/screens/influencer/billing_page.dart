import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../bloc/billing/billing_cubit.dart';
import '../../bloc/billing/billing_state.dart';
import '../../layouts/influencer_shell.dart';
import '../../widgets/glass_card.dart';

class BillingPage extends StatelessWidget {
  const BillingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return InfluencerShell(
      title: 'Subscription Plans',
      body: BlocListener<BillingCubit, BillingState>(
        listener: (context, state) async {
          if (state.checkoutUrl != null) {
            await launchUrl(Uri.parse(state.checkoutUrl!));
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose your plan', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width > 1000 ? 3 : width > 700 ? 2 : 1;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: AppConstants.subscriptionPlans.entries.map((entry) {
                      final plan = entry.value;
                      return GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(plan['name'], style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 8),
                            Text('\$${plan['price']} / month'),
                            const SizedBox(height: 8),
                            Text('${plan['sessions']} sessions per month'),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () {
                                context.read<BillingCubit>().startCheckout(
                                      priceId: plan['priceId'],
                                      successUrl: 'https://yourdomain.com/success',
                                      cancelUrl: 'https://yourdomain.com/cancel',
                                    );
                              },
                              child: const Text('Subscribe'),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
