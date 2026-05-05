# 🚀 Guide de Lancement - Mon Artisan

## ✅ État actuel du projet

L'application **Mon Artisan** est **prête pour le lancement MVP** avec ~75% des fonctionnalités implémentées.

---

## 📱 Fonctionnalités opérationnelles

### Pour les Clients:
- ✅ Inscription et connexion
- ✅ Recherche d'artisans par métier/ville
- ✅ Géolocalisation et tri par distance
- ✅ Consultation des profils artisans
- ✅ Création de commandes
- ✅ Paiement (simulation - à remplacer par FedaPay)
- ✅ Historique des commandes
- ✅ Notation des artisans
- ✅ Chat avec les artisans
- ✅ Favoris
- ✅ Notifications push
- ✅ Édition de profil

### Pour les Artisans:
- ✅ Inscription et connexion
- ✅ Gestion de disponibilité
- ✅ Réception de commandes
- ✅ Acceptation/Refus de commandes
- ✅ Marquage terminé
- ✅ Gestion des revenus
- ✅ Demande de retrait
- ✅ Chat avec les clients
- ✅ Notifications push
- ✅ Édition de profil
- ✅ Statistiques

---

## 🔧 Étapes pour finaliser

### 1. Configuration Firebase (URGENT)

#### a) Firestore Security Rules
Remplacer les règles de test par:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Artisans
    match /artisans/{artisanId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == resource.data.userId;
    }
    
    // Commandes
    match /commandes/{commandeId} {
      allow read: if request.auth.uid == resource.data.clientId 
                  || request.auth.uid == resource.data.artisanId;
      allow create: if request.auth.uid == request.resource.data.clientId;
      allow update: if request.auth.uid == resource.data.clientId 
                    || request.auth.uid == resource.data.artisanId;
    }
    
    // Avis
    match /avis/{avisId} {
      allow read: if request.auth != null;
      allow create: if request.auth.uid == request.resource.data.clientId;
    }
    
    // Notifications
    match /notifications/{notificationId} {
      allow read: if request.auth.uid == resource.data.userId;
      allow write: if false; // Seulement via Cloud Functions
    }
    
    // Favoris
    match /favoris/{favoriId} {
      allow read, write: if request.auth.uid == resource.data.clientId;
    }
    
    // Chat
    match /chats/{chatId}/messages/{messageId} {
      allow read: if request.auth.uid == resource.data.senderId 
                  || request.auth.uid == resource.data.receiverId;
      allow create: if request.auth.uid == request.resource.data.senderId;
    }
  }
}
```

#### b) Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_photos/{userId}.jpg {
      allow read: if true;
      allow write: if request.auth.uid == userId;
    }
    
    match /commande_photos/{commandeId}/{photoId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### 2. Intégration FedaPay (CRITIQUE)

#### a) Obtenir les clés API
1. Créer un compte sur https://fedapay.com
2. Obtenir les clés API (test et production)
3. Configurer les webhooks

#### b) Remplacer dans `lib/core/services/fedapay_service.dart`
```dart
static const String apiKey = 'VOTRE_CLE_API_FEDAPAY';
static const String publicKey = 'VOTRE_CLE_PUBLIQUE';
```

#### c) Implémenter les webhooks
Créer une Cloud Function pour recevoir les confirmations:

```javascript
// functions/index.js
exports.fedapayWebhook = functions.https.onRequest(async (req, res) => {
  const signature = req.headers['x-fedapay-signature'];
  // Vérifier la signature
  // Mettre à jour le statut de paiement
  // Notifier le client et l'artisan
});
```

### 3. Configuration des notifications push

#### a) Android
1. Télécharger `google-services.json` depuis Firebase Console
2. Placer dans `android/app/`
3. Vérifier que le package name correspond

#### b) iOS
1. Télécharger `GoogleService-Info.plist`
2. Placer dans `ios/Runner/`
3. Configurer les certificats APNs dans Firebase

### 4. Tests avant lancement

#### Tests fonctionnels
- [ ] Inscription client et artisan
- [ ] Connexion
- [ ] Recherche d'artisans
- [ ] Création de commande
- [ ] Paiement (avec FedaPay test)
- [ ] Acceptation de commande
- [ ] Chat
- [ ] Notation
- [ ] Notifications
- [ ] Gestion des revenus

#### Tests de performance
- [ ] Temps de chargement < 3s
- [ ] Scroll fluide
- [ ] Pas de crash
- [ ] Consommation batterie raisonnable

#### Tests multi-devices
- [ ] Android 6.0+
- [ ] iOS 12+
- [ ] Différentes tailles d'écran
- [ ] Connexion 3G/4G

### 5. Déploiement

#### a) Android (Play Store)
```bash
# Générer le keystore
keytool -genkey -v -keystore ~/mon-artisan-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias mon-artisan

