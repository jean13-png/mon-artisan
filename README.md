# 🚀 Mon Artisan - Application Mobile

Nouvelles fonctionnalité à verifier si c'est déja implémenter
5.1 Espace Artisan
● Inscription via agent terrain avec paiement de 958 FCFA
● Creation de profil (nom, metier, ville, quartier, photo, description, tarifs)
● Acceptation obligatoire du contrat d'engagement (section 6)
● Numero de telephone masque — non visible publiquement
● Reception et suivi des commandes clients
● Messagerie interne securisee avec les clients
● Portefeuille electronique : accumulation des gains et retrait vers Mobile Money
● Tableau de bord : commandes recues, revenus, avis clients, statistiques
● Notifications push pour chaque nouvelle commande ou message

5.2 Espace Client
● Acces gratuit a la plateforme — aucun frais d'inscription
● Recherche d'artisans par metier, ville et quartier
● Consultation des profils (photo, note, avis, specialite) sans voir le telephone
● Commande de prestation directement depuis l'application
● Paiement securise : MTN Mobile Money, Moov Money, carte bancaire
● Argent bloque (escrow) jusqu'a validation de la prestation
● Messagerie interne avec l'artisan uniquement via la plateforme
● Validation de la prestation pour debloquer le paiement
● Notation et avis apres chaque prestation
● Remboursement automatique si l'artisan n'honore pas la commande
5.3 Espace Administrateur (Back-office)
● Validation et moderation des comptes artisans inscrits par les agents
● Suivi en temps reel des inscriptions par agent (code de parrainage)
● Calcul automatique et suivi des remunerations des agents terrain
● Suivi de toutes les transactions et commissions
● Gestion des signalements, litiges et sanctions
● Tableau de bord statistiques complet
● Gestion des abonnements Premium et publicites

6. CONTRAT D'ENGAGEMENT ARTISAN
Lors de son inscription, chaque artisan doit obligatoirement lire et valider un contrat d'engagement.
Le bouton 'Finaliser l'inscription' reste inactif tant que la case n'est pas cochée.
Art. 1
L'artisan s'engage a realiser les prestations avec serieux, professionnalisme et dans les delais
convenus.
Art. 2 L'artisan s'engage a respecter les tarifs et conditions annonces sur son profil.
Art. 3
Tout artisan dont la qualite de travail est jugee insuffisante sera automatiquement retire de la
plateforme sans preavis.
Art. 4
L'artisan s'engage a communiquer uniquement via la messagerie interne pour toute discussion
liee a une commande.
Art. 5
L'artisan s'engage a ne pas demander aux clients de payer en dehors du systeme de paiement
officiel.
Art. 6
Toute fraude ou tentative de contournement entraine la suspension immediate et definitive du
compte.
Art. 7 Mon Artisan se reserve le droit de modifier ces conditions avec notification prealable.
■ J'ai lu et j'accepte les conditions generales et le contrat d'engagement de la plateforme Mon
Artisan. Je comprends que tout manquement a la qualite de mon travail peut entrainer mon retrait
automatique et definitif de la plateforme.
RETRAIT AUTOMATIQUE — Tout artisan ayant recu des reclamations averees pour travail mal
execute ou non-respect des engagements sera retire definitivement de la plateforme.

7. MESSAGERIE INTERNE ET PROTECTION ANTI-CONTOURNEMENT
7.1 Messagerie interne
● Chat instantane securise entre client et artisan pour chaque commande
● Numero de telephone de l'artisan jamais visible publiquement
● Filtre automatique : aucun numero ni lien externe ne peut etre partage
● Historique des echanges conserve et consultable par l'administrateur
● Notifications push a chaque message recu
7.2 Message d'avertissement automatique
AVERTISSEMENT IMPORTANT Tout appel ou echange en dehors de la plateforme Mon
Artisan (WhatsApp, SMS, appel direct...) est strictement interdit. En cas de litige survenant
suite a une communication externe, la plateforme Mon Artisan se desengage totalement de
toute responsabilite. Pour votre securite, utilisez UNIQUEMENT la messagerie officielle.
7.3 Avantages pour inciter à rester sur la plateforme
Pour l'artisan Pour le client

