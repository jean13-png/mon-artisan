# 🚀 CONFIGURATION POUR LA PRODUCTION

## 📋 CHECKLIST AVANT DÉPLOIEMENT

### 1. ✅ Clés FedaPay (DÉJÀ CONFIGURÉES)

**Fichier :** `lib/core/constants/app_constants.dart`

```dart
// Clés FedaPay LIVE (déjà configurées)
static const String fedapayPublicKey = 'pk_live_IDtylXn9RdMm5EVefFX1ifZt';
static const String fedapaySecretKey = 'sk_live_3KyG5_jI3QsfFqon1WzIDd8z';
```

✅ **Statut : Configuré avec les clés LIVE**

---

### 2. ⚠️ MODE TEST (ACTUELLEMENT ACTIVÉ)

**Fichier :** `lib/core/constants/app_constants.dart`

```dart
// MODE TEST - À DÉSACTIVER EN PRODUCTION
static const bool isTestMode = true; // ⚠️ Mettre à false en production
static const bool requirePaymentForArtisan = false; // ⚠️ Mettre à true en production
```

**Pour activer le paiement obligatoire :**

```dart
// MODE PRODUCTION
static const bool isTestMode = false;
static const bool requirePaymentForArtisan = true;
```

---

### 3. 🔄 FLUX D'INSCRIPTION ARTISAN

#### MODE TEST (Actuel)
```
Inscription → Contrat → PIN → Dashboard
(Paiement désactivé)
```

#### MODE PRODUCTION (À activer)
```
Inscription → Paiement 958 FCFA → Contrat → PIN → Dashboard
```

**Fichier à modifier :** `lib/screens/auth/register_screen.dart`

**Ligne 82-95 :** Décommenter le flux de paiement

```dart
if (widget.role == 'artisan') {
  if (AppConstants.requirePaymentForArtisan) {
    // MODE PRODUCTION : Rediriger vers le paiement
    context.go('${AppRouter.artisanPayment}?codeAgent=');
  } else {
    // MODE TEST : Sauter le paiement
    context.go(AppRouter.contratEngagement);
  }
}
```

---

### 4. 🔐 SÉCURITÉ

#### Firebase Security Rules

