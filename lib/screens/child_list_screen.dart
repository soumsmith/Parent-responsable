import 'package:flutter/material.dart';
import '../models/child.dart';
import '../models/note.dart';
import '../models/timetable_entry.dart';
import '../models/message.dart';
import '../models/fee.dart';
import '../services/api_service.dart';
import '../app.dart';
import 'notes_screen.dart';
import 'timetable_screen.dart';
import 'messages_screen.dart';
import 'fees_screen.dart';

/// Écran de détail d'un enfant avec onglets
class ChildListScreen extends StatefulWidget {
  final Child child;

  const ChildListScreen({
    super.key,
    required this.child,
  });

  @override
  State<ChildListScreen> createState() => _ChildListScreenState();
}

class _ChildListScreenState extends State<ChildListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Note> _notes = [];
  List<TimetableEntry> _timetable = [];
  List<Message> _messages = [];
  List<Fee> _fees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = App.of(context).apiService;
      
      final results = await Future.wait([
        apiService.getNotesForChild(widget.child.id),
        apiService.getTimetableForChild(widget.child.id),
        apiService.getMessages(App.of(context).currentUserId ?? 'parent1'),
        apiService.getFeesForChild(widget.child.id),
      ]);

      setState(() {
        _notes = results[0] as List<Note>;
        _timetable = results[1] as List<TimetableEntry>;
        _messages = results[2] as List<Message>;
        _fees = results[3] as List<Fee>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.child.fullName),
        backgroundColor: const Color(0xFFE3F2FD), // Bleu clair selon maquette
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.orange, // Orange pour l'onglet actif selon maquette
          unselectedLabelColor: Colors.black,
          indicatorColor: Colors.orange,
          tabs: const [
            Tab(text: 'Notes'),
            Tab(text: 'Emploi du temps'),
            Tab(text: 'Devoirs'),
            Tab(text: 'Absences'),
            Tab(text: 'Sanctions'),
            Tab(text: 'Messagerie'),
            Tab(text: 'Frais'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(0xFFE3F2FD), // Bleu clair selon maquette
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  NotesScreen(childId: widget.child.id),
                  TimetableScreen(childId: widget.child.id),
                  _buildHomeworkTab(),
                  _buildAbsencesTab(),
                  _buildSanctionsTab(),
                  MessagesScreen(),
                  FeesScreen(childId: widget.child.id),
                ],
              ),
      ),
    );
  }

  Widget _buildHomeworkTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Message selon maquette
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Text(
              'Cher parents,\nMerci de vous impliquer régulièrement dans le suivi et l\'amélioration du résultat scolaire de votre enfant.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          // Onglets selon maquette ÉTAPE 7
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange, // Orange pour l'onglet actif
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'COURS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.blue, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'EXERCICES',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.blue, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'CORRIGÉS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Contenu placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Devoirs et exercices',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Fonctionnalité à venir',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsencesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Message selon maquette
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Text(
              'Cher parents,\nMerci de vous impliquer régulièrement dans le suivi et l\'amélioration du résultat scolaire de votre enfant.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          // Contenu placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Absences et présences',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Aucune absence enregistrée',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSanctionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Message selon maquette
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Text(
              'Cher parents,\nMerci de vous impliquer régulièrement dans le suivi et l\'amélioration du résultat scolaire de votre enfant.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          // Contenu placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Sanctions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Aucune sanction enregistrée',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

