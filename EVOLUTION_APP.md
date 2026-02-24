# Évolution de l'application Parent Responsable

Ce document décrit les changements effectués et la structure mise en place pour les modules demandés.

## ✅ Réalisé

### 1. SQLite – Version 4 (migrations)

- **Version DB** : passée de 3 à 4.
- **Nouvelles tables** :
  - `notes` : id, childId, matiereId, matiereNom, note, coefficient, periodeId, anneeId, dateNote, createdAt
  - `averages` : childId, periodeId, anneeId, moyenne, rang, updatedAt
  - `fees` : id, childId, libelle, montantTotal, montantPaye, dateEcheance, statut, updatedAt
  - `payments` : id, feeId, childId, montant, datePaiement, mode, reference, createdAt
  - `attendance` : id, childId, date, statut, motif, createdAt
  - `sanctions` : id, childId, type, libelle, dateSanction, description, createdAt
  - `timetable` : id, childId, jourSemaine, heureDebut, heureFin, matiereNom, salle, professeur, semaine, updatedAt
  - `report_cards` : id, childId, periodeId, anneeId, fileUrl, filePath, qrData, updatedAt
  - `risk_alerts` : id, childId, matiereNom, score, recommandation, updatedAt
  - `threads` : id, parentId, title, lastMessageAt, unreadCount, updatedAt
  - `messages` : id, threadId, senderId, senderName, content, isFromMe, createdAt, readAt
  - `events` : id, ecoleId, title, description, dateDebut, dateFin, lieu, type, updatedAt
  - `tickets` : id, eventId, parentId, childId, qrCode, createdAt
  - `supplies` : id, classeId, libelle, description, prix, updatedAt
  - `orders` : id, parentId, childId, statut, total, createdAt, updatedAt

- **Méthodes DatabaseService** :
  - Notes : `saveNotes`, `getNotesByChildAndPeriode`, `saveAverage`, `getAverage`
  - Fees / Payments : `saveFees`, `getFeesByChild`, `savePayments`, `getPaymentsByChild`
  - Présence / Sanctions : `saveAttendance`, `getAttendanceByChild`, `saveSanctions`, `getSanctionsByChild`
  - Emploi du temps : `saveTimetable`, `getTimetableByChild`
  - Messagerie : `saveThread`, `getThreadsByParent`, `saveMessages`, `getMessagesByThread`

### 2. Notes – Implémentation

- **NotesScreen** (`lib/screens/notes_tab_screen.dart`) : écran de l’onglet Notes. Liste des enfants du parent ; au tap → ouverture des notes de l’enfant.
- **ChildNotesScreen** (ex-`NotesScreen` dans `lib/screens/notes_screen.dart`) : notes d’un enfant (périodes, matières, moyennes). Utilise déjà `PoulsScolaireApiService.getNotesByEleveMatricule` (équivalent GET students/{matricule}/notes).
- **NoteDetailScreen** (`lib/screens/note_detail_screen.dart`) : détail d’une note (matière, note, coef, date, moyenne, rang, appréciation).
- **Navigation** :
  - Onglet **Notes** → `NotesScreen` (liste enfants) → tap enfant → `ChildNotesScreen(childId)`.
  - Depuis **ChildListScreen** → onglet Notes → `ChildNotesScreen(childId)`.
- **Placeholder supprimé** : l’onglet Notes affiche désormais `NotesScreen` au lieu de `NotesPlaceholderScreen`.

### 3. Scolarité & Paiements – Accès

- **FeesTabScreen** (`lib/screens/fees_tab_screen.dart`) : liste des enfants pour scolarité & paiements ; au tap → `FeesScreen(childId)` (écran existant).
- **Menu « Plus »** : entrée **Scolarité & Paiements** ouvre `FeesTabScreen` dans le `MainScreenWrapper`.

### 4. Scolarité & Paiements (complet)

- **FeesScreen** : charge depuis SQLite puis sync API `getFeesByMatricule` / `getPaymentsByMatricule`. Affiche résumé (montant total, payé, reste), liste des frais à régler / payés, **badge rouge "Retard"** si échéance dépassée, bouton **Historique des paiements**.
- **PaymentHistoryScreen** : liste des paiements (enfant) depuis SQLite.
- **PaymentDetailScreen** : détail d’un frais + paiements associés.
- **FeesTabScreen** : liste des enfants → tap → FeesScreen(childId). Accessible via menu **Plus → Scolarité & Paiements**.
- **PoulsScolaireApiService** : `getFeesByMatricule`, `getPaymentsByMatricule` (GET /students/{matricule}/fees et /payments).
- **Modèle Fee** : `fromDbMap`, `toDbMap` pour SQLite.