**Firestore :**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Fonction helper pour vérifier le rôle
    function hasRole(role) {
      return request.auth != null && 
             get(/databases/$(database)/documents/users/$(request.auth.uid))
             .data.roles.hasAny([role]);
    }
    
    // Users
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId || hasRole('admin');
    }
    
    // Artisans
    match /artisans/{artisanId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if hasRole('admin') || 
                       get(/databases/$(database)/documents/artisans/$(artisanId))
                       .data.userId == request.auth.uid;
    }
    
    // Commandes
    match /commandes/{commandeId} {
      allow read: if request.auth != null && (
        resource.data.clientId == request.auth.uid ||
        resource.data.artisanId == request.auth.uid ||
        hasRole('admin')
      );
      allow create: if request.auth != null;
      allow update: if request.auth != null && (
        resource.data.clientId == request.auth.uid ||
        resource.data.artisanId == request.auth.uid ||
        hasRole('admin')
      );
    }
    
    // Agents (admin seulement)
    match /agents/{agentId} {
      allow read, write: if hasRole('admin');
    }
    
    // Paiements
    match /paiements/{paiementId} {
      allow read: if hasRole('admin') || 
                     resource.data.userId == request.auth.uid;
      allow write: if request.auth != null;
    }
    
    // Chat
    match /chats/{chatId}/messages/{messageId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**Storage :**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /artisans/{userId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /commandes/{commandeId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    match /users/{userId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

### 5. 🧹 NETTOYAGE DU CODE

#### Retirer les print() de debug

**Fichiers à nettoyer :**
- `lib/providers/artisan_provider.dart`
- `lib/providers/auth_provider.dart`
- `lib/providers/commande_provider.dart`
- `lib/screens/artisan/complete_profile_screen.dart`
- `lib/screens/auth/artisan_payment_screen.dart`

**Commande :**
```bash
# Rechercher tous les print()
grep -r "print(" lib/

# Les remplacer par des logs appropriés ou les supprimer
```

#### Retirer les imports non utilisés

```bash
flutter analyze
# Corriger les warnings "unused_import"
```

---

### 6. 📱 BUILD PRODUCTION

#### Android

```bash
# 1. Générer le keystore (si pas déjà fait)
keytool -genkey -v -keystore mon-artisan-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias mon-artisan

# 2. Créer android/key.properties
storePassword=<votre_password>
keyPassword=<votre_password>
keyAlias=mon-artisan
storeFile=../mon-artisan-key.jks

# 3. Build AAB pour Play Store
flutter build appbundle --release

# 4. Build APK pour distribution directe
flutter build apk --release
```

#### iOS

```bash
# 1. Configurer les certificats dans Xcode
# 2. Build IPA
flutter build ipa --release
```

---

### 7. 🧪 TESTS AVANT PRODUCTION

#### Tests obligatoires

- [ ] Inscription client
- [ ] Inscription artisan avec paiement 958 FCFA
- [ ] Recherche d'artisans
- [ ] Création de commande
- [ ] Paiement commande (FedaPay LIVE)
- [ ] Chat avec filtre anti-contournement
- [ ] Validation de prestation (escrow)
- [ ] Portefeuille artisan
- [ ] Retrait artisan
- [ ] Dashboard admin
- [ ] Validation artisans par admin
- [ ] Gestion agents par admin

#### Tests de sécurité

- [ ] Firestore Security Rules actives
- [ ] Storage Security Rules actives
- [ ] Authentification obligatoire
- [ ] Rôles correctement vérifiés
- [ ] Téléphone artisan masqué
- [ ] Filtre chat fonctionnel

---

### 8. 📊 MONITORING

#### Firebase Analytics

**Activer dans :** `lib/main.dart`

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Activer Analytics
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  
  runApp(MyApp(analytics: analytics));
}
```

#### Crashlytics

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Activer Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  
  runApp(const MyApp());
}
```

---

### 9. 🔔 NOTIFICATIONS PUSH

#### Configuration FCM

**Android :** `android/app/google-services.json` (déjà configuré)
**iOS :** `ios/Runner/GoogleService-Info.plist` (à configurer)

**Tester :**
- Nouvelle commande → Notification artisan
- Message chat → Notification destinataire
- Validation prestation → Notification artisan
- Paiement débloqué → Notification artisan

---

### 10. 💰 FEDAPAY WEBHOOK (Optionnel)

**Pour recevoir les confirmations de paiement :**

1. Créer un endpoint backend (Firebase Functions)
2. Configurer le webhook dans FedaPay Dashboard
3. Vérifier les signatures

**Exemple Firebase Function :**

```javascript
exports.fedapayWebhook = functions.https.onRequest(async (req, res) => {
  const signature = req.headers['x-fedapay-signature'];
  // Vérifier la signature
  // Traiter le paiement
  // Mettre à jour Firestore
  res.status(200).send('OK');
});
```

---

## 🚀 DÉPLOIEMENT ÉTAPE PAR ÉTAPE

### Étape 1 : Préparation (1 jour)
1. ✅ Configurer les clés FedaPay (FAIT)
2. ⏳ Activer le mode production
3. ⏳ Nettoyer le code (print, imports)
4. ⏳ Configurer Firebase Security Rules

### Étape 2 : Tests (2-3 jours)
1. ⏳ Tests fonctionnels complets
2. ⏳ Tests de paiement réels
3. ⏳ Tests de sécurité
4. ⏳ Tests de performance

### Étape 3 : Build (1 jour)
1. ⏳ Build Android (AAB + APK)
2. ⏳ Build iOS (IPA)
3. ⏳ Tests sur devices réels

### Étape 4 : Déploiement (1-2 jours)
1. ⏳ Upload Google Play Store
2. ⏳ Upload Apple App Store
3. ⏳ Configuration monitoring
4. ⏳ Documentation utilisateur

---

## 📞 SUPPORT

**En cas de problème :**
- Email admin : tossajean13@gmail.com
- Dashboard admin : Accessible via l'app
- Firebase Console : https://console.firebase.google.com
- FedaPay Dashboard : https://dashboard.fedapay.com

---

## ✅ CHECKLIST FINALE

Avant de passer en production, vérifier :

- [ ] Mode test désactivé (`isTestMode = false`)
- [ ] Paiement artisan activé (`requirePaymentForArtisan = true`)
- [ ] Clés FedaPay LIVE configurées
- [ ] Firebase Security Rules actives
- [ ] Tous les tests passés
- [ ] Code nettoyé (print, imports)
- [ ] Analytics activé
- [ ] Crashlytics activé
- [ ] Notifications testées
- [ ] Build production réussi
- [ ] Compte admin créé
- [ ] Documentation à jour

---

**Date de création : 5 Mai 2026**
**Version : 1.0.0**
**Statut : MODE TEST ACTIVÉ**

