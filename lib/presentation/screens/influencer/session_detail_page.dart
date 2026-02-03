import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/entities/question.dart';
import '../../../domain/repositories/session_repository.dart';
import '../../layouts/influencer_shell.dart';
import '../../bloc/polls/polls_cubit.dart';
import '../../bloc/polls/polls_state.dart';
import '../../bloc/questions/questions_cubit.dart';
import '../../bloc/questions/questions_state.dart';
import '../../layouts/influencer_shell.dart';
import '../../widgets/glass_card.dart';

class SessionDetailPage extends StatefulWidget {
  const SessionDetailPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  Session? _sessionOverride;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<QuestionsCubit>().watchQuestions(widget.sessionId);
    context.read<PollsCubit>().watchResponses(widget.sessionId);
  }

  void _pickRandomWinner(List<String> ids) {
    if (ids.isEmpty) return;
    final winnerId = ids[Random().nextInt(ids.length)];
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Random Winner'),
        content: Text('Winner ID: $winnerId'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  void _pickRandomWinnerFromAskers(List<QuestionAsker> askers) {
    if (askers.isEmpty) return;
    final winner = askers[Random().nextInt(askers.length)];
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Random Winner'),
        content: Text(
          '${winner.name ?? 'User'}\n${winner.email ?? ''}\n${winner.userId}',
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionRepo = sl<SessionRepository>();
    return InfluencerShell(
      title: 'Session Details',
      actions: [
        IconButton(
          icon: const Icon(Icons.link),
          onPressed: () async {
            final session = await sessionRepo.getSessionById(widget.sessionId);
            final publicLink = session == null
                ? ''
                : '${AppConstants.publicBaseUrl}/${session.publicLink}';
            if (publicLink.isNotEmpty) {
              await Clipboard.setData(ClipboardData(text: publicLink));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Copied: $publicLink')),
                );
              }
            }
          },
        ),
      ],
      body: FutureBuilder(
        future: sessionRepo.getSessionById(widget.sessionId),
        builder: (context, snapshot) {
          final session = _sessionOverride ?? snapshot.data;
          final publicLink = session == null
              ? ''
              : '${AppConstants.publicBaseUrl}/${session.publicLink}';
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              final questionPanel = GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Questions', style: Theme.of(context).textTheme.headlineSmall),
                        const Spacer(),
                        Text(
                          session?.status == SessionStatus.active ? 'Live' : 'Paused',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: BlocBuilder<QuestionsCubit, QuestionsState>(
                        builder: (context, state) {
                          if (state.isLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final visibleQuestions = state.questions
                              .where((q) => q.duplicateGroupId == null || q.duplicateGroupId == q.id)
                              .toList();
                          if (visibleQuestions.isEmpty) {
                            return const Center(child: Text('No questions yet.'));
                          }
                          return ListView.separated(
                            itemCount: visibleQuestions.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final question = visibleQuestions[index];
                              final askerCount = question.askers.isNotEmpty
                                  ? question.askers.length
                                  : question.repeatCount;
                              return GlassCard(
                                child: ListTile(
                                  title: Text(question.questionText),
                                  subtitle: Text(
                                    [
                                      if (question.createdByName != null)
                                        question.createdByName!,
                                      if (question.createdByEmail != null)
                                        question.createdByEmail!,
                                    ].join(' • '),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.15),
                                          ),
                                        ),
                                        child: Text(
                                          '${askerCount}x',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      _AskerAvatars(askers: question.askers),
                                    ],
                                  ),
                                  onTap: () => context.go('/question/${question.id}'),
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

              final sidePanel = Column(
                children: [
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Poll Activity',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 12),
                        BlocBuilder<PollsCubit, PollsState>(
                          builder: (context, state) {
                            if (state.isLoading) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            return Text('Total votes: ${state.responses.length}');
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Random Winner',
                                style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                final askers = context
                                    .read<QuestionsCubit>()
                                    .state
                                    .questions
                                    .expand((q) => q.askers)
                                    .toList();
                                _pickRandomWinnerFromAskers(askers);
                              },
                              child: const Text('Pick from Question Askers'),
                            ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            final pollIds = context
                                .read<PollsCubit>()
                                .state
                                .responses
                                .map((r) => r.userId)
                                .toList();
                            _pickRandomWinner(pollIds);
                          },
                          child: const Text('Pick from Poll Participants'),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final content = isWide
                  ? Row(
                      children: [
                        Expanded(flex: 2, child: questionPanel),
                        const SizedBox(width: 16),
                        Expanded(child: sidePanel),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(child: questionPanel),
                        const SizedBox(height: 16),
                        sidePanel,
                      ],
                    );

              return Column(
                children: [
                  if (publicLink.isNotEmpty) ...[
                    GlassCard(
                      child: Row(
                        children: [
                          const Icon(Icons.link),
                          const SizedBox(width: 12),
                          Expanded(child: Text(publicLink)),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: publicLink),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Public link copied')),
                                );
                              }
                            },
                            child: const Text('Copy'),
                          ),
                          const SizedBox(width: 8),
                              if (session != null)
                                ElevatedButton(
                                  onPressed: () async {
                                    final nextStatus = session.status == SessionStatus.active
                                        ? SessionStatus.paused
                                        : SessionStatus.active;
                                    await sessionRepo.updateSession(
                                      session.copyWith(status: nextStatus),
                                    );
                                    if (mounted) {
                                      setState(() {
                                        _sessionOverride =
                                            session.copyWith(status: nextStatus);
                                      });
                                    }
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            nextStatus == SessionStatus.active
                                            ? 'Session is live'
                                            : 'Session paused',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                session.status == SessionStatus.active ? 'Pause' : 'Go Live',
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Expanded(child: content),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _AskerAvatars extends StatelessWidget {
  const _AskerAvatars({required this.askers});

  final List<QuestionAsker> askers;

  @override
  Widget build(BuildContext context) {
    if (askers.isEmpty) return const SizedBox.shrink();
    final display = askers.take(6).toList();
    return SizedBox(
      width: 20.0 * display.length,
      height: 28,
      child: Stack(
        children: [
          for (var i = 0; i < display.length; i++)
            Positioned(
              left: i * 18.0,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.white.withOpacity(0.1),
                child: ClipOval(
                  child: display[i].photoUrl != null
                      ? Image.network(
                          display[i].photoUrl!,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.person, size: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
