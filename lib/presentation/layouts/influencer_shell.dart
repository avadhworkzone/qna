import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_state.dart';
import '../widgets/glass_card.dart';

class InfluencerShell extends StatelessWidget {
  const InfluencerShell({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    const sidebarWidth = 280.0;
    return Scaffold(
      drawer: Drawer(
        child: _SidebarContent(onClose: () => Navigator.of(context).pop()),
      ),
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B1021),
              Color(0xFF0F1B33),
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 980;
            return Row(
              children: [
                if (isDesktop)
                  SizedBox(
                    width: sidebarWidth,
                    child: _SidebarContent(onClose: null),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: body,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  const _SidebarContent({required this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B1021),
            Color(0xFF161B2C),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage:
                        user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                    child:
                        user?.photoUrl == null ? const Icon(Icons.person, size: 28) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Influencer',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (onClose != null)
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                if (onClose != null) onClose!();
                context.go('/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Create Session'),
              onTap: () {
                if (onClose != null) onClose!();
                context.go('/session/create');
              },
            ),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Billing'),
              onTap: () {
                if (onClose != null) onClose!();
                context.go('/billing');
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GlassCard(
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Premium insights unlock as your audience grows.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () => context.read<AuthCubit>().signOut(),
            ),
          ],
        ),
      ),
    );
  }
}
