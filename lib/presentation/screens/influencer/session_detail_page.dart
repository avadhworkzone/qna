import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/entities/question.dart';
import '../../../domain/repositories/session_repository.dart';
import '../../bloc/polls/polls_cubit.dart';
import '../../bloc/polls/polls_state.dart';
import '../../bloc/questions/questions_cubit.dart';
import '../../bloc/questions/questions_state.dart';
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

  Future<void> _confirmDelete(
    BuildContext context,
    SessionRepository sessionRepo,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete session?'),
        content: const Text(
          'This will move the session to Deleted Sessions. You can still view it later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await sessionRepo.softDeleteSession(widget.sessionId);
    if (mounted) {
      context.go('/deleted-sessions');
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    Session session,
    SessionRepository sessionRepo,
  ) async {
    final titleController = TextEditingController(text: session.title);
    final descController = TextEditingController(text: session.description);
    DateTime? start = session.startTime;
    DateTime? expiry = session.expiryTime;

    Future<void> pickStart() async {
      final date = await showDatePicker(
        context: context,
        firstDate: DateTime.now().subtract(const Duration(days: 1)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (date == null) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(start ?? DateTime.now()),
      );
      if (time == null) return;
      start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    }

    Future<void> pickExpiry() async {
      final date = await showDatePicker(
        context: context,
        firstDate: DateTime.now().subtract(const Duration(days: 1)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (date == null) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(expiry ?? DateTime.now()),
      );
      if (time == null) return;
      expiry = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Session'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(start == null ? 'Start not set' : '$start'),
                  ),
                  TextButton(onPressed: pickStart, child: const Text('Pick Start')),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(expiry == null ? 'Expiry not set' : '$expiry'),
                  ),
                  TextButton(onPressed: pickExpiry, child: const Text('Pick Expiry')),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final updated = session.copyWith(
      title: titleController.text.trim(),
      description: descController.text.trim(),
      startTime: start,
      expiryTime: expiry,
    );
    await sessionRepo.updateSession(updated);
    if (mounted) {
      setState(() => _sessionOverride = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionRepo = sl<SessionRepository>();
    return FutureBuilder(
      future: sessionRepo.getSessionById(widget.sessionId),
      builder: (context, snapshot) {
        final session = _sessionOverride ?? snapshot.data;
        final publicLink = session == null
            ? ''
            : '${AppConstants.publicBaseUrl}/${session.publicLink}';
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            final headerActions = Row(
              children: [
                Text('Session Details',
                    style: Theme.of(context).textTheme.headlineMedium),
                const Spacer(),
                if (publicLink.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () async {
                      final uri = Uri.parse(publicLink);
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    tooltip: 'Open Public Link',
                  ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: session == null
                      ? null
                      : () => _showEditDialog(context, session, sessionRepo),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: session == null
                      ? null
                      : () => _confirmDelete(context, sessionRepo),
                ),
              ],
            );
            final questionPanel = GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  headerActions,
                  if (session != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      session.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        session?.status == SessionStatus.active
                            ? 'Live'
                            : 'Paused',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      BlocBuilder<QuestionsCubit, QuestionsState>(
                        builder: (context, state) {
                          final unique = <String>{};
                          for (final q in state.questions) {
                            unique.add(q.userId);
                            for (final a in q.askers) {
                              unique.add(a.userId);
                            }
                          }
                          return Container(
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
                              'Participants: ${unique.length}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
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
                            return const Center(child: Text('No responses yet.'));
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
                                      const SizedBox(width: 10),
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
                      Text('Random Selection',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 12),
                      if (session?.type == SessionType.poll) ...[
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
                      ] else ...[
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
                          child: const Text('Pick from Respondents'),
                        ),
                      ],
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
                        if (session != null && session.deletedAt == null)
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
    if (display.length == 1) {
      final asker = display.first;
      return CircleAvatar(
        radius: 12,
        backgroundColor: Colors.white.withOpacity(0.1),
        backgroundImage:
            asker.photoUrl != null ? NetworkImage(asker.photoUrl!) : null,
        child: asker.photoUrl == null ? const Icon(Icons.person, size: 12) : null,
      );
    }
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
                backgroundImage: display[i].photoUrl != null
                    ? NetworkImage(display[i].photoUrl!)
                    : null,
                child: display[i].photoUrl == null
                    ? const Icon(Icons.person, size: 12)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
