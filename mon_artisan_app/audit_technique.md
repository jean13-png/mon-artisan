# 🔍 Audit Technique Complet — Mon Artisan

## 1. Contexte & Architecture Générale

**Mon Artisan** est une application mobile Flutter cross-platform (Android/iOS) destinée au marché béninois. Elle connecte les clients aux artisans locaux avec un système de commandes, de paiement en escrow (FedaPay) et de notation.

### Stack Technique
| Composant | Technologie |
|-----------|-------------|
| Framework | Flutter 3.41.6 |
| Backend | Firebase (Auth, Firestore, Storage, FCM) |
| State Management | Provider |
| Navigation | GoRouter |
| Paiement | FedaPay (sandbox non configuré) |
| Upload Images | Cloudinary (unsigned upload) |
| Cartes/Geo | geolocator, geocoding, geoflutterfire_plus |

### Rôles Utilisateurs
- **Client** : recherche, commande, paiement, notation
- **Artisan** : gestion profil, réception commandes, devis, revenus
- **Admin** : validation artisans, gestion utilisateurs/agents, statistiques
- Un utilisateur peut avoir **plusieurs rôles simultanément**

### Flux Métier Principal
```
Client → Commande → Artisan (accepte/refuse) → Paiement escrow FedaPay → 
Prestation → Client valide → Paiement débloqué → Artisan crédité
```

---

## 2. 🔴 PROBLÈMES CRITIQUES

### 🔴 C1 — Clés API Firebase exposées en clair dans le code source
**Fichier :** `lib/firebase_options.dart`

La clé API Firebase (`AIzaSyA9TjqLD4_Q782vSJsDZSJKRLF6j1m6tjc`) et l'App ID Android sont codés en dur dans le fichier source versionné.

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyA9TjqLD4_Q782vSJsDZSJKRLF6j1m6tjc', // ⚠️ EXPOSÉ
  appId: '1:442644179511:android:3e5e625c755f7914f7adb2',
  ...
);
```

**Risque :** Quiconque accède au dépôt peut utiliser ce projet Firebase, créer des comptes, lire/écrire des données si les règles Firestore sont mal configurées.

**Recommandation :** Ce fichier doit être ajouté au `.gitignore`. Utiliser les fichiers `google-services.json` / `GoogleService-Info.plist` natifs non versionnés, ou `flutter_dotenv`.

---

### 🔴 C2 — Clé Cloudinary exposée et upload non sécurisé
**Fichier :** `lib/core/services/cloudinary_service.dart`

```dart
static const String _cloudName = 'do1ylvil1';
static const String _uploadPreset = 'mon_artisan'; // unsigned preset
```

L'upload d'images utilise un **unsigned upload preset Cloudinary côté client**. N'importe qui connaissant ces valeurs peut uploader des fichiers illimités dans ce cloud Cloudinary, engendrant des coûts non maîtrisés.

**Recommandation :** Passer à un upload **signé** via un backend sécurisé (Cloud Function Firebase), ou au minimum restreindre le preset Cloudinary à certains types de fichiers/tailles.

---

### 🔴 C3 — Mode simulation activé en production (paiement fictif)
**Fichier :** `lib/core/constants/app_constants.dart`

```dart
static const bool simulateFedaPay = true; // ✅ Mettre à false quand les clés sont bonnes
static const bool isTestMode = true;
static const bool requirePaymentForArtisan = false;
static const String fedapaySecretKey = 'sk_sandbox_YOUR_TEST_KEY'; // Placeholder
```

Le paiement est entièrement simulé (les commandes sont validées sans argent réel). Si cette version est déployée en production, **aucune transaction réelle n'aura lieu** mais le système créditera quand même les artisans fictifs.

**Recommandation :** Créer un système de build flavors (`dev`, `staging`, `prod`) avec des constantes séparées. Ne jamais commiter des clés sandbox dans le code.

---

### 🔴 C4 — Clé iOS et Web Firebase sont des placeholders invalides
**Fichier :** `lib/firebase_options.dart`

```dart
static FirebaseOptions get currentPlatform {
  return android; // iOS et Web ignorés !
}

