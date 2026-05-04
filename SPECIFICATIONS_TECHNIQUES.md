# SPÉCIFICATIONS TECHNIQUES - MON ARTISAN

## CONTEXTE DU PROJET

Application mobile cross-platform (Android/iOS) pour connecter clients et artisans au Bénin.
Référence design : Yango (interface simple, rouge dominant, pas de dégradés, pas d'emojis).
Site de référence données : https://artiprobtp.netlify.app

## STACK TECHNIQUE IMPOSÉE

### Frontend Mobile
- Framework : Flutter 3.41.6
- Langage : Dart 3.11.4
- Compatibilité : Android 6.0+ et iOS 12+

### Backend & Base de données
- Backend : Firebase (Firestore, Authentication, Storage, Cloud Functions)
- Base de données : Cloud Firestore (NoSQL)
- Stockage fichiers : Firebase Storage

### Services externes
- Paiement : FedaPay API (https://fedapay.com)
- Géolocalisation : Google Maps API / Mapbox
- Notifications : Firebase Cloud Messaging (FCM)

### Packages Flutter essentiels
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^3.8.1
  firebase_auth: ^5.3.4
  cloud_firestore: ^5.5.2
  firebase_storage: ^12.3.8
  firebase_messaging: ^15.1.8
  
  # Géolocalisation
  google_maps_flutter: ^2.10.0
  geolocator: ^13.0.2
  geocoding: ^3.0.0
  geoflutterfire_plus: ^0.0.3
  
  # Paiement FedaPay
  http: ^1.2.2
  
  # UI/UX
  flutter_svg: ^2.0.10
  cached_network_image: ^3.4.1
  shimmer: ^3.0.0
  
  # State Management
  provider: ^6.1.2
  
  # Navigation
  go_router: ^14.6.2
  
  # Utilitaires
  intl: ^0.20.1
  shared_preferences: ^2.3.4
  image_picker: ^1.1.2
  permission_handler: ^11.3.1
```

## ARCHITECTURE DE L'APPLICATION

### Structure des dossiers
```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── colors.dart          # Charte graphique
│   │   ├── text_styles.dart
│   │   └── app_constants.dart
│   ├── routes/
│   │   └── app_router.dart
│   ├── services/
│   │   ├── firebase_service.dart
│   │   ├── fedapay_service.dart
│   │   ├── geolocation_service.dart
│   │   └── notification_service.dart
│   └── utils/
│       ├── validators.dart
│       └── helpers.dart
├── models/
│   ├── user_model.dart
│   ├── artisan_model.dart
│   ├── commande_model.dart
│   └── metier_model.dart
├── providers/
│   ├── auth_provider.dart
│   ├── artisan_provider.dart
│   └── commande_provider.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── role_selection_screen.dart
│   ├── client/
│   │   ├── home_client_screen.dart
│   │   ├── search_artisan_screen.dart
│   │   ├── artisan_profile_screen.dart
│   │   ├── commande_screen.dart
│   │   └── payment_screen.dart
│   ├── artisan/
│   │   ├── home_artisan_screen.dart
│   │   ├── profile_artisan_screen.dart
│   │   ├── commandes_list_screen.dart
│   │   └── revenus_screen.dart
│   └── shared/
│       ├── splash_screen.dart
│       └── onboarding_screen.dart
└── widgets/
    ├── custom_button.dart
    ├── custom_textfield.dart
    ├── artisan_card.dart
    └── loading_widget.dart
```

## CHARTE GRAPHIQUE (STRICTE)

### Couleurs principales
```dart
// lib/core/constants/colors.dart
class AppColors {
  // Couleurs principales
  static const Color primaryBlue = Color(0xFF1A3C6E);
  static const Color accentRed = Color(0xFFC0392B);
  static const Color white = Color(0xFFFFFFFF);
  
  // Couleurs secondaires
  static const Color greyLight = Color(0xFFF5F5F5);
  static const Color greyMedium = Color(0xFFBDBDBD);
  static const Color greyDark = Color(0xFF757575);
  static const Color black = Color(0xFF000000);
  
  // États
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  
  // Transparences
  static const Color overlay = Color(0x80000000);
}
```

### Typographie
```dart
// lib/core/constants/text_styles.dart
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // Titres
  static TextStyle h1 = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryBlue,
  );
  
  static TextStyle h2 = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryBlue,
  );
  
  static TextStyle h3 = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );
  
  // Corps de texte
  static TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.black,
  );
  
  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.greyDark,
  );
  
  static TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.greyMedium,
  );
  
  // Boutons
  static TextStyle button = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
}
```

### Règles de design
- PAS de dégradés de couleurs
- PAS d'emojis dans l'interface
- Utiliser Font Awesome pour les icônes
- Fond blanc ou gris clair uniquement
- Couleur dominante : BLEU #1A3C6E (navigation, headers, boutons principaux)
- Couleur accent : ROUGE #C0392B (éléments importants, CTAs secondaires, badges)
- Boutons principaux : bleu (primaryBlue)
- Boutons d'action importante : rouge (accentRed)
- Coins arrondis : 8px pour les cartes, 12px pour les boutons
- Ombres légères : elevation 2-4 maximum
- Espacement : multiples de 8 (8, 16, 24, 32px)

## STRUCTURE DE LA BASE DE DONNÉES FIRESTORE

### Collection : users
```
users/{userId}
├── role: string ("client" | "artisan")
├── nom: string
├── prenom: string
├── telephone: string
├── email: string
├── photoUrl: string (nullable)
├── ville: string
├── quartier: string
├── position: GeoPoint {latitude, longitude}
├── createdAt: Timestamp
├── updatedAt: Timestamp
└── isActive: boolean
```

### Collection : artisans (profils détaillés)
```
artisans/{artisanId}
├── userId: string (référence users)
├── metier: string (ex: "Électricien")
├── metierCategorie: string (pour filtrage)
├── description: string
├── experience: number (années)
├── tarifs: map {
│   ├── tarifHoraire: number
│   ├── tarifJournalier: number
│   └── deplacementInclus: boolean
│ }
├── disponibilite: boolean
├── rayonAction: number (km)
├── position: GeoPoint
├── geohash: string (pour requêtes géospatiales)
├── ville: string
├── quartier: string
├── photos: array[string] (URLs)
├── certifications: array[string]
├── noteGlobale: number (0-5)
├── nombreAvis: number
├── nombreCommandes: number
├── revenusTotal: number
├── revenusDisponibles: number
├── isVerified: boolean
├── createdAt: Timestamp
└── updatedAt: Timestamp
```

### Collection : commandes
```
commandes/{commandeId}
├── clientId: string
├── artisanId: string
├── metier: string
├── description: string
├── adresse: string
├── position: GeoPoint
├── ville: string
├── quartier: string
├── dateIntervention: Timestamp
├── heureIntervention: string
├── statut: string ("en_attente" | "acceptee" | "en_cours" | "terminee" | "annulee")
├── montant: number
├── commission: number
├── montantArtisan: number
├── paiementStatut: string ("en_attente" | "paye" | "reverse")
├── fedapayTransactionId: string
├── photos: array[string]
├── noteClient: number (nullable)
├── noteArtisan: number (nullable)
├── commentaireClient: string (nullable)
├── commentaireArtisan: string (nullable)
├── createdAt: Timestamp
├── acceptedAt: Timestamp (nullable)
├── completedAt: Timestamp (nullable)
└── updatedAt: Timestamp
```

### Collection : metiers (catégories)
```
metiers/{metierId}
├── nom: string
├── categorie: string
├── description: string
├── iconName: string (Font Awesome)
├── ordre: number (pour tri)
└── isActive: boolean
```

### Collection : avis
```
avis/{avisId}
├── commandeId: string
├── artisanId: string
├── clientId: string
├── note: number (1-5)
├── commentaire: string
├── createdAt: Timestamp
└── isVisible: boolean
```

### Collection : notifications
```
notifications/{notificationId}
├── userId: string
├── type: string ("nouvelle_commande" | "commande_acceptee" | "paiement" | "avis")
├── titre: string
├── message: string
├── data: map (données contextuelles)
├── isRead: boolean
└── createdAt: Timestamp
```

### Collection : villes
```
villes/{villeId}
├── nom: string
├── departement: string
├── quartiers: array[string]
├── position: GeoPoint (centre ville)
└── isActive: boolean
```

## LISTE DES MÉTIERS (depuis artiprobtp.netlify.app)

### Catégorie : BTP & Construction
- Électricien
- Plombier
- Maçon
- Peintre
- Menuisier
- Carreleur
- Charpentier
- Soudeur
- Plafonneur
- Serrurier / Métallier
- Couvreur / Zingueur
- Vitrier / Miroitier
- Poseur de Parquet
- Poseur Faux-Plafond

### Catégorie : Énergie & Climatisation
- Panneaux Solaires
- Climatisation
- Chauffagiste
- Installateur Gaz
- Électricité Industrielle

### Catégorie : Aménagement & Finitions
- Paysagiste
- Étanchéité
- Isolation Thermique
- Plâtrier / Stucateur
- Peintre Industriel

### Catégorie : Gros Œuvre
- Démolition
- Terrassement
- Béton Armé / Ferrailleur
- Coffreur / Bancheur
- Échafaudeur

### Catégorie : Études & Conception
- Architecte / Dessinateur
- Bureau d'étude BTP
- Géotechnicien
- Topographe
- Expert en Bâtiment

### Catégorie : Équipements & Installations
- Ascensoriste
- Domotique / Smart Home
- Alarme / Sécurité
- Technicien Fibre Optique

### Catégorie : Eau & Assainissement
- Foreur / Puits
- Assainissement
- Construction Piscine

### Catégorie : Services & Maintenance
- Rénovation Générale
- Nettoyage Chantier
- Location Engins BTP
- Monteur Préfabriqué

### Catégorie : Services à la personne (bonus)
- Coiffeuse
- Maquilleuse
- Esthéticienne
- Tresse africaine
- Femme de ménage
- Nounou
- Garde malade

### Catégorie : Événementiel (bonus)
- Traiteur
- Pâtissier
- Décorateur
- Photographe
- Vidéaste
- DJ
- Wedding planner

### Catégorie : Réparation (bonus)
- Mécanicien
- Carrossier
- Réparateur téléphone

## VILLES DU BÉNIN (principales)

### Départements et villes
```dart
const Map<String, List<String>> villesBenin = {
  "Atlantique": ["Cotonou", "Abomey-Calavi", "Ouidah", "Allada", "Tori-Bossito"],
  "Littoral": ["Cotonou"],
  "Ouémé": ["Porto-Novo", "Akpro-Missérété", "Adjarra", "Sèmè-Kpodji"],
  "Borgou": ["Parakou", "Tchaourou", "N'Dali", "Bembèrèkè"],
  "Alibori": ["Kandi", "Malanville", "Banikoara", "Gogounou"],
  "Atacora": ["Natitingou", "Tanguiéta", "Kouandé", "Boukoumbé"],
  "Donga": ["Djougou", "Bassila", "Copargo"],
  "Zou": ["Abomey", "Bohicon", "Covè", "Zagnanado"],
  "Collines": ["Savalou", "Savè", "Dassa-Zoumè", "Bantè"],
  "Mono": ["Lokossa", "Athiémé", "Grand-Popo", "Comè"],
  "Couffo": ["Aplahoué", "Dogbo", "Djakotomey", "Klouékanmè"],
  "Plateau": ["Pobè", "Kétou", "Sakété", "Adja-Ouèrè"],
};
```

## INTÉGRATION FEDAPAY

### Configuration
```dart
// lib/core/services/fedapay_service.dart
class FedaPayService {
  static const String apiKey = 'YOUR_FEDAPAY_API_KEY'; // À configurer
  static const String baseUrl = 'https://api.fedapay.com/v1';
  static const double commissionRate = 0.10; // 10% de commission
  
