import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_colors.dart';
import '../widgets/custom_card.dart';

/// Affichage du ticket (QR, infos événement)
class TicketScreen extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final Map<String, dynamic> event;
  final String establishmentName;

  const TicketScreen({
    super.key,
    required this.ticket,
    required this.event,
    required this.establishmentName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = event['title'] as String? ?? 'Événement';
    final dateDebut = event['dateDebut'] as int?;
    final lieu = event['lieu'] as String?;
    final qrCode = ticket['qrCode'] as String?;

    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        title: Text('Mon ticket', style: TextStyle(color: AppColors.getTextColor(isDark))),
        backgroundColor: AppColors.getSurfaceColor(isDark),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomCard(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Icon(Icons.confirmation_number, size: 48, color: AppColors.primary),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.getTextColor(isDark), fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    establishmentName,
                    style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary)),
                  ),
                  if (dateDebut != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.fromMillisecondsSinceEpoch(dateDebut)),
                      style: TextStyle(color: AppColors.getTextColor(isDark)),
                    ),
                  ],
                  if (lieu != null && lieu.isNotEmpty)
                    Text(lieu, style: TextStyle(color: AppColors.getTextColor(isDark))),
                ],
              ),
            ),
            if (qrCode != null && qrCode.isNotEmpty) ...[
              Text(
                'Code d\'entrée',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.getTextColor(isDark)),
              ),
              const SizedBox(height: 8),
              CustomCard(
                child: SelectableText(
                  qrCode,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 14, color: AppColors.getTextColor(isDark)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Présentez ce code à l\'entrée.',
                style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary), fontSize: 13),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Votre réservation est enregistrée.',
                  style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
