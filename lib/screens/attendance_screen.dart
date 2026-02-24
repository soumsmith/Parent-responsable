import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../config/app_colors.dart';
import '../widgets/custom_card.dart';

/// Présence : taux et liste des absences
class AttendanceScreen extends StatefulWidget {
  final String childId;

  const AttendanceScreen({super.key, required this.childId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
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
          final fromApi = await api.getAttendanceByMatricule(matricule);
          if (fromApi.isNotEmpty) {
            final toSave = fromApi.map((a) => {
              'id': a['id'] ?? 'att_${widget.childId}_${a['date']}',
              'childId': widget.childId,
              'date': a['date'] ?? a['dateDebut'] ?? DateTime.now().millisecondsSinceEpoch,
              'statut': a['statut'] ?? a['status'] ?? 'ABSENT',
              'motif': a['motif'] ?? a['reason'],
            }).toList();
            await db.saveAttendance(widget.childId, toSave);
          }
        } catch (e) {
          print('⚠️ getAttendanceByMatricule: $e');
        }
      }
      final maps = await db.getAttendanceByChild(widget.childId);
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
    final total = _list.length;
    final absences = _list.where((e) => (e['statut'] as String? ?? '').toUpperCase().contains('ABSENT')).length;
    final taux = total > 0 ? ((total - absences) / total * 100).toStringAsFixed(1) : '—';

    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        title: Text('Présence', style: TextStyle(color: AppColors.getTextColor(isDark))),
        backgroundColor: AppColors.getSurfaceColor(isDark),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  CustomCard(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text('Taux de présence', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.getTextColor(isDark))),
                          const SizedBox(height: 8),
                          Text('$taux %', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(height: 4),
                          Text('$absences absence(s) sur $total jour(s)', style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary))),
                        ],
                      ),
                    ),
                  ),
                  Text('Liste des absences', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark))),
                  const SizedBox(height: 8),
                  if (_list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text('Aucune donnée', style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary)))),
                    )
                  else
                    ..._list.where((e) => (e['statut'] as String? ?? '').toUpperCase().contains('ABSENT')).map((e) {
                      final dateMs = e['date'] as int?;
                      final date = dateMs != null ? DateTime.fromMillisecondsSinceEpoch(dateMs) : null;
                      return CustomCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.event_busy, color: AppColors.warning),
                          title: Text(date != null ? '${date.day}/${date.month}/${date.year}' : '—'),
                          subtitle: Text(e['motif'] as String? ?? e['statut'] as String? ?? ''),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
