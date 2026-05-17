# Mon Artisan

Application mobile cross-platform (Android/iOS) pour connecter clients et artisans au Bénin.

## Stack Technique

- **Framework**: Flutter 3.41.6
- **Langage**: Dart 3.11.4
- **Backend**: Firebase (Firestore, Authentication, Storage, Cloud Functions)
- **Paiement**: FedaPay API
- **Géolocalisation**: Google Maps API
- **Notifications**: Firebase Cloud Messaging

## Prérequis

- Flutter SDK 3.41.6 ou supérieur
- Dart 3.11.4 ou supérieur
- Android Studio / Xcode
- Compte Firebase
- Compte FedaPay
- Google Maps API Key

## Installation

1. Cloner le repository
```bash
git clone <repository-url>
cd mon_artisan_app
```

2. Installer les dépendances
```bash
flutter pub get
```

3. Configuration Firebase

- Créer un projet Firebase sur https://console.firebase.google.com
- Ajouter une application Android et iOS
- Télécharger les fichiers de configuration :
  - `google-services.json` → `android/app/`
  - `GoogleService-Info.plist` → `ios/Runner/`

4. Configuration FedaPay

- Obtenir votre API Key sur https://dashboard.fedapay.com
- Modifier `lib/core/constants/app_constants.dart` avec votre clé API

5. Configuration Google Maps

- Obtenir une API Key sur Google Cloud Console
- Ajouter la clé dans :
  - Android: `android/app/src/main/AndroidManifest.xml`
  - iOS: `ios/Runner/AppDelegate.swift`

## Lancer l'application

```bash
# Mode debug
flutter run

# Mode release
flutter run --release
```

## Structure du projet

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/       # Couleurs, styles, constantes
│   ├── routes/          # Navigation
│   ├── services/        # Services Firebase, FedaPay, etc.
│   └── utils/           # Utilitaires
├── models/              # Modèles de données
├── providers/           # State management
├── screens/             # Écrans de l'application
│   ├── auth/           # Authentification
│   ├── client/         # Interface client
│   ├── artisan/        # Interface artisan
│   └── shared/         # Écrans partagés
└── widgets/            # Composants réutilisables
```

## Fonctionnalités principales

### Pour les Clients
- Recherche d'artisans par métier et localisation
- Consultation des profils et avis
- Passage de commandes
- Paiement sécurisé via FedaPay
- Suivi des commandes en temps réel
- Notation des artisans

### Pour les Artisans
- Création et gestion du profil professionnel
- Réception de commandes géolocalisées
- Acceptation/Refus de commandes
- Gestion des revenus
- Demande de retrait

## Configuration Firestore

### Collections principales
- `users` : Profils utilisateurs
- `artisans` : Profils détaillés des artisans
- `commandes` : Commandes et prestations
- `metiers` : Liste des métiers disponibles
- `avis` : Avis et notations
- `villes` : Villes et quartiers du Bénin

### Security Rules

Déployer les règles de sécurité Firestore depuis Firebase Console.

## Build pour production

### Android
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ipa --release
```

## Tests

```bash
# Tests unitaires
flutter test

# Tests d'intégration
flutter test integration_test
```

## Déploiement

### Google Play Store
1. Générer un keystore
2. Configurer `android/key.properties`
3. Build l'AAB
4. Upload sur Play Console

### Apple App Store
1. Configurer les certificats
2. Build l'IPA
3. Upload via Xcode ou Transporter

## Support

Pour toute question ou problème :
- Documentation Flutter : https://docs.flutter.dev
- Documentation Firebase : https://firebase.google.com/docs
- Documentation FedaPay : https://docs.fedapay.com

## Licence

Copyright © 2026 Mon Artisan. Tous droits réservés.
