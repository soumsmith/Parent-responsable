import 'package:flutter/material.dart';
import '../models/timetable_entry.dart';
import '../services/database_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/custom_card.dart';
import '../config/app_colors.dart';

/// Écran d'affichage de l'emploi du temps (SQLite + API)
class TimetableScreen extends StatefulWidget {
  final String childId;

  const TimetableScreen({super.key, required this.childId});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  List<TimetableEntry> _timetable = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  static const List<String> _days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

  Future<void> _loadTimetable() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseService.instance;
      final info = await db.getChildInfoById(widget.childId);
      final matricule = info?['matricule'] as String?;
      if (matricule != null && matricule.isNotEmpty) {
        try {
          final api = PoulsScolaireApiService();
          final fromApi = await api.getTimetableByMatricule(matricule);
          if (fromApi.isNotEmpty) {
            final toSave = fromApi.map((t) {
              final dayStr = t['dayOfWeek'] as String? ?? t['jour'] as String? ?? 'Lundi';
              final jourSemaine = _days.indexOf(dayStr) + 1;
              if (jourSemaine <= 0) return null;
              return {
                'id': t['id'] ?? 'tt_${widget.childId}_${jourSemaine}_${t['heureDebut']}_${t.hashCode}',
                'childId': widget.childId,
                'jourSemaine': jourSemaine,
                'heureDebut': t['heureDebut'] ?? t['startTime'] ?? '08:00',
                'heureFin': t['heureFin'] ?? t['endTime'] ?? '09:00',
                'matiereNom': t['matiereNom'] ?? t['subject'] ?? '',
                'salle': t['salle'] ?? t['room'],
                'professeur': t['professeur'] ?? t['teacher'],
              };
            }).whereType<Map<String, dynamic>>().toList();
            if (toSave.isNotEmpty) await db.saveTimetable(widget.childId, toSave);
          }
        } catch (e) {
          print('⚠️ getTimetableByMatricule: $e');
        }
      }
      final maps = await db.getTimetableByChild(widget.childId);
      final list = maps.map((m) => TimetableEntry.fromDbMap(m, widget.childId)).toList();
      setState(() {
        _timetable = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        title: Text('Emploi du temps', style: TextStyle(color: AppColors.getTextColor(isDark))),
        backgroundColor: AppColors.getSurfaceColor(isDark),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _timetable.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 64, color: AppColors.getTextColor(isDark, type: TextType.secondary)),
                      const SizedBox(height: 16),
                      Text('Aucun emploi du temps disponible', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.getTextColor(isDark))),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTimetable,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.getSurfaceColor(isDark),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.getBorderColor(isDark)),
                          ),
                          child: Text(
                            'Merci de vous impliquer dans le suivi scolaire de votre enfant.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.getTextColor(isDark)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._buildTimetableByDay(),
                      ],
                    ),
                  ),
                ),
    );
  }

  List<Widget> _buildTimetableByDay() {
    // Grouper par jour
    final Map<String, List<TimetableEntry>> byDay = {};
    for (var entry in _timetable) {
      byDay.putIfAbsent(entry.dayOfWeek, () => []).add(entry);
    }

    // Trier les jours
    final dayOrder = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final sortedDays = byDay.keys.toList()
      ..sort((a, b) => dayOrder.indexOf(a).compareTo(dayOrder.indexOf(b)));

    return sortedDays.map((day) {
      final entries = byDay[day]!..sort((a, b) => a.startTime.hour.compareTo(b.startTime.hour));
      
      return CustomCard(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              day,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
            ...entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 100,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD), // Bleu clair
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue, width: 1),
                        ),
                        child: Text(
                          entry.timeRange,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.subject,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (entry.room != null)
                              Text(
                                'Salle: ${entry.room}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            if (entry.teacher != null)
                              Text(
                                entry.teacher!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );
    }).toList();
  }
}