  // Créer une transaction
  Future<Map<String, dynamic>> createTransaction({
    required double amount,
    required String description,
    required String customerEmail,
    required String customerPhone,
    required String commandeId,
  }) async {
    // Implémentation API FedaPay
  }
  
  // Vérifier le statut d'une transaction
  Future<String> checkTransactionStatus(String transactionId) async {
    // Implémentation
  }
  
  // Calculer la commission
  static double calculateCommission(double montant) {
    return montant * commissionRate;
  }
  
  static double calculateArtisanAmount(double montant) {
    return montant - calculateCommission(montant);
  }
}
```

### Documentation FedaPay
- API Docs : https://docs.fedapay.com
- Moyens de paiement supportés : Mobile Money (MTN, Moov), Cartes bancaires
- Webhook pour notifications de paiement

## FONCTIONNALITÉS DÉTAILLÉES

### 1. AUTHENTIFICATION

#### Écran de sélection de rôle (première ouverture)
- Bouton "Je suis un Client"
- Bouton "Je suis un Artisan"
- Design simple, logo centré en haut

#### Inscription
- Champs : Nom, Prénom, Téléphone, Email, Mot de passe
- Validation OTP par SMS (Firebase Auth)
- Sélection Ville et Quartier (dropdown)
- Géolocalisation automatique (demander permission)
- Pour artisan : sélection du métier + description

#### Connexion
- Téléphone ou Email + Mot de passe
- Option "Mot de passe oublié"
- Connexion automatique si déjà connecté

### 2. INTERFACE CLIENT

#### Écran d'accueil
```
┌─────────────────────────────────┐
│ Logo Mon Artisan    [Menu] [🔔] │
├─────────────────────────────────┤
│                                 │
│  [Barre de recherche]           │
│  "Quel service cherchez-vous ?" │
│                                 │
│  Filtres :                      │
│  [Ville ▼] [Quartier ▼]         │
│                                 │
├─────────────────────────────────┤
│  Catégories populaires          │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐   │
│  │ ⚡ │ │ 🔧 │ │ 🎨 │ │ 🪚 │   │
│  └────┘ └────┘ └────┘ └────┘   │
│  Élec.  Plomb. Peint. Menu.    │
│                                 │
├─────────────────────────────────┤
│  Tous les métiers (grille)      │
│  ┌──────────┐ ┌──────────┐     │
│  │ Électr.  │ │ Plombier │     │
│  │ 45 art.  │ │ 32 art.  │     │
│  └──────────┘ └──────────┘     │
│                                 │
└─────────────────────────────────┘
```

#### Recherche d'artisans
- Filtres : Métier, Ville, Quartier, Rayon (km)
- Tri : Plus proche, Mieux noté, Prix
- Affichage liste avec :
  - Photo artisan
  - Nom, métier
  - Note (étoiles) + nombre d'avis
  - Distance (ex: "2.5 km")
  - Tarif indicatif
  - Badge "Vérifié" si isVerified
  - Bouton "Voir profil"

#### Profil artisan
- Photo de profil
- Nom, métier, ville/quartier
- Note globale + nombre d'avis
- Description
- Tarifs (horaire/journalier)
- Galerie photos (travaux réalisés)
- Avis clients (liste)
- Bouton bleu "Commander" (fixe en bas)

#### Passer une commande
- Description du besoin (textarea)
- Date et heure souhaitées
- Adresse d'intervention (auto-remplie, modifiable)
- Montant estimé (saisi par client ou artisan)
- Photos du problème (optionnel, max 3)
- Bouton "Confirmer et payer"

#### Paiement
- Récapitulatif commande
- Montant total
- Choix moyen de paiement :
  - MTN Mobile Money
  - Moov Money
  - Carte bancaire
- Redirection FedaPay
- Confirmation de paiement
- Notification artisan automatique

#### Suivi commande
- Statut en temps réel :
  - En attente d'acceptation
  - Acceptée (date/heure confirmée)
  - En cours
  - Terminée
- Bouton "Contacter l'artisan" (appel téléphonique)
- Bouton "Annuler" (si en_attente uniquement)
- Après terminée : "Noter l'artisan"

#### Historique
- Liste des commandes passées
- Filtres : Toutes, En cours, Terminées, Annulées
- Possibilité de recommander le même artisan

### 3. INTERFACE ARTISAN

#### Écran d'accueil artisan
```
┌─────────────────────────────────┐
│ Bonjour [Nom]       [Menu] [🔔] │
├─────────────────────────────────┤
│  Statut : [●] En ligne          │
│  [Toggle switch]                │
│                                 │
│  ┌─────────────────────────────┐│
│  │ Revenus disponibles         ││
│  │ 125 000 FCFA                ││
│  │ [Retirer]                   ││
│  └─────────────────────────────┘│
│                                 │
│  Statistiques du mois           │
│  ┌──────┐ ┌──────┐ ┌──────┐    │
│  │  12  │ │ 4.8  │ │ 340K │    │
│  │Cmdes │ │Note  │ │FCFA  │    │
│  └──────┘ └──────┘ └──────┘    │
│                                 │
├─────────────────────────────────┤
│  Nouvelles commandes (3)        │
│  ┌─────────────────────────────┐│
│  │ Réparation électrique       ││
│  │ Cotonou - Akpakpa           ││
│  │ 2.3 km • 15 000 FCFA        ││
│  │ [Refuser] [Accepter]        ││
│  └─────────────────────────────┘│
│                                 │
└─────────────────────────────────┘
```

#### Gestion du profil
- Modifier photo, description
- Modifier tarifs
- Ajouter/supprimer photos de travaux
- Modifier rayon d'action
- Gérer disponibilité

#### Commandes reçues
- Onglets : Nouvelles, Acceptées, En cours, Terminées
- Notification push pour nouvelle commande
- Détails commande :
  - Nom client, téléphone
  - Description besoin
  - Adresse + carte
  - Distance
  - Montant
  - Photos du problème
- Actions :
  - Accepter (confirme date/heure)
  - Refuser (avec raison optionnelle)
  - Contacter client
  - Marquer "Terminée"

#### Revenus
- Solde disponible
- Historique des paiements
- Détail par commande (montant - commission)
- Bouton "Demander un retrait"
- Historique des retraits

### 4. NOTIFICATIONS PUSH

#### Pour le client
- "Votre commande a été acceptée par [Artisan]"
- "Votre commande est en cours"
- "[Artisan] a terminé votre commande. Notez-le !"
- "Paiement confirmé"

#### Pour l'artisan
- "Nouvelle commande à [Distance] km de vous !"
- "Le client a validé votre prestation. Revenus disponibles."
- "Vous avez reçu un nouvel avis"
- "Votre retrait a été traité"

### 5. SYSTÈME DE GÉOLOCALISATION

#### Recherche d'artisans proches
```dart
// Utiliser geoflutterfire_plus
Future<List<Artisan>> findNearbyArtisans({
  required String metier,
  required GeoPoint userPosition,
  required double radiusKm,
}) async {
  // Requête géospatiale Firestore
  // Filtrer par métier + distance
  // Trier par distance croissante
  // Retourner liste artisans disponibles
}
```

#### Calcul de distance
```dart
double calculateDistance(GeoPoint point1, GeoPoint point2) {
  // Formule Haversine
  // Retourne distance en km
}
```

### 6. SYSTÈME DE NOTATION

#### Après validation commande
- Client note artisan (1-5 étoiles)
- Commentaire optionnel
- Artisan peut noter client (optionnel)
- Mise à jour noteGlobale artisan (moyenne)
- Affichage dans profil artisan

#### Calcul note globale
```dart
void updateArtisanRating(String artisanId, double newRating) {
  // Récupérer noteGlobale et nombreAvis actuels
  // Calculer nouvelle moyenne
  // Mettre à jour Firestore
}
```

## SÉCURITÉ ET BONNES PRATIQUES

### 1. Authentification et autorisation
- Utiliser Firebase Authentication
- Tokens JWT pour API calls
- Règles Firestore Security Rules strictes :
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users : lecture propre profil, écriture propre profil uniquement
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Artisans : lecture publique, écriture propriétaire uniquement
    match /artisans/{artisanId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == resource.data.userId;
    }
    
    // Commandes : lecture si client ou artisan concerné
    match /commandes/{commandeId} {
      allow read: if request.auth.uid == resource.data.clientId 
                  || request.auth.uid == resource.data.artisanId;
      allow create: if request.auth.uid == request.resource.data.clientId;
      allow update: if request.auth.uid == resource.data.clientId 
                    || request.auth.uid == resource.data.artisanId;
    }
    
    // Avis : lecture publique, création par client uniquement
    match /avis/{avisId} {
      allow read: if request.auth != null;
      allow create: if request.auth.uid == request.resource.data.clientId;
    }
    
    // Métiers et villes : lecture publique
    match /metiers/{metierId} {
      allow read: if true;
    }
    match /villes/{villeId} {
      allow read: if true;
    }
  }
}
```

