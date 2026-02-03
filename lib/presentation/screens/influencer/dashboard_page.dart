import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/user.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/sessions/sessions_cubit.dart';
import '../../bloc/sessions/sessions_state.dart';
import '../../layouts/influencer_shell.dart';
import '../../widgets/glass_card.dart';

class InfluencerDashboardPage extends StatefulWidget {
  const InfluencerDashboardPage({super.key});

  @override
  State<InfluencerDashboardPage> createState() => _InfluencerDashboardPageState();
}

class _InfluencerDashboardPageState extends State<InfluencerDashboardPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authState = context.read<AuthCubit>().state;
    if (authState.user != null) {
      context.read<SessionsCubit>().watchSessions(authState.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InfluencerShell(
      title: 'Influencer Dashboard',
      actions: [
        IconButton(
          onPressed: () => context.go('/billing'),
          icon: const Icon(Icons.credit_card),
        ),
        IconButton(
          onPressed: () => context.read<AuthCubit>().signOut(),
          icon: const Icon(Icons.logout),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/session/create'),
        label: const Text('Create Session'),
        icon: const Icon(Icons.add),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final user = authState.user;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (user.role != UserRole.influencer) {
            return Center(
              child: Text(
                'Audience users should access sessions via public links.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DashboardHeader(user: user),
              const SizedBox(height: 20),
              BlocBuilder<SessionsCubit, SessionsState>(
                builder: (context, sessionState) {
                  final activeCount = sessionState.sessions.where((s) => s.isActive).length;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _MetricCard(
                        label: 'Session Credits',
                        value: user.sessionCredits.toString(),
                        icon: Icons.bolt,
                      ),
                      _MetricCard(
                        label: 'Active Sessions',
                        value: activeCount.toString(),
                        icon: Icons.wifi_tethering,
                      ),
                      const _MetricCard(
                        label: 'Questions Today',
                        value: '0',
                        icon: Icons.question_answer,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Text('Your Sessions', style: Theme.of(context).textTheme.headlineMedium),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => context.go('/sessions'),
                    icon: const Icon(Icons.list),
                    label: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: BlocBuilder<SessionsCubit, SessionsState>(
                  builder: (context, state) {
                    if (state.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.sessions.isEmpty) {
                      return Center(
                        child: GlassCard(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'No sessions yet. Create your first Q&A.',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: state.sessions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final session = state.sessions[index];
                        return GlassCard(
                          child: ListTile(
                            title: Text(session.title),
                            subtitle: Text(session.description),
                            trailing: Icon(
                              session.isActive ? Icons.check_circle : Icons.stop_circle,
                              color: session.isActive
                                  ? AppTheme.successColor
                                  : AppTheme.warningColor,
                            ),
                            onTap: () => context.go('/session/${session.id}'),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage:
              user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
          child: user.photoUrl == null ? const Icon(Icons.person, size: 28) : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back', style: Theme.of(context).textTheme.bodySmall),
            Text(
              user.name,
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ],
        ),
        const Spacer(),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: const [
              Icon(Icons.auto_graph),
              SizedBox(width: 8),
              Text('Engagement Index +12%'),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 26),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ],
      ),
    );
  }
}
