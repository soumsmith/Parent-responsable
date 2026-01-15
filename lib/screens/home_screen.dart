import 'package:flutter/material.dart';
import '../models/child.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../app.dart';
import '../widgets/child_item.dart';
import '../widgets/section_title.dart';
import 'child_list_screen.dart';
import 'add_child_screen.dart';

/// Écran d'accueil avec liste des enfants
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Child> _children = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final parentId = App.of(context).currentUserId ?? 'parent1';
      
      // Charger depuis l'API (qui charge maintenant depuis la base de données locale)
      final apiService = App.of(context).apiService;
      final children = await apiService.getChildrenForParent(parentId);
      
      // Mettre à jour les photos manquantes pour les enfants existants
      final poulsApiService = PoulsScolaireApiService();
      for (final child in children) {
        if ((child.photoUrl == null || child.photoUrl!.isEmpty) && child.id.isNotEmpty) {
          try {
            // Récupérer les informations de l'enfant depuis la base de données
            final childInfo = await DatabaseService.instance.getChildInfoById(child.id);
            if (childInfo != null) {
              final ecoleId = childInfo['ecoleId'] as int?;
              final matricule = childInfo['matricule'] as String?;
              
              if (ecoleId != null && matricule != null) {
                // Récupérer l'année scolaire ouverte pour cette école
                final anneeScolaire = await poulsApiService.getAnneeScolaireOuverte(ecoleId);
                final anneeId = anneeScolaire.anneeOuverteCentraleId;
                
                // Rechercher l'élève dans l'API pour récupérer cheminphoto
                final eleve = await poulsApiService.findEleveByMatricule(
                  ecoleId,
                  anneeId,
                  matricule,
                );
                
                if (eleve != null && eleve.urlPhoto != null && eleve.urlPhoto!.isNotEmpty) {
                  // Mettre à jour la photo dans la base de données
                  await DatabaseService.instance.updateChildPhoto(child.id, eleve.urlPhoto);
                  // Mettre à jour l'objet child en mémoire
                  final updatedChild = Child(
                    id: child.id,
                    firstName: child.firstName,
                    lastName: child.lastName,
                    establishment: child.establishment,
                    grade: child.grade,
                    photoUrl: eleve.urlPhoto,
                    parentId: child.parentId,
                  );
                  final index = children.indexOf(child);
                  if (index >= 0) {
                    children[index] = updatedChild;
                  }
                  print('✅ Photo mise à jour pour ${child.fullName}: ${eleve.urlPhoto}');
                }
              }
            }
          } catch (e) {
            print('⚠️ Erreur lors de la mise à jour de la photo pour ${child.fullName}: $e');
          }
        }
      }
      
      setState(() {
        _children = children;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pouls École Parent'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Ajouter un élève',
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AddChildScreen(),
                ),
              );
              // Rafraîchir la liste si un élève a été ajouté
              if (result == true) {
                _loadChildren();
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(0xFFE3F2FD), // Bleu clair selon maquette
            ],
          ),
        ),
        child: Column(
          children: [
            // Message d'accueil selon maquette ÉTAPE 4
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.black,
                  width: 1,
                ),
              ),
              child: Text(
                'Cher parents,\nMerci de vous impliquer régulièrement dans le suivi et l\'amélioration du résultat scolaire de votre enfant.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            // Liste des enfants
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Erreur: $_error',
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadChildren,
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        )
                      : _children.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.child_care,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucun enfant trouvé',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Ajoutez un élève pour commencer',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final result = await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const AddChildScreen(),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadChildren();
                                      }
                                    },
                                    icon: const Icon(Icons.person_add),
                                    label: const Text('Ajouter un élève'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _children.length,
                              itemBuilder: (context, index) {
                                final child = _children[index];
                                return ChildItem(
                                  child: child,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ChildListScreen(child: child),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