### 2. Validation des données
- Valider tous les inputs côté client ET serveur
- Utiliser Cloud Functions pour logique métier sensible
- Vérifier montants, commissions, statuts

### 3. Paiement sécurisé
- JAMAIS stocker de données bancaires
- Utiliser uniquement FedaPay pour transactions
- Vérifier statut paiement via webhook
- Logger toutes les transactions
- Système de double vérification pour retraits

### 4. Protection des données personnelles
- Chiffrement HTTPS obligatoire
- Pas d'affichage complet du téléphone (masquer 3 chiffres)
- Demander consentement géolocalisation
- Politique de confidentialité dans l'app

### 5. Gestion des erreurs
```dart
// Wrapper pour toutes les requêtes
Future<T> safeApiCall<T>(Future<T> Function() apiCall) async {
  try {
    return await apiCall();
  } on FirebaseException catch (e) {
    // Logger l'erreur
    throw AppException('Erreur Firebase: ${e.message}');
  } on SocketException {
    throw AppException('Pas de connexion internet');
  } catch (e) {
    throw AppException('Une erreur est survenue');
  }
}
```

### 6. Performance
- Utiliser pagination pour listes (20 items par page)
- Cache images avec cached_network_image
- Lazy loading pour galeries photos
- Optimiser requêtes Firestore (indexes)
- Compression images avant upload (max 1MB)

