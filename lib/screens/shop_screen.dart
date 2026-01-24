import 'package:flutter/material.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _selectedFilter = 'Tous';
  bool _isOnline = true;

  final List<String> _filters = ['Tous', 'Services', 'Livres', 'PDF', 'Vidéos'];

  final List<Map<String, String>> _libraryItems = [
    {
      'title': 'LIBOULI',
      'subtitle': 'Votre Boutique et Librairie en Ligne',
      'type': 'Service',
      'icon': 'shopping_bag',
      'color': '0xFF6366F1',
    },
    {
      'title': 'POULS-PAID',
      'subtitle': 'Frais de scolarité',
      'type': 'Service',
      'icon': 'school',
      'color': '0xFF8B5CF6',
    },
    {
      'title': 'Mathématiques',
      'subtitle': 'CE1 - Manuel complet',
      'type': 'Livre',
      'icon': 'calculate',
      'color': '0xFF3B82F6',
    },
    {
      'title': 'Sciences',
      'subtitle': 'CM2 - Expériences',
      'type': 'PDF',
      'icon': 'science',
      'color': '0xFF10B981',
    },
    {
      'title': 'Français',
      'subtitle': 'Grammaire et conjugaison',
      'type': 'Livre',
      'icon': 'menu_book',
      'color': '0xFF8B5CF6',
    },
    {
      'title': 'Histoire',
      'subtitle': 'De la Préhistoire à nos jours',
      'type': 'Vidéo',
      'icon': 'history_edu',
      'color': '0xFFF59E0B',
    },
  ];

  List<Map<String, String>> get _filteredItems {
    if (_selectedFilter == 'Tous') return _libraryItems;
    if (_selectedFilter == 'Services') return _libraryItems.where((item) => item['type'] == 'Service').toList();
    return _libraryItems.where((item) => item['type'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Bibliothèque',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _isOnline ? const Color(0xFF10B981) : const Color(0xFF6B7280),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.circle,
                  size: 8,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                const Text(
                  'En ligne',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter == _selectedFilter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected 
                        ? null 
                        : Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected 
                          ? Theme.of(context).colorScheme.onPrimary 
                          : Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Results Count and Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredItems.length} résultats',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: _isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isOnline ? 'En ligne' : 'Hors ligne',
                      style: TextStyle(
                        color: _isOnline 
                          ? Theme.of(context).colorScheme.primary 
                          : Theme.of(context).colorScheme.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      onPressed: () {
                        setState(() {
                          _isOnline = !_isOnline;
                        });
                      },
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Grid View
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return _buildLibraryCard(item);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryCard(Map<String, String> item) {
    final IconData iconData = _getIconData(item['icon']!);
    final Color color = Color(int.parse(item['color']!));
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconData,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            
            // Title
            Text(
              item['title']!,
              style: TextStyle(
                color: Theme.of(context).textTheme.titleMedium?.color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            
            // Subtitle
            Text(
              item['subtitle']!,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const Spacer(),
            
            // Type Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item['type']!,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'school':
        return Icons.school;
      case 'calculate':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'menu_book':
        return Icons.menu_book;
      case 'history_edu':
        return Icons.history_edu;
      case 'public':
        return Icons.public;
      case 'language':
        return Icons.language;
      case 'picture_as_pdf':
        return Icons.picture_as_pdf;
      case 'play_circle':
        return Icons.play_circle;
      case 'headphones':
        return Icons.headphones;
      default:
        return Icons.insert_drive_file;
    }
  }
}

