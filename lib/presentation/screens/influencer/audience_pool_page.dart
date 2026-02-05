import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/utils/web_file_picker_selector.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../widgets/glass_card.dart';

class AudiencePoolPage extends StatefulWidget {
  const AudiencePoolPage({super.key});

  @override
  State<AudiencePoolPage> createState() => _AudiencePoolPageState();
}

class _AudiencePoolPageState extends State<AudiencePoolPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _handleController = TextEditingController();
  final _nameController = TextEditingController();
  final _csvController = TextEditingController();
  bool _isImporting = false;
  String? _csvFileName;
  String? _csvPreview;
  String? _winner;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _handleController.dispose();
    _nameController.dispose();
    _csvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final organizerId = user.id;
    final publicJoinLink = '${Uri.base.origin}/join/$organizerId';
    final firestore = sl<FirebaseFirestore>();
    final membersQuery = firestore
        .collection(FirestorePaths.audiencePools)
        .doc(organizerId)
        .collection('members')
        .orderBy('createdAt', descending: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final maxTextWidth =
                max(160.0, min(520.0, constraints.maxWidth - 180));
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Audience Pool',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                GlassCard(
                  child: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(Icons.link),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxTextWidth),
                        child: Text(
                          publicJoinLink,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: publicJoinLink),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Join link copied')),
                            );
                          }
                        },
                        child: const Text('Copy'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Opt‑in List'),
            Tab(text: 'CSV Import'),
            Tab(text: 'IG Comments'),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              ListView(
                padding: const EdgeInsets.all(0),
                children: [
                  GlassCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _handleController,
                            decoration: const InputDecoration(
                              labelText: 'Instagram handle (or name)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Display name (optional)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            final handle = _handleController.text.trim();
                            if (handle.isEmpty) return;
                            await firestore
                                .collection(FirestorePaths.audiencePools)
                                .doc(organizerId)
                                .collection('members')
                                .add({
                              'organizerId': organizerId,
                              'handle': handle,
                              'name': _nameController.text.trim(),
                              'createdAt': DateTime.now().millisecondsSinceEpoch,
                              'source': 'manual',
                            });
                            _handleController.clear();
                            _nameController.clear();
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_winner != null)
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.emoji_events),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Winner: $_winner',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.teal.withOpacity(0.5),
                                ),
                              ),
                              child: const Text('Highlighted'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: membersQuery.snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final members = snapshot.data!.docs;
                      if (members.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text('No respondents yet. Share your join link.'),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: members.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final data = members[index].data();
                          final handle = data['handle']?.toString() ?? '';
                          final name = data['name']?.toString();
                          return GlassCard(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.white24,
                                    child: Text(
                                      handle.isNotEmpty
                                          ? handle[0].toLowerCase()
                                          : '?',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          handle,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                        if (name != null && name.isNotEmpty)
                                          Text(
                                            name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.delete, size: 18),
                                    onPressed: () =>
                                        members[index].reference.delete(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final snapshot = await membersQuery.get();
                      if (snapshot.docs.isEmpty) return;
                      final random = Random();
                      final pick = snapshot.docs[random.nextInt(snapshot.docs.length)];
                      setState(() {
                        _winner = pick.data()['handle']?.toString();
                      });
                    },
                    icon: const Icon(Icons.casino),
                    label: const Text('Pick Random Respondent'),
                  ),
                ],
              ),
              ListView(
                padding: const EdgeInsets.all(0),
                children: [
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CSV Import',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          Text(
                            'Paste CSV with columns: handle,name (name optional).',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          if (kIsWeb)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () async {
                                  final result =
                                      await WebFilePicker.pickCsvData();
                                  if (!mounted) return;
                                  final text = result?.text;
                                  if (text == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No file selected or CSV could not be read.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  if (text.trim().isEmpty) {
                                    setState(() {
                                      _csvFileName = result?.name;
                                      _csvController.text = text;
                                      _csvPreview = null;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('CSV file is empty.'),
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    _csvFileName = result?.name;
                                    _csvController.text = text;
                                    _csvPreview = text
                                        .split(RegExp(r'[\r\n]+'))
                                        .where((e) => e.trim().isNotEmpty)
                                        .take(5)
                                        .join('\n');
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'CSV loaded (${text.split(RegExp(r'[\\r\\n]+')).length} lines).',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Upload CSV file'),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            _csvController.text.isEmpty
                                ? 'No CSV loaded'
                                : 'Loaded ${_csvController.text.length} chars',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (_csvFileName != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'File: $_csvFileName',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 6),
                          TextField(
                            controller: _csvController,
                            maxLines: 8,
                            decoration: const InputDecoration(
                              labelText: 'Paste CSV data',
                            ),
                          ),
                          if (_csvPreview != null) ...[
                            const SizedBox(height: 8),
                            GlassCard(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: SelectableText(
                                  _csvPreview!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontFamily: 'monospace'),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _isImporting
                                ? null
                                : () async {
                                    final raw = _csvController.text.trim();
                                    if (raw.isEmpty) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Paste or upload a CSV first.',
                                            ),
                                          ),
                                        );
                                      }
                                      return;
                                    }
                                    setState(() => _isImporting = true);
                                    final lines = raw
                                        .split(RegExp(r'[\r\n]+'))
                                        .map((e) => e.trim())
                                        .where((e) => e.isNotEmpty)
                                        .toList();
                                    if (lines.isNotEmpty &&
                                        lines.first
                                            .toLowerCase()
                                            .contains('handle')) {
                                      lines.removeAt(0);
                                    }
                                    var imported = 0;
                                    for (final line in lines) {
                                      final parts = line.split(',');
                                      final handle = parts.first.trim();
                                      if (handle.isEmpty) continue;
                                      final name =
                                          parts.length > 1 ? parts[1].trim() : '';
                                      await firestore
                                          .collection(FirestorePaths.audiencePools)
                                          .doc(organizerId)
                                          .collection('members')
                                          .add({
                                        'organizerId': organizerId,
                                        'handle': handle,
                                        'name': name,
                                        'createdAt':
                                            DateTime.now().millisecondsSinceEpoch,
                                        'source': 'csv',
                                      });
                                      imported += 1;
                                    }
                                    if (mounted) {
                                      setState(() {
                                        _isImporting = false;
                                        _csvController.clear();
                                        _csvPreview = null;
                                        _csvFileName = null;
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Imported $imported rows.'),
                                        ),
                                      );
                                    }
                                  },
                            icon: _isImporting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.upload_file),
                            label: Text(
                              _isImporting ? 'Importing...' : 'Import CSV',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              Center(
                child: GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'Instagram comments picker is coming next.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