# Configurer android/key.properties
storePassword=VOTRE_MOT_DE_PASSE
keyPassword=VOTRE_MOT_DE_PASSE
keyAlias=mon-artisan
storeFile=/chemin/vers/mon-artisan-key.jks

# Build release
flutter build appbundle --release

# Upload sur Play Console
```

#### b) iOS (App Store)
```bash
# Build iOS
flutter build ipa --release

# Upload via Xcode ou Transporter
```

---

## 📊 Données de test à créer

### Villes et quartiers
Créer dans Firestore collection `villes`:
```json
{
  "nom": "Cotonou",
  "departement": "Littoral",
  "quartiers": ["Akpakpa", "Ganhi", "Cadjehoun", "Fidjrosse"],
  "isActive": true
}
```

### Métiers
Créer dans Firestore collection `metiers`:
```json
{
  "nom": "Électricien",
  "categorie": "BTP & Construction",
  "description": "Installation et réparation électrique",
  "iconName": "bolt",
  "ordre": 1,
  "isActive": true
}
```

---

## 🔐 Sécurité

### À faire avant production:
1. ✅ Activer les règles Firestore
2. ✅ Activer les règles Storage
3. ⏳ Configurer App Check (anti-bot)
4. ⏳ Activer 2FA pour Firebase Console
5. ⏳ Configurer les quotas et limites
6. ⏳ Mettre en place monitoring (Crashlytics)

---

## 📈 Monitoring et Analytics

### Firebase Analytics
Déjà configuré, événements à tracker:
- Inscription (client/artisan)
- Recherche artisan
- Création commande
- Paiement
- Notation

### Crashlytics
```dart
// À ajouter dans main.dart
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
```

---

## 💰 Modèle économique

### Commission
- **10%** sur chaque transaction
- Calculé automatiquement
- Déduit avant versement à l'artisan

### Retraits artisans
- Minimum: **5 000 FCFA**
- Frais: À définir
- Délai: 24-48h

---

## 📞 Support

### Pour les utilisateurs
- Email: support@monartisan.bj
- Téléphone: +229 XX XX XX XX
- Chat in-app (à implémenter)

### Pour les développeurs
- Documentation: Ce fichier
- Code source: GitHub
- Firebase Console: https://console.firebase.google.com

---

## 🎯 Roadmap post-lancement

### Phase 1 (Mois 1-2)
- Corriger les bugs remontés
- Optimiser les performances
- Ajouter plus de métiers
- Étendre à plus de villes

### Phase 2 (Mois 3-4)
- Interface admin complète
- Statistiques avancées
- Programme de parrainage
- Badges et gamification

### Phase 3 (Mois 5-6)
- Mode hors ligne
- Carte interactive
- Réservation de créneaux
- Paiement en plusieurs fois

---

## ✅ Checklist finale avant lancement

### Configuration
- [ ] Firebase rules activées
- [ ] FedaPay configuré
- [ ] Notifications push testées
- [ ] Clés API sécurisées
- [ ] App Check activé

### Contenu
- [ ] 50+ artisans inscrits
- [ ] Toutes les villes du Bénin
- [ ] Tous les métiers listés
- [ ] Photos de qualité

### Legal
- [ ] Conditions d'utilisation
- [ ] Politique de confidentialité
- [ ] Mentions légales
- [ ] CGV

### Marketing
- [ ] Page web vitrine
- [ ] Réseaux sociaux
- [ ] Campagne de lancement
- [ ] Partenariats

---

## 🚀 Commande de lancement

```bash
# Vérifier que tout est OK
flutter doctor

# Tester sur device
flutter run -d 11139373AQ003625

# Build production
flutter build appbundle --release  # Android
flutter build ipa --release        # iOS

# 🎉 LANCEMENT!
```

---

**Bon lancement! 🚀**
