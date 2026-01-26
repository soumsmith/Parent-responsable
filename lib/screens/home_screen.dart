import 'package:flutter/material.dart';
import '../models/child.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/section_title.dart';
import '../config/app_colors.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger les enfants lorsque la page devient visible (utile après vérification OTP)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChildren();
    });
  }

  Future<void> _loadChildren() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Rafraîchir l'utilisateur actuel (utile après reconnexion)
      MainScreenWrapper.of(context).refreshCurrentUser();
      
      final parentId = MainScreenWrapper.of(context).currentUserId ?? 'parent1';
      
      // Charger depuis l'API (qui charge maintenant depuis la base de données locale)
      final apiService = MainScreenWrapper.of(context).apiService;
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
      backgroundColor: AppColors.getPureBackground(isDark),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Pouls École',
          style: TextStyle(
            color: AppColors.getTextColor(isDark),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: AppColors.getPureAppBarBackground(isDark),
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.getTextColor(isDark),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Notifications
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.toSurface(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
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
          backgroundColor: AppColors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add, size: 20),
          label: Text(
            'Ajouter',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.white,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
              AppColors.primary.withOpacity(0),
              AppColors.primary.withOpacity(0),
              AppColors.primary.withOpacity(0.3),
              AppColors.getPureAppBarBackground(true),

            ]
                : [
              AppColors.primary.withOpacity(0),
              AppColors.primary.withOpacity(0),
              AppColors.primary.withOpacity(0.3),
              AppColors.getPureAppBarBackground(false),

            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Header hero section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(
                    //   'Bonjour ! 👋',
                    //   style: TextStyle(
                    //     fontSize: 28,
                    //     fontWeight: FontWeight.w300,
                    //     color: AppColors.getTextColor(isDark, type: TextType.secondary),
                    //     height: 1.2,
                    //   ),
                    // ),
                    // const SizedBox(height: 32),
                    Text(
                      'Suivez le parcours scolaire\nde vos enfants',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getTextColor(isDark),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Stats cards
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'My nutritionist',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.getTextColor(isDark),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Get personalized advice',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: AppColors.getTextColor(isDark, type: TextType.secondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.purple.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.purple,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.restaurant_menu,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'My recipes',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.getTextColor(isDark),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Healthy meal ideas',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: AppColors.getTextColor(isDark, type: TextType.secondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.article,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'My articles',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.getTextColor(isDark),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Latest parenting tips',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: AppColors.getTextColor(isDark, type: TextType.secondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.school,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'My classes',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.getTextColor(isDark),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Track progress',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: AppColors.getTextColor(isDark, type: TextType.secondary),
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
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Section enfants
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.getPureBackground(isDark),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Row(
                          children: [
                            Text(
                              'Mes Enfants',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.getTextColor(isDark),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.toSurface(),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_children.length} enfant${_children.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
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
                                          color: AppColors.error,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Une erreur est survenue',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.getTextColor(isDark),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _error!,
                                          style: TextStyle(
                                            color: AppColors.getTextColor(isDark, type: TextType.secondary),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 24),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: AppColors.primaryGradient,
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
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      AppColors.primaryLight.withOpacity(0.15),
                                                      AppColors.primary.withOpacity(0.08),
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(30),
                                                ),
                                                child: Icon(
                                                  Icons.child_care,
                                                  size: 32,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              Text(
                                                'Commencez votre parcours',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.getTextColor(isDark),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Ajoutez votre premier enfant\npour suivre son évolution',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.getTextColor(isDark, type: TextType.secondary),
                                                  height: 1.3,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 28),
                                              Container(
                                                decoration: BoxDecoration(
                                                  gradient: AppColors.primaryGradient,
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
                                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                                        itemCount: _children.length,
                                        itemBuilder: (context, index) {
                                          final child = _children[index];
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 20),
                                            decoration: BoxDecoration(
                                              color: AppColors.getPureBackground(isDark),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isDark
                                                    ? AppColors.grey700.withOpacity(0.3)
                                                    : AppColors.grey200.withOpacity(0.5),
                                                width: 1,
                                              ),
                                            ),
                                            child: ListTile(
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                              leading: Container(
                                                width: 42,
                                                height: 42,
                                                decoration: BoxDecoration(
                                                  gradient: AppColors.primaryGradient,
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
                                                  color: AppColors.getTextColor(isDark),
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
                                                      color: AppColors.getTextColor(isDark, type: TextType.secondary),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    child.grade.isNotEmpty ? child.grade : 'Classe non renseignée',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: AppColors.getTextColor(isDark, type: TextType.secondary).withOpacity(0.7),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              trailing: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.toSurface(),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Icon(
                                                  Icons.arrow_forward_ios,
                                                  color: AppColors.primary,
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

