import 'package:flutter/material.dart';
import '../models/child.dart';
import 'custom_card.dart';

/// Widget pour afficher un enfant dans une carte
class ChildItem extends StatelessWidget {
  final Child child;
  final VoidCallback? onTap;

  const ChildItem({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Log pour déboguer
    final childName = child.fullName;
    final photoUrl = child.photoUrl;
    print('🖼️ ChildItem.build pour $childName');
    print('   photoUrl: ${photoUrl ?? "null"}');
    print('   photoUrl isNotEmpty: ${photoUrl?.isNotEmpty ?? false}');
    
    return CustomCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Photo de l'élève depuis urlPhoto
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          photoUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          cacheWidth: 120, // Optimiser le cache (2x pour les écrans haute résolution)
                          cacheHeight: 120,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback vers l'icône si le chargement échoue
                            print('⚠️ Erreur lors du chargement de la photo pour $childName');
                            print('   URL: $photoUrl');
                            print('   Erreur: $error');
                            print('   StackTrace: $stackTrace');
                            return Container(
                              color: const Color(0xFFE3F2FD), // Bleu clair
                              child: Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                          loadingBuilder: (context, imageChild, loadingProgress) {
                            if (loadingProgress == null) {
                              print('✅ Photo chargée avec succès pour $childName');
                              return imageChild;
                            }
                            // Afficher un indicateur de chargement
                            final progress = loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null;
                            if (progress != null) {
                              print('⏳ Chargement de la photo pour $childName: ${(progress * 100).toStringAsFixed(0)}%');
                            }
                            return Container(
                              color: const Color(0xFFE3F2FD), // Bleu clair
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Container(
                        // Placeholder si pas de photo
                        color: const Color(0xFFE3F2FD), // Bleu clair
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.grey[600],
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom de l'enfant
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        child.fullName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Nom de l'établissement (en rouge selon maquette)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        child.establishment,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Classe (en rouge selon maquette)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Classe: ${child.grade}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bouton "Voir plus" centré selon maquette
          Center(
            child: TextButton(
              onPressed: onTap,
              child: const Text('Voir plus'),
            ),
          ),
        ],
      ),
    );
  }
}

