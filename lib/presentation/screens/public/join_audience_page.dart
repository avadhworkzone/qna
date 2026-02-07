import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/di/service_locator.dart';
import '../../widgets/app_background.dart';
import '../../widgets/glass_card.dart';

class JoinAudiencePage extends StatefulWidget {
  const JoinAudiencePage({super.key, required this.organizerId});

  final String organizerId;

  @override
  State<JoinAudiencePage> createState() => _JoinAudiencePageState();
}

class _JoinAudiencePageState extends State<JoinAudiencePage> {
  final _handleController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _handleController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestore = sl<FirebaseFirestore>();
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Join the Audience',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'Submit your handle to be included in random picks.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _handleController,
                      decoration: const InputDecoration(
                        labelText: 'Instagram handle (required)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Display name (optional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              final handle = _handleController.text.trim();
                              if (handle.isEmpty) return;
                              setState(() => _isSubmitting = true);
                              await firestore
                                  .collection(FirestorePaths.audiencePools)
                                  .doc(widget.organizerId)
                                  .collection('members')
                                  .add({
                                'organizerId': widget.organizerId,
                                'handle': handle,
                                'name': _nameController.text.trim(),
                                'createdAt': DateTime.now().millisecondsSinceEpoch,
                                'source': 'opt-in',
                              });
                              if (mounted) {
                                setState(() => _isSubmitting = false);
                                _handleController.clear();
                                _nameController.clear();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('You are added.')),
                                );
                              }
                            },
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Join'),
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
