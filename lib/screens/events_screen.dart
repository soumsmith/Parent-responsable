import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../config/app_colors.dart';
import '../widgets/custom_card.dart';
import 'event_detail_screen.dart';

/// Liste des événements d'un établissement
class EventsScreen extends StatefulWidget {
  final int ecoleId;
  final String establishmentName;

  const EventsScreen({super.key, required this.ecoleId, required this.establishmentName});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      try {
        final api = PoulsScolaireApiService();
        final fromApi = await api.getEventsByEcoleId(widget.ecoleId);
        if (fromApi.isNotEmpty) {
          final list = fromApi.map((e) {
            final deb = e['dateDebut']; final fin = e['dateFin'];
            return {
              'id': e['id'],
              'ecoleId': widget.ecoleId,
              'title': e['title'] ?? e['nom'],
              'description': e['description'],
              'dateDebut': deb is int ? deb : (deb is String ? DateTime.tryParse(deb)?.millisecondsSinceEpoch : null) ?? DateTime.now().millisecondsSinceEpoch,
              'dateFin': fin is int ? fin : (fin is String ? DateTime.tryParse(fin)?.millisecondsSinceEpoch : null),
              'lieu': e['lieu'],
              'type': e['type'],
            };
          }).toList();
          await DatabaseService.instance.saveEvents(widget.ecoleId, list);
        }
      } catch (e) {
        print('⚠️ getEventsByEcoleId: $e');
      }
      final list = await DatabaseService.instance.getEventsByEcole(widget.ecoleId);
      setState(() {
        _events = list;
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
          title: Text(widget.establishmentName, style: TextStyle(color: AppColors.getTextColor(isDark), fontSize: 18)),
          backgroundColor: AppColors.getSurfaceColor(isDark),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        title: Text(widget.establishmentName, style: TextStyle(color: AppColors.getTextColor(isDark), fontSize: 18)),
        backgroundColor: AppColors.getSurfaceColor(isDark),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _events.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_available, size: 64, color: AppColors.getTextColor(isDark, type: TextType.tertiary)),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun événement',
                      style: TextStyle(color: AppColors.getTextColor(isDark), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final e = _events[index];
                  final id = e['id'] as String? ?? '';
                  final title = e['title'] as String? ?? 'Événement';
                  final dateDebut = e['dateDebut'] as int?;
                  final type = e['type'] as String? ?? '';
                  return CustomCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EventDetailScreen(
                          event: e,
                          establishmentName: widget.establishmentName,
                          onTicketCreated: _load,
                        ),
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Icon(Icons.calendar_today, color: AppColors.primary, size: 22),
                      ),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: dateDebut != null
                          ? Text(
                              '${DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(dateDebut))}${type.isNotEmpty ? ' · $type' : ''}',
                              style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary), fontSize: 13),
                            )
                          : null,
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
