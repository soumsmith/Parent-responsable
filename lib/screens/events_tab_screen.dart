import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../config/app_colors.dart';
import '../widgets/custom_card.dart';
import 'events_screen.dart';

/// Liste des établissements pour accéder aux événements
class EventsTabScreen extends StatefulWidget implements MainScreenChild {
  const EventsTabScreen({super.key});

  @override
  State<EventsTabScreen> createState() => _EventsTabScreenState();
}

class _EventsTabScreenState extends State<EventsTabScreen> {
  List<Map<String, dynamic>> _schools = []; // { ecoleId, name }
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final parentId = MainScreenWrapper.of(context).currentUserId ?? '';
      final infos = await DatabaseService.instance.getChildrenInfoByParent(parentId);
      final seen = <int>{};
      final list = <Map<String, dynamic>>[];
      for (final c in infos) {
        final ecoleId = c['ecoleId'] as int?;
        final name = c['establishment'] as String? ?? 'Établissement';
        if (ecoleId != null && !seen.contains(ecoleId)) {
          seen.add(ecoleId);
          list.add({'ecoleId': ecoleId, 'name': name});
        }
      }
      setState(() {
        _schools = list;
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
        appBar: AppBar(
          title: Text('Événements', style: TextStyle(color: AppColors.getTextColor(isDark))),
          backgroundColor: AppColors.getSurfaceColor(isDark),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_schools.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Événements', style: TextStyle(color: AppColors.getTextColor(isDark))),
          backgroundColor: AppColors.getSurfaceColor(isDark),
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'Aucun établissement. Ajoutez un enfant pour voir les événements.',
            style: TextStyle(color: AppColors.getTextColor(isDark)),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        title: Text('Événements', style: TextStyle(color: AppColors.getTextColor(isDark))),
        backgroundColor: AppColors.getSurfaceColor(isDark),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _schools.length,
          itemBuilder: (context, index) {
            final s = _schools[index];
            final ecoleId = s['ecoleId'] as int;
            final name = s['name'] as String;
            return CustomCard(
              margin: const EdgeInsets.only(bottom: 12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EventsScreen(ecoleId: ecoleId, establishmentName: name),
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Icon(Icons.event, color: AppColors.primary),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Voir les événements'),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        ),
      ),
    );
  }
}
