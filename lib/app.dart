import 'dart:async';
import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'services/api_service.dart';
import 'services/mock_api_service.dart';
import 'services/remote_api_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/tutor_screen.dart';
import 'widgets/bottom_nav.dart';

/// Widget principal de l'application avec navigation
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();

  /// Récupère l'instance de App depuis le contexte
  static _AppState of(BuildContext context) {
    return context.findAncestorStateOfType<_AppState>()!;
  }

  /// Récupère l'instance de App depuis le contexte (peut retourner null)
  static _AppState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<_AppState>();
  }
}

class _AppState extends State<App> {
  int _currentIndex = 0;
  late ApiService _apiService;
  String? _currentUserId;
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    // Initialise le service API selon le mode
    _apiService = AppConfig.MOCK_MODE
        ? MockApiService()
        : RemoteApiService();
    
    // Récupère l'ID de l'utilisateur connecté
    final user = AuthService.instance.getCurrentUser();
    _currentUserId = user?.id;

    // Écouter les notifications SEULEMENT si le service est déjà initialisé
    _setupNotificationListener();
  }

  /// Configure l'écoute des notifications
  void _setupNotificationListener() {
    try {
      // Vérifier si NotificationService est disponible avant de l'utiliser
      _notificationSubscription = NotificationService().notificationStream.listen(
        (notificationData) {
          _handleNotification(notificationData);
        },
      );
    } catch (e) {
      print('⚠️ NotificationService non disponible: $e');
      // Ne pas faire échouer l'application si les notifications ne sont pas disponibles
    }
  }

  /// Gère une notification reçue
  void _handleNotification(Map<String, dynamic> data) {
    // Afficher un snackbar ou naviguer selon le type de notification
    final type = data['data']?['type'] as String?;
    final title = data['title'] as String? ?? 'Notification';
    final body = data['body'] as String? ?? '';

    // Afficher un snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(body),
            ],
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Voir',
            onPressed: () {
              _navigateToNotificationScreen(data);
            },
          ),
        ),
      );
    }
  }

  /// Navigue vers l'écran approprié selon le type de notification
  void _navigateToNotificationScreen(Map<String, dynamic> data) {
    final type = data['data']?['type'] as String?;
    final notificationData = data['data'] as Map<String, dynamic>?;

    if (!mounted) return;

    // Navigation selon le type de notification
    switch (type?.toLowerCase()) {
      case 'note_added':
      case 'note_updated':
        // Naviguer vers l'écran des notes
        if (notificationData?['childId'] != null) {
          // TODO: Naviguer vers l'écran des notes avec l'enfant spécifié
        }
        break;
      case 'message_received':
        // Naviguer vers l'écran des messages
        setState(() {
          _currentIndex = 1; // Index de l'écran Messages
        });
        break;
      case 'fee_added':
        // Naviguer vers l'écran des frais
        // TODO: Implémenter la navigation
        break;
      default:
        // Ne rien faire pour les autres types
        break;
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  /// Expose le service API pour les écrans enfants
  ApiService get apiService => _apiService;
  
  /// Expose l'ID de l'utilisateur actuel
  String? get currentUserId => _currentUserId;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Détermine l'écran à afficher selon l'index
    Widget currentScreen;
    switch (_currentIndex) {
      case 0:
        currentScreen = const HomeScreen();
        break;
      case 1:
        currentScreen = const MessagesScreen();
        break;
      case 2:
        // Pour les notes, on affiche un écran de sélection d'enfant
        // ou on redirige vers le premier enfant
        currentScreen = const NotesPlaceholderScreen();
        break;
      case 3:
        currentScreen = const MoreScreen();
        break;
      default:
        currentScreen = const HomeScreen();
    }

    return Scaffold(
      body: currentScreen,
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

/// Écran placeholder pour les notes (nécessite de sélectionner un enfant)
class NotesPlaceholderScreen extends StatelessWidget {
  const NotesPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.grade,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Sélectionnez un enfant depuis l\'écran d\'accueil',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Écran "Plus" avec options supplémentaires
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plus'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('Boutique (Libouli)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ShopScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Tuteur à domicile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TutorScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Paramètres'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

