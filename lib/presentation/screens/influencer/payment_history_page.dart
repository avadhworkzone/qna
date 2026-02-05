import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/di/service_locator.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../widgets/glass_card.dart';

class PaymentHistoryPage extends StatelessWidget {
  const PaymentHistoryPage({super.key});

  String _formatDateTime(DateTime value) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = months[local.month - 1];
    final year = local.year.toString();
    var hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final isPm = hour >= 12;
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final amPm = isPm ? 'PM' : 'AM';
    return '$day/$month/$year  $hour:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final firestore = sl<FirebaseFirestore>();
    final user = context.watch<AuthCubit>().state.user;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment History', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: firestore
                .collection(FirestorePaths.payments)
                .where('userId', isEqualTo: user.id)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Unable to load payments. ${snapshot.error}',
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text('No payments yet.'));
              }
              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final amount = (data['amount'] as num?)?.toDouble() ?? 0;
                  final plan = data['planName']?.toString() ?? 'Plan';
                  final credits = (data['creditsAdded'] as num?)?.toInt() ?? 0;
                  final status = data['status']?.toString() ?? 'paid';
                  final currency = data['currency']?.toString().toUpperCase() ?? 'USD';
                  final paymentIntentId = data['paymentIntentId']?.toString();
                  final sessionId = data['checkoutSessionId']?.toString();
                  final createdAt = DateTime.fromMillisecondsSinceEpoch(
                    (data['createdAt'] as num?)?.toInt() ?? 0,
                  );
                  return GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PlanBadge(plan: plan),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '$plan • ${currency == 'USD' ? '\$' : ''}${amount.toStringAsFixed(0)} $currency',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(width: 12),
                                    _StatusPill(status: status),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Credits +$credits',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDateTime(createdAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 10),
                                _PaymentMeta(
                                  paymentIntentId: paymentIntentId,
                                  sessionId: sessionId,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isPaid = status.toLowerCase() == 'paid' || status.toLowerCase() == 'succeeded';
    final color = isPaid ? Colors.greenAccent : Colors.orangeAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.plan});

  final String plan;

  @override
  Widget build(BuildContext context) {
    final color = plan.toLowerCase() == 'pro'
        ? const Color(0xFF38BDF8)
        : plan.toLowerCase() == 'growth'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF22C55E);
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color.withOpacity(0.9), color.withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          plan.substring(0, 1).toUpperCase(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _PaymentMeta extends StatelessWidget {
  const _PaymentMeta({
    required this.paymentIntentId,
    required this.sessionId,
  });

  final String? paymentIntentId;
  final String? sessionId;

  @override
  Widget build(BuildContext context) {
    final meta = paymentIntentId ?? sessionId;
    if (meta == null || meta.isEmpty) {
      return const SizedBox.shrink();
    }
    return InkWell(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: meta));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction ID copied.')),
          );
        }
      },
      child: SizedBox(
        width: 180,
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Txn: $meta',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.copy, size: 14),
          ],
        ),
      ),
    );
  }
}