static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'AIzaSyDvZ_example_key_ios', // ⚠️ FAKE KEY
  appId: '1:442644179511:ios:example_app_id', // ⚠️ FAKE
  ...
);
```

Le getter `currentPlatform` **retourne toujours la config Android**, même sur iOS/Web. Et les configs iOS/Web ont de **fausses clés**. L'app plantera ou se comportera de façon imprévisible sur iOS.

**Recommandation :** Utiliser la méthode `FlutterFire CLI` standard avec détection de plateforme (`Platform.isIOS`, `kIsWeb`), et générer les vraies options Firebase pour iOS.

---

### 🔴 C5 — Race condition au démarrage (Splash Screen)
**Fichier :** `lib/screens/shared/splash_screen.dart`

```dart
// Condition inversée — si user != null mais userModel == null → attendre
while (attempts < 6 && authProvider.firebaseUser != null && authProvider.userModel == null) {
```

La boucle attend jusqu'à 3 secondes que `userModel` soit chargé. Mais si Firebase Auth est rapide et que Firestore est lent (réseau 3G), `userModel` peut rester `null` après 3 secondes → l'utilisateur est **redirigé vers la sélection de rôle** malgré être authentifié, le déconnectant logiquement.

---

### 🔴 C6 — Pas de protection des routes (aucun auth guard)
**Fichier :** `lib/core/routes/app_router.dart`

GoRouter n'a aucun `redirect` configuré. Un utilisateur non authentifié peut naviguer directement vers `/home-client`, `/admin-dashboard`, etc. via `context.go()`. Il n'y a **aucun garde de route**.

**Recommandation :** Ajouter un `redirect` global dans `GoRouter` qui vérifie l'état d'authentification et le rôle avant d'autoriser l'accès aux routes protégées.

---

### 🔴 C7 — Crash potentiel sur navigation avec `state.extra`
**Fichier :** `lib/core/routes/app_router.dart`

```dart
builder: (context, state) {
  final artisan = state.extra as ArtisanModel; // Cast non sécurisé
  return ArtisanProfileScreen(artisan: artisan);
},
```

Si l'utilisateur navigue directement vers `/artisan-profile` (depuis un lien deep-link ou un rechargement), `state.extra` sera `null` → **crash** `Null check operator used on a null value`.

Même problème pour : `selectCommandeType`, `createCommande`, `commandeDetail`, `chat`, `rateArtisan`.

**Recommandation :** Utiliser `state.extra as ArtisanModel?` avec vérification null, ou passer les IDs comme query parameters et recharger depuis Firestore.

---

### 🔴 C8 — `_createBasicArtisanProfile` utilise `.add()` au lieu de `.set()` avec l'UID
**Fichier :** `lib/providers/auth_provider.dart` (ligne 312)

```dart
await FirebaseService.firestore
    .collection('artisans')
    .add(artisanData); // ⚠️ Génère un ID aléatoire, pas l'UID
```

Le profil artisan est créé avec un ID aléatoire Firestore, **pas l'UID de l'utilisateur**. Cela complexifie les requêtes (nécessite toujours `where('userId', ...)`) et brise la règle Firestore :

```
allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
```

Cette règle vérifie que `userId` dans les données == UID, mais l'ID du document lui-même sera différent. Cela crée également un risque si l'utilisateur s'inscrit deux fois : **plusieurs profils artisan** peuvent être créés pour le même utilisateur.

---

### 🔴 C9 — Incohérence dans la gestion des IDs artisan vs userId
**Architecture**

Tout le projet mélange `artisanId` (ID du document artisan dans Firestore) et `userId` (UID Firebase Auth). Dans le `CommmandeModel`, `artisanId` stocke le **userId** (UID Auth), pas l'ID du document artisan :

```dart
// Dans createCommande :
final newCommande = CommandeModel(
  artisanId: artisanId, // Ceci est en fait le userId de l'artisan
  ...
);
```

Puis dans `_crediterArtisan` :
```dart
final artisanQuery = await firestore.collection('artisans')
  .where('userId', isEqualTo: artisanId) // artisanId == userId ici
```

Cette ambiguïté est une **bombe à retardement** pour la maintenabilité.

---

## 3. 🟠 PROBLÈMES MAJEURS

### 🟠 M1 — Duplication de logique (DRY violation massive)

La formule Haversine de calcul de distance est **copiée-collée 3 fois** :
- `lib/core/services/geolocation_service.dart` → `GeolocationService.calculateDistance()`
- `lib/providers/artisan_provider.dart` → `_calculateDistance()` (avec π = 3.14159... codé en dur)
- `lib/providers/commande_provider.dart` → `calculateDistance()`

La méthode `_loadUnreadCounts()` est dupliquée à l'identique dans `HomeClientScreen` et `HomeArtisanScreen`.

---

### 🟠 M2 — `_loadCommandes()` dans ArtisanProvider est commentée/non utilisée
**Fichier :** `lib/providers/artisan_provider.dart` (ligne 46)

```dart
// Ne pas charger les commandes pour éviter l'erreur d'index
// await _loadCommandes();
```

La méthode `_loadCommandes()` est définie mais **ne jamais appelée depuis `loadArtisanProfile()`**. Les commandes de `ArtisanProvider` (`_nouvellesCommandes`, `_commandesAcceptees`, etc.) sont donc **toujours vides** sauf appel explicite depuis l'UI. L'écran artisan charge les commandes via `CommandeProvider` mais affiche aussi `artisanProvider.nouvellesCommandes` — incohérence.

---

### 🟠 M3 — La recherche récupère TOUS les artisans de Firestore
**Fichier :** `lib/providers/artisan_provider.dart` (ligne 136)

```dart
final querySnapshot = await FirebaseService.artisansCollection.get(); // Tout récupérer
```

La recherche d'artisans **charge toute la collection** puis filtre en mémoire. À grande échelle (1000+ artisans), cela va :
- Exploser la consommation de quota Firestore
- Ralentir drastiquement l'app sur réseau lent (3G)
- Augmenter la facture Firebase

---

### 🟠 M4 — Les statistiques admin utilisent 4 requêtes full-scan séparées
**Fichier :** `lib/screens/admin/admin_dashboard_screen.dart` (lignes 37-82)

5 requêtes `get()` sans filtre ou avec filtre simple sont effectuées séquentiellement, récupérant potentiellement tout Firestore juste pour afficher 4 chiffres.

---

### 🟠 M5 — Créditer l'artisan sans transaction atomique
**Fichier :** `lib/providers/commande_provider.dart` (`_crediterArtisan`, ligne 490)

```dart
final currentRevenus = artisanDoc.data()['revenusDisponibles'].toDouble();
// ... 
await firestore.collection('artisans').doc(artisanDoc.id).update({
  'revenusDisponibles': currentRevenus + montant,
});
```

Le calcul `lecture → calcul → écriture` n'est **pas atomique**. Si deux validations simultanées se produisent (bug client, double-tap), une des deux mises à jour sera perdue (race condition financière).

**Recommandation :** Utiliser `FieldValue.increment(montant)` ou une transaction Firestore.

---

### 🟠 M6 — Règle Firestore trop permissive pour les notifications
**Fichier :** `firestore.rules` (ligne 144)

```
allow create: if isAuthenticated();
```

**Tout utilisateur authentifié peut créer une notification pour n'importe quel autre utilisateur.** Cela permet le spam de notifications ou des attaques sociales (ex : envoyer de fausses notifications de paiement).

---

### 🟠 M7 — Règle Firestore pour `users` : faille de lecture
**Fichier :** `firestore.rules` (lignes 28-32)

```javascript
allow read: if isOwner(userId) || isAdmin() ||
  (isAuthenticated() && request.query.limit <= 1);
```

Tout utilisateur authentifié peut lire **n'importe quel profil utilisateur** en faisant une requête avec `limit(1)`. Cela expose les données personnelles (email, téléphone, adresse, position GPS) de tous les utilisateurs.

---

### 🟠 M8 — Incrément `nombreCommandes` effectué deux fois
**Fichiers :** `lib/core/services/firestore_service.dart` (ligne 458) ET `lib/providers/commande_provider.dart` (ligne 511)

`nombreCommandes` est incrémenté dans `accepterCommandeTransaction()` (FirestoreService) ET dans `_crediterArtisan()` (CommandeProvider). Si les deux sont appelés, le compteur est **incrémenté en double**.

---

### 🟠 M9 — Quarantaine de `print()` en production
Le code contient **des centaines de `print()`** qui fuiteront des informations sensibles en production :
- Tokens FCM (`FCM Token: ...`)
- IDs d'utilisateurs
- Montants de transactions
- Données de commandes

**Recommandation :** Utiliser un logger conditionnel (`kDebugMode`) ou le package `logger`.

---

### 🟠 M10 — `AutoRefresh` artisan par polling toutes les 30s
**Fichier :** `lib/screens/artisan/home_artisan_screen.dart` (ligne 55)

```dart
void _startAutoRefresh() {
  Future.delayed(const Duration(seconds: 30), () {
    // ...
    _loadArtisanData();
    _startAutoRefresh(); // Récursif !
  });
}
```

Ce polling récursif toutes les 30 secondes effectue des requêtes Firestore en permanence. Il n'est jamais proprement annulé (le flag `_autoRefreshActive` est mis à `false` dans `dispose()` mais si un `Future.delayed` est déjà en cours, il peut s'exécuter après le dispose et appeler `mounted` sur un widget démonté).

**Recommandation :** Utiliser les **Streams Firestore** (`snapshots()`) pour écouter les changements en temps réel.

---

## 4. 🟡 PROBLÈMES MOYENS

### 🟡 Mo1 — Fichiers vides ou sans contenu
- `lib/screens/auth/agent_payment_screen.dart` → **0 bytes** (fichier vide !)
- `lib/screens/admin/validate_artisans_screen.dart` → **0 bytes** (fichier vide !)

Ces fichiers sont importés nulle part (non utilisés dans le router) mais leur présence crée de la confusion.

---

### 🟡 Mo2 — Écrans non référencés dans le router
- `lib/screens/client/devis_detail_screen.dart` → **non référencé dans AppRouter**
- `lib/screens/client/favoris_screen.dart` → **non référencé dans AppRouter**
- `lib/screens/auth/agent_code_screen.dart` → **non référencé dans AppRouter**
- `lib/screens/shared/conversations_list_screen.dart` → navigué avec `MaterialPageRoute` au lieu de GoRouter

---

### 🟡 Mo3 — Quartier non lié à la ville dans le formulaire d'inscription
**Fichier :** `lib/screens/auth/register_screen.dart` (ligne 239)

```dart
CustomTextField(
  label: 'Quartier (optionnel)',
  controller: TextEditingController(text: _selectedQuartier ?? ''),
  // Ce controller est recréé à chaque build → données perdues !
)
```

Un nouveau `TextEditingController` est créé à **chaque rebuild** du widget. Les données saisies sont perdues lors de tout `setState`. De plus, le quartier est  lié à la ville sélectionnée (le système supporte des quartiers par ville dans `villes_benin.dart`).

---

### 🟡 Mo4 — Position GPS codée en dur pour l'inscription
**Fichier :** `lib/screens/auth/register_screen.dart` (ligne 77)

```dart
position: const GeoPoint(6.3703, 2.3912), // Cotonou par défaut
```

Tous les utilisateurs s'inscrivent avec la position de Cotonou, **peu importe leur ville**. Cela rend la géolocalisation inutile pour les nouveaux utilisateurs.

---

### 🟡 Mo5 — Filtre `_showFilterDialog` dans home_client avec villes codées en dur
**Fichier :** `lib/screens/client/home_client_screen.dart` (lignes 524-547)

Le dialogue de filtre affiche une liste fixe de 4 villes et 4 quartiers alors que `villes_benin.dart` contient une liste complète. Incohérence de données.

---

### 🟡 Mo6 — Catégorie des métiers incohérente
**Fichier :** `lib/providers/auth_provider.dart` vs `lib/core/constants/metiers_data.dart`

Dans `_createBasicArtisanProfile`, les catégories sont définies en dur avec une liste **partielle** :
```dart
'Bâtiment': ['Maçon', 'Électricien', 'Plombier', 'Peintre', 'Carreleur', 'Menuisier'],
```

Alors que `metiers_data.dart` définit **10 catégories** (BTP & Construction, Énergie & Climatisation, etc.). Un artisan s'inscrivant comme "Panneaux Solaires" sera classé en "Autre" car sa catégorie n'est pas dans la liste de `auth_provider.dart`.

---

### 🟡 Mo7 — `refuserCommande` : incohérence dans le statut
**Fichier :** `lib/providers/commande_provider.dart` (ligne 332) et `artisan_provider.dart` (ligne 335)

Quand un artisan **refuse** une commande, le statut passe à `'annulee'` au lieu de `'refusee'`. La commande refusée et la commande annulée par le client ont le même statut — impossible de les distinguer.

---

### 🟡 Mo8 — Validation artisan possible même si profil incomplet (règles Firestore)
**Fichier :** `firestore.rules` (lignes 56-61)

La règle de mise à jour artisan permet à n'importe qui d'authentifié de modifier `disponibilite` et `commandeEnCours` s'ils font partie de la liste de champs autorisés :
```javascript
request.resource.data.keys().hasOnly([...]) && request.resource.data.keys().hasAny([...])
```

Cette condition ne vérifie pas que l'appelant est lié à la commande en question, ni que la commande existe réellement.

---

### 🟡 Mo9 — Aucune gestion du `google-services.json` manquant
Le README indique que `google-services.json` doit être ajouté manuellement mais il n'est pas dans le projet. Le build Android **échouera silencieusement** si ce fichier manque.

---

### 🟡 Mo10 — Le `_remboursementClient` ne rembourse pas réellement
**Fichier :** `lib/providers/commande_provider.dart` (`rembourserClient`, ligne 523)

```dart
// Mettre à jour le statut
await firestore.collection('commandes').doc(commandeId).update({
  'statut': 'annulee',
  'paiementStatut': 'rembourse',
  ...
});
```

Le remboursement ne fait que changer le statut en base. **Aucun remboursement FedaPay réel n'est effectué**. L'artisan n'est pas non plus libéré de la commande annulée dans ce chemin.

---

## 5. 🟢 PROBLÈMES MINEURS / AMÉLIORATIONS

### 🟢 Mi1 — Duplication de constantes de collections Firestore
`FirebaseService` et `FirestoreService` définissent tous les deux les mêmes références de collections Firestore (`users`, `artisans`, `commandes`, etc.). Le code utilise tantôt l'un, tantôt l'autre, sans règle claire.

### 🟢 Mi2 — Notification ID aléatoire problématique
**Fichier :** `lib/core/services/notification_service.dart` (ligne 144)

```dart
await _localNotifications.show(
  DateTime.now().millisecond, // ⚠️ Peut être dupliqué !
```

L'ID de notification utilise `DateTime.now().millisecond` (0-999), pas `millisecondsSinceEpoch`. Si deux notifications arrivent dans la même milliseconde, l'une écrase l'autre.

### 🟢 Mi3 — `firebase_storage` importé mais Cloudinary est utilisé pour les uploads
`firebase_storage: ^12.3.8` est dans les dépendances et `FirebaseService.storage` est défini, mais tous les uploads d'images utilisent Cloudinary. Firebase Storage est un **import inutile** (coût de taille APK).

### 🟢 Mi4 — `flutter_dotenv` importé mais non utilisé
`flutter_dotenv: ^5.1.0` est dans les dépendances mais aucun `.env` n'est chargé, et aucune variable d'environnement n'est lue. Dépendance inutile.

### 🟢 Mi5 — `geoflutterfire_plus` utilisé seulement pour générer des geohashes
La génération de geohash n'utilise qu'une seule ligne de cette bibliothèque. Une implémentation simple suffirait.

### 🟢 Mi6 — `flutter_local_notifications` et `firebase_messaging` importés avec des versions pouvant entrer en conflit
La version `^17.1.2` de `flutter_local_notifications` avec `firebase_messaging: ^15.1.8` peuvent avoir des incompatibilités sur certaines versions de Gradle/AGP.

### 🟢 Mi7 — `ArtisanModel.toFirestore()` n'inclut pas les champs `nom`, `prenom`, `email`, `telephone`
**Fichier :** `lib/models/artisan_model.dart` (lignes 144-182)

Ces champs sont lus depuis Firestore (`fromFirestore`) et stockés en mémoire mais **ne sont jamais réécrits** dans `toFirestore()`. Si on appelle `.set()` avec `toFirestore()`, ces données sont perdues.

### 🟢 Mi8 — Pas de limite sur la taille des messages dans le chat
**Fichier :** `lib/core/services/chat_service.dart`

Aucune validation de longueur de message. Un message de 100MB peut théoriquement être envoyé.

### 🟢 Mi9 — Fichiers documentation en dehors du dossier `docs/`
Plusieurs fichiers `.md` de documentation technique sont à la racine de `mon_artisan_app/` au lieu d'être dans `docs/` :
- `PAIEMENTS_FEDAPAY_ACTIFS.md`
- `SYSTEME_DEUX_MODES_COMMANDE.md`
- `CHANGELOG_FINAL.md`
- `FIRESTORE_RULES_CORRECTED.txt`
- `check_artisans.txt`

### 🟢 Mi10 — Validation de formulaire manquante
Dans `register_screen.dart`, la confirmation de mot de passe ne vérifie pas si le champ est vide (`Validators.validatePassword` n'est pas appliqué sur le champ de confirmation).

---

## 6. Structure & Architecture

### Points Positifs ✅
- Architecture globalement claire : `models/`, `providers/`, `screens/`, `services/`, `widgets/`
- Provider bien utilisé pour la gestion d'état
- GoRouter correctement intégré
- Modèles avec `fromFirestore()` et `toFirestore()` bien définis
- Système d'idempotence pour certaines opérations (valider, payer, devis)
- Design token system (`AppColors`, `AppTextStyles`) cohérent
- Règles Firestore globalement correctes (avec exceptions notées)

### Points Négatifs ❌
- **Pas de couche Repository** : les Providers accèdent directement à Firestore, mélangeant logique UI et logique data
- **Pas de modèle de données `Chat`/`Message`** : les données chat sont manipulées sous forme de `Map<String, dynamic>` 
- **Pas de tests** : le dossier `test/` est vide
- **`lib/scripts/`** : dossier présent dans `lib` alors qu'il devrait être à la racine
- Pas de gestion des erreurs réseau globale (ex : `Connectivity`)
- Pas de `flavor` ou `environment` pour distinguer dev/staging/prod

---

## 7. État Général du Projet

| Dimension | Score | Commentaire |
|-----------|-------|-------------|
| Fonctionnel | 6/10 | Flux métier défini mais beaucoup de fonctionnalités incomplètes (remboursement, retrait réel) |
| Sécurité | 3/10 | Clés exposées, règles trop permissives, pas de route guards |
| Performance | 4/10 | Requêtes full-scan, polling au lieu de streams, pas de pagination |
| Qualité du Code | 5/10 | Duplication, print partout, pas de tests |
| Maintenabilité | 5/10 | Structure OK mais coupling fort Provider→Firestore |
| Scalabilité | 3/10 | La recherche full-scan ne passera pas à l'échelle |

---

## 8. Recommandations Prioritaires

### Priorité 1 — Sécurité (Critique, à faire immédiatement)
1. **Ajouter `firebase_options.dart` et `google-services.json` au `.gitignore`**
2. **Renouveler la clé API Firebase** (la clé actuelle est compromise)
3. **Corriger les règles Firestore** pour les notifications (restreindre la création)
4. **Corriger la règle de lecture `users`** (supprimer le `limit <= 1` permissif)
5. **Passer l'upload Cloudinary en mode signé** (via Cloud Function)
6. **Ajouter les route guards** dans GoRouter

### Priorité 2 — Bugs Critiques
7. **Corriger l'ambiguïté `artisanId` vs `userId`** dans tout le projet
8. **Corriger `_createBasicArtisanProfile`** pour utiliser `set()` avec l'UID
9. **Sécuriser les casts `state.extra`** dans le router
10. **Corriger `currentPlatform`** dans `firebase_options.dart` pour iOS

### Priorité 3 — Performance
11. **Remplacer le polling** artisan par des Streams Firestore (`snapshots()`)
12. **Remplacer la recherche full-scan** par des requêtes Firestore composées avec pagination
13. **Utiliser `FieldValue.increment()`** pour les crédits financiers (atomicité)

### Priorité 4 — Architecture & Qualité
14. **Ajouter une couche Repository** entre Providers et Firestore
15. **Unifier `FirebaseService` et `FirestoreService`** (une seule source de vérité)
16. **Supprimer les dépendances inutiles** : `flutter_dotenv`, `firebase_storage` (si Cloudinary est conservé)
17. **Ajouter des tests unitaires** pour les modèles et les services
18. **Créer des build flavors** dev/staging/prod avec des constantes séparées
19. **Remplacer tous les `print()`** par un logger conditionnel

---

*Audit réalisé le 2026-05-08 — 100% des fichiers sources analysés.*
