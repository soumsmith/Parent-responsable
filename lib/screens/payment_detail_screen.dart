import 'package:flutter/material.dart';
import '../models/fee.dart';
import '../services/database_service.dart';
import '../config/app_colors.dart';

/// Détail d'un frais et des paiements associés
class PaymentDetailScreen extends StatelessWidget {
  final String childId;
  final Fee fee;

  const PaymentDetailScreen({super.key, required this.childId, required this.fee});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        title: Text(fee.type, style: TextStyle(color: AppColors.getTextColor(isDark))),
        backgroundColor: AppColors.getSurfaceColor(isDark),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseService.instance.getPaymentsByChild(childId),
        builder: (context, snapshot) {
          final payments = snapshot.data ?? [];
          final forThisFee = payments.where((p) => p['feeId'] == fee.id).toList();
          if (forThisFee.isEmpty && payments.isNotEmpty) {
            forThisFee.addAll(payments.take(5));
          } else if (payments.isEmpty) {
            forThisFee.addAll([]);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(context, isDark, 'Montant total', '${fee.amount.toStringAsFixed(0)} FCFA'),
                const SizedBox(height: 8),
                _row(context, isDark, 'Échéance', '${fee.dueDate.day}/${fee.dueDate.month}/${fee.dueDate.year}'),
                _row(context, isDark, 'Statut', fee.isPaid ? 'Payé' : 'Non payé'),
                if (forThisFee.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Paiements', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark))),
                  const SizedBox(height: 8),
                  ...forThisFee.map((p) {
                    final montant = (p['montant'] as num?)?.toDouble() ?? 0;
                    final dateMs = p['datePaiement'] as int?;
                    final date = dateMs != null ? DateTime.fromMillisecondsSinceEpoch(dateMs) : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${montant.toStringAsFixed(0)} FCFA', style: TextStyle(color: AppColors.getTextColor(isDark))),
                          Text(date != null ? '${date.day}/${date.month}/${date.year}' : '', style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary))),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, bool isDark, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary))),
        Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.getTextColor(isDark))),
      ],
    );
  }
}
