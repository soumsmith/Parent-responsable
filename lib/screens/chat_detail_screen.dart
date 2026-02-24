import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../config/app_colors.dart';

/// Conversation : messages + champ d'envoi
class ChatDetailScreen extends StatefulWidget {
  final String threadId;
  final String title;
  final String parentId;
  final VoidCallback? onBack;

  const ChatDetailScreen({
    super.key,
    required this.threadId,
    required this.title,
    required this.parentId,
    this.onBack,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      try {
        final api = PoulsScolaireApiService();
        final fromApi = await api.getMessagesByThreadId(widget.threadId);
        if (fromApi.isNotEmpty) {
          final list = fromApi.map((m) => _normalizeMessage(m)).toList();
          await DatabaseService.instance.saveMessages(widget.threadId, list);
        }
      } catch (e) {
        print('⚠️ getMessagesByThreadId: $e');
      }
      await DatabaseService.instance.updateThreadLastMessage(widget.threadId, DateTime.now().millisecondsSinceEpoch, unreadCount: 0);
      final list = await DatabaseService.instance.getMessagesByThread(widget.threadId);
      setState(() {
        _messages = list;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _normalizeMessage(Map<String, dynamic> m) {
    final fromMe = (m['isFromMe'] == true) || (m['senderId'] == widget.parentId);
    return {
      'id': m['id'] ?? 'msg_${m['createdAt']}_${m.hashCode}',
      'threadId': widget.threadId,
      'senderId': m['senderId'],
      'senderName': m['senderName'] ?? (fromMe ? 'Moi' : 'Établissement'),
      'content': m['content'] ?? m['text'] ?? '',
      'isFromMe': fromMe,
      'createdAt': m['createdAt'] is int ? m['createdAt'] : (m['createdAt'] is String ? DateTime.tryParse(m['createdAt'] as String)?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch : DateTime.now().millisecondsSinceEpoch),
      'readAt': m['readAt'],
    };
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();

    final now = DateTime.now().millisecondsSinceEpoch;
    final tempId = 'temp_${widget.parentId}_$now';
    final newMsg = {
      'id': tempId,
      'threadId': widget.threadId,
      'senderId': widget.parentId,
      'senderName': 'Moi',
      'content': text,
      'isFromMe': true,
      'createdAt': now,
      'readAt': null,
    };

    setState(() {
      _sending = true;
      _messages = [..._messages, newMsg];
    });
    await DatabaseService.instance.insertMessage(newMsg);
    await DatabaseService.instance.updateThreadLastMessage(widget.threadId, now, unreadCount: 0);
    _scrollToBottom();

    try {
      final api = PoulsScolaireApiService();
      final result = await api.postMessage(widget.threadId, text, widget.parentId);
      if (result != null && result['id'] != null && mounted) {
        final updated = [..._messages];
        final idx = updated.indexWhere((m) => m['id'] == tempId);
        if (idx >= 0) updated[idx] = {...updated[idx], 'id': result['id']};
        setState(() => _messages = updated);
      }
    } catch (e) {
      print('⚠️ postMessage: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Envoi échoué: $e')));
    }
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        title: Text(widget.title, style: TextStyle(color: AppColors.getTextColor(isDark), fontSize: 18)),
        backgroundColor: AppColors.getSurfaceColor(isDark),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun message. Envoyez le premier.',
                          style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.secondary)),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final m = _messages[index];
                          final fromMe = (m['isFromMe'] as int?) == 1 || (m['isFromMe'] as bool?) == true;
                          final content = m['content'] as String? ?? '';
                          final createdAt = m['createdAt'] as int? ?? 0;
                          return Align(
                            alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                              decoration: BoxDecoration(
                                color: fromMe ? AppColors.primary.withOpacity(0.2) : AppColors.getSurfaceColor(isDark),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(fromMe ? 16 : 4),
                                  bottomRight: Radius.circular(fromMe ? 4 : 16),
                                ),
                                border: Border.all(color: AppColors.getBorderColor(isDark).withOpacity(0.5)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(content, style: TextStyle(color: AppColors.getTextColor(isDark), fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(createdAt)),
                                    style: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.tertiary), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.getSurfaceColor(isDark), border: Border(top: BorderSide(color: AppColors.getBorderColor(isDark)))),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        hintStyle: TextStyle(color: AppColors.getTextColor(isDark, type: TextType.tertiary)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: AppColors.getBorderColor(isDark))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      style: TextStyle(color: AppColors.getTextColor(isDark)),
                      maxLines: 3,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
