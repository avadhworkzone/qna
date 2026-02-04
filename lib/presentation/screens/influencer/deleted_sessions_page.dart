import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../bloc/sessions/sessions_cubit.dart';
import '../../bloc/sessions/sessions_state.dart';
import '../../widgets/glass_card.dart';

class DeletedSessionsPage extends StatelessWidget {
  const DeletedSessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Deleted Sessions', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Expanded(
          child: BlocBuilder<SessionsCubit, SessionsState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              final deleted = state.sessions
                  .where((session) => session.deletedAt != null)
                  .toList();
              if (deleted.isEmpty) {
                return const Center(child: Text('No deleted sessions.'));
              }
              return ListView.separated(
                itemCount: deleted.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final session = deleted[index];
                  return GlassCard(
                    child: ListTile(
                      title: Text(session.title),
                      subtitle: Text(session.description),
                      trailing: Icon(
                        Icons.delete_forever,
                        color: AppTheme.warningColor,
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
  }
}