## FONCTIONNALITÉS BONUS (DIFFÉRENCIATION)

### 1. Mode hors ligne
- Sauvegarder dernières recherches en local
- Afficher profils artisans consultés (cache)
- Synchroniser quand connexion revient

### 2. Chat intégré (optionnel mais recommandé)
- Discussion client-artisan avant commande
- Envoi de photos dans le chat
- Notifications messages non lus
- Package : flutter_chat_ui

### 3. Système de favoris
- Client peut sauvegarder artisans favoris
- Accès rapide pour recommander

### 4. Partage de profil artisan
- Bouton "Partager" sur profil artisan
- Génération lien deep link
- Partage via WhatsApp, SMS, etc.

### 5. Historique de recherche
- Sauvegarder recherches récentes
- Suggestions basées sur historique

### 6. Système de parrainage
- Code parrain pour nouveaux utilisateurs
- Bonus pour parrain et filleul
- Tracking dans Firestore

### 7. Badges artisans
- "Nouveau" (< 1 mois)
- "Populaire" (> 50 commandes)
- "Top noté" (note > 4.5)
- "Réactif" (accepte vite les commandes)
- "Vérifié" (documents validés par admin)

### 8. Estimation de prix intelligente
- Suggérer fourchette de prix selon métier
- Basée sur historique commandes similaires

