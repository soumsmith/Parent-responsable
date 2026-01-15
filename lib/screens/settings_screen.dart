import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../app.dart';
import '../config/app_config.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_button.dart';
import 'login_screen.dart';

/// Écran des paramètres
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user != null)
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informations du compte',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Nom', user.fullName),
                      const SizedBox(height: 8),
                      _buildInfoRow('Email', user.email),
                      const SizedBox(height: 8),
                      _buildInfoRow('Téléphone', user.phone),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Application',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('Version'),
                      subtitle: const Text('1.0.0'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.bug_report),
                      title: const Text('Mode'),
                      subtitle: Text(
                        AppConfig.MOCK_MODE ? 'Mode Mock (Développement)' : 'Mode Production',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Déconnexion',
                backgroundColor: Colors.red,
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Déconnexion'),
                      content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Déconnexion'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await AuthService.instance.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}