### 5. Présence & Conduite (complet)

- **AttendanceScreen** : charge depuis SQLite + API `getAttendanceByMatricule`. Affiche **taux de présence**, liste des absences.
- **DisciplineScreen** : charge depuis SQLite + API `getSanctionsByMatricule`. Affiche liste des sanctions.
- **PresConduiteTabScreen** : liste des enfants avec boutons **Présence** et **Conduite** par enfant. Accessible via menu **Plus → Présence & Conduite**.
- **PoulsScolaireApiService** : `getAttendanceByMatricule`, `getSanctionsByMatricule` (GET /students/{matricule}/attendance et /sanctions).

### 6. Emploi du temps (complet)

- **TimetableScreen** : charge depuis SQLite puis sync API `getTimetableByMatricule`. RefreshIndicator, AppBar + thème.
- **TimetableTabScreen** (`lib/screens/timetable_tab_screen.dart`) : liste des enfants → tap → TimetableScreen(childId). Accessible via menu **Plus → Emploi du temps**.
- **TimetableEntry** : `fromDbMap`, `toDbMap` pour SQLite. **PoulsScolaireApiService** : `getTimetableByMatricule(matricule, {int? week})`.

### 7. Bulletin PDF + QR (complet)

- **ReportCardScreen** (`lib/screens/report_card_screen.dart`) : sélection période, **blocage si solde > 0** (reste à payer depuis SQLite fees), puis appel API `getReportCardByMatricule(matricule, periodeId)`.
- **PdfViewerScreen** (`lib/screens/pdf_viewer_screen.dart`) : affichage lien « Ouvrir le bulletin PDF » (url_launcher), texte QR de vérification.
- **ReportCardTabScreen** (`lib/screens/report_card_tab_screen.dart`) : liste des enfants → tap → ReportCardScreen(childId). Accessible via menu **Plus → Bulletin PDF**.
- **PoulsScolaireApiService** : `getReportCardByMatricule(matricule, {int? periodeId})` (GET /students/{matricule}/report-card?periodeId=).

### 8. Élève en difficulté (complet)

- **StudentRiskScreen** (`lib/screens/student_risk_screen.dart`) : chargement SQLite puis sync API `getRiskAnalysisByMatricule`. **Graphique en barres** (fl_chart) : scores par matière (sur 20), couleurs rouge / orange / bleu selon le score. Liste **Recommandations** par matière (icône, score, texte).
- **StudentRiskTabScreen** (`lib/screens/student_risk_tab_screen.dart`) : liste des enfants → tap → StudentRiskScreen(childId). Accessible via menu **Plus → Élève en difficulté**.
- **DatabaseService** : `saveRiskAlerts`, `getRiskAlertsByChild`. **PoulsScolaireApiService** : `getRiskAnalysisByMatricule(matricule)` (GET /students/{matricule}/risk-analysis).

### 9. Messagerie réelle (complet)

- **ChatListScreen** : liste des conversations (threads), SQLite + API getMessageThreads, badge unread, tap → ChatDetailScreen.
- **ChatDetailScreen** : messages, envoi (insertMessage + postMessage), bulles fromMe à droite.
- **DatabaseService** : insertMessage, updateThreadLastMessage. **PoulsScolaireApiService** : getMessageThreads, getMessagesByThreadId, postMessage.
- Menu **Plus → Messagerie**.

### 10. Événements scolaires (complet)

- **EventsTabScreen** : liste établissements (enfants du parent) → EventsScreen(ecoleId, nom). **EventsScreen** : liste événements (SQLite + getEventsByEcoleId). **EventDetailScreen** : détail + bouton Obtenir un ticket → postEventTicket, TicketScreen. **TicketScreen** : ticket + code QR/entrée.
- **DatabaseService** : saveEvents, getEventsByEcole, saveTicket, getTicketsByParent, getTicketsByEvent. **PoulsScolaireApiService** : getEventsByEcoleId, postEventTicket. Menu **Plus → Événements**.

### 11. Fournitures & commandes (complet)

