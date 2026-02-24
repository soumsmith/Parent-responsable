import '../models/child.dart';
import '../models/note.dart';
import '../models/timetable_entry.dart';
import '../models/message.dart';
import '../models/fee.dart';
import 'api_service.dart';

/// Implémentation future pour les appels API REST (Quarkus)
/// 
/// TODO: Implémenter les appels HTTP réels
/// 
/// Exemple d'implémentation :
/// ```dart
/// @override
/// Future<List<Child>> getChildrenForParent(String parentId) async {
///   final token = await AuthService.instance.getToken();
///   final response = await http.get(
///     Uri.parse('${AppConfig.API_BASE_URL}/api/parents/$parentId/children'),
///     headers: {
///       'Authorization': 'Bearer $token',
///       'Content-Type': 'application/json',
///     },
///   ).timeout(AppConfig.API_TIMEOUT);
///   
///   if (response.statusCode == 200) {
///     final List<dynamic> data = json.decode(response.body);
///     return data.map((json) => Child.fromJson(json)).toList();
///   } else {
///     throw Exception('Failed to load children: ${response.statusCode}');
///   }
/// }
/// ```
/// 
/// Dépendances à ajouter dans pubspec.yaml :
/// - http: ^1.1.0
/// - dio: ^5.4.0 (alternative à http)
class RemoteApiService implements ApiService {
  // TODO: Injecter AuthService pour récupérer le token JWT
  // TODO: Injecter un client HTTP (http ou dio)
  
  @override
  Future<List<Child>> getChildrenForParent(String parentId) {
    // TODO: Implémenter l'appel HTTP
    throw UnimplementedError('RemoteApiService not yet implemented');
  }

  @override
  Future<List<Note>> getNotesForChild(String childId, {String? trimester, String? year}) {
    // TODO: Implémenter l'appel HTTP
    throw UnimplementedError('RemoteApiService not yet implemented');
  }

  @override
  Future<List<SubjectAverage>> getSubjectAveragesForChild(String childId, {String? trimester, String? year}) {
    // TODO: Implémenter l'appel HTTP
    throw UnimplementedError('RemoteApiService not yet implemented');
  }

  @override
  Future<GlobalAverage> getGlobalAveragesForChild(String childId, {String? trimester, String? year}) {
    // TODO: Implémenter l'appel HTTP
    throw UnimplementedError('RemoteApiService not yet implemented');
  }

  @override
  Future<List<TimetableEntry>> getTimetableForChild(String childId) {
    // TODO: Implémenter l'appel HTTP
    throw UnimplementedError('RemoteApiService not yet implemented');
  }

  @override
  Future<List<Message>> getMessages(String parentId) {
    // TODO: Implémenter l'appel HTTP
    throw UnimplementedError('RemoteApiService not yet implemented');
  }

  @override
  Future<List<Fee>> getFeesForChild(String childId) {
    // TODO: Implémenter l'appel HTTP
    throw UnimplementedError('RemoteApiService not yet implemented');
  }

  @override
  Future<bool> addChild(String parentId, Child child) {
    // TODO: Implémenter l'appel HTTP
    // POST /api/parents/{parentId}/children
    throw UnimplementedError('RemoteApiService not yet implemented');
  }

  // ---------- Domaines étendus (TODO: appels HTTP vers backend) ----------
  @override
  Future<List<Map<String, dynamic>>> getAttendanceForChild(String childId) async {
    // TODO: GET /api/children/{childId}/attendance ou équivalent
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getSanctionsForChild(String childId) async {
    // TODO: GET /api/children/{childId}/sanctions
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getRiskAlertsForChild(String childId) async {
    // TODO: GET /api/children/{childId}/risk-analysis
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getMessageThreads(String parentId) async {
    // TODO: GET /api/parents/{parentId}/messages/threads
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getEventsForEcole(int ecoleId) async {
    // TODO: GET /api/schools/{ecoleId}/events
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getSuppliesForClasse(int classeId) async {
    // TODO: GET /api/classes/{classeId}/supplies
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getOrdersForParent(String parentId) async {
    // TODO: GET /api/orders?parentId=
    return [];
  }
}

