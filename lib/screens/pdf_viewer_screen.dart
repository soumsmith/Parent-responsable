import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_colors.dart';
import '../widgets/custom_card.dart';

/// Affichage du bulletin : lien PDF + QR code (texte ou placeholder)
class PdfViewerScreen extends StatelessWidget {
  final String title;
  final String? fileUrl;
  final String? qrData;

  const PdfViewerScreen({super.key, required this.title, this.fileUrl, this.qrData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        title: Text(title, style: TextStyle(color: AppColors.getTextColor(isDark), fontSize: 18)),
        backgroundColor: AppColors.getSurfaceColor(isDark),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (fileUrl != null && fileUrl!.isNotEmpty) ...[
              CustomCard(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.picture_as_pdf, color: Colors.white)),
                  title: const Text('Ouvrir le bulletin PDF'),
                  subtitle: Text(fileUrl!.length > 50 ? '${fileUrl!.substring(0, 50)}...' : fileUrl!),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () async {
                    final uri = Uri.tryParse(fileUrl!);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir le lien')));
                    }
                  },
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text('Aucun PDF disponible pour cette période.', style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary))),
              ),
            if (qrData != null && qrData!.isNotEmpty) ...[
              Text('QR Code de vérification', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.getTextColor(isDark))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.getSurfaceColor(isDark),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.getBorderColor(isDark)),
                ),
                child: SelectableText(qrData!, style: TextStyle(fontSize: 12, color: AppColors.getTextColor(isDark))),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