- **SuppliesOrdersTabScreen** : Mes commandes → OrdersScreen ; Fournitures par élève → SuppliesScreen(childId). **SuppliesScreen** : fournitures par classe (SQLite + getSuppliesByClasseId). **OrdersScreen** / **OrderDetailScreen** : commandes parent (getOrdersByParentId). **DatabaseService** : saveSupplies, getSuppliesByClasse, saveOrders, getOrdersByParent. **PoulsScolaireApiService** : getSuppliesByClasseId, getOrdersByParentId. Menu **Plus → Fournitures & commandes**.

### 12. Notifications et Dashboard (complet)

- **Navigation par type** : MainScreenWrapper._handleNotification lit type, childId, threadId, eventId ; action « Voir » → _navigateFromNotification (NEW_GRADE → Notes/ChildNotes, PAYMENT_REMINDER → Fees, SANCTION/ABSENCE → Discipline/Attendance, MESSAGE → Chat, EVENT → EventsTab).
- **Dashboard** : HomeScreen affiche pour le premier enfant un tableau de bord (moyenne, solde, taux présence, alertes, prochain événement). getLastAverageByChild ajouté.

### 13. Architecture conservée

- Auth OTP, SQLite, FCM, `PoulsScolaireApiService`, `MockApiService` / `RemoteApiService`, BottomNavigation inchangés.
- Nouveaux écrans soit dans l’onglet Notes, soit accessibles via le menu (Plus).

---

### 14. ApiService / Mock / Remote étendu (complet)

- **ApiService** : getAttendanceForChild, getSanctionsForChild, getRiskAlertsForChild, getMessageThreads, getEventsForEcole, getSuppliesForClasse, getOrdersForParent. **MockApiService** : lecture SQLite. **RemoteApiService** : stubs.

## Référence backend

1. **PoulsScolaireApiService**  
    - Pour l’enfant sélectionné (ou premier) : moyenne actuelle, solde restant, taux de présence, alertes, prochain événement.

1. **PoulsScolaireApiService**  
    - Ajouter les appels pour : fees, payments, attendance, sanctions, timetable, report-card, risk-analysis, messages/threads, events, supplies, orders (selon les vrais endpoints backend).

2. **ApiService / Mock / Remote**  
    - Étendre l’interface et les implémentations pour ces nouveaux domaines si besoin (ex. fees, attendance, etc.) en restant cohérent avec `MOCK_MODE`.

---

## Fichiers créés / modifiés