● Systeme de notation : bonnes notes = plus de
clients ● Badge Verifie inspire confiance ●
Protection et mediation en cas de litige ●
Portefeuille securise et retrait facile

● Argent bloque — remboursement garanti si
artisan absent ● Recu officiel de paiement ●
Mediation plateforme en cas de probleme ● Zero
risque de fraude si paiement sur app


[![Flutter](https://img.shields.io/badge/Flutter-3.41.6-blue)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Latest-orange)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Proprietary-red)](LICENSE)

Application mobile cross-platform (Android/iOS) pour connecter clients et artisans au Bénin.

---

## 📱 Description

**Mon Artisan** est une plateforme innovante qui permet aux clients de trouver facilement des artisans qualifiés près de chez eux, de passer commande et de payer en ligne de manière sécurisée. Les artisans peuvent gérer leurs prestations et leurs revenus en toute simplicité.

---

## ✨ Fonctionnalités principales

### 👤 Pour les Clients
- ✅ Recherche d'artisans par métier, ville et distance
- ✅ Géolocalisation et tri par proximité
- ✅ Consultation des profils et avis
- ✅ Commande avec photos et description
- ✅ Paiement sécurisé (FedaPay)
- ✅ Chat en temps réel avec l'artisan
- ✅ Suivi des commandes
- ✅ Notation et avis
- ✅ Historique complet
- ✅ Favoris
- ✅ Notifications push

### 🔧 Pour les Artisans
- ✅ Profil professionnel complet
- ✅ Réception de commandes géolocalisées
- ✅ Acceptation/Refus de commandes
- ✅ Chat avec les clients
- ✅ Gestion de disponibilité
- ✅ Suivi des revenus en temps réel
- ✅ Demande de retrait (min 5000 FCFA)
- ✅ Statistiques détaillées
- ✅ Notifications push

---

## 🛠 Technologies utilisées

| Technologie | Version | Usage |
|------------|---------|-------|
| **Flutter** | 3.41.6 | Framework mobile |
| **Dart** | 3.11.4 | Langage |
| **Firebase Auth** | Latest | Authentification |
| **Cloud Firestore** | Latest | Base de données |
| **Firebase Storage** | Latest | Stockage fichiers |
| **FCM** | Latest | Notifications push |
| **FedaPay** | API v1 | Paiement mobile money |
| **Geolocator** | 13.0.2 | Géolocalisation |
| **GoRouter** | 14.6.2 | Navigation |
| **Provider** | 6.1.2 | State management |

---

## 🎨 Charte graphique

```dart
Bleu principal : #1A3C6E
Rouge accent   : #C0392B
Blanc          : #FFFFFF
Gris clair     : #F5F5F5
Succès         : #27AE60
Erreur         : #E74C3C
```

**Police** : Poppins (Google Fonts)

---

## 📂 Structure du projet

```
lib/
├── main.dart                 # Point d'entrée
├── app.dart                  # Configuration app
├── core/
│   ├── constants/           # Couleurs, styles, données
│   ├── routes/              # Navigation (GoRouter)
│   ├── services/            # Firebase, FedaPay, Géolocalisation
│   └── utils/               # Validateurs, helpers
├── models/                  # Modèles de données
├── providers/               # State management (Provider)
├── screens/                 # Écrans de l'app
│   ├── auth/               # Authentification
│   ├── client/             # Interface client
│   ├── artisan/            # Interface artisan
│   └── shared/             # Écrans partagés
└── widgets/                # Composants réutilisables
```

---

## 🚀 Installation et lancement

### Prérequis
- Flutter SDK 3.41.6+
- Dart SDK 3.11.4+
- Android Studio / Xcode
- Compte Firebase
- Compte FedaPay (pour paiements)

### Installation

```bash
# 1. Cloner le repository
git clone https://github.com/[username]/mon-artisan.git
cd mon-artisan/mon_artisan_app

# 2. Installer les dépendances
flutter pub get

# 3. Vérifier l'installation
flutter doctor

# 4. Lancer sur émulateur/device
flutter run

# 5. Lancer sur un device spécifique
flutter run -d 11139373AQ003625
```

### Configuration Firebase

1. Créer un projet sur [Firebase Console](https://console.firebase.google.com)
2. Ajouter une app Android et iOS
3. Télécharger les fichiers de configuration :
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
4. Activer les services :
   - ✅ Authentication (Email/Password, Phone)
   - ✅ Cloud Firestore
   - ✅ Storage
   - ✅ Cloud Messaging
5. Configurer les règles de sécurité (voir `GUIDE_LANCEMENT.md`)

### Configuration FedaPay

```dart
// lib/core/services/fedapay_service.dart
static const String apiKey = 'VOTRE_CLE_API_FEDAPAY';
static const String publicKey = 'VOTRE_CLE_PUBLIQUE';
```

---

## 📖 Documentation

- 📋 [Cahier des charges](cahier_des_charges.md)
- 🔧 [Spécifications techniques](SPECIFICATIONS_TECHNIQUES.md)
- 📊 [État d'implémentation](IMPLEMENTATION_STATUS.md)
- 🚀 [Guide de lancement](GUIDE_LANCEMENT.md)
- 💻 [Guide développement](mon_artisan_app/GUIDE_DEVELOPPEMENT.md)

---

## 🧪 Tests

```bash
# Tests unitaires
flutter test

# Tests d'intégration
flutter test integration_test/

# Analyse du code
flutter analyze

# Vérifier le formatage
flutter format --set-exit-if-changed .
```

---

## 📦 Build production

### Android (APK/AAB)
```bash
# Build APK
flutter build apk --release

# Build App Bundle (pour Play Store)
flutter build appbundle --release
```

### iOS (IPA)
```bash
# Build iOS
flutter build ipa --release
```

---

## 🌍 Déploiement

### Google Play Store
1. Créer un compte développeur ($25)
2. Générer un keystore
3. Configurer `android/key.properties`
4. Build AAB
5. Upload sur Play Console

### Apple App Store
1. Compte développeur Apple ($99/an)
2. Certificats et provisioning profiles
3. Build IPA
4. Upload via Xcode/Transporter

---

## 📊 État du projet

| Catégorie | Progression |
|-----------|-------------|
| **Authentification** | ✅ 100% |
| **Interface Client** | ✅ 95% |
| **Interface Artisan** | ✅ 95% |
| **Commandes** | ✅ 100% |
| **Paiement** | ⏳ 80% (simulation) |
| **Notifications** | ✅ 100% |
| **Géolocalisation** | ✅ 100% |
| **Chat** | ✅ 100% |
| **Revenus** | ✅ 100% |
| **Profil** | ✅ 100% |
| **TOTAL** | **~75%** |

**Statut** : ✅ **Prêt pour MVP**

---

## 🤝 Contribution

Ce projet est actuellement en développement privé. Pour toute contribution, contactez l'équipe.

---

## 📄 Licence

Tous droits réservés - Mon Artisan © 2026

---

## 👥 Équipe

- **Développement** : [Votre nom]
- **Design** : [Designer]
- **Product Owner** : [PO]

---

## 📞 Contact

- **Email** : support@monartisan.bj
- **Téléphone** : +229 XX XX XX XX
- **Site web** : https://monartisan.bj

---

## 🙏 Remerciements

- Firebase pour l'infrastructure
- FedaPay pour les paiements
- La communauté Flutter
- Tous les artisans du Bénin

---

**Fait avec ❤️ au Bénin 🇧🇯**
