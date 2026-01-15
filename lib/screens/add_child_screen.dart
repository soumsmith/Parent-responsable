import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/child.dart';
import '../models/eleve.dart';
import '../models/ecole.dart';
import '../services/api_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/mock_api_service.dart';
import '../services/remote_api_service.dart';
import '../services/notification_service.dart';
import '../config/app_config.dart';
import '../widgets/custom_button.dart';

/// Écran pour ajouter un élève par matricule
class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _matriculeController = TextEditingController();
  final PoulsScolaireApiService _poulsApiService = PoulsScolaireApiService();
  
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isLoadingEcoles = false;
  Eleve? _foundEleve;
  Ecole? _foundEcole;
  String? _errorMessage;
  
  List<Ecole> _ecoles = [];
  int? _selectedEcoleId;
  final TextEditingController _ecoleSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEcoles();
  }

  @override
  void dispose() {
    _matriculeController.dispose();
    _ecoleSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadEcoles() async {
    setState(() {
      _isLoadingEcoles = true;
      _errorMessage = null;
    });
    
    print('🔄 Début du chargement des écoles...');
    
    try {
      final ecoles = await _poulsApiService.getAllEcoles();
      print('✅ ${ecoles.length} école(s) chargée(s) avec succès');
      
      setState(() {
        _ecoles = ecoles;
        _isLoadingEcoles = false;
        // Ne pas initialiser _selectedEcoleId - le champ doit rester vide
      });
      
      if (ecoles.isEmpty) {
        print('⚠️ Aucune école trouvée');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucune école disponible'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des écoles: $e');
      print('Stack trace: ${StackTrace.current}');
      
      setState(() {
        _isLoadingEcoles = false;
        _errorMessage = 'Erreur lors du chargement des écoles. Appuyez sur "Réessayer" pour recharger.';
      });
      
      if (mounted) {
        // Afficher un message d'erreur plus détaillé dans une dialog
        final errorMessage = e.toString();
        final isDnsError = errorMessage.contains('Failed host lookup') || 
                          errorMessage.contains('No address associated');
        
        if (isDnsError) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Erreur de connexion'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Impossible de se connecter au serveur. Le nom de domaine ne peut pas être résolu.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text('Solutions possibles :'),
                    const SizedBox(height: 8),
                    const Text('1. Vérifiez votre connexion internet'),
                    const Text('2. Si vous êtes sur un émulateur, vérifiez qu\'il a accès à internet'),
                    const Text('3. Testez l\'URL dans un navigateur :'),
                    const SizedBox(height: 4),
                    SelectableText(
                      'https://api-pro.pouls-scolaire.net/api/connecte/ecole',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('4. Vérifiez que le nom de domaine est correct'),
                    const Text('5. Vérifiez les paramètres DNS de votre réseau'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _loadEcoles();
                  },
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Réessayer',
                textColor: Colors.white,
                onPressed: () {
                  _loadEcoles();
                },
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _searchEleve() async {
    if (_matriculeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer un matricule';
      });
      return;
    }

    if (_selectedEcoleId == null) {
      setState(() {
        _errorMessage = 'Veuillez sélectionner une école';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _foundEleve = null;
      _foundEcole = null;
    });

    try {
      final matricule = _matriculeController.text.trim();
      print('🔍 ===== RECHERCHE D\'ÉLÈVE =====');
      print('📝 Matricule recherché: $matricule');
      print('🏫 École ID: $_selectedEcoleId');
      
      // Charger l'année scolaire ouverte
      final anneeScolaire = await _poulsApiService.getAnneeScolaireOuverte(_selectedEcoleId!);
      final idAnnee = anneeScolaire.anneeOuverteCentraleId;
      
      print('📅 Identifiant de l\'année scolaire récupéré: $idAnnee');

      // Vérifier que l'année scolaire est valide
      if (idAnnee == 0 || anneeScolaire.anneeEcoleList.isEmpty) {
        print('❌ Aucune année scolaire ouverte trouvée');
        setState(() {
          _errorMessage = 'Aucune année scolaire ouverte trouvée pour cette école';
          _isSearching = false;
        });
        return;
      }

      // Rechercher l'élève par matricule
      print('🔎 Appel de findEleveByMatricule avec:');
      print('   - École ID: $_selectedEcoleId');
      print('   - Année ID: $idAnnee');
      print('   - Matricule: $matricule');
      
      final eleve = await _poulsApiService.findEleveByMatricule(
        _selectedEcoleId!,
        idAnnee,
        matricule,
      );

      if (eleve != null) {
        // Trouver l'école correspondante
        final ecole = _ecoles.firstWhere(
          (e) => e.ecoleid == _selectedEcoleId,
          orElse: () => _ecoles.first,
        );

        print('✅ ===== ÉLÈVE SÉLECTIONNÉ =====');
        print('👤 Informations de l\'élève sélectionné:');
        print('   - Matricule: ${eleve.matriculeEleve}');
        print('   - Nom complet: ${eleve.fullName}');
        print('   - Nom: ${eleve.nomEleve}');
        print('   - Prénom: ${eleve.prenomEleve}');
        print('   - Classe ID (classeid): ${eleve.classeid}');
        print('   - Classe (libellé): ${eleve.classe}');
        print('   - École ID: ${ecole.ecoleid}');
        print('   - École: ${ecole.ecoleclibelle}');
        print('   - Année ID utilisée: $idAnnee');
        print('================================');

        setState(() {
          _foundEleve = eleve;
          _foundEcole = ecole;
          _isSearching = false;
        });
      } else {
        print('❌ Aucun élève trouvé avec le matricule: $matricule');
        setState(() {
          _errorMessage = 'Aucun élève trouvé avec ce matricule';
          _isSearching = false;
        });
      }
    } catch (e) {
      String errorMsg = 'Erreur lors de la recherche';
      if (e.toString().contains('année scolaire')) {
        errorMsg = 'Impossible de récupérer l\'année scolaire pour cette école. Veuillez réessayer ou contacter le support.';
      } else if (e.toString().contains('timeout')) {
        errorMsg = 'La requête a pris trop de temps. Vérifiez votre connexion internet.';
      } else {
        errorMsg = 'Erreur lors de la recherche: ${e.toString().split(':').last.trim()}';
      }
      
      setState(() {
        _errorMessage = errorMsg;
        _isSearching = false;
      });
      
      // Log pour le débogage
      print('Erreur recherche élève: $e');
    }
  }

  Future<void> _handleAddChild() async {
    if (_foundEleve == null || _foundEcole == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Informations de l\'élève manquantes'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Stocker les valeurs localement pour éviter les problèmes de null
    final eleve = _foundEleve!;
    final ecole = _foundEcole!;

    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer l'utilisateur actuel depuis AuthService
      final currentUser = AuthService.instance.getCurrentUser();
      if (currentUser == null) {
        throw Exception('Aucun utilisateur connecté. Veuillez vous reconnecter.');
      }
      
      final parentId = currentUser.id;
      
      // Créer le service API directement
      final apiService = AppConfig.MOCK_MODE
          ? MockApiService()
          : RemoteApiService();

      // Vérifier que les valeurs nécessaires ne sont pas vides
      if (eleve.prenomEleve.isEmpty || eleve.nomEleve.isEmpty) {
        throw Exception('Les informations de l\'élève sont incomplètes');
      }

      final newChild = Child(
        id: eleve.inscriptionsidEleve.toString(),
        firstName: eleve.prenomEleve,
        lastName: eleve.nomEleve,
        establishment: ecole.ecoleclibelle.isNotEmpty 
            ? ecole.ecoleclibelle 
            : 'École non spécifiée',
        grade: eleve.classe.isNotEmpty 
            ? eleve.classe 
            : 'Classe non spécifiée',
        photoUrl: eleve.urlPhoto,
        parentId: parentId,
      );

      // Vérifier et logger les valeurs avant sauvegarde
      print('📝 Sauvegarde de l\'élève:');
      print('   - Matricule: ${eleve.matriculeEleve}');
      print('   - Ecole ID: ${ecole.ecoleid}');
      print('   - Classe ID (classeid): ${eleve.classeid}');
      print('   - Classe Name: ${eleve.classe}');
      print('   - Photo URL: ${eleve.urlPhoto ?? "null"}');
      
      if (eleve.classeid == null || eleve.classeid == 0) {
        print('⚠️ ATTENTION: classeid est null ou 0!');
      }
      
      if (eleve.urlPhoto == null || eleve.urlPhoto!.isEmpty) {
        print('⚠️ ATTENTION: urlPhoto est null ou vide!');
      }
      
      // Sauvegarder l'enfant dans la base de données locale
      await DatabaseService.instance.saveChild(
        newChild,
        matricule: eleve.matriculeEleve,
        ecoleId: ecole.ecoleid,
        ecoleName: ecole.ecoleclibelle,
        classeId: eleve.classeid,
        classeName: eleve.classe,
      );
      
      print('✅ Enfant sauvegardé avec classeId: ${eleve.classeid}');

      // Associer le matricule au token FCM et réenregistrer le token
      await _updateNotificationTokenWithNewMatricule(parentId, eleve.matriculeEleve);

      // Ajouter l'enfant via l'API
      final success = await apiService.addChild(parentId, newChild);

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Élève ajouté avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Retour avec succès
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'ajout de l\'élève'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un élève'),
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Icône
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_add,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'AJOUTER UN ÉLÈVE',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Recherchez votre enfant par son matricule',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Formulaire de recherche
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Sélection de l'école
                        // Toujours afficher le champ, même si les écoles ne sont pas encore chargées
                        _isLoadingEcoles
                            ? const TextField(
                                enabled: false,
                                decoration: InputDecoration(
                                  labelText: 'École *',
                                  hintText: 'Chargement des écoles...',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.school),
                                  suffixIcon: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                ),
                              )
                            : _ecoles.isEmpty
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      TextFormField(
                                        controller: _ecoleSearchController,
                                        decoration: InputDecoration(
                                          labelText: 'École *',
                                          hintText: _errorMessage ?? 'Aucune école disponible',
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(Icons.school),
                                          suffixIcon: const Icon(Icons.error_outline),
                                        ),
                                        enabled: false,
                                        validator: (value) {
                                          return _errorMessage ?? 'Impossible de charger les écoles. Veuillez réessayer.';
                                        },
                                      ),
                                      if (_errorMessage != null) ...[
                                        const SizedBox(height: 12),
                                        ElevatedButton.icon(
                                          onPressed: _loadEcoles,
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Réessayer'),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                        ),
                                      ],
                                    ],
                                  )
                                : Autocomplete<Ecole>(
                            displayStringForOption: (Ecole ecole) => ecole.ecoleclibelle,
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              // Si le champ est vide, retourner toutes les écoles
                              if (textEditingValue.text.isEmpty) {
                                return _ecoles;
                              }
                              // Sinon, filtrer les écoles selon la recherche
                              final query = textEditingValue.text.toLowerCase();
                              return _ecoles.where((ecole) {
                                final nomMatch = ecole.ecoleclibelle.toLowerCase().contains(query);
                                final codeMatch = ecole.ecolecode.toLowerCase().contains(query);
                                return nomMatch || codeMatch;
                              }).toList();
                            },
                            onSelected: (Ecole ecole) {
                              setState(() {
                                _selectedEcoleId = ecole.ecoleid;
                                _foundEleve = null;
                                _foundEcole = null;
                                _errorMessage = null;
                              });
                            },
                            fieldViewBuilder: (
                              BuildContext context,
                              TextEditingController fieldTextEditingController,
                              FocusNode fieldFocusNode,
                              VoidCallback onFieldSubmitted,
                            ) {
                              // Initialiser le controller avec le nom de l'école sélectionnée si elle existe
                              if (_selectedEcoleId != null && fieldTextEditingController.text.isEmpty) {
                                final selectedEcole = _ecoles.firstWhere(
                                  (e) => e.ecoleid == _selectedEcoleId,
                                  orElse: () => _ecoles.first,
                                );
                                if (selectedEcole.ecoleid == _selectedEcoleId) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    fieldTextEditingController.text = selectedEcole.ecoleclibelle;
                                  });
                                }
                              }
                              
                              return TextFormField(
                                controller: fieldTextEditingController,
                                focusNode: fieldFocusNode,
                                decoration: InputDecoration(
                                  labelText: 'École *',
                                  hintText: 'Rechercher une école...',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.school),
                                  suffixIcon: _selectedEcoleId != null
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            fieldTextEditingController.clear();
                                            setState(() {
                                              _selectedEcoleId = null;
                                              _foundEleve = null;
                                              _foundEcole = null;
                                              _errorMessage = null;
                                            });
                                          },
                                        )
                                      : const Icon(Icons.search),
                                ),
                                onChanged: (value) {
                                  // Réinitialiser la sélection si le texte ne correspond plus à l'école sélectionnée
                                  if (_selectedEcoleId != null) {
                                    final selectedEcole = _ecoles.firstWhere(
                                      (e) => e.ecoleid == _selectedEcoleId,
                                      orElse: () => _ecoles.first,
                                    );
                                    if (value != selectedEcole.ecoleclibelle) {
                                      setState(() {
                                        _selectedEcoleId = null;
                                        _foundEleve = null;
                                        _foundEcole = null;
                                        _errorMessage = null;
                                      });
                                    }
                                  }
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez rechercher et sélectionner une école';
                                  }
                                  if (_selectedEcoleId == null) {
                                    return 'Veuillez sélectionner une école dans la liste';
                                  }
                                  return null;
                                },
                              );
                            },
                            optionsViewBuilder: (
                              BuildContext context,
                              AutocompleteOnSelected<Ecole> onSelected,
                              Iterable<Ecole> options,
                            ) {
                              if (options.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4.0,
                                  borderRadius: BorderRadius.circular(8),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxHeight: 300),
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (BuildContext context, int index) {
                                        final Ecole option = options.elementAt(index);
                                        return InkWell(
                                          onTap: () {
                                            onSelected(option);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  option.ecoleclibelle,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                if (option.ecolecode.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Code: ${option.ecolecode}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 16),
                        // Champ matricule
                        TextFormField(
                          controller: _matriculeController,
                          decoration: const InputDecoration(
                            labelText: 'Matricule de l\'élève *',
                            hintText: 'Ex: MAT001',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer le matricule';
                            }
                            return null;
                          },
                          autofocus: true,
                          onFieldSubmitted: (_) => _searchEleve(),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage ?? '',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        CustomButton(
                          text: _isSearching ? 'Recherche...' : 'Rechercher',
                          onPressed: _isSearching ? null : _searchEleve,
                          isLoading: _isSearching,
                        ),
                      ],
                    ),
                  ),
                  // Affichage des résultats
                  if (_foundEleve != null && _foundEcole != null) ...[
                    const SizedBox(height: 24),
                    Builder(
                      builder: (context) {
                        final eleve = _foundEleve!;
                        final ecole = _foundEcole!;
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green[700]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Élève trouvé',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[900],
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Photo de l'élève
                              if (eleve.urlPhoto != null && eleve.urlPhoto!.isNotEmpty) ...[
                                Center(
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.green,
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: Image.network(
                                        eleve.urlPhoto!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[300],
                                            child: Icon(
                                              Icons.person,
                                              size: 50,
                                              color: Colors.grey[600],
                                            ),
                                          );
                                        },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              _buildInfoRow(Icons.person, 'Nom', eleve.fullName),
                              const SizedBox(height: 8),
                              _buildInfoRow(Icons.school, 'École', ecole.ecoleclibelle),
                              const SizedBox(height: 8),
                              _buildInfoRow(Icons.class_, 'Classe', eleve.classe),
                              const SizedBox(height: 8),
                              _buildInfoRow(Icons.badge, 'Matricule', eleve.matriculeEleve),
                              const SizedBox(height: 24),
                              CustomButton(
                                text: 'Ajouter cet élève',
                                onPressed: _handleAddChild,
                                isLoading: _isLoading,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Info box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Entrez le matricule de votre enfant pour le retrouver dans le système scolaire.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.blue[900],
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  /// Met à jour le token de notification avec le nouveau matricule
  Future<void> _updateNotificationTokenWithNewMatricule(String userId, String newMatricule) async {
    try {
      print('🔄 Mise à jour du token de notification avec le nouveau matricule: $newMatricule');
      
      final notificationService = NotificationService();
      
      // Obtenir le token de manière asynchrone (récupère depuis Firebase si nécessaire)
      final token = await notificationService.getTokenAsync();
      
      if (token == null || token.isEmpty) {
        print('⚠️ Aucun token FCM disponible actuellement.');
        print('   Le matricule sera associé au token lors de la prochaine initialisation des notifications.');
        print('   Ou lorsque le token FCM sera disponible.');
        // Ne pas bloquer l'ajout de l'élève si le token n'est pas disponible
        // Le token sera mis à jour lors de la prochaine initialisation
        return;
      }
      
      // Récupérer tous les matricules de l'utilisateur (y compris le nouveau)
      final databaseService = DatabaseService.instance;
      final childrenInfo = await databaseService.getChildrenInfoByParent(userId);
      
      // Extraire les matricules non null
      final matricules = childrenInfo
          .map((info) => info['matricule'] as String?)
          .where((matricule) => matricule != null && matricule.isNotEmpty)
          .cast<String>()
          .toList();
      
      if (matricules.isEmpty) {
        print('⚠️ Aucun matricule trouvé pour l\'utilisateur');
        return;
      }
      
      print('📋 Matricules à associer au token: ${matricules.length}');
      for (final matricule in matricules) {
        print('   - $matricule');
      }
      
      // Déterminer le type d'appareil
      final deviceType = Platform.isIOS ? 'ios' : 'android';
      
      // Réenregistrer le token avec tous les matricules
      final apiService = PoulsScolaireApiService();
      final success = await apiService.registerNotificationToken(
        token,
        userId,
        deviceType: deviceType,
        matricules: matricules,
      );
      
      if (success) {
        print('✅ Token de notification mis à jour avec succès avec ${matricules.length} matricule(s)');
      } else {
        print('❌ Erreur lors de la mise à jour du token de notification');
      }
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du token de notification: $e');
      // Ne pas bloquer l'ajout de l'élève si la mise à jour du token échoue
    }
  }
}
