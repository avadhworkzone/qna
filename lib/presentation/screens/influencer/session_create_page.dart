import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/session.dart';
import '../../../core/extensions/session_extensions.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/sessions/sessions_cubit.dart';

class SessionCreatePage extends StatefulWidget {
  const SessionCreatePage({super.key});

  @override
  State<SessionCreatePage> createState() => _SessionCreatePageState();
}

class _SessionCreatePageState extends State<SessionCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  SessionType _type = SessionType.questionBox;
  DateTime? _startTime;
  DateTime? _expiryTime;
  bool _allowMultipleQuestions = false;
  bool _isSubmitting = false;
  final List<TextEditingController> _pollControllers = [
    TextEditingController()
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    for (final controller in _pollControllers) {
      controller.dispose();
    }
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

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'Required';
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

  Future<void> _pickStartTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );
    if (time == null) return;
    setState(() {
      _startTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _addPollOption() {
    setState(() => _pollControllers.add(TextEditingController()));
  }

  void _removePollOption(int index) {
    if (_pollControllers.length <= 1) return;
    final controller = _pollControllers.removeAt(index);
    controller.dispose();
    setState(() {});
  }

  List<String> _pollOptions() {
    return _pollControllers
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  bool _validatePollOptions() {
    if (_type == SessionType.questionBox) return true;
    final options = _pollOptions();
    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 2 poll options.')),
      );
      return false;
    }
    if (_pollControllers.any((c) => c.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all poll options.')),
      );
      return false;
    }
    return true;
  }

  bool _validateTimes() {
    if (_startTime == null || _expiryTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and expiry time.')),
      );
      return false;
    }
    if (_expiryTime!.isBefore(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expiry time must be after start time.')),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 980;
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'New Session',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                  if (authState.user != null)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Credits: ${authState.user!.sessionCredits}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Configure your session and go live when ready.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildBasicsCard()),
                          const SizedBox(width: 20),
                          Expanded(child: _buildScheduleCard()),
                        ],
                      )
                    : ListView(
                        children: [
                          _buildBasicsCard(),
                          const SizedBox(height: 16),
                          _buildScheduleCard(),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                    if (!_formKey.currentState!.validate()) return;
                    if (!_validateTimes()) return;
                    if (!_validatePollOptions()) return;
                    final influencerId = authState.user?.id;
                    if (influencerId == null) return;
                    if ((authState.user?.sessionCredits ?? 0) <= 0) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No credits left. Please purchase a plan.'),
                          ),
                        );
                        context.go('/billing');
                      }
                      return;
                    }
                    setState(() => _isSubmitting = true);
                    try {
                      final user = authState.user;
                      final session = Session(
                        id: '',
                        influencerId: influencerId,
                        title: _titleController.text.trim(),
                        description: _descController.text.trim(),
                        type: _type,
                        publicLink: '',
                        createdAt: DateTime.now(),
                        startTime: _startTime,
                        expiryTime: _expiryTime,
                        status: SessionStatus.paused,
                        isAnonymous: false,
                        allowMultipleQuestions: _allowMultipleQuestions,
                        pollOptions: _type == SessionType.questionBox
                            ? null
                            : {
                                'options': _pollOptions(),
                              },
                        influencerName: user?.name,
                        influencerPhotoUrl: user?.photoUrl,
                      );
                      final created =
                          await context.read<SessionsCubit>().create(session);
                      await context.read<AuthCubit>().refreshProfile();
                      if (mounted && created != null) {
                        context.go('/session/${created.id}');
                      } else if (mounted) {
                        context.go('/dashboard');
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isSubmitting = false);
                      }
                    }
                  },
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle),
                  label:
                      Text(_isSubmitting ? 'Creating...' : 'Create Session'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBasicsCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Basics', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
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
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter a description' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<SessionType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Session Type'),
              items: SessionType.values
                  .where((type) => type != SessionType.mixedMode)
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
              const SizedBox(height: 4),
              ...List.generate(_pollControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _pollControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Option ${index + 1}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_pollControllers.length > 1)
                        IconButton(
                          onPressed: () => _removePollOption(index),
                          icon: const Icon(Icons.close),
                        ),
                    ],
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addPollOption,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Option'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Schedule & Settings',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Allow Multiple Responses Per Respondent'),
              value: _allowMultipleQuestions,
              onChanged: (value) => setState(() => _allowMultipleQuestions = value),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Start Time'),
              subtitle: Text(
                _formatDateTime(_startTime),
              ),
              trailing: const Icon(Icons.schedule),
              onTap: _pickStartTime,
            ),
            const SizedBox(height: 6),
            ListTile(
              title: const Text('Expiry Time'),
              subtitle: Text(
                _formatDateTime(_expiryTime),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickExpiry,
            ),
          ],
        ),
      ),
    );
  }
}
