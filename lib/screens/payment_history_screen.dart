import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../config/app_colors.dart';
import '../widgets/custom_card.dart';

/// Historique des paiements pour un enfant
class PaymentHistoryScreen extends StatefulWidget {
  final String childId;

  const PaymentHistoryScreen({super.key, required this.childId});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final list = await DatabaseService.instance.getPaymentsByChild(widget.childId);
      setState(() {
        _payments = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        title: Text('Historique des paiements', style: TextStyle(color: AppColors.getTextColor(isDark))),
        backgroundColor: AppColors.getSurfaceColor(isDark),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? Center(
                  child: Text(
                    'Aucun paiement enregistré',
                    style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary)),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _payments.length,
                    itemBuilder: (context, index) {
                      final p = _payments[index];
                      final montant = (p['montant'] as num?)?.toDouble() ?? 0;
                      final dateMs = p['datePaiement'] as int?;
                      final date = dateMs != null ? DateTime.fromMillisecondsSinceEpoch(dateMs) : null;
                      return CustomCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text('${montant.toStringAsFixed(0)} FCFA', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(date != null ? '${date.day}/${date.month}/${date.year}' : '—'),
                          trailing: Text(p['mode'] as String? ?? p['reference'] as String? ?? '', style: TextStyle(fontSize: 12, color: AppColors.getTextColor(isDark, type: TextType.secondary))),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
