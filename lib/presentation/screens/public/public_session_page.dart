import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/question.dart';
import '../../../domain/entities/poll_response.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/repositories/session_repository.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/utils/web_redirect.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/questions/questions_cubit.dart';
import '../../bloc/polls/polls_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublicSessionPage extends StatefulWidget {
  const PublicSessionPage({super.key, required this.publicLink});

  final String publicLink;

  @override
  State<PublicSessionPage> createState() => _PublicSessionPageState();
}

class _PublicSessionPageState extends State<PublicSessionPage> {
  final _questionController = TextEditingController();
  bool _isSubmitting = false;
  bool _isVoting = false;
  String? _existingQuestionId;
  String? _loadedUserId;
  bool _hasSubmitted = false;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _loadDraft(String sessionId, String? userId) async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final draftKey = 'draft_$sessionId';
    final draft = prefs.getString(draftKey);
    if (draft != null && draft.isNotEmpty && _questionController.text.isEmpty) {
      _questionController.text = draft;
    }
    if (userId != null) {
      final qidKey = 'qid_${sessionId}_$userId';
      _existingQuestionId = prefs.getString(qidKey);
      if (_existingQuestionId != null) {
        _hasSubmitted = true;
      }
    }
  }

  Future<void> _saveDraft(String sessionId, String text) async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_$sessionId', text);
  }

  @override
  Widget build(BuildContext context) {
    final sessionRepo = sl<SessionRepository>();
    final authState = context.watch<AuthCubit>().state;
    if (_isSubmitting && authState.status != AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      });
    }

    return Scaffold(
      body: FutureBuilder<Session?>(
        future: sessionRepo.getSessionByPublicLink(widget.publicLink),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final session = snapshot.data;
          if (session == null) {
            return const Center(child: Text('Session not found.'));
          }
          final pollOptions = (session.pollOptions?['options'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          final isActive = session.isActive;
          final isAuthed = authState.status == AuthStatus.authenticated &&
              authState.user != null;
          if (_loadedUserId != authState.user?.id) {
            _loadedUserId = authState.user?.id;
            _loadDraft(session.id, _loadedUserId);
          }
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B1021),
                  Color(0xFF111A2F),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Card(
                    margin: const EdgeInsets.all(20),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundImage: session.influencerPhotoUrl != null
                                    ? NetworkImage(session.influencerPhotoUrl!)
                                    : null,
                                child: session.influencerPhotoUrl == null
                                    ? const Icon(Icons.person, size: 28)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.influencerName ?? 'Influencer',
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                  Text(
                                    'Live Q&A',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppTheme.successColor.withOpacity(0.2)
                                      : AppTheme.warningColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isActive
                                        ? AppTheme.successColor.withOpacity(0.4)
                                        : AppTheme.warningColor.withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  isActive ? 'LIVE' : 'OFFLINE',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                          if (authState.user != null) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: authState.user!.photoUrl != null
                                      ? NetworkImage(authState.user!.photoUrl!)
                                      : null,
                                  child: authState.user!.photoUrl == null
                                      ? const Icon(Icons.person, size: 18)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  authState.user!.name,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () async {
                                    if (!kIsWeb) {
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.remove('draft_${session.id}');
                                      await prefs.remove(
                                        'qid_${session.id}_${authState.user!.id}',
                                      );
                                    }
                                    if (mounted) {
                                      setState(() {
                                        _questionController.clear();
                                        _existingQuestionId = null;
                                        _hasSubmitted = false;
                                      });
                                    }
                                    await context.read<AuthCubit>().signOut();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Logged out.'),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Logout'),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 20),
                          Text(
                            session.title,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(session.description),
                          if (!isActive) ...[
                            const SizedBox(height: 12),
                            const Text('This session is not live yet.'),
                          ],
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ask a question',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _questionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Type your question',
                                  ),
                                  onChanged: (value) => _saveDraft(session.id, value),
                                ),
                                const SizedBox(height: 12),
                                if (!isAuthed)
                                  ElevatedButton(
                                    onPressed: () {
                                      final redirect = Uri.encodeComponent(
                                        '/public/${widget.publicLink}',
                                      );
                                      final target = '/login?redirect=$redirect';
                                      try {
                                        _saveDraft(
                                          session.id,
                                          _questionController.text,
                                        );
                                      } catch (_) {}
                                      if (!context.mounted) return;
                                      GoRouter.of(context).go(target);
                                      WebRedirect.go(target);
                                    },
                                    child: const Text('Login to Submit'),
                                  )
                                else
                                  ElevatedButton(
                                    onPressed: _isSubmitting
                                        ? null
                                        : () async {
                                            debugPrint('Public submit tapped');
                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            messenger.hideCurrentSnackBar();
                                            if (!isActive) {
                                              messenger.showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Session is not live yet.',
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            if (!session.allowMultipleQuestions &&
                                                _hasSubmitted) {
                                              messenger.showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Only one question is allowed for this session.',
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            final text =
                                                _questionController.text.trim();
                                            if (text.isEmpty) {
                                              messenger.showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Please type a question first.',
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            setState(() => _isSubmitting = true);
                                            bool ok = false;
                                            String? failureMessage;
                                            try {
                                              if (_existingQuestionId == null &&
                                                  !session.allowMultipleQuestions) {
                                                final firestore =
                                                    sl<FirebaseFirestore>();
                                                final existing = await firestore
                                                    .collection(
                                                      FirestorePaths.questions,
                                                    )
                                                    .where(
                                                      'sessionId',
                                                      isEqualTo: session.id,
                                                    )
                                                    .where(
                                                      'userId',
                                                      isEqualTo:
                                                          authState.user!.id,
                                                    )
                                                    .limit(1)
                                                    .get();
                                                if (existing.docs.isNotEmpty) {
                                                  final doc = existing.docs.first;
                                                  _existingQuestionId = doc.id;
                                                  _hasSubmitted = true;
                                                  if (!kIsWeb) {
                                                    final prefs =
                                                        await SharedPreferences
                                                            .getInstance();
                                                    await prefs.setString(
                                                      'qid_${session.id}_${authState.user!.id}',
                                                      doc.id,
                                                    );
                                                  }
                                                  if (context.mounted) {
                                                    messenger.showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'You have already submitted a question.',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                  if (mounted) {
                                                    setState(() {
                                                      _isSubmitting = false;
                                                    });
                                                  }
                                                  return;
                                                }
                                              }
                                              final created = await context
                                                  .read<QuestionsCubit>()
                                                  .create(
                                                    Question(
                                                      id: '',
                                                      sessionId: session.id,
                                                      userId: authState.user!.id,
                                                      questionText: text,
                                                      createdAt: DateTime.now(),
                                                      createdByName:
                                                          authState.user!.name,
                                                      createdByEmail:
                                                          authState.user!.email,
                                                      createdByPhotoUrl:
                                                          authState.user!.photoUrl,
                                                    ),
                                                  );
                                              ok = created != null;
                                              if (created != null) {
                                                if (!session.allowMultipleQuestions) {
                                                  _existingQuestionId = created.id;
                                                  _hasSubmitted = true;
                                                  if (!kIsWeb) {
                                                    final prefs =
                                                        await SharedPreferences
                                                            .getInstance();
                                                    await prefs.setString(
                                                      'qid_${session.id}_${authState.user!.id}',
                                                      created.id,
                                                    );
                                                  }
                                                }
                                              }
                                            } on TimeoutException {
                                              failureMessage =
                                                  'Request is taking too long. Please try again.';
                                              try {
                                                final firestore =
                                                    sl<FirebaseFirestore>();
                                                final existing = await firestore
                                                    .collection(
                                                      FirestorePaths.questions,
                                                    )
                                                    .where(
                                                      'sessionId',
                                                      isEqualTo: session.id,
                                                    )
                                                    .where(
                                                      'userId',
                                                      isEqualTo: authState.user!.id,
                                                    )
                                                    .limit(1)
                                                    .get();
                                                if (existing.docs.isNotEmpty) {
                                                  final doc = existing.docs.first;
                                                  _existingQuestionId = doc.id;
                                                  _hasSubmitted = true;
                                                  ok = true;
                                                  failureMessage = null;
                                                }
                                              } catch (_) {}
                                            } catch (e) {
                                              ok = false;
                                              failureMessage = e.toString();
                                              debugPrint('Submit failed: $e');
                                            } finally {
                                              if (mounted) {
                                                setState(() => _isSubmitting = false);
                                              }
                                            }
                                            if (context.mounted) {
                                              final error = failureMessage ??
                                                  context
                                                      .read<QuestionsCubit>()
                                                      .state
                                                      .errorMessage;
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    ok
                                                        ? 'Feedback submitted'
                                                        : error ??
                                                            'Submission failed',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            !isActive
                                                ? 'Session not live'
                                                : _hasSubmitted &&
                                                        !session
                                                            .allowMultipleQuestions
                                                    ? 'Submitted'
                                                    : 'Submit Question',
                                          ),
                                  ),
                              ],
                            ),
                          ),
                          if (session.type != SessionType.questionBox && pollOptions.isNotEmpty)
                            ...[
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardColor.withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Quick Poll',
                                      style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: pollOptions.map((option) {
                                        return OutlinedButton(
                                          onPressed: !isActive || _isVoting
                                              ? null
                                              : () async {
                                                  if (authState.user == null) {
                                                    final redirect = Uri.encodeComponent(
                                                      '/public/${widget.publicLink}',
                                                    );
                                                    showDialog<void>(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        title: const Text('Login required'),
                                                        content: const Text(
                                                          'Please log in to vote in this poll.',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(context).pop(),
                                                            child: const Text('Cancel'),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              Navigator.of(context).pop();
                                                              context
                                                                  .go('/login?redirect=$redirect');
                                                            },
                                                            child: const Text('Login'),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    return;
                                                  }
                                                  setState(() => _isVoting = true);
                                                  final ok = await context
                                                      .read<PollsCubit>()
                                                      .submit(
                                                        PollResponse(
                                                          id: '',
                                                          sessionId: session.id,
                                                          userId: authState.user!.id,
                                                          selectedOption: option,
                                                          createdAt: DateTime.now(),
                                                        ),
                                                      );
                                                  if (mounted) {
                                                    setState(() => _isVoting = false);
                                                  }
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          ok ? 'Vote submitted' : 'Vote failed',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                          child: Text(option),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          const SizedBox(height: 12),
                          Text(
                            'Powered by QA SaaS',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
