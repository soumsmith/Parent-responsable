import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/matiere.dart';
import '../models/periode.dart';
import '../models/annee_scolaire.dart';
import '../models/note_api.dart';
import '../services/api_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../services/database_service.dart';
import '../app.dart';
import '../widgets/custom_card.dart';

/// Écran d'affichage des notes
class NotesScreen extends StatefulWidget {
  final String childId;

  const NotesScreen({
    super.key,
    required this.childId,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<SubjectAverage> _allSubjectAverages = [];
  List<SubjectAverage> _filteredSubjectAverages = [];
  GlobalAverage? _globalAverage;
  bool _isLoading = true;
  bool _isLoadingNotes = false; // État séparé pour le chargement des notes
  String? _selectedSubject;
  String? _selectedTrimester;
  String? _selectedYear;

  // Données chargées depuis les API
  List<Matiere> _matieres = [];
  List<Periode> _periodes = [];
  List<String> _trimestersList = ['Tous']; // Cache pour éviter les recalculs
  AnneeScolaire? _anneeScolaire;
  
  // Informations de l'enfant
  int? _ecoleId;
  int? _classeId;
  String? _matricule;
  int? _anneeId;
  
  // Notes chargées depuis l'API
  Map<String, List<NoteApi>> _notesByMatiere = {}; // matiereId (string) -> liste de notes
  
  final PoulsScolaireApiService _poulsApiService = PoulsScolaireApiService();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  /// Charge les données initiales : informations de l'enfant, matières, périodes, année scolaire
  Future<void> _loadInitialData() async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('👁️  CLIC SUR "VOIR PLUS" - CHARGEMENT DE L\'ÉCRAN DES NOTES');
    print('═══════════════════════════════════════════════════════════');
    print('🆔 Child ID: ${widget.childId}');
    print('');
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer les informations de l'enfant depuis la base de données
      print('📂 Récupération des informations de l\'enfant depuis la base de données...');
      final childInfo = await DatabaseService.instance.getChildInfoById(widget.childId);
      
      if (childInfo == null) {
        throw Exception('Enfant non trouvé dans la base de données');
      }

      _ecoleId = childInfo['ecoleId'] as int?;
      _classeId = childInfo['classeId'] as int?;
      _matricule = childInfo['matricule'] as String?;

      print('✅ Informations de l\'élève récupérées depuis la base de données:');
      print('   🏫 École ID: $_ecoleId');
      print('   📚 Classe ID (classeid): $_classeId');
      print('   🎫 Matricule: $_matricule');
      print('');

      if (_ecoleId == null || _classeId == null || _matricule == null) {
        throw Exception('Informations d\'école, de classe ou matricule manquantes pour cet enfant');
      }
      
      if (_classeId == 0 || _classeId == 1) {
        print('⚠️ ATTENTION: classeId semble incorrect: $_classeId');
        print('⚠️ Vérifiez que classeid est correctement sauvegardé dans la base de données');
        print('');
      }

      // Charger les périodes et année scolaire (les matières seront extraites des notes)
      print('🔄 Chargement des périodes et année scolaire...');
      print('   📚 Les matières seront extraites directement des notes');
      print('');
      
      final results = await Future.wait([
        _poulsApiService.getAllPeriodes(),
        _poulsApiService.getAnneeScolaireOuverte(_ecoleId!),
      ]);

      final periodes = results[0] as List<Periode>;
      final anneeScolaire = results[1] as AnneeScolaire;

      // Calculer la liste des trimestres après avoir récupéré les périodes
      final trimestersList = <String>['Tous'];
      if (periodes.isNotEmpty) {
        final periodesSorted = List<Periode>.from(periodes);
        periodesSorted.sort((a, b) {
          final niveauCompare = a.niveau.compareTo(b.niveau);
          if (niveauCompare != 0) return niveauCompare;
          return a.libelle.compareTo(b.libelle);
        });
        for (final periode in periodesSorted) {
          trimestersList.add(periode.libelle);
        }
        print('📅 Périodes triées: ${periodesSorted.length}');
        for (final p in periodesSorted) {
          print('   - ID: ${p.id}, Libellé: ${p.libelle}, Niveau: ${p.niveau}');
        }
      }
      
      setState(() {
        _matieres = []; // Sera rempli après le chargement des notes
        _periodes = periodes;
        _trimestersList = trimestersList;
        _anneeScolaire = anneeScolaire;
      });
      
      print('✅ Données chargées:');
      print('   📚 Matières: (seront extraites des notes)');
      print('   📅 Périodes: ${_periodes.length}');
      print('   📆 Trimestres: ${_trimestersList.length}');
      print('   📆 Année scolaire: ${_anneeScolaire != null ? "Oui" : "Non"}');
      print('');
      
      // Récupérer l'ID de l'année scolaire ouverte et définir l'année par défaut
      if (_anneeScolaire != null && _anneeScolaire!.anneeEcoleList.isNotEmpty) {
        _anneeId = _anneeScolaire!.anneeOuverteCentraleId;
        
        // Trouver l'année ouverte et la sélectionner par défaut
        final anneeOuverte = _anneeScolaire!.anneeEcoleList.firstWhere(
          (a) => a.statut == 'OUVERTE',
          orElse: () => _anneeScolaire!.anneeEcoleList.first,
        );
        _selectedYear = anneeOuverte.anneeLibelle;
        print('📅 Année sélectionnée: $_selectedYear (ID: $_anneeId)');
      }

      // Initialiser les sélections par défaut
      _selectedSubject = null; // 'Toutes' sera affiché dans le dropdown
      if (_trimestersList.isNotEmpty) {
        _selectedTrimester = null; // 'Tous' sera affiché dans le dropdown
        print('📆 Trimestres disponibles: ${_trimestersList.length}');
        print('   Liste: ${_trimestersList.join(", ")}');
      } else {
        print('⚠️ Aucun trimestre disponible');
      }
      
      print('📚 Matières: (seront disponibles après le chargement des notes)');
      print('');

      setState(() {
        _isLoading = false;
      });
      
      print('✅ État de chargement terminé (_isLoading = false)');
      print('');

      // Charger les notes maintenant que les données sont prêtes
      try {
        await _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors du chargement des notes: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur lors du chargement initial: $e');
      print('Stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _loadData({String? trimester, String? year}) async {
    if (_ecoleId == null || _classeId == null || _matricule == null || _anneeId == null) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingNotes = true;
      });
    }

    try {
      // Récupérer l'ID de la période sélectionnée (dynamique selon la sélection)
      // Par défaut, utiliser l'ID 1 si aucune période n'est sélectionnée
      int? periodeId;
      String periodeLibelle = '';
      if (trimester != null && trimester != 'Tous') {
        final selectedPeriode = _periodes.firstWhere(
          (p) => p.libelle == trimester,
          orElse: () => _periodes.firstWhere(
            (p) => p.id == 1,
            orElse: () => _periodes.first,
          ),
        );
        periodeId = selectedPeriode.id;
        periodeLibelle = selectedPeriode.libelle;
      } else if (_selectedTrimester != null && _selectedTrimester != 'Tous') {
        final selectedPeriode = _periodes.firstWhere(
          (p) => p.libelle == _selectedTrimester,
          orElse: () => _periodes.firstWhere(
            (p) => p.id == 1,
            orElse: () => _periodes.first,
          ),
        );
        periodeId = selectedPeriode.id;
        periodeLibelle = selectedPeriode.libelle;
      } else {
        // Par défaut, utiliser l'ID 1
        try {
          final defaultPeriode = _periodes.firstWhere(
            (p) => p.id == 1,
            orElse: () => _periodes.isNotEmpty ? _periodes.first : throw Exception('Aucune période disponible'),
          );
          periodeId = defaultPeriode.id;
          periodeLibelle = defaultPeriode.libelle;
        } catch (e) {
          // Si l'ID 1 n'existe pas, prendre la première période disponible
          if (_periodes.isNotEmpty) {
            periodeId = _periodes.first.id;
            periodeLibelle = _periodes.first.libelle;
          }
        }
      }

      if (periodeId == null) {
        throw Exception('Aucune période disponible');
      }
      
      print('');
      print('📆 Période sélectionnée pour charger les notes:');
      print('   - ID: $periodeId');
      print('   - Libellé: $periodeLibelle');
      print('');

      // Récupérer le libellé de la matière sélectionnée pour le filtrage côté client
      // On charge toutes les notes et on filtre côté client pour plus de simplicité
      String? selectedMatiereLibelle;
      if (_selectedSubject != null && _selectedSubject!.isNotEmpty && _selectedSubject != 'Toutes') {
        selectedMatiereLibelle = _selectedSubject;
        print('🔍 Filtrage par matière: $selectedMatiereLibelle');
      }

      // Charger toutes les notes depuis l'API (filtrage côté client)
      final notesResult = await _poulsApiService.getNotesByEleveMatricule(
        _anneeId!,
        _classeId!,
        periodeId,
        _matricule!,
      );

      final notes = notesResult.notes;
      
      print('📥 Notes reçues de l\'API:');
      print('   📝 Nombre de notes: ${notes.length}');
      print('   📊 Moyenne globale: ${notesResult.moyenneGlobale ?? "N/A"}');
      print('   🏆 Rang global: ${notesResult.rangGlobal ?? "N/A"}');
      if (notes.isEmpty) {
        print('⚠️ ATTENTION: Aucune note retournée par l\'API');
        print('   Vérifiez les paramètres:');
        print('      - Année ID: $_anneeId');
        print('      - Classe ID: $_classeId');
        print('      - Période ID: $periodeId');
        print('      - Matricule: $_matricule');
      }
      print('');

      // Organiser les notes par matière et extraire les matières depuis les notes
      // Utiliser le libellé de la matière comme clé
      final Map<String, List<NoteApi>> notesByMatiere = {};
      final Map<String, double?> moyennesParMatiere = {}; // Stocker les moyennes depuis l'API
      final Map<String, int?> rangsParMatiere = {}; // Stocker les rangs depuis l'API
      final Map<String, double?> coefsParMatiere = {}; // Stocker les coefficients depuis l'API
      final Map<String, Matiere> matieresFromNotes = {}; // Map libellé -> Matiere extraite des notes
      
      print('📊 Organisation des notes par matière:');
      print('   📝 Nombre total de notes: ${notes.length}');
      
      for (final note in notes) {
        if (note.matiereLibelle != null && note.matiereLibelle!.isNotEmpty) {
          final matiereLibelle = note.matiereLibelle!;
          notesByMatiere.putIfAbsent(matiereLibelle, () => []).add(note);
          
          // Stocker la moyenne, le rang et le coefficient depuis l'API (ils sont identiques pour toutes les notes d'une matière)
          if (note.moyenne != null) {
            moyennesParMatiere[matiereLibelle] = note.moyenne;
          }
          if (note.rang != null) {
            rangsParMatiere[matiereLibelle] = note.rang;
          }
          if (note.coef != null) {
            coefsParMatiere[matiereLibelle] = note.coef;
          }
          
          // Créer un objet Matiere à partir des données de la note si pas déjà créé
          if (!matieresFromNotes.containsKey(matiereLibelle)) {
            matieresFromNotes[matiereLibelle] = Matiere(
              id: note.matiereId ?? 0,
              libelle: matiereLibelle,
              coef: note.coef,
            );
          }
        }
      }
      
      // Mettre à jour la liste des matières avec celles extraites des notes
      final matieresList = matieresFromNotes.values.toList();
      matieresList.sort((a, b) => a.libelle.compareTo(b.libelle));
      
      print('   📚 Matières trouvées dans les notes: ${notesByMatiere.keys.length}');
      for (final libelle in notesByMatiere.keys) {
        print('      - $libelle: ${notesByMatiere[libelle]!.length} note(s)');
      }
      print('');
      
      print('📋 Matières extraites:');
      for (final matiere in matieresList) {
        print('   - ${matiere.libelle} (ID: ${matiere.id})');
      }
      print('');
      
      // Mettre à jour _matieres avec les matières extraites des notes
      if (mounted) {
        setState(() {
          _matieres = matieresList;
        });
        print('✅ Liste des matières mise à jour avec ${matieresList.length} matière(s) depuis l\'API des notes');
        print('');
      }

      // Trier les notes par date pour chaque matière
      for (final matiereId in notesByMatiere.keys) {
        notesByMatiere[matiereId]!.sort((a, b) {
          if (a.dateNote == null || b.dateNote == null) return 0;
          try {
            // Parser les dates pour une comparaison correcte
            final dateA = NoteApi.parseDate(a.dateNote);
            final dateB = NoteApi.parseDate(b.dateNote);
            if (dateA == null || dateB == null) {
              // Fallback: comparaison de strings si le parsing échoue
              return a.dateNote!.compareTo(b.dateNote!);
            }
            return dateA.compareTo(dateB);
          } catch (e) {
            // Fallback: comparaison de strings en cas d'erreur
            return a.dateNote!.compareTo(b.dateNote!);
          }
        });
      }

      // Convertir en SubjectAverage pour compatibilité
      // Utiliser directement les matières extraites des notes pour une correspondance parfaite
      final List<SubjectAverage> averages = [];
      print('🔄 Conversion en SubjectAverage:');
      print('   📚 Matières extraites des notes: ${matieresList.length}');
      
      for (final matiere in matieresList) {
        // Chercher les notes par libellé de matière (correspondance exacte maintenant)
        final matiereNotes = notesByMatiere[matiere.libelle] ?? [];
        
        // Si une matière spécifique est sélectionnée, ignorer les autres
        if (selectedMatiereLibelle != null && matiere.libelle != selectedMatiereLibelle) {
          continue;
        }

        // Inclure la matière uniquement si elle a des notes
        if (matiereNotes.isNotEmpty) {
          // Utiliser la moyenne depuis l'API, sinon calculer
          double moyenne = moyennesParMatiere[matiere.libelle] ?? 0.0;
          if (moyenne == 0.0 && matiereNotes.isNotEmpty) {
            // Fallback: calculer si non disponible dans l'API
            final sum = matiereNotes.fold<double>(0.0, (sum, note) => sum + (note.note ?? 0.0));
            moyenne = sum / matiereNotes.length;
          }
          
          // Utiliser le coefficient depuis l'API, sinon depuis la matière
          double coef = coefsParMatiere[matiere.libelle] ?? 
                       (matiere.coef != null ? (matiere.coef as num).toDouble() : 1.0);
          
          // Utiliser le rang depuis l'API
          int? rang = rangsParMatiere[matiere.libelle];
          
          // Récupérer le matiereId depuis les notes pour la base de données
          int? dbMatiereId = matiere.id;
          if (matiereNotes.isNotEmpty && matiereNotes.first.matiereId != null) {
            dbMatiereId = matiereNotes.first.matiereId;
          }

          // Vérifier si la note a été consultée
          final viewed = await DatabaseService.instance.isNoteViewed(
            widget.childId,
            dbMatiereId ?? matiere.id,
            periodeId,
            _anneeId!,
          );

          print('   ✅ ${matiere.libelle}: ${matiereNotes.length} note(s), moyenne: $moyenne, rang: ${rang ?? "N/A"}');

          // Convertir les notes et numéroter selon les dates d'évaluation
          final notesList = matiereNotes.map((n) => n.toNote(widget.childId)).toList();
          
          // Trier les notes par date pour la numérotation
          notesList.sort((a, b) => a.date.compareTo(b.date));
          
          // Numéroter les notes selon leur ordre chronologique (N°1, N°2, etc.)
          for (int i = 0; i < notesList.length; i++) {
            notesList[i] = Note(
              id: notesList[i].id,
              childId: notesList[i].childId,
              subject: notesList[i].subject,
              grade: notesList[i].grade,
              coefficient: notesList[i].coefficient,
              date: notesList[i].date,
              assignmentNumber: 'N°${i + 1}', // Numérotation basée sur l'ordre chronologique
              average: notesList[i].average,
              rank: notesList[i].rank,
              totalStudents: notesList[i].totalStudents,
              mention: notesList[i].mention,
              noteSur: notesList[i].noteSur,
            );
          }

          averages.add(SubjectAverage(
            subject: matiere.libelle,
            notes: notesList,
            average: moyenne,
            coefficient: coef,
            weightedAverage: moyenne * coef,
            rank: rang,
            totalStudents: matiereNotes.isNotEmpty ? matiereNotes.first.effectif : null,
            viewed: viewed,
          ));
        }
      }
      
      print('   📊 Total de SubjectAverage créés: ${averages.length}');
      if (averages.isEmpty && notes.isNotEmpty) {
        print('⚠️ ATTENTION: Des notes ont été chargées mais aucun SubjectAverage n\'a été créé');
        print('   Cela peut indiquer un problème de correspondance entre les matières et les notes');
      }
      print('');

      // Trier par moyenne pondérée décroissante
      averages.sort((a, b) => b.weightedAverage.compareTo(a.weightedAverage));

      if (mounted) {
        setState(() {
          _notesByMatiere = notesByMatiere;
          _allSubjectAverages = averages;
          _filteredSubjectAverages = List.from(averages);
          _isLoadingNotes = false;
          _isLoading = false; // S'assurer que le chargement est terminé
        });
        print('✅ État mis à jour:');
        print('   📊 _allSubjectAverages: ${_allSubjectAverages.length}');
        print('   🔍 _filteredSubjectAverages: ${_filteredSubjectAverages.length}');
        print('   📚 _matieres: ${_matieres.length}');
        print('   ⏳ _isLoading: $_isLoading');
        print('   ⏳ _isLoadingNotes: $_isLoadingNotes');
        print('');
      }

      // Utiliser les moyennes globales depuis l'API
      if (mounted) {
        final globalMoyenne = notesResult.moyenneGlobale ?? 0.0;
        final globalRang = notesResult.rangGlobal ?? 0;

        setState(() {
          _globalAverage = GlobalAverage(
            trimesterAverage: globalMoyenne,
            trimesterRank: globalRang,
            trimesterMention: _getMention(globalMoyenne),
            annualAverage: 0.0, // Non disponible
            annualRank: 0,
            annualMention: '',
          );
        });
      }

      if (mounted) {
        _applyFilters();
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des notes: $e');
      print('Stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _isLoadingNotes = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des notes: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _getMention(double moyenne) {
    if (moyenne >= 16) return 'Très Bien';
    if (moyenne >= 14) return 'Bien';
    if (moyenne >= 12) return 'Assez Bien';
    if (moyenne >= 10) return 'Passable';
    return 'Insuffisant';
  }

  /// Récupère la liste des trimestres depuis les périodes (utilise le cache)
  List<String> get _trimesters => _trimestersList;

  /// Récupère la liste des années depuis l'année scolaire
  List<String> get _years {
    final list = ['Toutes'];
    if (_anneeScolaire != null) {
      for (final annee in _anneeScolaire!.anneeEcoleList) {
        list.add(annee.anneeLibelle);
      }
    }
    return list;
  }

  void _applyFilters() {
    setState(() {
      _filteredSubjectAverages = _allSubjectAverages.where((avg) {
        // Filtrer par matière si sélectionnée
        if (_selectedSubject != null && _selectedSubject!.isNotEmpty && _selectedSubject != 'Toutes') {
          return avg.subject == _selectedSubject;
        }
        return true;
      }).toList();
    });
  }

  void _onSubjectChanged(String value) {
    setState(() {
      _selectedSubject = value == 'Toutes' ? null : value;
    });
    // Recharger les données avec la nouvelle matière
    _loadData(trimester: _selectedTrimester, year: _selectedYear);
  }

  void _onTrimesterChanged(String? value) {
    setState(() {
      _selectedTrimester = value == 'Tous' ? null : value;
    });
    // Recharger les données avec le nouveau trimestre
    _loadData(trimester: _selectedTrimester, year: _selectedYear);
  }


  /// Marque une note comme consultée (Vue)
  Future<void> _markAsViewed(SubjectAverage subjectAvg) async {
    if (_ecoleId == null || _classeId == null || _anneeId == null) {
      print('⚠️ Impossible de marquer comme consulté: informations manquantes');
      return;
    }

    print('👁️  Marquage de la note comme consultée:');
    print('   📚 Matière: ${subjectAvg.subject}');

    // Trouver la matière correspondante
    Matiere? matiere;
    try {
      matiere = _matieres.firstWhere(
        (m) => m.libelle == subjectAvg.subject,
      );
      print('   🆔 Matière ID: ${matiere.id}');
    } catch (e) {
      print('❌ Matière non trouvée: ${subjectAvg.subject}');
      return;
    }

    // Récupérer l'ID de la période actuellement sélectionnée
    int? periodeId;
    String periodeLibelle = '';
    if (_selectedTrimester != null && _selectedTrimester != 'Tous') {
      try {
        final selectedPeriode = _periodes.firstWhere(
          (p) => p.libelle == _selectedTrimester,
        );
        periodeId = selectedPeriode.id;
        periodeLibelle = selectedPeriode.libelle;
      } catch (e) {
        print('⚠️ Période sélectionnée non trouvée, utilisation de la première');
        if (_periodes.isNotEmpty) {
          periodeId = _periodes.first.id;
          periodeLibelle = _periodes.first.libelle;
        }
      }
    } else if (_periodes.isNotEmpty) {
      periodeId = _periodes.first.id;
      periodeLibelle = _periodes.first.libelle;
    }

    if (periodeId == null) {
      print('❌ Aucune période disponible');
      return;
    }

    print('   📆 Période ID: $periodeId');
    print('   📆 Période: $periodeLibelle');
    print('   📅 Année ID: $_anneeId');

    // Marquer comme consulté dans la base de données
    try {
      await DatabaseService.instance.markNoteAsViewed(
        widget.childId,
        matiere.id,
        periodeId,
        _anneeId!,
      );
      print('✅ Note marquée comme consultée dans la base de données');
    } catch (e) {
      print('❌ Erreur lors du marquage: $e');
      return;
    }

    // Mettre à jour l'état
    setState(() {
      final index = _allSubjectAverages.indexWhere((a) => a.subject == subjectAvg.subject);
      if (index >= 0) {
        _allSubjectAverages[index] = SubjectAverage(
          subject: subjectAvg.subject,
          notes: subjectAvg.notes,
          average: subjectAvg.average,
          coefficient: subjectAvg.coefficient,
          weightedAverage: subjectAvg.weightedAverage,
          rank: subjectAvg.rank,
          totalStudents: subjectAvg.totalStudents,
          viewed: true,
        );
        _applyFilters();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Message selon maquette
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Text(
                'Cher parents,\nMerci de vous impliquer régulièrement dans le suivi et l\'amélioration du résultat scolaire de votre enfant.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            // Filtres selon maquette - Année en premier
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Affichage de l'année (non sélectionnable) - Positionné en premier
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Année',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    isDense: true,
                  ),
                  readOnly: true,
                  controller: TextEditingController(
                    text: _selectedYear ?? 'Chargement...',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      flex: 2,
                      child: _isLoading || _matieres.isEmpty
                          ? TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'MATIÈRE',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.search),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                isDense: true,
                              ),
                              readOnly: true,
                              controller: TextEditingController(text: 'Chargement...'),
                            )
                          : Autocomplete<String>(
                              key: ValueKey('matiere_autocomplete_${_matieres.length}_${_selectedSubject}'),
                              initialValue: TextEditingValue(
                                text: _selectedSubject ?? 'Toutes',
                              ),
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return ['Toutes', ..._matieres.map((m) => m.libelle)];
                                }
                                final query = textEditingValue.text.toLowerCase();
                                final filtered = _matieres.where((m) => 
                                  m.libelle.toLowerCase().contains(query)
                                ).map((m) => m.libelle).toList();
                                return ['Toutes', ...filtered];
                              },
                              displayStringForOption: (String option) => option,
                              fieldViewBuilder: (
                                BuildContext context,
                                TextEditingController fieldTextEditingController,
                                FocusNode fieldFocusNode,
                                VoidCallback onFieldSubmitted,
                              ) {
                                return TextFormField(
                                  controller: fieldTextEditingController,
                                  focusNode: fieldFocusNode,
                                  decoration: const InputDecoration(
                                    labelText: 'MATIÈRE',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.search),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                    isDense: true,
                                  ),
                                  onFieldSubmitted: (String value) {
                                    onFieldSubmitted();
                                  },
                                );
                              },
                              onSelected: (String selection) {
                                print('🔄 Matière sélectionnée: $selection');
                                _onSubjectChanged(selection);
                              },
                            ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 2,
                      child: _isLoading || _trimesters.isEmpty
                          ? TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Trimestre',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.search),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                isDense: true,
                              ),
                              readOnly: true,
                              controller: TextEditingController(
                                text: _trimesters.isEmpty ? 'Aucun trimestre disponible' : 'Chargement...',
                              ),
                            )
                          : Autocomplete<String>(
                              key: ValueKey('trimestre_autocomplete_${_trimestersList.length}_${_selectedTrimester}'),
                              initialValue: TextEditingValue(
                                text: _selectedTrimester ?? 'Tous',
                              ),
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return _trimesters;
                                }
                                final query = textEditingValue.text.toLowerCase();
                                return _trimesters.where((t) => 
                                  t.toLowerCase().contains(query)
                                ).toList();
                              },
                              displayStringForOption: (String option) => option,
                              fieldViewBuilder: (
                                BuildContext context,
                                TextEditingController fieldTextEditingController,
                                FocusNode fieldFocusNode,
                                VoidCallback onFieldSubmitted,
                              ) {
                                return TextFormField(
                                  controller: fieldTextEditingController,
                                  focusNode: fieldFocusNode,
                                  decoration: const InputDecoration(
                                    labelText: 'Trimestre',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.search),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                    isDense: true,
                                  ),
                                  onFieldSubmitted: (String value) {
                                    onFieldSubmitted();
                                  },
                                );
                              },
                              onSelected: (String selection) {
                                print('🔄 Trimestre sélectionné: $selection');
                                _onTrimesterChanged(selection);
                              },
                            ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Tableau des notes
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_isLoadingNotes)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_filteredSubjectAverages.isNotEmpty) ...[
              _buildNotesTable(),
              const SizedBox(height: 16),
            ] else if (_allSubjectAverages.isEmpty && !_isLoadingNotes) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune note disponible',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ChildId: ${widget.childId}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Aucune matière ne correspond aux filtres sélectionnés',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
            // Moyennes globales
            if (_globalAverage != null && !_isLoadingNotes) ...[
              const SizedBox(height: 16),
              _buildGlobalAverages(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesTable() {
    if (_filteredSubjectAverages.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth > 0 ? constraints.maxWidth : 300,
              ),
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // En-tête
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[700],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 100, child: _buildHeaderCell('Matière')),
                          SizedBox(width: 80, child: _buildHeaderCell('1', subHeaders: ['N°Dev', 'Date', 'Note'])),
                          SizedBox(width: 80, child: _buildHeaderCell('2', subHeaders: ['N°Dev', 'Date', 'Note'])),
                          SizedBox(width: 80, child: _buildHeaderCell('3', subHeaders: ['N°Dev', 'Date', 'Note'])),
                          SizedBox(width: 80, child: _buildHeaderCell('4', subHeaders: ['N°Dev', 'Date', 'Note'])),
                          SizedBox(width: 60, child: _buildHeaderCell('Moy')),
                          SizedBox(width: 50, child: _buildHeaderCell('Coef')),
                          SizedBox(width: 70, child: _buildHeaderCell('Moy Coef')),
                          SizedBox(width: 50, child: _buildHeaderCell('Rang')),
                          SizedBox(width: 60, child: _buildHeaderCell('Effectif')),
                          SizedBox(width: 50, child: _buildHeaderCell('Vue')),
                        ],
                      ),
                    ),
                    // Lignes de données
                    ..._filteredSubjectAverages.map((avg) => _buildSubjectRow(avg)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCell(String text, {List<String>? subHeaders}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        if (subHeaders != null)
          ...subHeaders.map((h) => Text(
                h,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              )),
      ],
    );
  }

  Widget _buildSubjectRow(SubjectAverage avg) {
    final notes = avg.notes;
    // Alterner les couleurs selon maquette (vert clair et blanc)
    final isEven = _filteredSubjectAverages.indexOf(avg) % 2 == 0;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isEven ? Colors.green[50] : Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(avg.subject, style: const TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 80, child: _buildNoteCell(notes.isNotEmpty ? notes[0] : null)),
          SizedBox(width: 80, child: _buildNoteCell(notes.length > 1 ? notes[1] : null)),
          SizedBox(width: 80, child: _buildNoteCell(notes.length > 2 ? notes[2] : null)),
          SizedBox(width: 80, child: _buildNoteCell(notes.length > 3 ? notes[3] : null)),
          SizedBox(width: 60, child: Center(child: Text(avg.average.toStringAsFixed(2)))),
          SizedBox(width: 50, child: Center(child: Text(avg.coefficient.toStringAsFixed(1)))),
          SizedBox(width: 70, child: Center(child: Text(avg.weightedAverage.toStringAsFixed(2)))),
          SizedBox(width: 50, child: Center(child: Text(avg.rank?.toString() ?? '-'))),
          SizedBox(width: 60, child: Center(child: Text(avg.totalStudents?.toString() ?? '-'))),
          SizedBox(
            width: 50,
            child: Center(
              // Icône circulaire jaune selon maquette - cliquable pour marquer comme consulté
              child: GestureDetector(
                onTap: () {
                  if (!avg.viewed) {
                    _markAsViewed(avg);
                  }
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: Center(
                    child: avg.viewed
                        ? const Text('V', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black))
                        : const Text('', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCell(Note? note) {
    if (note == null) return const Text('-');
    // Afficher la note au format "note/note sur"
    final noteText = note.noteSur != null 
        ? '${note.grade.toStringAsFixed(1)}/${note.noteSur!.toStringAsFixed(0)}'
        : note.grade.toStringAsFixed(1);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${note.assignmentNumber}'),
        Text(
          '${note.date.day}/${note.date.month}',
          style: const TextStyle(fontSize: 10),
        ),
        Text(
          noteText,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildGlobalAverages() {
    if (_globalAverage == null) return const SizedBox.shrink();
    
    return Row(
      children: [
        Expanded(
          child: CustomCard(
            backgroundColor: Colors.green[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Moyenne Partielle Trimestrielle en Cours',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_globalAverage!.trimesterAverage.toStringAsFixed(2)} Rang ${_globalAverage!.trimesterRank}${_getOrdinalSuffix(_globalAverage!.trimesterRank)} ${_globalAverage!.trimesterMention}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_globalAverage!.trimesterAverage == 0.0)
                  Text(
                    'Aucune note disponible',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CustomCard(
            backgroundColor: Colors.green[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Moyenne Partielle Annuelle',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _globalAverage!.annualAverage > 0
                      ? '${_globalAverage!.annualAverage.toStringAsFixed(2)} Rang ${_globalAverage!.annualRank}${_getOrdinalSuffix(_globalAverage!.annualRank)} ${_globalAverage!.annualMention}'
                      : 'Non disponible',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _globalAverage!.annualAverage > 0 ? null : Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getOrdinalSuffix(int number) {
    if (number == 1) return 'er';
    return 'ème';
  }
}