### 9. Disponibilité en temps réel
- Artisan peut définir plages horaires
- Calendrier de disponibilité
- Réservation créneau spécifique

### 10. Système de réclamation
- Bouton "Signaler un problème"
- Formulaire de réclamation
- Traitement par admin

## WORKFLOW COMPLET D'UNE COMMANDE

```
1. CLIENT recherche artisan
   ↓
2. CLIENT consulte profil artisan
   ↓
3. CLIENT passe commande + description
   ↓
4. CLIENT paie via FedaPay
   ↓ (paiement confirmé)
5. SYSTÈME notifie artisans proches
   ↓
6. ARTISAN reçoit notification push
   ↓
7. ARTISAN consulte détails commande
   ↓
8. ARTISAN accepte ou refuse
   ↓ (si accepte)
9. CLIENT reçoit notification "Acceptée"
   ↓
10. ARTISAN se rend sur place
    ↓
11. ARTISAN réalise prestation
    ↓
12. ARTISAN marque "Terminée"
    ↓
13. CLIENT reçoit notification
    ↓
14. CLIENT valide prestation
    ↓
15. CLIENT note artisan
    ↓
16. SYSTÈME calcule commission
    ↓
17. SYSTÈME crédite compte artisan
    ↓
18. ARTISAN peut demander retrait
```

