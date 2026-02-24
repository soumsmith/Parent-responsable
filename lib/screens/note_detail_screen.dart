import 'package:flutter/material.dart';
import '../models/note_api.dart';
import '../config/app_colors.dart';

/// Écran de détail d'une note
class NoteDetailScreen extends StatelessWidget {
  final NoteApi note;
  final String childName;

  const NoteDetailScreen({
    super.key,
    required this.note,
    this.childName = '',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        title: Text('Détail de la note', style: TextStyle(color: AppColors.getTextColor(isDark))),
        backgroundColor: AppColors.getSurfaceColor(isDark),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.getTextColor(isDark)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (childName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(childName, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.getTextColor(isDark, type: TextType.secondary))),
              ),
            _buildRow(context, isDark, 'Matière', note.matiereLibelle ?? '—'),
            const SizedBox(height: 12),
            _buildRow(context, isDark, 'Note', '${note.note ?? 0} / ${note.noteSur ?? 20}'),
            const SizedBox(height: 12),
            _buildRow(context, isDark, 'Coefficient', '${note.coef ?? 1}'),
            if (note.dateNote != null) ...[
              const SizedBox(height: 12),
              _buildRow(context, isDark, 'Date', note.dateNote!),
            ],
            if (note.moyenne != null) ...[
              const SizedBox(height: 12),
              _buildRow(context, isDark, 'Moyenne de la classe', '${note.moyenne}'),
            ],
            if (note.rang != null) ...[
              const SizedBox(height: 12),
              _buildRow(context, isDark, 'Rang', '${note.rang}'),
            ],
            if (note.effectif != null) ...[
              const SizedBox(height: 12),
              _buildRow(context, isDark, 'Effectif', '${note.effectif}'),
            ],
            if (note.appreciation != null && note.appreciation!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Appréciation', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.getTextColor(isDark, type: TextType.secondary))),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.getSurfaceColor(isDark),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.getBorderColor(isDark)),
                ),
                child: Text(note.appreciation!, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.getTextColor(isDark))),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, bool isDark, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 140, child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.getTextColor(isDark, type: TextType.secondary)))),
        Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.getTextColor(isDark), fontWeight: FontWeight.w500))),
      ],
    );
  }
}
