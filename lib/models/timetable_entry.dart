// Import nécessaire pour TimeOfDay
import 'package:flutter/material.dart';

/// Modèle représentant une entrée d'emploi du temps
class TimetableEntry {
  final String id;
  final String childId;
  final String dayOfWeek; // Jour de la semaine
  final TimeOfDay startTime; // Heure de début
  final TimeOfDay endTime; // Heure de fin
  final String subject; // Matière
  final String? room; // Salle
  final String? teacher; // Professeur

  TimetableEntry({
    required this.id,
    required this.childId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.subject,
    this.room,
    this.teacher,
  });

  String get timeRange => '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    final startParts = (json['startTime'] as String).split(':');
    final endParts = (json['endTime'] as String).split(':');
    
    return TimetableEntry(
      id: json['id'] as String,
      childId: json['childId'] as String,
      dayOfWeek: json['dayOfWeek'] as String,
      startTime: TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      ),
      subject: json['subject'] as String,
      room: json['room'] as String?,
      teacher: json['teacher'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'dayOfWeek': dayOfWeek,
      'startTime': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      'endTime': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      'subject': subject,
      'room': room,
      'teacher': teacher,
    };
  }

  static const List<String> _days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

  static String _dayName(int? jourSemaine) {
    if (jourSemaine == null || jourSemaine < 1 || jourSemaine > 7) return 'Lundi';
    return _days[jourSemaine - 1];
  }

  static TimeOfDay _parseTime(String? s) {
    if (s == null || s.isEmpty) return const TimeOfDay(hour: 8, minute: 0);
    final parts = s.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? 8;
      final m = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
    }
    return const TimeOfDay(hour: 8, minute: 0);
  }

  /// Création depuis une ligne SQLite (timetable)
  factory TimetableEntry.fromDbMap(Map<String, dynamic> m, String childId) {
    final jour = m['jourSemaine'] as int? ?? 1;
    final start = _parseTime(m['heureDebut'] as String?);
    final end = _parseTime(m['heureFin'] as String?);
    return TimetableEntry(
      id: m['id'] as String? ?? '',
      childId: childId,
      dayOfWeek: _dayName(jour),
      startTime: start,
      endTime: end,
      subject: m['matiereNom'] as String? ?? '',
      room: m['salle'] as String?,
      teacher: m['professeur'] as String?,
    );
  }

  /// Conversion vers format SQLite pour saveTimetable
  Map<String, dynamic> toDbMap() {
    final dayIndex = _days.indexOf(dayOfWeek) + 1;
    return {
      'id': id,
      'childId': childId,
      'jourSemaine': dayIndex > 0 ? dayIndex : 1,
      'heureDebut': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      'heureFin': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      'matiereNom': subject,
      'salle': room,
      'professeur': teacher,
    };
  }
}

