# Référence API – Données scolaires

Base URL utilisée dans l’app : **`AppConfig.POULS_SCOLAIRE_API_URL`** (ex. `https://api-pro.pouls-scolaire.net/api`).

---

## 1. Années scolaires disponibles

### Année scolaire ouverte pour une école (implémenté)

Retourne **l’année scolaire ouverte** pour une école donnée (une seule année).

| Méthode | URL | Paramètres |
|--------|-----|------------|
| **GET** | `/annee/list-ouverte-to-ecole-dto` | Query : `ecole` = `ecoleId` (int) |

**Exemple :**  
`GET /api/annee/list-ouverte-to-ecole-dto?ecole=38`

**Dans le code :**  
`PoulsScolaireApiService.getAnneeScolaireOuverte(int ecoleId)`

**Réponse attendue :**  
Objet avec au moins `anneeOuverteCentraleId` (id de l’année), libellé, etc. (voir `AnneeScolaire.fromJson`).

---

### Liste de toutes les années (à ajouter côté backend si besoin)

Si le backend expose une liste de **toutes les années disponibles** (pour une école ou globalement), par exemple :

- `GET /annee/list?ecole={ecoleId}`  
ou  
- `GET /annee/list-all`

il suffit d’ajouter une méthode dans `PoulsScolaireApiService` qui appelle cet endpoint et retourne `List<AnneeScolaire>` (ou équivalent). Ce n’est pas encore implémenté dans l’app.

---

## 2. Ensemble des écoles

| Méthode | URL | Paramètres |
|--------|-----|------------|
| **GET** | `/connecte/ecole` | Aucun |

**Exemple :**  
`GET /api/connecte/ecole`

**Dans le code :**  
`PoulsScolaireApiService.getAllEcoles()`

**Réponse attendue :**  
Tableau JSON. Chaque élément doit contenir au minimum les champs attendus par `Ecole.fromJson` (ex. `ecoleid`, `ecoleclibelle`).

---

## 3. Ensemble des élèves d’une école pour une année donnée

| Méthode | URL | Paramètres |
|--------|-----|------------|
| **GET** | `/inscriptions/list-eleve-classe/{idEcole}/{idAnnee}` | Path : `idEcole` (int), `idAnnee` (int) |

**Exemple :**  
`GET /api/inscriptions/list-eleve-classe/38/5`

**Dans le code :**  
`PoulsScolaireApiService.getElevesByEcoleAndAnnee(int idEcole, int idAnnee)`

**Réponse attendue :**  
Tableau JSON. Chaque élément doit contenir les champs utilisés par `Eleve.fromJson` (ex. `matriculeEleve`, `classeid`, `classe`, noms, etc.).

---

## 4. Ensemble des classes d’une école

| Méthode | URL | Paramètres |
|--------|-----|------------|
| **GET** | `/classes/list-all-populate-by-ecole` | Query : `ecole` = `ecoleId` (int) |

**Exemple :**  
`GET /api/classes/list-all-populate-by-ecole?ecole=38`

**Dans le code :**  
`PoulsScolaireApiService.getClassesByEcole(int ecoleId)`

**Réponse attendue :**  
Tableau JSON. Chaque élément doit contenir les champs attendus par `Classe.fromJson` (ex. `id`, `libelle`, etc.).

---

## Résumé

| Donnée | Endpoint | Méthode / service |
|--------|----------|--------------------|
| **Année(s) scolaire(s)** | `/annee/list-ouverte-to-ecole-dto?ecole={ecoleId}` | `getAnneeScolaireOuverte(ecoleId)` — 1 année “ouverte” par école |
| **Toutes les écoles** | `/connecte/ecole` | `getAllEcoles()` |
| **Élèves d’une école pour une année** | `/inscriptions/list-eleve-classe/{idEcole}/{idAnnee}` | `getElevesByEcoleAndAnnee(idEcole, idAnnee)` |
| **Classes d’une école** | `/classes/list-all-populate-by-ecole?ecole={ecoleId}` | `getClassesByEcole(ecoleId)` |

---

## Chargement groupé (école complète)

Pour charger en une fois année, classes et élèves d’une école :

**Dans le code :**  
`PoulsScolaireApiService.loadAllDataForEcole(int ecoleId)`

Cette méthode enchaîne :

1. `getAnneeScolaireOuverte(ecoleId)` → année ouverte  
2. `getClassesByEcole(ecoleId)` → liste des classes  
3. `getAllPeriodes()` → périodes  
4. `getElevesByEcoleAndAnnee(ecoleId, anneeOuverteCentraleId)` → tous les élèves de l’école pour cette année  

et retourne un objet `SchoolData` (année, classes, périodes, élèves, élèves par classe).
