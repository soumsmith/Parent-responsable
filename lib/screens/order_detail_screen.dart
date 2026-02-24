import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_colors.dart';
import '../widgets/custom_card.dart';

/// Détail d'une commande
class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final id = order['id'] as String? ?? '—';
    final statut = order['statut'] as String? ?? 'PENDING';
    final total = (order['total'] as num?)?.toDouble();
    final createdAt = order['createdAt'] as int?;
    final childId = order['childId'] as String?;

    Color statusColor(String s) {
      switch (s.toUpperCase()) {
        case 'DELIVERED':
        case 'LIVREE':
          return AppColors.primary;
        case 'CANCELLED':
        case 'ANNULEE':
          return AppColors.error;
        default:
          return Colors.orange;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        title: Text('Détail commande', style: TextStyle(color: AppColors.getTextColor(isDark))),
        backgroundColor: AppColors.getSurfaceColor(isDark),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CustomCard(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Commande ', style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary))),
                    Expanded(child: SelectableText(id, style: TextStyle(color: AppColors.getTextColor(isDark), fontWeight: FontWeight.w600))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Statut : ', style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor(statut).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(statut, style: TextStyle(color: statusColor(statut), fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                if (createdAt != null) ...[
                  const SizedBox(height: 12),
                  Text('Date : ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.fromMillisecondsSinceEpoch(createdAt))}', style: TextStyle(color: AppColors.getTextColor(isDark))),
                ],
                if (childId != null && childId.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Élève : $childId', style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary), fontSize: 13)),
                ],
                if (total != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: TextStyle(color: AppColors.getTextColor(isDark), fontWeight: FontWeight.w600)),
                      Text('${total.toStringAsFixed(0)} FCFA', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
