# Guide de Développement - Mon Artisan

## Structure du projet créée

Le projet Flutter a été initialisé avec la structure suivante :

### Fichiers de configuration
- `pubspec.yaml` : Dépendances et configuration du projet
- `.gitignore` : Fichiers à ignorer par Git
- `README.md` : Documentation principale
- `FIREBASE_SETUP.md` : Guide de configuration Firebase

### Architecture de l'application

```
lib/
├── main.dart                    # Point d'entrée
├── app.dart                     # Configuration MaterialApp
├── core/
│   ├── constants/
│   │   ├── colors.dart         # Charte graphique (BLEU #1A3C6E, ROUGE #C0392B)
│   │   ├── text_styles.dart    # Styles de texte (Poppins)
│   │   ├── app_constants.dart  # Constantes globales
│   │   ├── villes_benin.dart   # Villes et départements du Bénin
│   │   └── metiers_data.dart   # Liste complète des métiers
│   ├── services/
│   │   ├── firebase_service.dart  # Service Firebase centralisé
│   │   └── fedapay_service.dart   # Intégration paiement FedaPay
│   └── utils/
│       └── validators.dart     # Validateurs de formulaires
├── models/
│   ├── user_model.dart         # Modèle utilisateur
│   ├── artisan_model.dart      # Modèle artisan
│   ├── commande_model.dart     # Modèle commande
│   └── metier_model.dart       # Modèle métier
├── providers/
│   └── auth_provider.dart      # Provider d'authentification
├── screens/
│   ├── auth/
│   │   ├── role_selection_screen.dart  # Sélection Client/Artisan
│   │   └── login_screen.dart           # Connexion
│   └── shared/
│       └── splash_screen.dart          # Écran de démarrage
└── widgets/
    ├── custom_button.dart      # Bouton personnalisé
    └── custom_textfield.dart   # Champ de texte personnalisé
```

## Prochaines étapes de développement

### 1. Configuration Firebase (PRIORITAIRE)

Suivre le guide `FIREBASE_SETUP.md` pour :
- Créer le projet Firebase
- Ajouter les applications Android et iOS
- Télécharger les fichiers de configuration
- Activer les services (Auth, Firestore, Storage, FCM)
- Configurer les règles de sécurité

### 2. Écrans à créer

#### Authentification
- [ ] `register_screen.dart` : Inscription client/artisan
- [ ] `forgot_password_screen.dart` : Réinitialisation mot de passe
- [ ] `otp_verification_screen.dart` : Vérification OTP SMS

#### Interface Client
- [ ] `home_client_screen.dart` : Accueil avec recherche et catégories
- [ ] `search_artisan_screen.dart` : Recherche et filtres
- [ ] `artisan_profile_screen.dart` : Profil détaillé artisan
- [ ] `commande_screen.dart` : Formulaire de commande
- [ ] `payment_screen.dart` : Paiement FedaPay
- [ ] `commande_detail_screen.dart` : Détails et suivi commande
- [ ] `historique_screen.dart` : Historique des commandes

#### Interface Artisan
- [ ] `home_artisan_screen.dart` : Dashboard artisan
- [ ] `profile_artisan_screen.dart` : Gestion profil
- [ ] `commandes_list_screen.dart` : Liste des commandes
- [ ] `commande_artisan_detail_screen.dart` : Détails commande artisan
- [ ] `revenus_screen.dart` : Gestion des revenus

### 3. Widgets à créer

- [ ] `artisan_card.dart` : Carte artisan dans les listes
- [ ] `loading_widget.dart` : Indicateur de chargement
- [ ] `metier_card.dart` : Carte métier sur l'accueil
- [ ] `commande_card.dart` : Carte commande dans l'historique
- [ ] `rating_widget.dart` : Affichage et saisie de notes
- [ ] `photo_picker_widget.dart` : Sélection de photos
- [ ] `map_widget.dart` : Carte Google Maps

### 4. Providers à créer

- [ ] `artisan_provider.dart` : Gestion des artisans
- [ ] `commande_provider.dart` : Gestion des commandes
- [ ] `metier_provider.dart` : Gestion des métiers
- [ ] `location_provider.dart` : Géolocalisation

### 5. Services à créer

- [ ] `geolocation_service.dart` : Géolocalisation et calcul distances
- [ ] `notification_service.dart` : Notifications push FCM
- [ ] `storage_service.dart` : Upload/download images Firebase Storage
- [ ] `search_service.dart` : Recherche géospatiale artisans

### 6. Navigation

- [ ] Créer `app_router.dart` avec GoRouter
- [ ] Définir les routes pour tous les écrans
- [ ] Gérer la navigation conditionnelle (auth/non-auth)
- [ ] Deep linking pour partage de profils

