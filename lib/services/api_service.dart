import '../models/child.dart';
import '../models/note.dart';
import '../models/timetable_entry.dart';
import '../models/message.dart';
import '../models/fee.dart';

/// Interface abstraite pour les services API
/// 
/// TODO: En production, RemoteApiService implémentera ces méthodes
/// avec des appels HTTP vers les endpoints Quarkus :
/// - GET /api/parents/{parentId}/children
/// - GET /api/children/{childId}/notes
/// - GET /api/children/{childId}/timetable
/// - GET /api/parents/{parentId}/messages
/// - GET /api/children/{childId}/fees
/// 
/// Headers requis :
/// - Authorization: Bearer {JWT_TOKEN}
/// - Content-Type: application/json
abstract class ApiService {
  /// Récupère la liste des enfants d'un parent
  /// 
  /// Endpoint: GET /api/parents/{parentId}/children
  Future<List<Child>> getChildrenForParent(String parentId);

  /// Récupère les notes d'un enfant
  /// 
  /// Endpoint: GET /api/children/{childId}/notes?trimester={trimester}&year={year}
  Future<List<Note>> getNotesForChild(String childId, {String? trimester, String? year});

  /// Récupère les moyennes par matière d'un enfant
  /// 
  /// Endpoint: GET /api/children/{childId}/notes/averages?trimester={trimester}&year={year}
  Future<List<SubjectAverage>> getSubjectAveragesForChild(String childId, {String? trimester, String? year});

  /// Récupère les moyennes globales d'un enfant
  /// 
  /// Endpoint: GET /api/children/{childId}/notes/global-averages?trimester={trimester}&year={year}
  Future<GlobalAverage> getGlobalAveragesForChild(String childId, {String? trimester, String? year});

  /// Récupère l'emploi du temps d'un enfant
  /// 
  /// Endpoint: GET /api/children/{childId}/timetable
  Future<List<TimetableEntry>> getTimetableForChild(String childId);

  /// Récupère les messages d'un parent
  /// 
  /// Endpoint: GET /api/parents/{parentId}/messages
  Future<List<Message>> getMessages(String parentId);

  /// Récupère les frais de scolarité d'un enfant
  /// 
  /// Endpoint: GET /api/children/{childId}/fees
  Future<List<Fee>> getFeesForChild(String childId);

  /// Ajoute un enfant à un parent
  /// 
  /// Endpoint: POST /api/parents/{parentId}/children
  /// Body: { "firstName": "...", "lastName": "...", "establishment": "...", "grade": "..." }
  /// Response: { "id": "...", "child": {...} }
  Future<bool> addChild(String parentId, Child child);

  // ---------- Domaines étendus (présence, conduite, risque, messagerie, événements, fournitures, commandes) ----------
  // En MOCK_MODE, MockApiService lit depuis SQLite. En production, RemoteApiService appellera les endpoints backend.

  /// Présence : liste des enregistrements (date, statut, motif)
  Future<List<Map<String, dynamic>>> getAttendanceForChild(String childId);

  /// Sanctions / conduite
  Future<List<Map<String, dynamic>>> getSanctionsForChild(String childId);

  /// Alertes risque (élève en difficulté)
  Future<List<Map<String, dynamic>>> getRiskAlertsForChild(String childId);

  /// Threads de messagerie du parent
  Future<List<Map<String, dynamic>>> getMessageThreads(String parentId);

  /// Événements d'un établissement
  Future<List<Map<String, dynamic>>> getEventsForEcole(int ecoleId);

  /// Fournitures d'une classe
  Future<List<Map<String, dynamic>>> getSuppliesForClasse(int classeId);

  /// Commandes du parent
  Future<List<Map<String, dynamic>>> getOrdersForParent(String parentId);
}

