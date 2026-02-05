import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/question.dart';
import '../../../data/models/question_model.dart';
import '../../widgets/glass_card.dart';

class QuestionDetailPage extends StatelessWidget {
  const QuestionDetailPage({super.key, required this.questionId});

  final String questionId;

  @override
  Widget build(BuildContext context) {
    final firestore = sl<FirebaseFirestore>();
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: firestore.collection(FirestorePaths.questions).doc(questionId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!.data();
        if (data == null) {
          return const Center(child: Text('Response not found.'));
        }
        final question = QuestionModel.fromFirestore(data, snapshot.data!.id);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(question.questionText,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    [
                      if (question.createdByName != null) question.createdByName!,
                      if (question.createdByEmail != null) question.createdByEmail!,
                    ].join(' • '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Respondents who submitted this',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: question.askers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final asker = question.askers[index];
                  return GlassCard(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: asker.photoUrl != null
                            ? NetworkImage(asker.photoUrl!)
                            : null,
                        child:
                            asker.photoUrl == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(asker.name ?? 'Respondent'),
                      subtitle: Text(asker.email ?? asker.userId),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