## GESTION DES STATUTS DE COMMANDE

### Statuts possibles
1. **en_attente** : Commande créée, paiement validé, en attente acceptation artisan
2. **acceptee** : Artisan a accepté, date/heure confirmée
3. **en_cours** : Artisan a commencé le travail
4. **terminee** : Artisan a marqué terminée, en attente validation client
5. **validee** : Client a validé, paiement reversé à artisan
6. **annulee** : Commande annulée (par client ou artisan)
7. **litige** : Problème signalé, intervention admin nécessaire

### Transitions autorisées
```
en_attente → acceptee (par artisan)
en_attente → annulee (par client ou timeout 24h)
acceptee → en_cours (par artisan)
acceptee → annulee (par artisan avec raison)
en_cours → terminee (par artisan)
terminee → validee (par client)
terminee → litige (par client si problème)
* → litige (par admin)
```

### Règles métier
- Si aucun artisan n'accepte en 24h → statut "annulee" + remboursement automatique
- Si client ne valide pas en 48h après "terminee" → validation automatique
- En cas d'annulation après acceptation → frais d'annulation 10%
- En cas de litige → blocage paiement jusqu'à résolution admin

## CONFIGURATION FIREBASE

### 1. Créer projet Firebase
- Aller sur https://console.firebase.google.com
- Créer nouveau projet "mon-artisan-benin"
- Activer Google Analytics (optionnel)

### 2. Ajouter applications
- Ajouter app Android (package: com.monartisan.app)
- Télécharger google-services.json → android/app/
- Ajouter app iOS (bundle: com.monartisan.app)
- Télécharger GoogleService-Info.plist → ios/Runner/

### 3. Activer services
- Authentication : Email/Password, Phone
- Firestore Database : Mode production avec rules
- Storage : Pour photos profils et travaux
- Cloud Messaging : Pour notifications push
- Cloud Functions : Pour logique serveur (webhooks, calculs)

