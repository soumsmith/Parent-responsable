import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../config/app_colors.dart';
import '../widgets/custom_card.dart';
import 'pdf_viewer_screen.dart';

/// Bulletin PDF : sélection période, vérification solde, ouverture PDF + QR
class ReportCardScreen extends StatefulWidget {
  final String childId;

  const ReportCardScreen({super.key, required this.childId});

  @override
  State<ReportCardScreen> createState() => _ReportCardScreenState();
}

class _ReportCardScreenState extends State<ReportCardScreen> {
  List<Map<String, dynamic>> _periodes = [];
  bool _isLoading = true;
  double _resteApayer = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseService.instance;
      final info = await db.getChildInfoById(widget.childId);
      final ecoleId = info?['ecoleId'] as int?;
      final matricule = info?['matricule'] as String?;

      double reste = 0;
      try {
        final fees = await db.getFeesByChild(widget.childId);
        for (final f in fees) {
          final total = (f['montantTotal'] as num?)?.toDouble() ?? 0;
          final paye = (f['montantPaye'] as num?)?.toDouble() ?? 0;
          reste += (total - paye);
        }
      } catch (_) {}

      List<Map<String, dynamic>> periodes = [];
      if (ecoleId != null && matricule != null) {
        try {
          final api = PoulsScolaireApiService();
          final annee = await api.getAnneeScolaireOuverte(ecoleId);
          final periodesList = await api.getAllPeriodes();
          periodes = periodesList.asMap().entries.map((e) => {'id': e.value.id, 'libelle': e.value.libelle}).toList();
        } catch (_) {}
      }

      setState(() {
        _periodes = periodes;
        _resteApayer = reste;
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
        appBar: AppBar(title: Text('Bulletin', style: TextStyle(color: AppColors.getTextColor(isDark))), backgroundColor: AppColors.getSurfaceColor(isDark), elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final blocage = _resteApayer > 0;

    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        title: Text('Bulletin PDF', style: TextStyle(color: AppColors.getTextColor(isDark))),
        backgroundColor: AppColors.getSurfaceColor(isDark),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (blocage) ...[
            CustomCard(
              margin: const EdgeInsets.only(bottom: 16),
              backgroundColor: AppColors.errorSurface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.block, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Accès bloqué', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.error, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Un solde de ${_resteApayer.toStringAsFixed(0)} FCFA est dû. Veuillez régler les frais pour accéder au bulletin.', style: TextStyle(color: AppColors.getTextColor(isDark))),
                  ],
                ),
              ),
            ),
          ],
          if (_periodes.isEmpty && !blocage)
            Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Aucune période disponible', style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary)))))
          else
            ..._periodes.map((p) {
              final periodeId = p['id'] as int?;
              final libelle = p['libelle'] as String? ?? 'Période';
              return CustomCard(
                margin: const EdgeInsets.only(bottom: 12),
                onTap: blocage
                    ? null
                    : () => _openReport(context, periodeId, libelle, isDark),
                child: ListTile(
                  title: Text(libelle),
                  trailing: blocage ? const Icon(Icons.lock) : const Icon(Icons.picture_as_pdf),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _openReport(BuildContext context, int? periodeId, String libelle, bool isDark) async {
    try {
      final db = DatabaseService.instance;
      final info = await db.getChildInfoById(widget.childId);
      final matricule = info?['matricule'] as String?;
      if (matricule == null) return;
      final api = PoulsScolaireApiService();
      final data = await api.getReportCardByMatricule(matricule, periodeId: periodeId);
      final url = data?['fileUrl'] as String? ?? data?['url'] as String?;
      final qrData = data?['qrData'] as String? ?? data?['qrCode'] as String?;
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(
            title: 'Bulletin $libelle',
            fileUrl: url,
            qrData: qrData,
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }
}
