import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../config/app_colors.dart';
import '../widgets/custom_card.dart';

/// Élève en difficulté : analyse des risques par matière, graphique et recommandations
class StudentRiskScreen extends StatefulWidget {
  final String childId;

  const StudentRiskScreen({super.key, required this.childId});

  @override
  State<StudentRiskScreen> createState() => _StudentRiskScreenState();
}

class _StudentRiskScreenState extends State<StudentRiskScreen> {
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;

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
      final matricule = info?['matricule'] as String?;
      if (matricule != null && matricule.isNotEmpty) {
        try {
          final api = PoulsScolaireApiService();
          final fromApi = await api.getRiskAnalysisByMatricule(matricule);
          if (fromApi.isNotEmpty) {
            final toSave = fromApi.map((a) => {
              'id': a['id'] ?? 'risk_${widget.childId}_${a['matiereNom'] ?? a['matiere']}',
              'matiereNom': a['matiereNom'] ?? a['matiere'] ?? '',
              'score': (a['score'] as num?)?.toDouble() ?? (a['note'] as num?)?.toDouble(),
              'recommandation': a['recommandation'] ?? a['recommendation'] ?? '',
            }).toList();
            await db.saveRiskAlerts(widget.childId, toSave);
          }
        } catch (e) {
          print('⚠️ getRiskAnalysisByMatricule: $e');
        }
      }
      final list = await db.getRiskAlertsByChild(widget.childId);
      setState(() {
        _alerts = list;
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
          title: Text('Élève en difficulté', style: TextStyle(color: AppColors.getTextColor(isDark))),
          backgroundColor: AppColors.getSurfaceColor(isDark),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final hasAlerts = _alerts.isNotEmpty;
    final barGroups = _alerts.asMap().entries.map((e) {
      final score = (e.value['score'] as num?)?.toDouble() ?? 0;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: score.clamp(0.0, 20.0),
            color: score < 10 ? AppColors.error : (score < 12 ? Colors.orange : AppColors.primary),
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        title: Text('Élève en difficulté', style: TextStyle(color: AppColors.getTextColor(isDark))),
        backgroundColor: AppColors.getSurfaceColor(isDark),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!hasAlerts)
              CustomCard(
                margin: const EdgeInsets.only(bottom: 16),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline, size: 48, color: AppColors.primary),
                        const SizedBox(height: 12),
                        Text(
                          'Aucune alerte pour le moment',
                          style: TextStyle(color: AppColors.getTextColor(isDark), fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Les matières en difficulté apparaîtront ici après analyse.',
                          style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary), fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              Text(
                'Scores par matière (sur 20)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.getTextColor(isDark)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 20,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipRoundedRadius: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final label = _alerts.isNotEmpty && group.x < _alerts.length
                              ? (_alerts[group.x]['matiereNom'] as String? ?? 'Matière ${group.x + 1}')
                              : 'Matière';
                          return BarTooltipItem(
                            '$label\n${rod.toY.toStringAsFixed(1)}/20',
                            TextStyle(color: AppColors.getTextColor(isDark), fontSize: 12),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < _alerts.length) {
                              final nom = _alerts[value.toInt()]['matiereNom'] as String? ?? '';
                              final short = nom.length > 8 ? '${nom.substring(0, 7)}.' : nom;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  short,
                                  style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary), fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          reservedSize: 28,
                          interval: 1,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: 5,
                          getTitlesWidget: (value, meta) => Text(
                            value.toInt().toString(),
                            style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary), fontSize: 11),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: AppColors.getBorderColor(isDark).withOpacity(0.3))),
                    barGroups: barGroups,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Recommandations',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.getTextColor(isDark)),
              ),
              const SizedBox(height: 8),
              ..._alerts.map((a) {
                final matiere = a['matiereNom'] as String? ?? 'Matière';
                final score = (a['score'] as num?)?.toDouble();
                final rec = a['recommandation'] as String? ?? '';
                return CustomCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            score != null && score < 10 ? Icons.warning_amber_rounded : Icons.info_outline,
                            color: score != null && score < 10 ? AppColors.error : AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(matiere, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          if (score != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (score < 10 ? AppColors.error : (score < 12 ? Colors.orange : AppColors.primary)).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('${score.toStringAsFixed(1)}/20', style: TextStyle(fontWeight: FontWeight.w600, color: score < 10 ? AppColors.error : AppColors.primary)),
                            ),
                        ],
                      ),
                      if (rec.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(rec, style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary), fontSize: 14)),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