### 4. Indexes Firestore nécessaires
```
Collection: artisans
- metier (Ascending) + position (Geohash) + disponibilite (Ascending)
- ville (Ascending) + metier (Ascending) + noteGlobale (Descending)

Collection: commandes
- clientId (Ascending) + createdAt (Descending)
- artisanId (Ascending) + statut (Ascending) + createdAt (Descending)
```

### 5. Cloud Functions importantes
```javascript
// functions/index.js

// Webhook FedaPay pour confirmer paiement
exports.fedapayWebhook = functions.https.onRequest(async (req, res) => {
  // Vérifier signature FedaPay
  // Mettre à jour statut paiement commande
  // Notifier artisan
});

// Calculer et mettre à jour note artisan
exports.updateArtisanRating = functions.firestore
  .document('avis/{avisId}')
  .onCreate(async (snap, context) => {
    const avis = snap.data();
    // Recalculer moyenne
    // Mettre à jour artisan
  });

// Annulation automatique si pas d'acceptation en 24h
exports.autoCancel = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    // Chercher commandes en_attente > 24h
    // Marquer annulee
    // Déclencher remboursement
  });

// Validation automatique si client ne valide pas en 48h
exports.autoValidate = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    // Chercher commandes terminee > 48h
    // Marquer validee
    // Créditer artisan
  });

// Notification nouvelle commande aux artisans proches
exports.notifyNearbyArtisans = functions.firestore
  .document('commandes/{commandeId}')
  .onCreate(async (snap, context) => {
    const commande = snap.data();
    // Trouver artisans dans rayon
    // Envoyer notification push
  });
```

## TESTS À EFFECTUER

### Tests fonctionnels
- [ ] Inscription client et artisan
- [ ] Connexion / Déconnexion
- [ ] Recherche artisans par métier
- [ ] Filtrage par ville/quartier
- [ ] Géolocalisation et calcul distance
- [ ] Consultation profil artisan
- [ ] Passage de commande
- [ ] Paiement FedaPay (mode test)
- [ ] Notification push artisan
- [ ] Acceptation/Refus commande
- [ ] Marquage terminée
- [ ] Validation client
- [ ] Notation artisan
- [ ] Calcul commission
- [ ] Crédit compte artisan
- [ ] Demande de retrait
- [ ] Historique commandes
- [ ] Modification profil
- [ ] Upload photos

### Tests de sécurité
- [ ] Firestore rules (tentative accès non autorisé)
- [ ] Validation inputs (injection SQL, XSS)
- [ ] Vérification tokens authentification
- [ ] Protection endpoints API
- [ ] Chiffrement données sensibles

### Tests de performance
- [ ] Temps de chargement < 3s
- [ ] Scroll fluide listes longues
- [ ] Chargement images optimisé
- [ ] Fonctionnement 3G/4G
- [ ] Consommation batterie raisonnable

### Tests multi-devices
- [ ] Android 6.0 à 14
- [ ] iOS 12 à 17
- [ ] Différentes tailles écrans
- [ ] Orientation portrait/paysage
- [ ] Mode sombre (si implémenté)

## DÉPLOIEMENT

### 1. Préparation Android
```bash
# Générer keystore
keytool -genkey -v -keystore ~/mon-artisan-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias mon-artisan

# Configurer android/key.properties
storePassword=<password>
keyPassword=<password>
keyAlias=mon-artisan
storeFile=<path>/mon-artisan-key.jks

# Build release
flutter build appbundle --release
```

### 2. Publication Google Play Store
- Créer compte développeur ($25)
- Créer application "Mon Artisan"
- Uploader AAB (android/build/app/outputs/bundle/release/)
- Remplir fiche store (description, screenshots, icône)
- Définir pays cibles (Bénin prioritaire)
- Soumettre pour review

### 3. Préparation iOS
```bash
# Build iOS
flutter build ipa --release
```

### 4. Publication Apple App Store
- Compte développeur Apple ($99/an)
- Certificats et provisioning profiles
- Uploader via Xcode ou Transporter
- Remplir fiche App Store Connect
- Soumettre pour review

### 5. Monitoring post-lancement
- Firebase Crashlytics : Suivi des crashes
- Firebase Analytics : Comportement utilisateurs
- Firebase Performance : Temps de chargement
- Avis utilisateurs : Répondre rapidement

## MAINTENANCE ET ÉVOLUTION

### Mises à jour régulières
- Corrections bugs signalés
- Optimisations performance
- Ajout nouveaux métiers
- Ajout nouvelles villes/quartiers
- Amélioration UI/UX selon retours

