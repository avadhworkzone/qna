import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';

class AdminQuestion {
  final String id;
  final String text;
  final Map<String, int> responseVotes;
  final int totalAnswers;
  final DateTime createdAt;
  final String adminId;

  AdminQuestion({
    required this.id,
    required this.text,
    required this.responseVotes,
    required this.totalAnswers,
    required this.createdAt,
    required this.adminId,
  });

  List<MapEntry<String, int>> get sortedAnswers {
    var entries = responseVotes.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  static AdminQuestion fromMap(String id, Map<String, dynamic> map) {
    Map<String, int> responseVotes = {};
    if (map['responseVotes'] != null) {
      Map<String, dynamic> rawCounts = Map<String, dynamic>.from(map['responseVotes']);
      responseVotes = rawCounts.map((key, value) => MapEntry(key, value as int));
    }
    
    int calculatedTotal = responseVotes.values.fold(0, (sum, count) => sum + count);
    
    return AdminQuestion(
      id: id,
      text: map['text'] ?? '',
      responseVotes: responseVotes,
      totalAnswers: calculatedTotal,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      adminId: map['adminId'] ?? '',
    );
  }
}

class AdminQAHomePage extends StatefulWidget {
  final Function(Locale) onLanguageChange;
  const AdminQAHomePage({super.key, required this.onLanguageChange});

  @override
  State<AdminQAHomePage> createState() => _AdminQAHomePageState();
}

class _AdminQAHomePageState extends State<AdminQAHomePage> {
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  
  int? selectedQuestionIndex;
  String? adminName;
  String? adminEmail;

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  Future<void> _loadAdminInfo() async {
    if (_currentUser != null) {
      DocumentSnapshot adminDoc = await _firestore
          .collection('admins')
          .doc(_currentUser!.uid)
          .get();
      
      if (adminDoc.exists) {
        Map<String, dynamic> data = adminDoc.data() as Map<String, dynamic>;
        setState(() {
          adminName = data['name'] ?? 'Admin';
          adminEmail = data['email'] ?? _currentUser!.email;
        });
      }
    }
  }

  Future<void> _addQuestion() async {
    if (_questionController.text.trim().isNotEmpty && _currentUser != null) {
      String questionText = _questionController.text.trim();
      await _firestore.collection('questions').add({
        'text': questionText,
        'responseVotes': {},
        'totalAnswers': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'adminId': _currentUser!.uid,
      });
      
      _questionController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question added successfully!')),
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

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel - ${adminName ?? "Loading..."}'),
        backgroundColor: Colors.purple.shade100,
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            onSelected: widget.onLanguageChange,
            itemBuilder: (context) => [
              const PopupMenuItem(value: Locale('en'), child: Text('🇺🇸 English')),
              const PopupMenuItem(value: Locale('hi'), child: Text('🇮🇳 हिंदी')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Admin Info Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.purple.shade600,
                  child: Text(
                    (adminName?.isNotEmpty == true) ? adminName![0].toUpperCase() : 'A',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adminName ?? 'Loading...',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      adminEmail ?? '',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('questions')
                  .where('adminId', isEqualTo: _currentUser?.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading questions'));
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No questions yet. Add your first question!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                
                final questions = snapshot.data!.docs.map((doc) {
                  return AdminQuestion.fromMap(doc.id, doc.data() as Map<String, dynamic>);
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
                                      decoration: const InputDecoration(
                                        hintText: 'Add an answer...',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _addAnswer(question.id, _answerController.text),
                                    child: const Text('Add'),
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
                                  const Text(
                                    'Answers:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
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
                          if (isSelected) const SizedBox(height: 16),
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