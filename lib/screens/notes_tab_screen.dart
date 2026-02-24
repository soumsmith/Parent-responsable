import 'package:flutter/material.dart';
import '../models/child.dart';
import '../services/database_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../config/app_colors.dart';
import '../widgets/custom_card.dart';
import 'notes_screen.dart';

/// Écran onglet Notes : liste des enfants pour sélectionner dont voir les notes
class NotesScreen extends StatefulWidget implements MainScreenChild {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Child> _children = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadChildren());
  }

  Future<void> _loadChildren() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final parentId = MainScreenWrapper.of(context).currentUserId ?? '';
      final list = await DatabaseService.instance.getChildrenByParent(parentId);
      setState(() {
        _children = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.getPureBackground(isDark),
        appBar: AppBar(
          title: Text('Notes', style: TextStyle(color: AppColors.getTextColor(isDark))),
          backgroundColor: AppColors.getSurfaceColor(isDark),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.getPureBackground(isDark),
        appBar: AppBar(
          title: Text('Notes', style: TextStyle(color: AppColors.getTextColor(isDark))),
          backgroundColor: AppColors.getSurfaceColor(isDark),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.getTextColor(isDark, type: TextType.secondary)),
                const SizedBox(height: 16),
                Text('Erreur', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.getTextColor(isDark))),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary))),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _loadChildren, child: const Text('Réessayer')),
              ],
            ),
          ),
        ),
      );
    }

    if (_children.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.getPureBackground(isDark),
        appBar: AppBar(
          title: Text('Notes', style: TextStyle(color: AppColors.getTextColor(isDark))),
          backgroundColor: AppColors.getSurfaceColor(isDark),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.grade, size: 64, color: AppColors.getTextColor(isDark, type: TextType.secondary)),
              const SizedBox(height: 16),
              Text(
                'Sélectionnez un enfant depuis l\'écran d\'accueil',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.getTextColor(isDark)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        title: Text('Notes', style: TextStyle(color: AppColors.getTextColor(isDark))),
        backgroundColor: AppColors.getSurfaceColor(isDark),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadChildren,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _children.length,
          itemBuilder: (context, index) {
            final child = _children[index];
            return CustomCard(
              margin: const EdgeInsets.only(bottom: 12),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChildNotesScreen(childId: child.id),
                  ),
                );
              },
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  backgroundImage: child.photoUrl != null && child.photoUrl!.isNotEmpty ? NetworkImage(child.photoUrl!) : null,
                  child: child.photoUrl == null || child.photoUrl!.isEmpty ? Text(child.firstName.isNotEmpty ? child.firstName[0].toUpperCase() : '?', style: const TextStyle(color: AppColors.primary)) : null,
                ),
                title: Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(child.establishment),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        ),
      ),
    );
  }
}
