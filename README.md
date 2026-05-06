# Mon Artisan - Plateforme de Mise en Relation Artisans-Clients

Application mobile Flutter pour connecter les clients aux artisans qualifiés au Bénin.

## 🚀 Démarrage Rapide

```bash
cd mon_artisan_app
flutter pub get
flutter run
```

## 📱 Fonctionnalités

### Pour les Clients
- 🔍 Recherche d'artisans par métier et localisation
- ⭐ Consultation des profils et avis
- 📝 Passage de commandes
- 💳 Paiement sécurisé (FedaPay)
- 📊 Suivi des commandes en temps réel

### Pour les Artisans
- 👤 Profil professionnel détaillé
- 📍 Réception de commandes géolocalisées
- ✅ Gestion des prestations
- 💰 Suivi des revenus
- 🏦 Demandes de retrait

### Pour les Administrateurs
- ✔️ Validation des profils artisans
- 👥 Gestion des agents commerciaux
- 📈 Statistiques globales

## 🛠️ Stack Technique

- **Framework**: Flutter 3.41.6
- **Backend**: Firebase (Firestore, Auth, Storage, FCM)
- **Paiement**: FedaPay API
- **Maps**: Google Maps API
- **State Management**: Provider

## 📚 Documentation

- [Guide de développement](mon_artisan_app/docs/GUIDE_DEVELOPPEMENT.md)
- [Configuration Admin](mon_artisan_app/docs/ADMIN_SETUP.md)
- [Règles de sécurité Firestore](mon_artisan_app/docs/GUIDE_REGLES_SECURITE.md)
- [Index Firestore requis](mon_artisan_app/docs/FIRESTORE_INDEXES_REQUIRED.md)

## 📦 Build APK

```bash
cd mon_artisan_app
flutter build apk --release --target-platform android-arm,android-arm64
```

L'APK sera dans : `build/app/outputs/flutter-apk/`

## 🔐 Configuration

1. **Firebase** : Ajouter `google-services.json` dans `android/app/`
2. **FedaPay** : Configurer la clé API dans `lib/core/constants/app_constants.dart`
3. **Google Maps** : Ajouter la clé API dans `AndroidManifest.xml`

## 📄 Licence

Copyright © 2026 Mon Artisan. Tous droits réservés.
