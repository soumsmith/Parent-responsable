import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/splash_screen.dart';
import 'config/app_config.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'dart:convert';

// Handler pour les notifications en background (doit être top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📨 Notification en background: ${message.notification?.title}');
  
  // Sauvegarder la notification dans la base de données
  try {
    final title = message.notification?.title ?? message.data['title'] ?? 'Notification';
    final body = message.notification?.body ?? message.data['body'] ?? '';
    final data = message.data;
    final timestamp = DateTime.now();
    final notificationId = '${timestamp.millisecondsSinceEpoch}_${message.hashCode}';
    
    // Déterminer l'expéditeur
    String? sender;
    if (data.containsKey('sender')) {
      sender = data['sender'] as String?;
    } else if (data.containsKey('type')) {
      final type = data['type'] as String?;
      if (type != null) {
        switch (type.toLowerCase()) {
          case 'note_added':
          case 'note_updated':
            sender = 'Système de notes';
            break;
          case 'message_received':
            sender = 'Messagerie';
            break;
          case 'fee_added':
            sender = 'Comptabilité';
            break;
          case 'absence':
            sender = 'Secrétariat';
            break;
          default:
            sender = 'Direction de l\'établissement';
        }
      }
    } else {
      sender = 'Direction de l\'établissement';
    }
    
    // Récupérer l'utilisateur actuel
    final authService = AuthService.instance;
    final user = authService.getCurrentUser();
    final parentId = user?.id;
    
    // Sauvegarder la notification
    final databaseService = DatabaseService.instance;
    await databaseService.saveNotification(
      id: notificationId,
      title: title,
      body: body,
      data: data.isNotEmpty ? data : null,
      timestamp: timestamp,
      sender: sender,
      parentId: parentId,
    );
    print('✅ Notification sauvegardée en background: $title');
  } catch (e) {
    print('❌ Erreur lors de la sauvegarde de la notification en background: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialisé');
    
    // Configurer le handler pour les notifications en background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Initialiser le service de notifications
    await NotificationService().initialize();
    print('✅ Service de notifications initialisé');
  } catch (e) {
    print('⚠️ Erreur lors de l\'initialisation de Firebase: $e');
    // Continuer même si Firebase échoue (pour le développement)
  }
  
  runApp(const PoulsEcoleParentApp());
}

/// Application principale
class PoulsEcoleParentApp extends StatelessWidget {
  const PoulsEcoleParentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pouls École Parent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B1F3B), // Bleu nuit
          primary: const Color(0xFF0B1F3B),
          secondary: const Color(0xFFF7941D), // Orange
          tertiary: const Color(0xFFFFC857), // Jaune
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: const Color(0xFF0B1F3B),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

