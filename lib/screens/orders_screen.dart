import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../config/app_colors.dart';
import '../widgets/custom_card.dart';
import 'order_detail_screen.dart';

/// Liste des commandes du parent
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final parentId = MainScreenWrapper.maybeOf(context)?.currentUserId ?? '';
      if (parentId.isNotEmpty) {
        try {
          final api = PoulsScolaireApiService();
          final fromApi = await api.getOrdersByParentId(parentId);
          if (fromApi.isNotEmpty) {
            final list = fromApi.map((o) => {
              'id': o['id'],
              'parentId': parentId,
              'childId': o['childId'],
              'statut': o['statut'] ?? o['status'] ?? 'PENDING',
              'total': (o['total'] as num?)?.toDouble(),
              'createdAt': o['createdAt'] is int ? o['createdAt'] : (o['createdAt'] is String ? DateTime.tryParse(o['createdAt'] as String)?.millisecondsSinceEpoch : null) ?? DateTime.now().millisecondsSinceEpoch,
              'updatedAt': o['updatedAt'] is int ? o['updatedAt'] : DateTime.now().millisecondsSinceEpoch,
            }).toList();
            await DatabaseService.instance.saveOrders(parentId, list);
          }
        } catch (e) {
          print('⚠️ getOrdersByParentId: $e');
        }
        final list = await DatabaseService.instance.getOrdersByParent(parentId);
        setState(() {
          _orders = list;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String statut) {
    switch (statut.toUpperCase()) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Mes commandes', style: TextStyle(color: AppColors.getTextColor(isDark))),
          backgroundColor: AppColors.getSurfaceColor(isDark),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        title: Text('Mes commandes', style: TextStyle(color: AppColors.getTextColor(isDark))),
        backgroundColor: AppColors.getSurfaceColor(isDark),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _orders.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.getTextColor(isDark, type: TextType.tertiary)),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune commande',
                      style: TextStyle(color: AppColors.getTextColor(isDark), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vos commandes de fournitures apparaîtront ici.',
                      style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final o = _orders[index];
                  final id = o['id'] as String? ?? '';
                  final statut = o['statut'] as String? ?? 'PENDING';
                  final total = (o['total'] as num?)?.toDouble();
                  final createdAt = o['createdAt'] as int?;
                  return CustomCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(order: o),
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _statusColor(statut).withOpacity(0.2),
                        child: Icon(Icons.receipt_long_outlined, color: _statusColor(statut), size: 22),
                      ),
                      title: Text(
                        'Commande #${id.length > 8 ? id.substring(0, 8) : id}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: createdAt != null
                          ? Text(
                              '${DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(createdAt))} · $statut',
                              style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary), fontSize: 13),
                            )
                          : Text(statut, style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary))),
                      trailing: total != null
                          ? Text(
                              '${total.toStringAsFixed(0)} F',
                              style: TextStyle(color: AppColors.getTextColor(isDark), fontWeight: FontWeight.w600),
                            )
                          : const Icon(Icons.chevron_right),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
