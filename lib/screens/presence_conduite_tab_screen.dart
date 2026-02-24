import 'package:flutter/material.dart';
import '../models/child.dart';
import '../services/database_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../config/app_colors.dart';
import '../widgets/custom_card.dart';
import 'attendance_screen.dart';
import 'discipline_screen.dart';

/// Liste des enfants pour accéder à Présence et Conduite
class PresConduiteTabScreen extends StatefulWidget implements MainScreenChild {
  const PresConduiteTabScreen({super.key});

  @override
  State<PresConduiteTabScreen> createState() => _PresConduiteTabScreenState();
}

class _PresConduiteTabScreenState extends State<PresConduiteTabScreen> {
  List<Child> _children = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() => _isLoading = true);
    try {
      final parentId = MainScreenWrapper.of(context).currentUserId ?? '';
      final list = await DatabaseService.instance.getChildrenByParent(parentId);
      setState(() {
        _children = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Présence & Conduite', style: TextStyle(color: AppColors.getTextColor(isDark))), backgroundColor: AppColors.getSurfaceColor(isDark), elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_children.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Présence & Conduite', style: TextStyle(color: AppColors.getTextColor(isDark))), backgroundColor: AppColors.getSurfaceColor(isDark), elevation: 0),
        body: Center(child: Text('Aucun enfant.', style: TextStyle(color: AppColors.getTextColor(isDark)))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Présence & Conduite', style: TextStyle(color: AppColors.getTextColor(isDark))),
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
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.2), child: Text(child.firstName.isNotEmpty ? child.firstName[0].toUpperCase() : '?', style: const TextStyle(color: AppColors.primary))),
                    title: Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(child.establishment),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AttendanceScreen(childId: child.id))),
                            icon: const Icon(Icons.event_available, size: 18),
                            label: const Text('Présence'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DisciplineScreen(childId: child.id))),
                            icon: const Icon(Icons.gavel, size: 18),
                            label: const Text('Conduite'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
