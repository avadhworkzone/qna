import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';

class Question {
  final String id;
  final String text;
  final Map<String, int> responseVotes;
  final int totalAnswers;
  final DateTime createdAt;
  final String? shareableLink;

  Question({
    required this.id,
    required this.text,
    required this.responseVotes,
    required this.totalAnswers,
    required this.createdAt,
    this.shareableLink,
  });

  List<MapEntry<String, int>> get sortedAnswers {
    var entries = responseVotes.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  static Question fromMap(String id, Map<String, dynamic> map) {
    String questionText = '';
    if (map.containsKey('question1')) {
      questionText = map['question1'] ?? '';
    } else {
      questionText = map['text'] ?? '';
    }
    
    Map<String, int> responseVotes = {};
    
    // Handle migration from old answerCounts to new responseVotes
    if (map['responseVotes'] != null) {
      Map<String, dynamic> rawCounts = Map<String, dynamic>.from(map['responseVotes']);
      responseVotes = rawCounts.map((key, value) => MapEntry(key, value as int));
    } else if (map['answerCounts'] != null) {
      // Fallback to old structure
      Map<String, dynamic> rawCounts = Map<String, dynamic>.from(map['answerCounts']);
      responseVotes = rawCounts.map((key, value) => MapEntry(key, value as int));
    }
    
    // Calculate total from responseVotes instead of using stored totalAnswers
    int calculatedTotal = responseVotes.values.fold(0, (sum, count) => sum + count);
    print('Question: $questionText, ResponseVotes: $responseVotes, Calculated Total: $calculatedTotal');
    
    return Question(
      id: id,
      text: questionText,
      responseVotes: responseVotes,
      totalAnswers: calculatedTotal,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      shareableLink: map['shareableLink'],
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
  final TextEditingController _questionController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  int? selectedQuestionIndex;
  
  Future<void> _addQuestion() async {
    if (_questionController.text.trim().isNotEmpty) {
      String questionText = _questionController.text.trim();
      DocumentReference docRef = await _firestore.collection('questions').add({
        'text': questionText,
        'responseVotes': {},
        'totalAnswers': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      String shareableLink = 'https://yourapp.com/question/${docRef.id}';
      await docRef.update({'shareableLink': shareableLink});
      
      _questionController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Question added! Link: $shareableLink'),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () => Clipboard.setData(ClipboardData(text: shareableLink)),
            ),
          ),
        );
      }
    }
  }

  void _showAddQuestionDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Question'),
          content: TextField(
            controller: _questionController,
            decoration: const InputDecoration(
              hintText: 'Enter your question...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) => setState(() {}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _questionController.text.trim().isEmpty ? null : () {
                Navigator.pop(context);
                _addQuestion();
              },
              child: const Text('Add Question'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addAnswer(String questionId, String answer) async {
    if (answer.trim().isNotEmpty) {
      String cleanAnswer = answer.trim();
      await _firestore.collection('questions').doc(questionId).update({
        'responseVotes.$cleanAnswer': FieldValue.increment(1),
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
                              '${question.totalAnswers} answers',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (question.shareableLink != null)
                                  IconButton(
                                    icon: const Icon(Icons.share, color: Colors.blue),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: question.shareableLink!));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Link copied!')),
                                      );
                                    },
                                  ),
                                Icon(
                                  isSelected ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  color: Colors.purple,
                                ),
                              ],
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
                          
                          if (isSelected && question.responseVotes.isNotEmpty)
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
                                  ...question.sortedAnswers.map((entry) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text(entry.key)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${entry.value}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.purple.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddQuestionDialog,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    _questionController.dispose();
    super.dispose();
  }
}