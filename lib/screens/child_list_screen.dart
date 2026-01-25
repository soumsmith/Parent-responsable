import 'package:flutter/material.dart';
import '../models/child.dart';
import '../models/note.dart';
import '../models/note_api.dart';
import '../models/matiere.dart';
import '../models/periode.dart';
import '../models/annee_scolaire.dart';
import '../models/timetable_entry.dart';
import '../models/message.dart';
import '../models/fee.dart';
import '../services/api_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../services/database_service.dart';
import '../services/theme_service.dart';
import '../config/app_colors.dart';
import '../widgets/main_screen_wrapper.dart';
import 'notes_screen.dart';
import 'timetable_screen.dart';
import 'messages_screen.dart';
import 'fees_screen.dart';

/// Écran de détail d'un enfant avec onglets
class ChildListScreen extends StatefulWidget {
  final Child child;

  const ChildListScreen({
    super.key,
    required this.child,
  });

  @override
  State<ChildListScreen> createState() => _ChildListScreenState();
}

class _ChildListScreenState extends State<ChildListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  List<Note> _notes = [];
  List<TimetableEntry> _timetable = [];
  List<Message> _messages = [];
  List<Fee> _fees = [];
  bool _isLoading = true;
  final ThemeService _themeService = ThemeService();
  
  // Variables pour les données de notes globales
  GlobalAverage? _globalAverage;
  bool _isLoadingNotes = false;
  final PoulsScolaireApiService _poulsApiService = PoulsScolaireApiService();
  
  // Informations de l'enfant pour l'API
  int? _ecoleId;
  int? _classeId;
  String? _matricule;
  int? _anneeId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _tabController.addListener(() {
      setState(() {});
    });
    
    _loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadGlobalNotesData() async {
    print('📊 Chargement des notes globales - DÉMARRAGE');
    
    if (_ecoleId == null || _classeId == null || _matricule == null || _anneeId == null) {
      print('⚠️ Impossible de charger les notes: informations manquantes');
      print('   ecoleId: $_ecoleId, classeId: $_classeId, matricule: $_matricule, anneeId: $_anneeId');
      setState(() {
        _isLoadingNotes = false;
      });
      return;
    }
    
    setState(() {
      _isLoadingNotes = true;
    });
    
    try {
      // Récupérer les périodes
      final periodes = await _poulsApiService.getAllPeriodes();
      if (periodes.isEmpty) {
        print('⚠️ Aucune période disponible');
        setState(() {
          _isLoadingNotes = false;
        });
        return;
      }
      
      // Utiliser la première période (Trimestre 1) par défaut
      final periodeId = periodes.first.id;
      print('📅 Utilisation de la période: ${periodes.first.libelle} (ID: $periodeId)');
      
      // Charger les notes depuis l'API
      print('🔄 Appel API avec:');
      print('   anneeId: $_anneeId');
      print('   classeId: $_classeId');
      print('   periodeId: $periodeId');
      print('   matricule: $_matricule');
      
      final notesResult = await _poulsApiService.getNotesByEleveMatricule(
        _anneeId!,
        _classeId!,
        periodeId,
        _matricule!,
      );
      
      print('✅ Notes reçues de l\'API:');
      print('   📝 Nombre de notes: ${notesResult.notes.length}');
      print('   📊 Moyenne globale: ${notesResult.moyenneGlobale ?? "N/A"}');
      print('   🏆 Rang global: ${notesResult.rangGlobal ?? "N/A"}');
      
      setState(() {
        _globalAverage = GlobalAverage(
          trimesterAverage: notesResult.moyenneGlobale ?? 0.0,
          trimesterRank: notesResult.rangGlobal ?? 0,
          trimesterMention: _getMention(notesResult.moyenneGlobale ?? 0.0),
          annualAverage: 0.0,
          annualRank: 0,
          annualMention: '',
        );
        _isLoadingNotes = false;
      });
      
      print('✅ DONNÉES APPLIQUÉES:');
      print('   📊 Moyenne: ${_globalAverage!.trimesterAverage}');
      print('   🏆 Rang: ${_globalAverage!.trimesterRank}');
      print('   🎖️ Mention: ${_globalAverage!.trimesterMention}');
      
    } catch (e) {
      print('❌ Erreur lors du chargement des notes: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() {
        _isLoadingNotes = false;
      });
    }
  }

  String _getMention(double moyenne) {
    if (moyenne >= 16) return 'Très Bien';
    if (moyenne >= 14) return 'Bien';
    if (moyenne >= 12) return 'Assez Bien';
    if (moyenne >= 10) return 'Passable';
    return 'Insuffisant';
  }

  String _getOrdinalSuffix(int number) {
    if (number == 1) return 'er';
    return 'ème';
  }

  Future<void> _loadData() async {
    print('📋 Début du chargement des données pour l\'enfant: ${widget.child.id}');
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = MainScreenWrapper.of(context).apiService;
      
      // Étape 1: Charger les informations de l'enfant d'abord
      print('📂 Étape 1: Récupération des informations de l\'enfant...');
      await _loadChildInfo();
      
      // Étape 2: Charger les autres données (timetable, messages, fees)
      print('📊 Étape 2: Chargement des données de base...');
      final results = await Future.wait([
        apiService.getNotesForChild(widget.child.id),
        apiService.getTimetableForChild(widget.child.id),
        apiService.getMessages(MainScreenWrapper.of(context).currentUserId ?? 'parent1'),
        apiService.getFeesForChild(widget.child.id),
      ]);

      setState(() {
        _notes = results[0] as List<Note>;
        _timetable = results[1] as List<TimetableEntry>;
        _messages = results[2] as List<Message>;
        _fees = results[3] as List<Fee>;
        _isLoading = false;
      });
      
      print('✅ Données de base chargées');
      print('   📝 Notes: ${_notes.length}');
      print('   📅 Timetable: ${_timetable.length}');
      print('   💬 Messages: ${_messages.length}');
      print('   💰 Fees: ${_fees.length}');
      
      // Étape 3: Charger les données de notes globales
      print('📊 Étape 3: Lancement du chargement des données de notes globales...');
      await _loadGlobalNotesData();
      
    } catch (e) {
      print('❌ Erreur lors du chargement des données: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _loadChildInfo() async {
    try {
      print('📂 Récupération des informations de l\'enfant depuis la base de données...');
      final childInfo = await DatabaseService.instance.getChildInfoById(widget.child.id);
      
      if (childInfo != null) {
        setState(() {
          _ecoleId = childInfo['ecoleId'] as int?;
          _classeId = childInfo['classeId'] as int?;
          _matricule = childInfo['matricule'] as String?;
        });
        
        print('✅ Informations de l\'enfant récupérées:');
        print('   🏫 École ID: $_ecoleId');
        print('   📚 Classe ID: $_classeId');
        print('   🎫 Matricule: $_matricule');
        
        // Charger l'année scolaire ouverte
        if (_ecoleId != null) {
          try {
            final anneeScolaire = await _poulsApiService.getAnneeScolaireOuverte(_ecoleId!);
            setState(() {
              _anneeId = anneeScolaire.anneeOuverteCentraleId;
            });
            print('   📅 Année ID: $_anneeId');
          } catch (e) {
            print('❌ Erreur lors du chargement de l\'année scolaire: $e');
          }
        }
      } else {
        print('❌ Aucune information trouvée pour l\'enfant ${widget.child.id}');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des informations de l\'enfant: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDarkMode),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          _buildProfileHeader(),
                          _buildSummaryCards(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              floating: false,
              delegate: _CustomTabBarDelegate(
                Container(
                  color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
                  child: _buildModernTabBar(),
                ),
              ),
            ),
          ];
        },
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  NotesScreen(childId: widget.child.id),
                  TimetableScreen(childId: widget.child.id),
                  _buildHomeworkTab(),
                  _buildAbsencesTab(),
                  _buildSanctionsTab(),
                  MessagesScreen(),
                  FeesScreen(childId: widget.child.id),
                ],
              ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final theme = Theme.of(context);
    final isDarkMode = _themeService.isDarkMode;
    
    return SliverAppBar(
      expandedHeight: 20,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.getPureAppBarBackground(isDarkMode),
      elevation: 0,
      forceElevated: false,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.child.fullName,
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: theme.iconTheme.color),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.warningGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: widget.child.photoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          widget.child.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar();
                          },
                        ),
                      )
                    : _buildDefaultAvatar(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.child.fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.child.grade,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.child.establishment,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatusBadge('⭐ Excellent', AppColors.success),
              const SizedBox(width: 8),
              _buildStatusBadge('✔ Assidu', AppColors.primary),
              const SizedBox(width: 8),
              _buildStatusBadge('📈 Progression', AppColors.secondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return const Icon(
      Icons.person,
      size: 40,
      color: Colors.white,
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Moyenne', 
                  _globalAverage != null 
                    ? '${_globalAverage!.trimesterAverage.toStringAsFixed(2)}'
                    : '--',
                  Colors.green, 
                  Icons.trending_up,
                  isLoading: _isLoadingNotes,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Rang', 
                  _globalAverage != null && _globalAverage!.trimesterRank > 0
                    ? '${_globalAverage!.trimesterRank}${_getOrdinalSuffix(_globalAverage!.trimesterRank)}'
                    : '--',
                  Colors.blue, 
                  Icons.emoji_events,
                  isLoading: _isLoadingNotes,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSummaryCard('Présence', '95%', AppColors.success, Icons.check_circle)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Appréciation', 
                  _globalAverage != null 
                    ? _globalAverage!.trimesterMention
                    : '--',
                  AppColors.secondary, 
                  Icons.star,
                  isLoading: _isLoadingNotes,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon, {bool isLoading = false}) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? AppColors.black.withOpacity(0.3)
                : AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              else
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            SizedBox(
              height: 28,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.getTextColor(isDarkMode, type: TextType.secondary).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersistentTabBar() {
    final isDarkMode = _themeService.isDarkMode;
    
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: AppColors.primaryGradient,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: '📊 Notes'),
            Tab(text: '📅 Emploi'),
            Tab(text: '📝 Devoirs'),
            Tab(text: '🚸 Absences'),
            Tab(text: '⚠️ Sanctions'),
            Tab(text: '💬 Messages'),
            Tab(text: '💰 Frais'),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTabBar() {
    final isDarkMode = _themeService.isDarkMode;
    
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        return Container(
          height: 35,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            itemBuilder: (context, index) {
              final isSelected = _tabController.index == index;
              return GestureDetector(
                onTap: () {
                  _tabController.animateTo(index);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? AppColors.primaryGradient
                        : null,
                    color: !isSelected
                        ? AppColors.getSurfaceColor(isDarkMode)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTabIcon(index),
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getTabTitle(index),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  IconData _getTabIcon(int index) {
    switch (index) {
      case 0:
        return Icons.bar_chart_rounded;
      case 1:
        return Icons.calendar_today_rounded;
      case 2:
        return Icons.edit_note_rounded;
      case 3:
        return Icons.person_off_rounded;
      case 4:
        return Icons.warning_rounded;
      case 5:
        return Icons.message_rounded;
      case 6:
        return Icons.payments_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Notes';
      case 1:
        return 'Emploi';
      case 2:
        return 'Devoirs';
      case 3:
        return 'Absences';
      case 4:
        return 'Sanctions';
      case 5:
        return 'Messages';
      case 6:
        return 'Frais';
      default:
        return '';
    }
  }

  // ... (rest of the methods remain the same)
  Widget _buildHomeworkTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            '💡 Message important',
            'Cher parents,\nMerci de vous impliquer régulièrement dans le suivi et l\'amélioration du résultat scolaire de votre enfant.',
            Colors.blue,
          ),
          const SizedBox(height: 20),
          _buildHomeworkCategories(),
          const SizedBox(height: 20),
          _buildHomeworkContent(),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, Color color) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : color.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.info_outline,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.grey[300] : const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkCategories() {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'COURS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'EXERCICES',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'CORRIGÉS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkContent() {
    return Column(
      children: [
        _buildHomeworkItem(
          'Mathématiques',
          'Exercices pages 45-47',
          'Pour demain',
          Icons.calculate,
          Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildHomeworkItem(
          'Français',
          'Rédaction : Mon héros préféré',
          'Pour vendredi',
          Icons.menu_book,
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildHomeworkItem(
          'Histoire',
          'Chapitre 3 : La Révolution française',
          'Pour lundi prochain',
          Icons.public,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildHomeworkItem(String subject, String task, String deadline, IconData icon, Color color) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[300] : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              deadline,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsencesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            '📈 Suivi de présence',
            'Cher parents,\nMerci de vous impliquer régulièrement dans le suivi et l\'amélioration du résultat scolaire de votre enfant.',
            Colors.green,
          ),
          const SizedBox(height: 20),
          _buildAttendanceSummary(),
          const SizedBox(height: 20),
          _buildAbsencesList(),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Résumé mensuel',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAttendanceStat('Présences', '18', Colors.green),
              ),
              Expanded(
                child: _buildAttendanceStat('Retards', '2', Colors.orange),
              ),
              Expanded(
                child: _buildAttendanceStat('Absences', '0', Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStat(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAbsencesList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Aucune absence enregistrée ce mois-ci',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF065F46),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSanctionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            '🎯 Comportement',
            'Cher parents,\nMerci de vous impliquer régulièrement dans le suivi et l\'amélioration du résultat scolaire de votre enfant.',
            Colors.purple,
          ),
          const SizedBox(height: 20),
          _buildBehaviorSummary(),
          const SizedBox(height: 20),
          _buildSanctionsList(),
        ],
      ),
    );
  }

  Widget _buildBehaviorSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Évaluation comportementale',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBehaviorItem('Excellent', '⭐', Colors.green),
              ),
              Expanded(
                child: _buildBehaviorItem('Bon', '👍', Colors.blue),
              ),
              Expanded(
                child: _buildBehaviorItem('À améliorer', '📈', Colors.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorItem(String label, String emoji, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSanctionsList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Excellent comportement ! Aucune sanction',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF065F46),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _TabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height + 16;

  @override
  double get maxExtent => _tabBar.preferredSize.height + 16;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}

class _CustomTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget _child;

  _CustomTabBarDelegate(this._child);

  @override
  double get minExtent => 59.0; // 35 height + 12 vertical padding + 12 margin

  @override
  double get maxExtent => 59.0; // 35 height + 12 vertical padding + 12 margin

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return _child;
  }

  @override
  bool shouldRebuild(_CustomTabBarDelegate oldDelegate) {
    return false;
  }
}