| Fichier | Action |
|--------|--------|
| `lib/services/database_service.dart` | Version 4, tables v4, méthodes notes/fees/payments/attendance/sanctions/timetable/threads/messages |
| `lib/screens/notes_tab_screen.dart` | **Créé** – NotesScreen (liste enfants) |
| `lib/screens/notes_screen.dart` | NotesScreen renommé en ChildNotesScreen |
| `lib/screens/note_detail_screen.dart` | **Créé** – détail d’une note |
| `lib/screens/fees_tab_screen.dart` | **Créé** – liste enfants pour scolarité |
| `lib/widgets/main_screen_wrapper.dart` | Onglet Notes → NotesScreen, import notes_tab_screen |
| `lib/widgets/bottom_sheet_menu.dart` | Entrée « Scolarité & Paiements » + import fees_tab_screen |
| `lib/screens/child_list_screen.dart` | Utilise ChildNotesScreen au lieu de NotesScreen |
| `lib/screens/fees_screen.dart` | Refait : SQLite + API, résumé, retard, Historique / Détail |
| `lib/screens/payment_history_screen.dart` | **Créé** – Historique des paiements |
| `lib/screens/payment_detail_screen.dart` | **Créé** – Détail frais + paiements |
| `lib/screens/attendance_screen.dart` | **Créé** – Taux présence, liste absences |
| `lib/screens/discipline_screen.dart` | **Créé** – Liste sanctions |
| `lib/screens/presence_conduite_tab_screen.dart` | **Créé** – Liste enfants + Présence / Conduite |
| `lib/models/fee.dart` | fromDbMap, toDbMap pour SQLite |
| `lib/services/pouls_scolaire_api_service.dart` | getFeesByMatricule, getPaymentsByMatricule, getAttendanceByMatricule, getSanctionsByMatricule, getTimetableByMatricule, getReportCardByMatricule |
| `lib/screens/timetable_screen.dart` | Modifié : SQLite + API, RefreshIndicator |
| `lib/screens/timetable_tab_screen.dart` | **Créé** – liste enfants → Emploi du temps |
| `lib/screens/report_card_screen.dart` | **Créé** – périodes, blocage solde, PDF + QR |
| `lib/screens/pdf_viewer_screen.dart` | **Créé** – lien PDF (url_launcher) + texte QR |
| `lib/screens/report_card_tab_screen.dart` | **Créé** – liste enfants → Bulletin |
| `lib/widgets/bottom_sheet_menu.dart` | Entrées « Emploi du temps », « Bulletin PDF » |
| `pubspec.yaml` | url_launcher ^6.2.0, fl_chart ^0.66.0 |
| `lib/screens/student_risk_screen.dart` | **Créé** – graphique fl_chart, recommandations |
| `lib/screens/student_risk_tab_screen.dart` | **Créé** – liste enfants → Élève en difficulté |
| `lib/widgets/bottom_sheet_menu.dart` | Entrée « Élève en difficulté » |
| `lib/services/database_service.dart` | saveRiskAlerts, getRiskAlertsByChild |
| `lib/services/pouls_scolaire_api_service.dart` | getRiskAnalysisByMatricule, getMessageThreads, getMessagesByThreadId, postMessage |
| `lib/screens/chat_list_screen.dart` | **Créé** – liste threads, sync API |
| `lib/screens/chat_detail_screen.dart` | **Créé** – messages, envoi, insertMessage + postMessage |
| `lib/services/database_service.dart` | + insertMessage, updateThreadLastMessage |
| `lib/widgets/bottom_sheet_menu.dart` | Entrée « Messagerie », « Événements » |
| `lib/services/database_service.dart` | + saveEvents, getEventsByEcole, saveTicket, getTicketsByParent, getTicketsByEvent |
| `lib/services/pouls_scolaire_api_service.dart` | + getEventsByEcoleId, postEventTicket |
| `lib/screens/events_tab_screen.dart` | **Créé** – liste établissements → événements |
| `lib/screens/events_screen.dart` | **Créé** – liste événements par école |
| `lib/screens/event_detail_screen.dart` | **Créé** – détail + Obtenir un ticket |
| `lib/screens/ticket_screen.dart` | **Créé** – affichage ticket + code QR |
| `lib/services/database_service.dart` | + saveSupplies, getSuppliesByClasse, saveOrders, getOrdersByParent |
| `lib/services/pouls_scolaire_api_service.dart` | + getSuppliesByClasseId, getOrdersByParentId |
| `lib/screens/supplies_orders_tab_screen.dart` | **Créé** – Mes commandes + Fournitures par élève |
| `lib/screens/supplies_screen.dart` | **Créé** – liste fournitures par classe |
| `lib/screens/orders_screen.dart` | **Créé** – liste commandes parent |
| `lib/screens/order_detail_screen.dart` | **Créé** – détail commande |
| `lib/widgets/bottom_sheet_menu.dart` | Entrée « Fournitures & commandes » |
| `lib/widgets/main_screen_wrapper.dart` | _handleNotification : payload type/childId/threadId/eventId, _navigateFromNotification vers Notes, Fees, Discipline, Attendance, Chat, Events |
| `lib/screens/home_screen.dart` | Tableau de bord (moyenne, solde, taux, alertes, prochain événement) pour le premier enfant |
| `lib/services/database_service.dart` | + getLastAverageByChild |
| `lib/services/api_service.dart` | + getAttendanceForChild, getSanctionsForChild, getRiskAlertsForChild, getMessageThreads, getEventsForEcole, getSuppliesForClasse, getOrdersForParent |
| `lib/services/mock_api_service.dart` | Implémentation des 7 méthodes depuis SQLite |
| `lib/services/remote_api_service.dart` | Stubs (retour []) + TODO pour HTTP |

---

## Contraintes respectées

- Auth OTP, SQLite local, FCM, PoulsScolaireApiService, architecture Mock/Remote, BottomNavigation conservés.
- Structure du projet et séparation services / UI respectées.
- Migrations SQLite par version.
- Gestion loading / error / empty states sur les nouveaux écrans (NotesScreen, FeesTabScreen, NoteDetailScreen).

Souhaitez-vous que l’on enchaîne avec un module précis (par ex. Fees + API + SQLite, ou Présence & Conduite) ?
