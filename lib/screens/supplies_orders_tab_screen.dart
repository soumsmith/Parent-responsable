import 'package:flutter/material.dart';
import '../models/child.dart';
import '../services/database_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../config/app_colors.dart';
import '../widgets/custom_card.dart';
import 'supplies_screen.dart';
import 'orders_screen.dart';

/// Point d'entrée Fournitures & commandes : Mes commandes + Fournitures par élève
class SuppliesOrdersTabScreen extends StatefulWidget implements MainScreenChild {
  const SuppliesOrdersTabScreen({super.key});

  @override
  State<SuppliesOrdersTabScreen> createState() => _SuppliesOrdersTabScreenState();
}

class _SuppliesOrdersTabScreenState extends State<SuppliesOrdersTabScreen> {
  List<Child> _children = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final parentId = MainScreenWrapper.of(context).currentUserId ?? '';
      final list = await DatabaseService.instance.getChildrenByParent(parentId);
      setState(() {
        _children = list;
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
        title: Text('Fournitures & commandes', style: TextStyle(color: AppColors.getTextColor(isDark))),
        backgroundColor: AppColors.getSurfaceColor(isDark),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  CustomCard(
                    margin: const EdgeInsets.only(bottom: 16),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OrdersScreen()),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Icon(Icons.shopping_cart_outlined, color: AppColors.primary),
                      ),
                      title: Text('Mes commandes', style: TextStyle(color: AppColors.getTextColor(isDark), fontWeight: FontWeight.w600)),
                      subtitle: Text('Voir l\'état de vos commandes', style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary), fontSize: 13)),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Fournitures par élève',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.getTextColor(isDark)),
                    ),
                  ),
                  if (_children.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Aucun enfant. Ajoutez un enfant pour voir les fournitures.',
                        style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary)),
                      ),
                    )
                  else
                    ..._children.map((child) => CustomCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => SuppliesScreen(childId: child.id)),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.2),
                              child: Text(
                                child.firstName.isNotEmpty ? child.firstName[0].toUpperCase() : '?',
                                style: const TextStyle(color: AppColors.primary),
                              ),
                            ),
                            title: Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(child.establishment),
                            trailing: const Icon(Icons.school_outlined),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