### Évolutions futures possibles
- Version web (Flutter Web)
- Système de réservation avancé
- Paiement en plusieurs fois
- Programme de fidélité
- Statistiques détaillées artisans
- Certification métiers
- Assurance prestations
- Système de garantie
- Marketplace matériaux
- Formation artisans en ligne

## DOCUMENTATION À FOURNIR

### 1. README.md
- Description projet
- Prérequis installation
- Instructions setup Firebase
- Configuration FedaPay
- Commandes build
- Structure projet

### 2. Guide utilisateur
- Comment s'inscrire
- Comment rechercher artisan
- Comment passer commande
- Comment payer
- Comment noter
- FAQ

### 3. Guide artisan
- Comment créer profil
- Comment recevoir commandes
- Comment gérer disponibilité
- Comment retirer gains
- Conseils optimisation profil

### 4. Documentation technique
- Architecture application
- Modèles de données
- API endpoints
- Cloud Functions
- Firestore rules
- Guide déploiement

## CHECKLIST AVANT LANCEMENT

### Technique
- [ ] Firebase configuré et testé
- [ ] FedaPay intégré et testé (mode production)
- [ ] Google Maps API configurée
- [ ] Notifications push fonctionnelles
- [ ] Firestore rules déployées
- [ ] Cloud Functions déployées
- [ ] Indexes Firestore créés
- [ ] Crashlytics activé
- [ ] Analytics configuré

### Contenu
- [ ] Liste métiers complète
- [ ] Liste villes/quartiers complète
- [ ] Icônes métiers (Font Awesome)
- [ ] Logo intégré
- [ ] Textes légaux (CGU, Politique confidentialité)
- [ ] Textes d'aide et FAQ

### Design
- [ ] Charte graphique respectée
- [ ] Pas d'emojis dans l'interface
- [ ] Icônes cohérentes
- [ ] Responsive toutes tailles écrans
- [ ] Animations fluides
- [ ] Loading states partout

### Tests
- [ ] Tests fonctionnels complets
- [ ] Tests sur vrais devices Android
- [ ] Tests sur vrais devices iOS
- [ ] Tests paiement réel
- [ ] Tests notifications
- [ ] Tests géolocalisation

### Légal
- [ ] CGU rédigées
- [ ] Politique de confidentialité
- [ ] Mentions légales
- [ ] Conditions artisans
- [ ] Taux commission défini

### Marketing
- [ ] Screenshots store (5 minimum)
- [ ] Icône application (1024x1024)
- [ ] Description courte et longue
- [ ] Mots-clés SEO
- [ ] Vidéo démo (optionnel)

## RESSOURCES ET LIENS UTILES

### Documentation
- Flutter : https://docs.flutter.dev
- Firebase : https://firebase.google.com/docs
- FedaPay : https://docs.fedapay.com
- Google Maps Flutter : https://pub.dev/packages/google_maps_flutter
- Geoflutterfire : https://pub.dev/packages/geoflutterfire_plus

### Design
- Font Awesome : https://fontawesome.com/icons
- Material Design : https://m3.material.io
- Figma (maquettes) : https://figma.com

### Outils
- Firebase Console : https://console.firebase.google.com
- Google Play Console : https://play.google.com/console
- App Store Connect : https://appstoreconnect.apple.com
- FedaPay Dashboard : https://dashboard.fedapay.com

## CONTACT ET SUPPORT

Pour toute question technique durant le développement :
- Documentation Flutter : https://docs.flutter.dev
- Stack Overflow : https://stackoverflow.com/questions/tagged/flutter
- Firebase Support : https://firebase.google.com/support
- FedaPay Support : support@fedapay.com

---

## NOTES IMPORTANTES POUR LE DÉVELOPPEMENT

1. **Simplicité avant tout** : Interface épurée, pas de fonctionnalités superflues
2. **Performance** : Optimiser pour connexions 3G/4G
3. **Sécurité** : Tester toutes les règles Firestore, valider tous les inputs
4. **Accessibilité** : Textes lisibles, boutons assez grands, contrastes suffisants
5. **Offline-first** : Gérer les cas sans connexion gracieusement
6. **Feedback utilisateur** : Loading states, messages d'erreur clairs, confirmations
7. **Localisation** : Tout en français, format dates/heures local
8. **Respect vie privée** : Demander permissions, expliquer pourquoi
9. **Évolutivité** : Code modulaire, facile à maintenir et étendre
10. **Tests** : Tester sur vrais devices, pas seulement émulateurs

**Bon développement !**