### 7. Fonctionnalités avancées

#### Géolocalisation
```dart
// À implémenter dans geolocation_service.dart
- Demander permissions localisation
- Obtenir position actuelle
- Calculer distance entre deux points (Haversine)
- Recherche artisans dans un rayon
- Intégration Google Maps
```

#### Paiement FedaPay
```dart
// À compléter dans fedapay_service.dart
- Créer transaction
- Redirection vers page paiement
- Webhook de confirmation
- Gestion des erreurs
- Calcul commission (10%)
```

#### Notifications Push
```dart
// À implémenter dans notification_service.dart
- Configuration FCM
- Demander permissions
- Gérer tokens devices
- Envoyer notifications ciblées
- Gérer réception et affichage
```

#### Upload d'images
```dart
// À implémenter dans storage_service.dart
- Compression images (max 1MB)
- Upload vers Firebase Storage
- Génération URLs
- Suppression images
```

### 8. Tests

- [ ] Tests unitaires pour les modèles
- [ ] Tests unitaires pour les services
- [ ] Tests unitaires pour les validators
- [ ] Tests d'intégration pour l'authentification
- [ ] Tests d'intégration pour les commandes
- [ ] Tests UI pour les écrans principaux

### 9. Optimisations

- [ ] Pagination des listes (20 items/page)
- [ ] Cache des images avec `cached_network_image`
- [ ] Lazy loading des galeries photos
- [ ] Optimisation des requêtes Firestore
- [ ] Gestion du mode hors ligne
- [ ] Compression des images avant upload

### 10. Configuration Android

```gradle
// android/app/build.gradle
- Configurer minSdkVersion: 21
- Configurer targetSdkVersion: 34
- Ajouter permissions (Internet, Location, Camera, Storage)
- Configurer Google Maps API Key
```

### 11. Configuration iOS

```swift
// ios/Runner/Info.plist
- Ajouter permissions (Location, Camera, Photos)
- Configurer Google Maps API Key
- Configurer App Transport Security
```

## Commandes utiles

### Développement
```bash
# Lancer l'app en mode debug
flutter run

# Lancer avec hot reload
flutter run --hot

# Lancer sur un device spécifique
flutter run -d <device-id>

# Voir les devices disponibles
flutter devices
```

### Build
```bash
# Build Android APK
flutter build apk --release

# Build Android App Bundle (pour Play Store)
flutter build appbundle --release

# Build iOS
flutter build ios --release
```

### Tests
```bash
# Lancer tous les tests
flutter test

# Lancer tests avec coverage
flutter test --coverage

# Analyser le code
flutter analyze
```

### Maintenance
```bash
# Mettre à jour les dépendances
flutter pub upgrade

# Nettoyer le projet
flutter clean

# Obtenir les dépendances
flutter pub get
```

## Checklist avant commit

- [ ] Code formaté (`flutter format .`)
- [ ] Pas d'erreurs d'analyse (`flutter analyze`)
- [ ] Tests passent (`flutter test`)
- [ ] Pas de console.log ou print() oubliés
- [ ] Commentaires ajoutés pour code complexe
- [ ] Constantes utilisées (pas de valeurs en dur)
- [ ] Gestion des erreurs implémentée
- [ ] Loading states ajoutés

## Bonnes pratiques

### Nommage
- Fichiers : `snake_case.dart`
- Classes : `PascalCase`
- Variables/fonctions : `camelCase`
- Constantes : `UPPER_SNAKE_CASE`

### Organisation du code
- Un widget par fichier
- Séparer logique métier et UI
- Utiliser const constructors quand possible
- Extraire les widgets réutilisables

### Performance
- Utiliser `const` pour widgets statiques
- Éviter `setState()` sur gros widgets
- Utiliser `ListView.builder` pour listes longues
- Disposer les controllers dans `dispose()`

### Sécurité
- Ne jamais commit les clés API
- Valider tous les inputs utilisateur
- Utiliser HTTPS uniquement
- Respecter les règles Firestore

## Ressources

- [Documentation Flutter](https://docs.flutter.dev)
- [Documentation Firebase](https://firebase.google.com/docs)
- [Documentation FedaPay](https://docs.fedapay.com)
- [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)
- [Provider](https://pub.dev/packages/provider)
- [GoRouter](https://pub.dev/packages/go_router)

## Support

Pour toute question :
1. Consulter la documentation officielle
2. Vérifier les issues GitHub des packages
3. Chercher sur Stack Overflow
4. Consulter les spécifications techniques

Bon développement !
