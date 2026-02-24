/// Modèle représentant des frais de scolarité
class Fee {
  final String id;
  final String childId;
  final String type; // Type de frais (Inscription, Réinscription, Scolarité, etc.)
  final double amount; // Montant
  final DateTime dueDate; // Date d'échéance
  final DateTime? paidDate; // Date de paiement
  final bool isPaid; // Statut de paiement
  final String? paymentMethod; // Méthode de paiement
  final String? reference; // Référence de paiement

  Fee({
    required this.id,
    required this.childId,
    required this.type,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    required this.isPaid,
    this.paymentMethod,
    this.reference,
  });

  factory Fee.fromJson(Map<String, dynamic> json) {
    return Fee(
      id: json['id'] as String,
      childId: json['childId'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      paidDate: json['paidDate'] != null 
          ? DateTime.parse(json['paidDate'] as String) 
          : null,
      isPaid: json['isPaid'] as bool,
      paymentMethod: json['paymentMethod'] as String?,
      reference: json['reference'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'type': type,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'isPaid': isPaid,
      'paymentMethod': paymentMethod,
      'reference': reference,
    };
  }

  /// Création depuis une ligne SQLite (fees)
  static Fee fromDbMap(Map<String, dynamic> m) {
    final total = (m['montantTotal'] as num?)?.toDouble() ?? 0;
    final paye = (m['montantPaye'] as num?)?.toDouble() ?? 0;
    final isPaid = paye >= total || (m['statut'] as String? ?? '').toUpperCase() == 'PAID';
    final echeance = m['dateEcheance'];
    DateTime due;
    if (echeance == null) {
      due = DateTime.now();
    } else if (echeance is int) {
      due = DateTime.fromMillisecondsSinceEpoch(echeance);
    } else {
      due = DateTime.tryParse(echeance.toString()) ?? DateTime.now();
    }
    return Fee(
      id: m['id'] as String? ?? '',
      childId: m['childId'] as String? ?? '',
      type: m['libelle'] as String? ?? 'Frais',
      amount: total,
      dueDate: due,
      paidDate: null,
      isPaid: isPaid,
      paymentMethod: null,
      reference: null,
    );
  }

  /// Conversion vers format SQLite pour saveFees
  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'childId': childId,
      'libelle': type,
      'montantTotal': amount,
      'montantPaye': isPaid ? amount : 0,
      'dateEcheance': dueDate.millisecondsSinceEpoch,
      'statut': isPaid ? 'PAID' : 'PENDING',
    };
  }
}

