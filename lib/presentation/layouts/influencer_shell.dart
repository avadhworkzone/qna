import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_state.dart';
import '../widgets/glass_card.dart';

class InfluencerShell extends StatefulWidget {
  const InfluencerShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<InfluencerShell> createState() => _InfluencerShellState();
}

class _InfluencerShellState extends State<InfluencerShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String _titleForLocation(String location) {
    if (location.startsWith('/session/create')) return 'Create Session';
    if (location.startsWith('/session/')) return 'Session Details';
    if (location.startsWith('/sessions')) return 'All Sessions';
    if (location.startsWith('/question/')) return 'Question Details';
    if (location.startsWith('/billing')) return 'Subscription Plans';
    return 'Influencer Dashboard';
  }

  @override
  Widget build(BuildContext context) {
    const sidebarWidth = 280.0;
    final isDesktop = MediaQuery.of(context).size.width >= 980;
    final location = GoRouterState.of(context).uri.toString();
    final title = _titleForLocation(location);
    return Scaffold(
      key: _scaffoldKey,
      drawer: isDesktop
          ? null
          : Drawer(
              child: _SidebarContent(onClose: () => Navigator.of(context).pop()),
            ),
      appBar: AppBar(
        title: Text(title),
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
        leading: isDesktop
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                    Navigator.of(context).pop();
                  } else {
                    _scaffoldKey.currentState?.openDrawer();
                  }
          },
        ),
      ),
      floatingActionButton: location == '/dashboard'
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/session/create'),
              label: const Text('Create Session'),
              icon: const Icon(Icons.add),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.light
                ? [
                    const Color(0xFFF7F8FB),
                    const Color(0xFFEFF2F8),
                  ]
                : [
                    const Color(0xFF0B1021),
                    const Color(0xFF0F1B33),
                  ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
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
                    child: KeyedSubtree(
                      key: ValueKey(location),
                      child: widget.child,
                    ),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.light
              ? [
                  const Color(0xFFFFFFFF),
                  const Color(0xFFF2F5FA),
                ]
              : [
                  const Color(0xFF0B1021),
                  const Color(0xFF161B2C),
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
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text('Deleted Sessions'),
              onTap: () {
                if (onClose != null) onClose!();
                context.go('/deleted-sessions');
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
