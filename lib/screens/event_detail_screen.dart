import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../config/app_colors.dart';
import '../widgets/custom_card.dart';
import 'ticket_screen.dart';

/// Détail d'un événement + bouton pour obtenir un ticket
class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  final String establishmentName;
  final VoidCallback? onTicketCreated;

  const EventDetailScreen({
    super.key,
    required this.event,
    required this.establishmentName,
    this.onTicketCreated,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _loadingTicket = false;

  Future<void> _obtainTicket() async {
    if (_loadingTicket) return;
    final parentId = MainScreenWrapper.maybeOf(context)?.currentUserId ?? '';
    if (parentId.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non connecté')));
      return;
    }
    setState(() => _loadingTicket = true);
    try {
      final api = PoulsScolaireApiService();
      final eventId = widget.event['id'] as String? ?? '';
      final result = await api.postEventTicket(eventId, parentId);
      if (result != null && mounted) {
        final ticket = {
          'id': result['id'] ?? 'ticket_${eventId}_$parentId',
          'eventId': eventId,
          'parentId': parentId,
          'childId': result['childId'],
          'qrCode': result['qrCode'] ?? result['qrData'],
          'createdAt': result['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
        };
        await DatabaseService.instance.saveTicket(ticket);
        widget.onTicketCreated?.call();
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TicketScreen(ticket: ticket, event: widget.event, establishmentName: widget.establishmentName),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'obtenir le ticket')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
    if (mounted) setState(() => _loadingTicket = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final e = widget.event;
    final title = e['title'] as String? ?? 'Événement';
    final description = e['description'] as String?;
    final dateDebut = e['dateDebut'] as int?;
    final dateFin = e['dateFin'] as int?;
    final lieu = e['lieu'] as String?;
    final type = e['type'] as String?;

    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        title: Text(title, style: TextStyle(color: AppColors.getTextColor(isDark), fontSize: 18)),
        backgroundColor: AppColors.getSurfaceColor(isDark),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (type != null && type.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Chip(
                label: Text(type),
                backgroundColor: AppColors.primary.withOpacity(0.2),
                side: BorderSide.none,
              ),
            ),
          if (dateDebut != null)
            _DetailRow(
              icon: Icons.calendar_today,
              label: 'Date',
              value: dateFin != null
                  ? '${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(dateDebut))} - ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(dateFin))}'
                  : DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(dateDebut)),
              isDark: isDark,
            ),
          if (lieu != null && lieu.isNotEmpty)
            _DetailRow(icon: Icons.place, label: 'Lieu', value: lieu, isDark: isDark),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Description', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.getTextColor(isDark))),
            const SizedBox(height: 4),
            Text(description, style: TextStyle(color: AppColors.getTextColor(isDark), height: 1.4)),
          ],
          const SizedBox(height: 24),
          CustomCard(
            child: Column(
              children: [
                Text(
                  'Participer à cet événement',
                  style: TextStyle(color: AppColors.getTextColor(isDark), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _loadingTicket ? null : _obtainTicket,
                  icon: _loadingTicket ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.confirmation_number_outlined),
                  label: Text(_loadingTicket ? 'Réservation...' : 'Obtenir un ticket'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({required this.icon, required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary), fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: AppColors.getTextColor(isDark), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
