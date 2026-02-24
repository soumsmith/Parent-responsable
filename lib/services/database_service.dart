import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/child.dart';

/// Service de gestion de la base de données locale SQLite
class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  factory DatabaseService() => instance;
  DatabaseService._internal();

  static Database? _database;

  /// Récupère l'instance de la base de données
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialise la base de données et crée les tables
  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'pouls_ecole_parent.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crée les tables lors de la première création de la base de données
  Future<void> _onCreate(Database db, int version) async {
    // Table des utilisateurs
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        smsCredits INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Table des enfants
    await db.execute('''
      CREATE TABLE children (
        id TEXT PRIMARY KEY,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        establishment TEXT NOT NULL,
        grade TEXT NOT NULL,
        photoUrl TEXT,
        parentId TEXT NOT NULL,
        matricule TEXT,
        ecoleId INTEGER,
        ecoleName TEXT,
        classeId INTEGER,
        classeName TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        FOREIGN KEY (parentId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Table pour suivre les notes consultées (Vue)
    await db.execute('''
      CREATE TABLE notes_viewed (
        id TEXT PRIMARY KEY,
        childId TEXT NOT NULL,
        matiereId INTEGER NOT NULL,
        periodeId INTEGER NOT NULL,
        anneeId INTEGER NOT NULL,
        viewedAt INTEGER NOT NULL,
        FOREIGN KEY (childId) REFERENCES children(id) ON DELETE CASCADE
      )
    ''');

    // Index pour améliorer les performances
    await db.execute('CREATE INDEX idx_notes_viewed_child ON notes_viewed(childId, matiereId, periodeId)');

    // Table des notifications FCM
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        data TEXT,
        timestamp INTEGER NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0,
        sender TEXT,
        parentId TEXT,
        FOREIGN KEY (parentId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Index pour améliorer les performances
    await db.execute('CREATE INDEX idx_children_parentId ON children(parentId)');
    await db.execute('CREATE INDEX idx_children_matricule ON children(matricule)');
    await db.execute('CREATE INDEX idx_notifications_parentId ON notifications(parentId)');
    await db.execute('CREATE INDEX idx_notifications_timestamp ON notifications(timestamp DESC)');
    await db.execute('CREATE INDEX idx_notifications_isRead ON notifications(isRead)');
    await _createV4Tables(db);
  }
  
  /// Tables ajoutées en version 4 (notes, fees, payments, attendance, etc.)
  Future<void> _createV4Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id TEXT PRIMARY KEY,
        childId TEXT NOT NULL,
        matiereId INTEGER NOT NULL,
        matiereNom TEXT NOT NULL,
        note REAL NOT NULL,
        coefficient REAL NOT NULL DEFAULT 1.0,
        periodeId INTEGER NOT NULL,
        anneeId INTEGER NOT NULL,
        dateNote TEXT,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (childId) REFERENCES children(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_childId ON notes(childId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_periode ON notes(childId, periodeId, anneeId)');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS averages (
        childId TEXT NOT NULL,
        periodeId INTEGER NOT NULL,
        anneeId INTEGER NOT NULL,
        moyenne REAL NOT NULL,
        rang INTEGER,
        updatedAt INTEGER NOT NULL,
        PRIMARY KEY (childId, periodeId, anneeId),
        FOREIGN KEY (childId) REFERENCES children(id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS fees (
        id TEXT PRIMARY KEY,
        childId TEXT NOT NULL,
        libelle TEXT,
        montantTotal REAL NOT NULL,
        montantPaye REAL NOT NULL DEFAULT 0,
        dateEcheance INTEGER,
        statut TEXT,
        updatedAt INTEGER NOT NULL,
        FOREIGN KEY (childId) REFERENCES children(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_fees_childId ON fees(childId)');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id TEXT PRIMARY KEY,
        feeId TEXT,
        childId TEXT NOT NULL,
        montant REAL NOT NULL,
        datePaiement INTEGER NOT NULL,
        mode TEXT,
        reference TEXT,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (childId) REFERENCES children(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payments_childId ON payments(childId)');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance (
        id TEXT PRIMARY KEY,
        childId TEXT NOT NULL,
        date INTEGER NOT NULL,
        statut TEXT NOT NULL,
        motif TEXT,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (childId) REFERENCES children(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_attendance_childId ON attendance(childId)');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sanctions (
        id TEXT PRIMARY KEY,
        childId TEXT NOT NULL,
        type TEXT,
        libelle TEXT,
        dateSanction INTEGER NOT NULL,
        description TEXT,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (childId) REFERENCES children(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sanctions_childId ON sanctions(childId)');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS timetable (
        id TEXT PRIMARY KEY,
        childId TEXT NOT NULL,
        jourSemaine INTEGER NOT NULL,
        heureDebut TEXT NOT NULL,
        heureFin TEXT NOT NULL,
        matiereNom TEXT NOT NULL,
        salle TEXT,
        professeur TEXT,
        semaine INTEGER,
        updatedAt INTEGER NOT NULL,
        FOREIGN KEY (childId) REFERENCES children(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_timetable_childId ON timetable(childId)');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS report_cards (
        id TEXT PRIMARY KEY,
        childId TEXT NOT NULL,
        periodeId INTEGER NOT NULL,
        anneeId INTEGER NOT NULL,
        fileUrl TEXT,
        filePath TEXT,
        qrData TEXT,
        updatedAt INTEGER NOT NULL,
        FOREIGN KEY (childId) REFERENCES children(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_report_cards_childId ON report_cards(childId)');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS risk_alerts (
        id TEXT PRIMARY KEY,
        childId TEXT NOT NULL,
        matiereNom TEXT,
        score REAL,
        recommandation TEXT,
        updatedAt INTEGER NOT NULL,
        FOREIGN KEY (childId) REFERENCES children(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_risk_alerts_childId ON risk_alerts(childId)');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS threads (
        id TEXT PRIMARY KEY,
        parentId TEXT NOT NULL,
        title TEXT,
        lastMessageAt INTEGER,
        unreadCount INTEGER DEFAULT 0,
        updatedAt INTEGER NOT NULL,
        FOREIGN KEY (parentId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_threads_parentId ON threads(parentId)');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        id TEXT PRIMARY KEY,
        threadId TEXT NOT NULL,
        senderId TEXT,
        senderName TEXT,
        content TEXT NOT NULL,
        isFromMe INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL,
        readAt INTEGER,
        FOREIGN KEY (threadId) REFERENCES threads(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_threadId ON messages(threadId)');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS events (
        id TEXT PRIMARY KEY,
        ecoleId INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        dateDebut INTEGER NOT NULL,
        dateFin INTEGER,
        lieu TEXT,
        type TEXT,
        updatedAt INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_events_ecoleId ON events(ecoleId)');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tickets (
        id TEXT PRIMARY KEY,
        eventId TEXT NOT NULL,
        parentId TEXT NOT NULL,
        childId TEXT,
        qrCode TEXT,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (eventId) REFERENCES events(id),
        FOREIGN KEY (parentId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tickets_eventId ON tickets(eventId)');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS supplies (
        id TEXT PRIMARY KEY,
        classeId INTEGER NOT NULL,
        libelle TEXT NOT NULL,
        description TEXT,
        prix REAL,
        updatedAt INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_supplies_classeId ON supplies(classeId)');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS orders (
        id TEXT PRIMARY KEY,
        parentId TEXT NOT NULL,
        childId TEXT,
        statut TEXT NOT NULL,
        total REAL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        FOREIGN KEY (parentId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_orders_parentId ON orders(parentId)');
  }

  /// Met à jour la base de données lors d'un changement de version
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Ajouter la table notes_viewed si elle n'existe pas
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notes_viewed (
          id TEXT PRIMARY KEY,
          childId TEXT NOT NULL,
          matiereId INTEGER NOT NULL,
          periodeId INTEGER NOT NULL,
          anneeId INTEGER NOT NULL,
          viewedAt INTEGER NOT NULL,
          FOREIGN KEY (childId) REFERENCES children(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_viewed_child ON notes_viewed(childId, matiereId, periodeId)');
    }
    if (oldVersion < 3) {
      // Ajouter la table notifications si elle n'existe pas
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          data TEXT,
          timestamp INTEGER NOT NULL,
          isRead INTEGER NOT NULL DEFAULT 0,
          sender TEXT,
          parentId TEXT,
          FOREIGN KEY (parentId) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_parentId ON notifications(parentId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_timestamp ON notifications(timestamp DESC)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_isRead ON notifications(isRead)');
    }
    if (oldVersion < 4) {
      await _createV4Tables(db);
    }
  }

  /// Sauvegarde ou met à jour un utilisateur
  Future<void> saveUser(User user) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.insert(
      'users',
      {
        'id': user.id,
        'email': user.email,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'phone': user.phone,
        'smsCredits': user.smsCredits,
        'createdAt': now,
        'updatedAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère un utilisateur par son ID
  Future<User?> getUserById(String userId) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isEmpty) return null;

    return User.fromJson(Map<String, dynamic>.from(maps.first));
  }

  /// Récupère un utilisateur par son numéro de téléphone
  Future<User?> getUserByPhone(String phone) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'phone = ?',
      whereArgs: [phone],
    );

    if (maps.isEmpty) return null;

    return User.fromJson(Map<String, dynamic>.from(maps.first));
  }

  /// Met à jour les crédits SMS d'un utilisateur
  Future<void> updateUserSmsCredits(String userId, int credits) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.update(
      'users',
      {
        'smsCredits': credits,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Sauvegarde ou met à jour un enfant
  Future<void> saveChild(Child child, {
    String? matricule,
    int? ecoleId,
    String? ecoleName,
    int? classeId,
    String? classeName,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.insert(
      'children',
      {
        'id': child.id,
        'firstName': child.firstName,
        'lastName': child.lastName,
        'establishment': child.establishment,
        'grade': child.grade,
        'photoUrl': child.photoUrl,
        'parentId': child.parentId,
        'matricule': matricule,
        'ecoleId': ecoleId,
        'ecoleName': ecoleName,
        'classeId': classeId,
        'classeName': classeName,
        'createdAt': now,
        'updatedAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère tous les enfants d'un parent
  Future<List<Child>> getChildrenByParent(String parentId) async {
    final db = await database;
    final maps = await db.query(
      'children',
      where: 'parentId = ?',
      whereArgs: [parentId],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) {
      return Child.fromJson(Map<String, dynamic>.from(map));
    }).toList();
  }

  /// Récupère un enfant par son ID
  Future<Child?> getChildById(String childId) async {
    final db = await database;
    final maps = await db.query(
      'children',
      where: 'id = ?',
      whereArgs: [childId],
    );

    if (maps.isEmpty) return null;

    return Child.fromJson(Map<String, dynamic>.from(maps.first));
  }

  /// Récupère les informations complètes d'un enfant (avec ecoleId et classeId)
  Future<Map<String, dynamic>?> getChildInfoById(String childId) async {
    final db = await database;
    final maps = await db.query(
      'children',
      where: 'id = ?',
      whereArgs: [childId],
    );

    if (maps.isEmpty) return null;

    return Map<String, dynamic>.from(maps.first);
  }

  /// Récupère les informations complètes de tous les enfants d'un parent (avec matricule)
  Future<List<Map<String, dynamic>>> getChildrenInfoByParent(String parentId) async {
    final db = await database;
    final maps = await db.query(
      'children',
      where: 'parentId = ?',
      whereArgs: [parentId],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  /// Récupère un enfant par son matricule
  Future<Child?> getChildByMatricule(String matricule) async {
    final db = await database;
    final maps = await db.query(
      'children',
      where: 'matricule = ?',
      whereArgs: [matricule],
    );

    if (maps.isEmpty) return null;

    return Child.fromJson(Map<String, dynamic>.from(maps.first));
  }

  /// Met à jour la photo d'un enfant
  Future<void> updateChildPhoto(String childId, String? photoUrl) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'children',
      {
        'photoUrl': photoUrl,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [childId],
    );
    print('✅ Photo mise à jour pour l\'enfant $childId: ${photoUrl ?? "null"}');
  }

  /// Supprime un enfant
  Future<void> deleteChild(String childId) async {
    final db = await database;
    await db.delete(
      'children',
      where: 'id = ?',
      whereArgs: [childId],
    );
  }

  /// Supprime tous les enfants d'un parent
  Future<void> deleteChildrenByParent(String parentId) async {
    final db = await database;
    await db.delete(
      'children',
      where: 'parentId = ?',
      whereArgs: [parentId],
    );
  }

  /// Supprime un utilisateur et tous ses enfants
  Future<void> deleteUser(String userId) async {
    final db = await database;
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    // Les enfants seront supprimés automatiquement grâce à ON DELETE CASCADE
  }

  /// Marque une note comme consultée (Vue)
  Future<void> markNoteAsViewed(String childId, int matiereId, int periodeId, int anneeId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = '${childId}_${matiereId}_${periodeId}_${anneeId}';
    
    await db.insert(
      'notes_viewed',
      {
        'id': id,
        'childId': childId,
        'matiereId': matiereId,
        'periodeId': periodeId,
        'anneeId': anneeId,
        'viewedAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Vérifie si une note a été consultée
  Future<bool> isNoteViewed(String childId, int matiereId, int periodeId, int anneeId) async {
    final db = await database;
    final id = '${childId}_${matiereId}_${periodeId}_${anneeId}';
    
    final maps = await db.query(
      'notes_viewed',
      where: 'id = ?',
      whereArgs: [id],
    );

    return maps.isNotEmpty;
  }

  /// Sauvegarde une notification FCM
  Future<void> saveNotification({
    required String id,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    required DateTime timestamp,
    String? sender,
    String? parentId,
  }) async {
    final db = await database;
    await db.insert(
      'notifications',
      {
        'id': id,
        'title': title,
        'body': body,
        'data': data != null ? jsonEncode(data) : null,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'isRead': 0,
        'sender': sender,
        'parentId': parentId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère toutes les notifications d'un parent
  Future<List<Map<String, dynamic>>> getNotificationsByParent(String parentId) async {
    final db = await database;
    final maps = await db.query(
      'notifications',
      where: 'parentId = ?',
      whereArgs: [parentId],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) {
      final result = Map<String, dynamic>.from(map);
      // Parser le champ data si présent
      if (result['data'] != null && result['data'] is String) {
        try {
          result['data'] = jsonDecode(result['data'] as String);
        } catch (e) {
          result['data'] = null;
        }
      }
      // Convertir isRead de INTEGER à bool
      result['isRead'] = (result['isRead'] as int? ?? 0) == 1;
      return result;
    }).toList();
  }

  /// Marque une notification comme lue
  Future<void> markNotificationAsRead(String notificationId) async {
    final db = await database;
    await db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  /// Marque toutes les notifications d'un parent comme lues
  Future<void> markAllNotificationsAsRead(String parentId) async {
    final db = await database;
    await db.update(
      'notifications',
      {'isRead': 1},
      where: 'parentId = ? AND isRead = ?',
      whereArgs: [parentId, 0],
    );
  }

  /// Récupère le nombre de notifications non lues d'un parent
  Future<int> getUnreadNotificationsCount(String parentId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE parentId = ? AND isRead = 0',
      [parentId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Supprime une notification
  Future<void> deleteNotification(String notificationId) async {
    final db = await database;
    await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  /// Supprime toutes les notifications d'un parent
  Future<void> deleteNotificationsByParent(String parentId) async {
    final db = await database;
    await db.delete(
      'notifications',
      where: 'parentId = ?',
      whereArgs: [parentId],
    );
  }

  // ---------- Notes (version 4) ----------
  Future<void> saveNotes(String childId, int periodeId, int anneeId, List<Map<String, dynamic>> notesList) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.delete('notes', where: 'childId = ? AND periodeId = ? AND anneeId = ?', whereArgs: [childId, periodeId, anneeId]);
    for (final n in notesList) {
      await db.insert('notes', {
        'id': n['id'] ?? '${childId}_${n['matiereId']}_${n['periodeId']}_$now',
        'childId': childId,
        'matiereId': n['matiereId'] as int,
        'matiereNom': n['matiereNom'] as String,
        'note': (n['note'] as num).toDouble(),
        'coefficient': (n['coefficient'] as num?)?.toDouble() ?? 1.0,
        'periodeId': periodeId,
        'anneeId': anneeId,
        'dateNote': n['dateNote'] as String?,
        'createdAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Map<String, dynamic>>> getNotesByChildAndPeriode(String childId, int periodeId, int anneeId) async {
    final db = await database;
    final maps = await db.query('notes', where: 'childId = ? AND periodeId = ? AND anneeId = ?', whereArgs: [childId, periodeId, anneeId]);
    return maps.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  Future<void> saveAverage(String childId, int periodeId, int anneeId, double moyenne, int? rang) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('averages', {
      'childId': childId,
      'periodeId': periodeId,
      'anneeId': anneeId,
      'moyenne': moyenne,
      'rang': rang,
      'updatedAt': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getAverage(String childId, int periodeId, int anneeId) async {
    final db = await database;
    final maps = await db.query('averages', where: 'childId = ? AND periodeId = ? AND anneeId = ?', whereArgs: [childId, periodeId, anneeId]);
    if (maps.isEmpty) return null;
    return Map<String, dynamic>.from(maps.first);
  }

  /// Dernière moyenne enregistrée pour un enfant (pour dashboard)
  Future<Map<String, dynamic>?> getLastAverageByChild(String childId) async {
    final db = await database;
    final maps = await db.query('averages', where: 'childId = ?', whereArgs: [childId], orderBy: 'updatedAt DESC', limit: 1);
    if (maps.isEmpty) return null;
    return Map<String, dynamic>.from(maps.first);
  }

  // ---------- Fees & Payments (version 4) ----------
  Future<void> saveFees(String childId, List<Map<String, dynamic>> feesList) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.delete('fees', where: 'childId = ?', whereArgs: [childId]);
    for (final f in feesList) {
      await db.insert('fees', {
        'id': f['id'] as String? ?? '${childId}_${now}_${f.hashCode}',
        'childId': childId,
        'libelle': f['libelle'],
        'montantTotal': (f['montantTotal'] as num).toDouble(),
        'montantPaye': (f['montantPaye'] as num?)?.toDouble() ?? 0,
        'dateEcheance': f['dateEcheance'],
        'statut': f['statut'],
        'updatedAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Map<String, dynamic>>> getFeesByChild(String childId) async {
    final db = await database;
    final maps = await db.query('fees', where: 'childId = ?', whereArgs: [childId]);
    return maps.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  Future<void> savePayments(String childId, List<Map<String, dynamic>> paymentsList) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.delete('payments', where: 'childId = ?', whereArgs: [childId]);
    for (final p in paymentsList) {
      await db.insert('payments', {
        'id': p['id'] as String? ?? 'pay_${now}_${p.hashCode}',
        'feeId': p['feeId'],
        'childId': childId,
        'montant': (p['montant'] as num).toDouble(),
        'datePaiement': p['datePaiement'],
        'mode': p['mode'],
        'reference': p['reference'],
        'createdAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentsByChild(String childId) async {
    final db = await database;
    final maps = await db.query('payments', where: 'childId = ?', whereArgs: [childId], orderBy: 'datePaiement DESC');
    return maps.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  // ---------- Attendance & Sanctions ----------
  Future<void> saveAttendance(String childId, List<Map<String, dynamic>> list) async {
    final db = await database;
    await db.delete('attendance', where: 'childId = ?', whereArgs: [childId]);
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final a in list) {
      await db.insert('attendance', {
        'id': a['id'] as String? ?? 'att_${childId}_${a['date']}_$now',
        'childId': childId,
        'date': a['date'],
        'statut': a['statut'] as String,
        'motif': a['motif'],
        'createdAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceByChild(String childId) async {
    final db = await database;
    final maps = await db.query('attendance', where: 'childId = ?', whereArgs: [childId], orderBy: 'date DESC');
    return maps.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  Future<void> saveSanctions(String childId, List<Map<String, dynamic>> list) async {
    final db = await database;
    await db.delete('sanctions', where: 'childId = ?', whereArgs: [childId]);
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final s in list) {
      await db.insert('sanctions', {
        'id': s['id'] as String? ?? 'sanct_${childId}_$now',
        'childId': childId,
        'type': s['type'],
        'libelle': s['libelle'],
        'dateSanction': s['dateSanction'],
        'description': s['description'],
        'createdAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Map<String, dynamic>>> getSanctionsByChild(String childId) async {
    final db = await database;
    final maps = await db.query('sanctions', where: 'childId = ?', whereArgs: [childId], orderBy: 'dateSanction DESC');
    return maps.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  // ---------- Timetable ----------
  Future<void> saveTimetable(String childId, List<Map<String, dynamic>> list) async {
    final db = await database;
    await db.delete('timetable', where: 'childId = ?', whereArgs: [childId]);
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final t in list) {
      await db.insert('timetable', {
        'id': t['id'] as String? ?? 'tt_${childId}_${t['jourSemaine']}_${t['heureDebut']}_$now',
        'childId': childId,
        'jourSemaine': t['jourSemaine'],
        'heureDebut': t['heureDebut'],
        'heureFin': t['heureFin'],
        'matiereNom': t['matiereNom'],
        'salle': t['salle'],
        'professeur': t['professeur'],
        'semaine': t['semaine'],
        'updatedAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Map<String, dynamic>>> getTimetableByChild(String childId) async {
    final db = await database;
    final maps = await db.query('timetable', where: 'childId = ?', whereArgs: [childId], orderBy: 'jourSemaine, heureDebut');
    return maps.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  // ---------- Risk alerts (élève en difficulté) ----------
  Future<void> saveRiskAlerts(String childId, List<Map<String, dynamic>> list) async {
    final db = await database;
    await db.delete('risk_alerts', where: 'childId = ?', whereArgs: [childId]);
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final r in list) {
      await db.insert('risk_alerts', {
        'id': r['id'] as String? ?? 'risk_${childId}_${r['matiereNom']}_$now',
        'childId': childId,
        'matiereNom': r['matiereNom'],
        'score': (r['score'] as num?)?.toDouble(),
        'recommandation': r['recommandation'],
        'updatedAt': now,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getRiskAlertsByChild(String childId) async {
    final db = await database;
    final maps = await db.query('risk_alerts', where: 'childId = ?', whereArgs: [childId], orderBy: 'score ASC');
    return maps.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  // ---------- Threads & Messages (messagerie) ----------
  Future<void> saveThread(Map<String, dynamic> thread) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('threads', {
      'id': thread['id'],
      'parentId': thread['parentId'],
      'title': thread['title'],
      'lastMessageAt': thread['lastMessageAt'],
      'unreadCount': thread['unreadCount'] ?? 0,
      'updatedAt': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getThreadsByParent(String parentId) async {
    final db = await database;
    final maps = await db.query('threads', where: 'parentId = ?', whereArgs: [parentId], orderBy: 'lastMessageAt DESC');
    return maps.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  Future<void> saveMessages(String threadId, List<Map<String, dynamic>> list) async {
    final db = await database;
    await db.delete('messages', where: 'threadId = ?', whereArgs: [threadId]);
    for (final m in list) {
      await db.insert('messages', {
        'id': m['id'],
        'threadId': threadId,
        'senderId': m['senderId'],
        'senderName': m['senderName'],
        'content': m['content'],
        'isFromMe': (m['isFromMe'] as bool? ?? false) ? 1 : 0,
        'createdAt': m['createdAt'],
        'readAt': m['readAt'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Map<String, dynamic>>> getMessagesByThread(String threadId) async {
    final db = await database;
    final maps = await db.query('messages', where: 'threadId = ?', whereArgs: [threadId], orderBy: 'createdAt ASC');
    return maps.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  /// Insère un seul message (ex: après envoi)
  Future<void> insertMessage(Map<String, dynamic> message) async {
    final db = await database;
    await db.insert('messages', {
      'id': message['id'],
      'threadId': message['threadId'],
      'senderId': message['senderId'],
      'senderName': message['senderName'],
      'content': message['content'],
      'isFromMe': (message['isFromMe'] as bool? ?? false) ? 1 : 0,
      'createdAt': message['createdAt'],
      'readAt': message['readAt'],
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Met à jour lastMessageAt et unreadCount d'un thread
  Future<void> updateThreadLastMessage(String threadId, int lastMessageAt, {int unreadCount = 0}) async {
    final db = await database;
    await db.update('threads', {'lastMessageAt': lastMessageAt, 'unreadCount': unreadCount, 'updatedAt': DateTime.now().millisecondsSinceEpoch}, where: 'id = ?', whereArgs: [threadId]);
  }

  // ---------- Events & Tickets ----------
  Future<void> saveEvents(int ecoleId, List<Map<String, dynamic>> list) async {
    final db = await database;
    await db.delete('events', where: 'ecoleId = ?', whereArgs: [ecoleId]);
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final e in list) {
      await db.insert('events', {
        'id': e['id'] ?? 'ev_${ecoleId}_${e['title']}_$now',
        'ecoleId': ecoleId,
        'title': e['title'] ?? '',
        'description': e['description'],
        'dateDebut': e['dateDebut'] ?? e['dateDebutMs'] ?? now,
        'dateFin': e['dateFin'] ?? e['dateFinMs'],
        'lieu': e['lieu'],
        'type': e['type'],
        'updatedAt': now,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getEventsByEcole(int ecoleId) async {
    final db = await database;
    final maps = await db.query('events', where: 'ecoleId = ?', whereArgs: [ecoleId], orderBy: 'dateDebut DESC');
    return maps.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  Future<void> saveTicket(Map<String, dynamic> ticket) async {
    final db = await database;
    await db.insert('tickets', {
      'id': ticket['id'],
      'eventId': ticket['eventId'],
      'parentId': ticket['parentId'],
      'childId': ticket['childId'],
      'qrCode': ticket['qrCode'],
      'createdAt': ticket['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getTicketsByParent(String parentId) async {
    final db = await database;
    final maps = await db.query('tickets', where: 'parentId = ?', whereArgs: [parentId], orderBy: 'createdAt DESC');
    return maps.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  Future<List<Map<String, dynamic>>> getTicketsByEvent(String eventId) async {
    final db = await database;
    final maps = await db.query('tickets', where: 'eventId = ?', whereArgs: [eventId]);
    return maps.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  // ---------- Supplies & Orders ----------
  Future<void> saveSupplies(int classeId, List<Map<String, dynamic>> list) async {
    final db = await database;
    await db.delete('supplies', where: 'classeId = ?', whereArgs: [classeId]);
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final s in list) {
      await db.insert('supplies', {
        'id': s['id'] ?? 'sup_${classeId}_${s['libelle']}_$now',
        'classeId': classeId,
        'libelle': s['libelle'] ?? '',
        'description': s['description'],
        'prix': (s['prix'] as num?)?.toDouble(),
        'updatedAt': now,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getSuppliesByClasse(int classeId) async {
    final db = await database;
    final maps = await db.query('supplies', where: 'classeId = ?', whereArgs: [classeId], orderBy: 'libelle');
    return maps.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  Future<void> saveOrders(String parentId, List<Map<String, dynamic>> list) async {
    final db = await database;
    await db.delete('orders', where: 'parentId = ?', whereArgs: [parentId]);
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final o in list) {
      await db.insert('orders', {
        'id': o['id'] ?? 'ord_${parentId}_$now',
        'parentId': parentId,
        'childId': o['childId'],
        'statut': o['statut'] ?? 'PENDING',
        'total': (o['total'] as num?)?.toDouble(),
        'createdAt': o['createdAt'] ?? now,
        'updatedAt': o['updatedAt'] ?? now,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getOrdersByParent(String parentId) async {
    final db = await database;
    final maps = await db.query('orders', where: 'parentId = ?', whereArgs: [parentId], orderBy: 'createdAt DESC');
    return maps.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  /// Ferme la base de données
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

