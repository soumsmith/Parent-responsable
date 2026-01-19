import 'package:flutter/material.dart';
import '../models/child.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../app.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Pouls École',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1A237E),
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A237E),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Notifications
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withOpacity(0.1)
                    : const Color(0xFF1A237E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: isDark ? Colors.white : const Color(0xFF1A237E),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7E57C2), Color(0xFF5E35B1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7E57C2).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add, size: 20),
          label: Text(
            'Ajouter',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: isDark ? Colors.white : const Color(0xFF1A237E),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F0F0F),
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                  ]
                : [
                    const Color(0xFFE8EAF6),
                    const Color(0xFFC5CAE9),
                    const Color(0xFF9FA8DA),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Header hero section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour ! 👋',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        color: isDark ? Colors.white70 : const Color(0xFF283593),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Suivez le parcours scolaire\nde vos enfants',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A237E),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Stats cards
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF81C784).withOpacity(0.2),
                                  const Color(0xFF66BB6A).withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF81C784).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF81C784),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.family_restroom,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${_children.length}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF2E7D32),
                                  ),
                                ),
                                Text(
                                  'Enfants',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white70 : const Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF64B5F6).withOpacity(0.2),
                                  const Color(0xFF42A5F5).withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF64B5F6).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF64B5F6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.school,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Actif',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF1976D2),
                                  ),
                                ),
                                Text(
                                  'Statut',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white70 : const Color(0xFF1976D2),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Section enfants
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.black.withOpacity(0.2)
                        : Colors.white.withOpacity(0.8),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Row(
                          children: [
                            Text(
                              'Mes Enfants',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1A237E),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7E57C2).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_children.length} enfant${_children.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF7E57C2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _error != null
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 64,
                                          color: isDark ? Colors.red[300] : Colors.red[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Une erreur est survenue',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _error!,
                                          style: TextStyle(
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 24),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF7E57C2), Color(0xFF5E35B1)],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: ElevatedButton(
                                            onPressed: _loadChildren,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            ),
                                            child: const Text(
                                              'Réessayer',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : _children.isEmpty
                                    ? SingleChildScrollView(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      const Color(0xFF7E57C2).withOpacity(0.15),
                                                      const Color(0xFF5E35B1).withOpacity(0.08),
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(30),
                                                ),
                                                child: Icon(
                                                  Icons.child_care,
                                                  size: 32,
                                                  color: const Color(0xFF7E57C2),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Commencez votre parcours',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark ? Colors.white : const Color(0xFF1A237E),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Ajoutez votre premier enfant\npour suivre son évolution',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                  height: 1.3,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 20),
                                              Container(
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFF7E57C2), Color(0xFF5E35B1)],
                                                  ),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: ElevatedButton.icon(
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
                                                  icon: const Icon(Icons.add, size: 16),
                                                  label: const Text('Ajouter'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.transparent,
                                                    shadowColor: Colors.transparent,
                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                                        itemCount: _children.length,
                                        itemBuilder: (context, index) {
                                          final child = _children[index];
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            decoration: BoxDecoration(
                                              color: isDark 
                                                  ? Colors.white.withOpacity(0.05)
                                                  : Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isDark 
                                                    ? Colors.white.withOpacity(0.1)
                                                    : Colors.grey.withOpacity(0.2),
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isDark
                                                      ? Colors.black.withOpacity(0.08)
                                                      : Colors.black.withOpacity(0.04),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: ListTile(
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              leading: Container(
                                                width: 42,
                                                height: 42,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      const Color(0xFF7E57C2),
                                                      const Color(0xFF5E35B1),
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: child.photoUrl != null && child.photoUrl!.isNotEmpty
                                                    ? ClipRRect(
                                                        borderRadius: BorderRadius.circular(10),
                                                        child: Image.network(
                                                          child.photoUrl!,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) {
                                                            return Icon(
                                                              Icons.person,
                                                              color: Colors.white,
                                                              size: 20,
                                                            );
                                                          },
                                                        ),
                                                      )
                                                    : const Icon(
                                                        Icons.person,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                              ),
                                              title: Text(
                                                child.fullName,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark ? Colors.white : const Color(0xFF1A237E),
                                                ),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    child.establishment.isNotEmpty ? child.establishment : 'Établissement non renseigné',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    child.grade.isNotEmpty ? child.grade : 'Classe non renseignée',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              trailing: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF7E57C2).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Icon(
                                                  Icons.arrow_forward_ios,
                                                  color: const Color(0xFF7E57C2),
                                                  size: 12,
                                                ),
                                              ),
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) => ChildListScreen(child: child),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

