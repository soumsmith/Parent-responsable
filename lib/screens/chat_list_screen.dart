import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../config/app_colors.dart';
import '../widgets/custom_card.dart';
import 'chat_detail_screen.dart';

/// Liste des conversations (threads) du parent
class ChatListScreen extends StatefulWidget implements MainScreenChild {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _threads = [];
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
      if (parentId.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }
      try {
        final api = PoulsScolaireApiService();
        final fromApi = await api.getMessageThreads(parentId);
        for (final t in fromApi) {
          await DatabaseService.instance.saveThread({
            'id': t['id'] ?? t['threadId'] ?? 'thread_${t.hashCode}',
            'parentId': parentId,
            'title': t['title'] ?? t['subject'] ?? t['with'] ?? 'Conversation',
            'lastMessageAt': t['lastMessageAt'] ?? t['lastMessageAtMs'] ?? t['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
            'unreadCount': t['unreadCount'] ?? 0,
          });
        }
      } catch (e) {
        print('⚠️ getMessageThreads: $e');
      }
      var list = await DatabaseService.instance.getThreadsByParent(parentId);
      // Pour tester l'UI : si aucune conversation, créer un thread de démonstration
      if (list.isEmpty && parentId.isNotEmpty) {
        final demoThread = {
          'id': 'demo_thread_1',
          'parentId': parentId,
          'title': 'Direction de l\'établissement',
          'lastMessageAt': DateTime.now().millisecondsSinceEpoch - 3600000,
          'unreadCount': 1,
        };
        await DatabaseService.instance.saveThread(demoThread);
        list = await DatabaseService.instance.getThreadsByParent(parentId);
      }
      setState(() {
        _threads = list;
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
          title: Text('Messagerie', style: TextStyle(color: AppColors.getTextColor(isDark))),
          backgroundColor: AppColors.getSurfaceColor(isDark),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        title: Text('Messagerie', style: TextStyle(color: AppColors.getTextColor(isDark))),
        backgroundColor: AppColors.getSurfaceColor(isDark),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _threads.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.getTextColor(isDark, type: TextType.tertiary)),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune conversation',
                      style: TextStyle(color: AppColors.getTextColor(isDark), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vos échanges avec l\'établissement apparaîtront ici.',
                      style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _threads.length,
                itemBuilder: (context, index) {
                  final t = _threads[index];
                  final threadId = t['id'] as String? ?? '';
                  final title = t['title'] as String? ?? 'Conversation';
                  final lastAt = t['lastMessageAt'] as int?;
                  final unread = (t['unreadCount'] as int?) ?? 0;
                  final parentId = MainScreenWrapper.of(context).currentUserId ?? '';
                  return CustomCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(
                          threadId: threadId,
                          title: title,
                          parentId: parentId,
                          onBack: _load,
                        ),
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Icon(Icons.chat, color: AppColors.primary),
                      ),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: lastAt != null
                          ? Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(lastAt)),
                              style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary), fontSize: 12),
                            )
                          : null,
                      trailing: unread > 0
                          ? CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.error,
                              child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 12)),
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
