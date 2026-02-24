import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../config/app_colors.dart';
import '../widgets/custom_card.dart';

/// Conduite : liste des sanctions
class DisciplineScreen extends StatefulWidget {
  final String childId;

  const DisciplineScreen({super.key, required this.childId});

  @override
  State<DisciplineScreen> createState() => _DisciplineScreenState();
}

class _DisciplineScreenState extends State<DisciplineScreen> {
  List<Map<String, dynamic>> _list = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseService.instance;
      final info = await db.getChildInfoById(widget.childId);
      final matricule = info?['matricule'] as String?;
      if (matricule != null && matricule.isNotEmpty) {
        try {
          final api = PoulsScolaireApiService();
          final fromApi = await api.getSanctionsByMatricule(matricule);
          if (fromApi.isNotEmpty) {
            final toSave = fromApi.map((s) => {
              'id': s['id'] ?? 'sanct_${widget.childId}_${s['dateSanction']}',
              'childId': widget.childId,
              'type': s['type'],
              'libelle': s['libelle'] ?? s['title'],
              'dateSanction': s['dateSanction'] ?? s['date'] ?? DateTime.now().millisecondsSinceEpoch,
              'description': s['description'],
            }).toList();
            await db.saveSanctions(widget.childId, toSave);
          }
        } catch (e) {
          print('⚠️ getSanctionsByMatricule: $e');
        }
      }
      final maps = await db.getSanctionsByChild(widget.childId);
      setState(() {
        _list = maps;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        title: Text('Conduite', style: TextStyle(color: AppColors.getTextColor(isDark))),
        backgroundColor: AppColors.getSurfaceColor(isDark),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? Center(
                  child: Text(
                    'Aucune sanction enregistrée',
                    style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary)),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.length,
                    itemBuilder: (context, index) {
                      final s = _list[index];
                      final dateMs = s['dateSanction'] as int?;
                      final date = dateMs != null ? DateTime.fromMillisecondsSinceEpoch(dateMs) : null;
                      return CustomCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: AppColors.warning.withOpacity(0.2), child: const Icon(Icons.gavel, color: AppColors.warning, size: 20)),
                          title: Text(s['libelle'] as String? ?? s['type'] as String? ?? 'Sanction', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(s['description'] as String? ?? ''),
                          trailing: Text(date != null ? '${date.day}/${date.month}/${date.year}' : '', style: TextStyle(fontSize: 12, color: AppColors.getTextColor(isDark, type: TextType.secondary))),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
