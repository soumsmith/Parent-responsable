import 'package:flutter/material.dart';
import '../models/fee.dart';
import '../services/database_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/custom_card.dart';
import '../config/app_colors.dart';
import 'payment_history_screen.dart';
import 'payment_detail_screen.dart';

/// Écran des frais de scolarité : SQLite + API, résumé, alertes retard, historique
class FeesScreen extends StatefulWidget {
  final String childId;

  const FeesScreen({super.key, required this.childId});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  List<Fee> _fees = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFees();
  }

  Future<void> _loadFees() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final db = DatabaseService.instance;
      List<Fee> fromDb = [];
      try {
        final maps = await db.getFeesByChild(widget.childId);
        fromDb = maps.map((m) => Fee.fromDbMap(m)).toList();
      } catch (_) {}

      String? matricule;
      try {
        final info = await db.getChildInfoById(widget.childId);
        matricule = info?['matricule'] as String?;
      } catch (_) {}

      if (matricule != null && matricule.isNotEmpty) {
        final api = PoulsScolaireApiService();
        try {
          final feesApi = await api.getFeesByMatricule(matricule);
          final paymentsApi = await api.getPaymentsByMatricule(matricule);
          if (feesApi.isNotEmpty) {
            final toSave = feesApi.map((f) {
              final total = (f['montantTotal'] as num?)?.toDouble() ?? (f['amount'] as num?)?.toDouble() ?? 0;
              final paye = (f['montantPaye'] as num?)?.toDouble() ?? 0;
              return {
                'id': f['id'] as String? ?? 'fee_${widget.childId}_${f.hashCode}',
                'childId': widget.childId,
                'libelle': f['libelle'] as String? ?? f['type'] as String? ?? 'Frais',
                'montantTotal': total,
                'montantPaye': paye,
                'dateEcheance': f['dateEcheance'] ?? f['dueDate'],
                'statut': paye >= total ? 'PAID' : 'PENDING',
              };
            }).toList();
            await db.saveFees(widget.childId, toSave);
          }
          if (paymentsApi.isNotEmpty) {
            final toSave = paymentsApi.map((p) => {
              'id': p['id'] as String? ?? 'pay_${p.hashCode}',
              'feeId': p['feeId'],
              'childId': widget.childId,
              'montant': (p['montant'] as num?)?.toDouble() ?? 0,
              'datePaiement': p['datePaiement'] ?? DateTime.now().millisecondsSinceEpoch,
              'mode': p['mode'],
              'reference': p['reference'],
            }).toList();
            await db.savePayments(widget.childId, toSave);
          }
        } catch (e) {
          print('⚠️ Sync fees/payments API: $e');
        }
      }

      final maps = await db.getFeesByChild(widget.childId);
      final list = maps.map((m) => Fee.fromDbMap(m)).toList();

      setState(() {
        _fees = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Scolarité & Paiements', style: TextStyle(color: AppColors.getTextColor(isDark))), backgroundColor: AppColors.getSurfaceColor(isDark), elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Scolarité & Paiements', style: TextStyle(color: AppColors.getTextColor(isDark))), backgroundColor: AppColors.getSurfaceColor(isDark), elevation: 0),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Erreur: $_error'), const SizedBox(height: 16), ElevatedButton(onPressed: _loadFees, child: const Text('Réessayer'))])),
      );
    }

    final now = DateTime.now();
    final unpaidFees = _fees.where((f) => !f.isPaid).toList();
    final paidFees = _fees.where((f) => f.isPaid).toList();
    final hasRetard = unpaidFees.any((f) => f.dueDate.isBefore(now));
    final total = _fees.fold<double>(0, (s, f) => s + f.amount);
    final paye = _fees.fold<double>(0, (s, f) => s + (f.isPaid ? f.amount : 0));
    final reste = total - paye;

    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        title: Text('Scolarité & Paiements', style: TextStyle(color: AppColors.getTextColor(isDark))),
        backgroundColor: AppColors.getSurfaceColor(isDark),
        elevation: 0,
        actions: [
          if (hasRetard)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(12)),
                child: const Text('Retard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PaymentHistoryScreen(childId: widget.childId))),
            child: const Text('Historique'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFees,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomCard(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Résumé', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark))),
                    const SizedBox(height: 12),
                    _buildSummaryRow(isDark, 'Montant total', '$total FCFA'),
                    _buildSummaryRow(isDark, 'Montant payé', '$paye FCFA', color: AppColors.success),
                    _buildSummaryRow(isDark, 'Reste à payer', '$reste FCFA', color: reste > 0 ? AppColors.warning : null),
                  ],
                ),
              ),
            ),
            if (unpaidFees.isNotEmpty) ...[
              Text('Frais à régler', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark))),
              const SizedBox(height: 8),
              ...unpaidFees.map((fee) => _buildFeeCard(context, fee, isDark, hasRetard: fee.dueDate.isBefore(now))),
              const SizedBox(height: 24),
            ],
            if (paidFees.isNotEmpty) ...[
              Text('Frais payés', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark))),
              const SizedBox(height: 8),
              ...paidFees.map((fee) => _buildFeeCard(context, fee, isDark)),
            ],
            if (_fees.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('Aucun frais enregistré', style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary))),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(bool isDark, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary))),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color ?? AppColors.getTextColor(isDark))),
        ],
      ),
    );
  }

  Widget _buildFeeCard(BuildContext context, Fee fee, bool isDark, {bool hasRetard = false}) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PaymentDetailScreen(childId: widget.childId, fee: fee))),
      backgroundColor: fee.isPaid ? AppColors.successSurface : (hasRetard ? AppColors.errorSurface : Colors.orange.shade50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(fee.type, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark)))),
              if (hasRetard) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(12)), child: const Text('Retard', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: fee.isPaid ? AppColors.success : AppColors.warning, borderRadius: BorderRadius.circular(20)),
                child: Text(fee.isPaid ? 'Payé' : 'Non payé', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Montant: ${fee.amount.toStringAsFixed(0)} FCFA', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark))),
          const SizedBox(height: 4),
          Text('Échéance: ${_formatDate(fee.dueDate)}', style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary))),
          if (fee.isPaid && fee.paidDate != null) ...[
            const SizedBox(height: 4),
            Text('Payé le ${_formatDate(fee.paidDate!)}', style: TextStyle(color: AppColors.success, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
