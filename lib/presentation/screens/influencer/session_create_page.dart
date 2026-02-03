import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/session.dart';
import '../../../core/extensions/session_extensions.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/sessions/sessions_cubit.dart';
import '../../layouts/influencer_shell.dart';

class SessionCreatePage extends StatefulWidget {
  const SessionCreatePage({super.key});

  @override
  State<SessionCreatePage> createState() => _SessionCreatePageState();
}

class _SessionCreatePageState extends State<SessionCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _pollOptionsController = TextEditingController();
  SessionType _type = SessionType.questionBox;
  DateTime? _expiryTime;
  bool _isAnonymous = false;
  bool _allowMultipleQuestions = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _pollOptionsController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 23, minute: 59),
    );
    if (time == null) return;
    setState(() {
      _expiryTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    return InfluencerShell(
      title: 'Create Session',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Card(
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text(
                      'New Session',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Configure your Q&A and go live when ready.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Session Title'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Please enter a title' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter a description'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<SessionType>(
                      value: _type,
                      decoration: const InputDecoration(labelText: 'Session Type'),
                      items: SessionType.values
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.label),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _type = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_type != SessionType.questionBox) ...[
                      TextFormField(
                        controller: _pollOptionsController,
                        decoration: const InputDecoration(
                          labelText: 'Poll Options (comma separated)',
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SwitchListTile(
                      title: const Text('Enable Anonymous Mode'),
                      value: _isAnonymous,
                      onChanged: (value) => setState(() => _isAnonymous = value),
                    ),
                    SwitchListTile(
                      title: const Text('Allow Multiple Questions Per User'),
                      value: _allowMultipleQuestions,
                      onChanged: (value) =>
                          setState(() => _allowMultipleQuestions = value),
                    ),
                    const SizedBox(height: 12),
              ListTile(
                title: const Text('Expiry Time'),
                subtitle: Text(
                  _expiryTime == null
                      ? 'Not set'
                      : '${_expiryTime!.toLocal()}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickExpiry,
              ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        final influencerId = authState.user?.id;
                        if (influencerId == null) return;
                        final user = authState.user;
                        final session = Session(
                          id: '',
                          influencerId: influencerId,
                          title: _titleController.text.trim(),
                          description: _descController.text.trim(),
                          type: _type,
                          publicLink: '',
                          createdAt: DateTime.now(),
                          expiryTime: _expiryTime,
                          status: SessionStatus.paused,
                          isAnonymous: _isAnonymous,
                          allowMultipleQuestions: _allowMultipleQuestions,
                          pollOptions: _type == SessionType.questionBox
                              ? null
                              : {
                                  'options': _pollOptionsController.text
                                      .split(',')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList(),
                                },
                          influencerName: user?.name,
                          influencerPhotoUrl: user?.photoUrl,
                        );
                        final created = await context.read<SessionsCubit>().create(session);
                        if (mounted && created != null) {
                          context.go('/session/${created.id}');
                        } else if (mounted) {
                          context.go('/dashboard');
                        }
                      },
                      child: const Text('Create Session'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
