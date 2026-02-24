import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../config/app_colors.dart';
import '../widgets/custom_card.dart';

/// Liste des fournitures pour la classe d'un enfant
class SuppliesScreen extends StatefulWidget {
  final String childId;

  const SuppliesScreen({super.key, required this.childId});

  @override
  State<SuppliesScreen> createState() => _SuppliesScreenState();
}

class _SuppliesScreenState extends State<SuppliesScreen> {
  List<Map<String, dynamic>> _supplies = [];
  String _childName = '';
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
      final classeId = info?['classeId'] as int?;
      _childName = '${info?['firstName'] ?? ''} ${info?['lastName'] ?? ''}'.trim();
      if (classeId != null) {
        try {
          final api = PoulsScolaireApiService();
          final fromApi = await api.getSuppliesByClasseId(classeId);
          if (fromApi.isNotEmpty) {
            final list = fromApi.map((s) => {
              'id': s['id'],
              'classeId': classeId,
              'libelle': s['libelle'] ?? s['name'],
              'description': s['description'],
              'prix': s['prix'],
            }).toList();
            await db.saveSupplies(classeId, list);
          }
        } catch (e) {
          print('⚠️ getSuppliesByClasseId: $e');
        }
        final list = await db.getSuppliesByClasse(classeId);
        setState(() {
          _supplies = list;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
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
          title: Text(_childName.isNotEmpty ? _childName : 'Fournitures', style: TextStyle(color: AppColors.getTextColor(isDark), fontSize: 18)),
          backgroundColor: AppColors.getSurfaceColor(isDark),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        title: Text(_childName.isNotEmpty ? _childName : 'Fournitures', style: TextStyle(color: AppColors.getTextColor(isDark), fontSize: 18)),
        backgroundColor: AppColors.getSurfaceColor(isDark),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _supplies.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.backpack_outlined, size: 64, color: AppColors.getTextColor(isDark, type: TextType.tertiary)),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune fourniture listée',
                      style: TextStyle(color: AppColors.getTextColor(isDark), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'La liste des fournitures pour cette classe sera affichée ici.',
                      style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _supplies.length,
                itemBuilder: (context, index) {
                  final s = _supplies[index];
                  final libelle = s['libelle'] as String? ?? 'Article';
                  final description = s['description'] as String?;
                  final prix = (s['prix'] as num?)?.toDouble();
                  return CustomCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 22),
                      ),
                      title: Text(libelle, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: description != null && description.isNotEmpty
                          ? Text(description, style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary), fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)
                          : null,
                      trailing: prix != null
                          ? Text(
                              '${prix.toStringAsFixed(0)} FCFA',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                            )
                          : null,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
