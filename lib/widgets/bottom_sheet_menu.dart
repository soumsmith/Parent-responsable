import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/shop_screen.dart';
import '../screens/tutor_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/new_settings_screen.dart';
import '../screens/fees_tab_screen.dart';
import '../screens/presence_conduite_tab_screen.dart';
import '../screens/timetable_tab_screen.dart';
import '../screens/report_card_tab_screen.dart';
import '../screens/student_risk_tab_screen.dart';
import '../screens/chat_list_screen.dart';
import '../screens/events_tab_screen.dart';
import '../screens/supplies_orders_tab_screen.dart';
import '../widgets/main_screen_wrapper.dart';
import '../config/app_colors.dart';

class BottomSheetMenu extends StatelessWidget {
  const BottomSheetMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDark),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          _buildHandleBar(context),
          
          // Header
          _buildHeader(context),
          
          // Menu Items
          _buildMenuItems(context),
          
          // Bottom Padding
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHandleBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.getBorderColor(isDark).withOpacity(0.6),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.toSurface(),
                  AppColors.primary.toSurface().withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.menu,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Menu',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextColor(isDark),
                letterSpacing: -0.3,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close_rounded,
              color: AppColors.getTextColor(isDark, type: TextType.secondary),
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.getSurfaceColor(isDark).withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    final menuItems = [
      {
        'title': 'Scolarité & Paiements',
        'subtitle': 'Frais, paiements et historique',
        'icon': Icons.payment_outlined,
        'color': 0xFF0EA5E9,
        'onTap': () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MainScreenWrapper(child: FeesTabScreen())),
          );
        },
      },
      {
        'title': 'Présence & Conduite',
        'subtitle': 'Absences et sanctions',
        'icon': Icons.event_available,
        'color': 0xFF10B981,
        'onTap': () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MainScreenWrapper(child: PresConduiteTabScreen())),
          );
        },
      },
      {
        'title': 'Emploi du temps',
        'subtitle': 'Voir les emplois du temps par enfant',
        'icon': Icons.calendar_today_outlined,
        'color': 0xFF0D9488,
        'onTap': () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MainScreenWrapper(child: TimetableTabScreen())),
          );
        },
      },
      {
        'title': 'Bulletin PDF',
        'subtitle': 'Télécharger le bulletin avec QR',
        'icon': Icons.picture_as_pdf_outlined,
        'color': 0xFFB45309,
        'onTap': () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MainScreenWrapper(child: ReportCardTabScreen())),
          );
        },
      },
      {
        'title': 'Élève en difficulté',
        'subtitle': 'Analyse des risques et recommandations',
        'icon': Icons.analytics_outlined,
        'color': 0xFFDC2626,
        'onTap': () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MainScreenWrapper(child: StudentRiskTabScreen())),
          );
        },
      },
      {
        'title': 'Messagerie',
        'subtitle': 'Conversations avec l\'établissement',
        'icon': Icons.chat_bubble_outline,
        'color': 0xFF059669,
        'onTap': () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MainScreenWrapper(child: ChatListScreen())),
          );
        },
      },
      {
        'title': 'Événements',
        'subtitle': 'Événements scolaires et réservation',
        'icon': Icons.event_outlined,
        'color': 0xFF7C3AED,
        'onTap': () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MainScreenWrapper(child: EventsTabScreen())),
          );
        },
      },
      {
        'title': 'Fournitures & commandes',
        'subtitle': 'Liste fournitures et mes commandes',
        'icon': Icons.backpack_outlined,
        'color': 0xFF0D9488,
        'onTap': () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MainScreenWrapper(child: SuppliesOrdersTabScreen())),
          );
        },
      },
      {
        'title': 'Boutique (Libouli)',
        'subtitle': 'Accéder à la boutique en ligne',
        'icon': Icons.shopping_bag_outlined,
        'color': 0xFF6366F1,
        'onTap': () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MainScreenWrapper(child: LibraryScreen())),
          );
        },
      },
      {
        'title': 'Tuteur à domicile',
        'subtitle': 'Trouver un tuteur pour vos enfants',
        'icon': Icons.school_outlined,
        'color': 0xFF8B5CF6,
        'onTap': () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MainScreenWrapper(child: TutorScreen())),
          );
        },
      },
      {
        'title': 'Profil',
        'subtitle': 'Gérer votre profil et informations',
        'icon': Icons.person_outline,
        'color': 0xFF2196F3,
        'onTap': () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        },
      },
      {
        'title': 'Aide & Support',
        'subtitle': 'FAQ, contact et assistance',
        'icon': Icons.help_outline,
        'color': 0xFF4CAF50,
        'onTap': () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
          );
        },
      },
      {
        'title': 'Paramètres',
        'subtitle': 'Préférences et configuration',
        'icon': Icons.settings_outlined,
        'color': 0xFF64748B,
        'onTap': () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NewSettingsScreen()),
          );
        },
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 6),
          ...menuItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == menuItems.length - 1;
            
            return _MenuItemTile(
              title: item['title'] as String,
              subtitle: item['subtitle'] as String,
              icon: item['icon'] as IconData,
              color: Color(item['color'] as int),
              onTap: item['onTap'] as VoidCallback,
              showDivider: !isLast,
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool showDivider;

  const _MenuItemTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextColor(isDark),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.getTextColor(isDark, type: TextType.secondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Arrow Icon
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.getTextColor(isDark, type: TextType.secondary),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider) ...[
          const SizedBox(height: 2),
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 64),
            decoration: BoxDecoration(
              color: AppColors.getBorderColor(isDark).withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 2),
        ],
      ],
    );
  }
}

// Utility function to show the bottom sheet
void showMenuBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (context) => const BottomSheetMenu(),
  );
}
