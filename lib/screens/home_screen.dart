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
  String? _dashboardMoyenne;
  String? _dashboardSolde;
  String? _dashboardTaux;
  int _dashboardAlertes = 0;
  String? _dashboardProchainEvent;
  bool _dashboardLoading = false;

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
        if ((child.photoUrl == null || child.photoUrl!.isEmpty) &&
            child.id.isNotEmpty) {
          try {
            // Récupérer les informations de l'enfant depuis la base de données
            final childInfo =
                await DatabaseService.instance.getChildInfoById(child.id);
            if (childInfo != null) {
              final ecoleId = childInfo['ecoleId'] as int?;
              final matricule = childInfo['matricule'] as String?;

              if (ecoleId != null && matricule != null) {
                // Récupérer l'année scolaire ouverte pour cette école
                final anneeScolaire =
                    await poulsApiService.getAnneeScolaireOuverte(ecoleId);
                final anneeId = anneeScolaire.anneeOuverteCentraleId;

                // Rechercher l'élève dans l'API pour récupérer cheminphoto
                final eleve = await poulsApiService.findEleveByMatricule(
                  ecoleId,
                  anneeId,
                  matricule,
                );

                if (eleve != null &&
                    eleve.urlPhoto != null &&
                    eleve.urlPhoto!.isNotEmpty) {
                  // Mettre à jour la photo dans la base de données
                  await DatabaseService.instance
                      .updateChildPhoto(child.id, eleve.urlPhoto);
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
                  print(
                      '✅ Photo mise à jour pour ${child.fullName}: ${eleve.urlPhoto}');
                }
              }
            }
          } catch (e) {
            print(
                '⚠️ Erreur lors de la mise à jour de la photo pour ${child.fullName}: $e');
          }
        }
      }

      setState(() {
        _children = children;
        _isLoading = false;
      });
      if (children.isNotEmpty) _loadDashboard(children.first.id);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDashboard(String childId) async {
    if (!mounted) return;
    setState(() => _dashboardLoading = true);
    try {
      final db = DatabaseService.instance;
      String? moyenne;
      final avg = await db.getLastAverageByChild(childId);
      if (avg != null && avg['moyenne'] != null) {
        final m = (avg['moyenne'] as num).toDouble();
        moyenne = m.toStringAsFixed(1);
      }
      double reste = 0;
      final fees = await db.getFeesByChild(childId);
      for (final f in fees) {
        final total = (f['montantTotal'] as num?)?.toDouble() ?? 0;
        final paye = (f['montantPaye'] as num?)?.toDouble() ?? 0;
        reste += (total - paye);
      }
      final solde = reste > 0 ? '${reste.toStringAsFixed(0)} FCFA' : null;
      double taux = 0;
      final att = await db.getAttendanceByChild(childId);
      if (att.isNotEmpty) {
        final presents = att.where((e) => (e['statut'] as String? ?? '').toUpperCase().contains('PRESENT')).length;
        taux = att.length > 0 ? (presents / att.length * 100) : 0;
      }
      final tauxStr = att.isNotEmpty ? '${taux.toStringAsFixed(0)}%' : null;
      final alerts = await db.getRiskAlertsByChild(childId);
      String? prochainEvent;
      final info = await db.getChildInfoById(childId);
      final ecoleId = info?['ecoleId'] as int?;
      if (ecoleId != null) {
        final events = await db.getEventsByEcole(ecoleId);
        final now = DateTime.now().millisecondsSinceEpoch;
        final next = events.where((e) => (e['dateDebut'] as int? ?? 0) > now).toList()
          ..sort((a, b) => ((a['dateDebut'] as int?) ?? 0).compareTo((b['dateDebut'] as int?) ?? 0));
        if (next.isNotEmpty) {
          final d = next.first['dateDebut'] as int?;
          final t = next.first['title'] as String? ?? 'Événement';
          if (d != null) prochainEvent = '${DateTime.fromMillisecondsSinceEpoch(d).day}/${DateTime.fromMillisecondsSinceEpoch(d).month} · $t';
        }
      }
      if (!mounted) return;
      setState(() {
        _dashboardMoyenne = moyenne;
        _dashboardSolde = solde;
        _dashboardTaux = tauxStr;
        _dashboardAlertes = alerts.length;
        _dashboardProchainEvent = prochainEvent;
        _dashboardLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _dashboardLoading = false);
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
        child: FloatingActionButton(
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
          backgroundColor: AppColors.primary,
          elevation: 8,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 24,
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
                                        Icons.child_care,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${_children.length}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.getTextColor(isDark),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Enfant${_children.length > 1 ? 's' : ''} inscrit${_children.length > 1 ? 's' : ''}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: AppColors.getTextColor(isDark,
                                            type: TextType.secondary),
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
                                        Icons.school,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _getUniqueClassesCount().toString(),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.getTextColor(isDark),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Classe${_getUniqueClassesCount() > 1 ? 's' : ''} différente${_getUniqueClassesCount() > 1 ? 's' : ''}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: AppColors.getTextColor(isDark,
                                            type: TextType.secondary),
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
                                        Icons.apartment,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _getUniqueSchoolsCount().toString(),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.getTextColor(isDark),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Établissement${_getUniqueSchoolsCount() > 1 ? 's' : ''}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: AppColors.getTextColor(isDark,
                                            type: TextType.secondary),
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
                                        Icons.grade,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _getAverageGradeDisplay(),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.getTextColor(isDark),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Niveau moyen',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: AppColors.getTextColor(isDark,
                                            type: TextType.secondary),
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
                      if (_children.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Text(
                            'Tableau de bord · ${_children.first.fullName}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.getTextColor(isDark, type: TextType.secondary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _dashboardLoading
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                              )
                            : Container(
                                margin: const EdgeInsets.symmetric(horizontal: 22),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.getSurfaceColor(isDark),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.getBorderColor(isDark)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        _dashboardTile(Icons.grade, 'Moyenne', _dashboardMoyenne ?? '—', isDark),
                                        const SizedBox(width: 12),
                                        _dashboardTile(Icons.payment, 'Solde', _dashboardSolde ?? 'À jour', isDark),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        _dashboardTile(Icons.event_available, 'Présence', _dashboardTaux ?? '—', isDark),
                                        const SizedBox(width: 12),
                                        _dashboardTile(Icons.warning_amber_rounded, 'Alertes', _dashboardAlertes > 0 ? '$_dashboardAlertes' : 'Aucune', isDark),
                                      ],
                                    ),
                                    if (_dashboardProchainEvent != null && _dashboardProchainEvent!.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _dashboardProchainEvent!,
                                              style: TextStyle(fontSize: 12, color: AppColors.getTextColor(isDark)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                        const SizedBox(height: 20),
                      ],
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                            color:
                                                AppColors.getTextColor(isDark),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _error!,
                                          style: TextStyle(
                                            color: AppColors.getTextColor(
                                                isDark,
                                                type: TextType.secondary),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 24),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: AppColors.primaryGradient,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: ElevatedButton(
                                            onPressed: _loadChildren,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 12),
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
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 24),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      AppColors.primaryLight
                                                          .withOpacity(0.15),
                                                      AppColors.primary
                                                          .withOpacity(0.08),
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(30),
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
                                                  color: AppColors.getTextColor(
                                                      isDark),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Ajoutez votre premier enfant\npour suivre son évolution',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.getTextColor(
                                                      isDark,
                                                      type: TextType.secondary),
                                                  height: 1.3,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 28),
                                              // Container(
                                              //   decoration: BoxDecoration(
                                              //     gradient:
                                              //         AppColors.primaryGradient,
                                              //     borderRadius:
                                              //         BorderRadius.circular(10),
                                              //   ),
                                              //   child: ElevatedButton.icon(
                                              //     onPressed: () async {
                                              //       final result =
                                              //           await Navigator.of(
                                              //                   context)
                                              //               .push(
                                              //         MaterialPageRoute(
                                              //           builder: (_) =>
                                              //               const AddChildScreen(),
                                              //         ),
                                              //       );
                                              //       if (result == true) {
                                              //         _loadChildren();
                                              //       }
                                              //     },
                                              //     icon: const Icon(Icons.add,
                                              //         size: 16),
                                              //     label: const Text('Ajouter'),
                                              //     style:
                                              //         ElevatedButton.styleFrom(
                                              //       backgroundColor:
                                              //           Colors.transparent,
                                              //       shadowColor:
                                              //           Colors.transparent,
                                              //       padding: const EdgeInsets
                                              //           .symmetric(
                                              //           horizontal: 16,
                                              //           vertical: 10),
                                              //     ),
                                              //   ),
                                              // ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 0, 16, 100),
                                        itemCount: _children.length,
                                        itemBuilder: (context, index) {
                                          final child = _children[index];
                                          return Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 20),
                                            decoration: BoxDecoration(
                                              color:
                                                  AppColors.getPureBackground(
                                                      isDark),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isDark
                                                    ? AppColors.grey700
                                                        .withOpacity(0.3)
                                                    : AppColors.grey200
                                                        .withOpacity(0.5),
                                                width: 1,
                                              ),
                                            ),
                                            child: ListTile(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 5),
                                              leading: Container(
                                                width: 42,
                                                height: 42,
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      AppColors.primaryGradient,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: child.photoUrl != null &&
                                                        child.photoUrl!
                                                            .isNotEmpty
                                                    ? ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        child: Image.network(
                                                          child.photoUrl!,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (context, error,
                                                                  stackTrace) {
                                                            return Icon(
                                                              Icons.person,
                                                              color:
                                                                  Colors.white,
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
                                                  color: AppColors.getTextColor(
                                                      isDark),
                                                ),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    child.establishment
                                                            .isNotEmpty
                                                        ? child.establishment
                                                        : 'Établissement non renseigné',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors
                                                          .getTextColor(isDark,
                                                              type: TextType
                                                                  .secondary),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    child.grade.isNotEmpty
                                                        ? child.grade
                                                        : 'Classe non renseignée',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: AppColors
                                                              .getTextColor(
                                                                  isDark,
                                                                  type: TextType
                                                                      .secondary)
                                                          .withOpacity(0.7),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              trailing: Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .toSurface(),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
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
                                                    builder: (_) =>
                                                        ChildListScreen(
                                                            child: child),
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

  // Méthodes utilitaires pour les statistiques
  int _getUniqueClassesCount() {
    final uniqueClasses = _children.map((child) => child.grade).toSet();
    return uniqueClasses.length;
  }

  int _getUniqueSchoolsCount() {
    final uniqueSchools = _children.map((child) => child.establishment).toSet();
    return uniqueSchools.length;
  }

  Widget _dashboardTile(IconData icon, String label, String value, bool isDark) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: AppColors.getTextColor(isDark, type: TextType.tertiary))),
                Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.getTextColor(isDark)), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAverageGradeDisplay() {
    if (_children.isEmpty) return '-';

    // Extraire les niveaux numériques des classes (ex: "6ème", "5ème", "4ème", etc.)
    final gradeLevels = _children.map((child) {
      final grade = child.grade.toLowerCase();
      if (grade.contains('cp') || grade.contains('1ère')) return 1;
      if (grade.contains('ce1') || grade.contains('2ème')) return 2;
      if (grade.contains('ce2') || grade.contains('3ème')) return 3;
      if (grade.contains('cm1') || grade.contains('4ème')) return 4;
      if (grade.contains('cm2') || grade.contains('5ème')) return 5;
      if (grade.contains('6ème')) return 6;
      if (grade.contains('5ème')) return 5;
      if (grade.contains('4ème')) return 4;
      if (grade.contains('3ème')) return 3;
      if (grade.contains('seconde')) return 10;
      if (grade.contains('première')) return 11;
      if (grade.contains('terminale')) return 12;
      return 3; // Valeur par défaut
    }).toList();

    if (gradeLevels.isEmpty) return '-';

    final average = gradeLevels.reduce((a, b) => a + b) / gradeLevels.length;

    // Convertir le niveau moyen en affichage textuel
    if (average <= 1) return 'CP';
    if (average <= 2) return 'CE1';
    if (average <= 3) return 'CE2';
    if (average <= 4) return 'CM1';
    if (average <= 5) return 'CM2';
    if (average <= 6) return '6ème';
    if (average <= 10) return 'Collège';
    if (average <= 11) return 'Première';
    return 'Lycée';
  }
}
