import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'l10n/app_localizations.dart';

class Question {
  final String id;
  final String text;
  final List<String> answers;
  final int answerCount;
  final DateTime createdAt;

  Question({
    required this.id,
    required this.text,
    required this.answers,
    required this.answerCount,
    required this.createdAt,
  });

  static Question fromMap(String id, Map<String, dynamic> map) {
    // Handle the current Firestore structure with question1, question2, etc.
    String questionText = '';
    if (map.containsKey('question1')) {
      questionText = map['question1'] ?? '';
    } else {
      questionText = map['text'] ?? '';
    }
    
    return Question(
      id: id,
      text: questionText,
      answers: List<String>.from(map['answers'] ?? []),
      answerCount: map['answerCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}

class QAHomePage extends StatefulWidget {
  final Function(Locale) onLanguageChange;
  const QAHomePage({super.key, required this.onLanguageChange});

  @override
  State<QAHomePage> createState() => _QAHomePageState();
}

class _QAHomePageState extends State<QAHomePage> {
  final TextEditingController _answerController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  int? selectedQuestionIndex;

  Future<void> _addAnswer(String questionId, String answer) async {
    if (answer.isNotEmpty) {
      await _firestore.collection('questions').doc(questionId).update({
        'answers': FieldValue.arrayUnion([answer]),
        'answerCount': FieldValue.increment(1),
      });
      _answerController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        backgroundColor: Colors.purple.shade100,
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            onSelected: widget.onLanguageChange,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: Locale('en'),
                child: Text('🇺🇸 English'),
              ),
              const PopupMenuItem(
                value: Locale('hi'),
                child: Text('🇮🇳 हिंदी'),
              ),
              const PopupMenuItem(
                value: Locale('es'),
                child: Text('🇪🇸 Español'),
              ),
              const PopupMenuItem(
                value: Locale('fr'),
                child: Text('🇫🇷 Français'),
              ),
              const PopupMenuItem(
                value: Locale('de'),
                child: Text('🇩🇪 Deutsch'),
              ),
              const PopupMenuItem(
                value: Locale('zh'),
                child: Text('🇨🇳 中文'),
              ),
              const PopupMenuItem(
                value: Locale('ja'),
                child: Text('🇯🇵 日本語'),
              ),
              const PopupMenuItem(
                value: Locale('ar'),
                child: Text('🇸🇦 العربية'),
              ),
              const PopupMenuItem(
                value: Locale('pt'),
                child: Text('🇧🇷 Português'),
              ),
              const PopupMenuItem(
                value: Locale('ru'),
                child: Text('🇷🇺 Русский'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('questions').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(l10n.errorLoading));
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.noQuestions,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                
                final questions = snapshot.data!.docs.map((doc) {
                  return Question.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                }).toList();
                
                return ListView.builder(
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    final isSelected = selectedQuestionIndex == index;
                    
                    return Card(
                      margin: const EdgeInsets.all(8),
                      elevation: isSelected ? 8 : 2,
                      color: isSelected ? Colors.purple.shade50 : Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(
                              question.text,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: isSelected ? 18 : 16,
                                color: isSelected ? Colors.purple.shade700 : Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              '${question.answerCount} answers',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Icon(
                              isSelected ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: Colors.purple,
                            ),
                            onTap: () {
                              setState(() {
                                selectedQuestionIndex = isSelected ? null : index;
                              });
                            },
                          ),
                          
                          if (isSelected) const Divider(),
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _answerController,
                                      decoration: InputDecoration(
                                        hintText: l10n.writeAnswer,
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _addAnswer(question.id, _answerController.text),
                                    child: Text(l10n.send),
                                  ),
                                ],
                              ),
                            ),
                          
                          if (isSelected && question.answers.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.answers,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...question.answers.map((answer) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: Text(answer),
                                  )),
                                ],
                              ),
                            ),
                          if (isSelected)
                            const SizedBox(height: 16),
                        ],
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

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }
}