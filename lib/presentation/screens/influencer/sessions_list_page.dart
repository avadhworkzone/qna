import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../bloc/sessions/sessions_cubit.dart';
import '../../bloc/sessions/sessions_state.dart';
import '../../layouts/influencer_shell.dart';
import '../../widgets/glass_card.dart';

class SessionsListPage extends StatefulWidget {
  const SessionsListPage({super.key});

  @override
  State<SessionsListPage> createState() => _SessionsListPageState();
}

class _SessionsListPageState extends State<SessionsListPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InfluencerShell(
      title: 'All Sessions',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search sessions',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BlocBuilder<SessionsCubit, SessionsState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final query = _searchController.text.trim().toLowerCase();
                final sessions = state.sessions.where((session) {
                  if (query.isEmpty) return true;
                  return session.title.toLowerCase().contains(query) ||
                      session.description.toLowerCase().contains(query);
                }).toList();
                if (sessions.isEmpty) {
                  return const Center(child: Text('No sessions found.'));
                }
                return ListView.separated(
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
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
      ),
    );
  }
}
