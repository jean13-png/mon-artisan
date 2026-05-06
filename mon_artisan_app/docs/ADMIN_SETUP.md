# 🔐 GUIDE DE CONFIGURATION ADMIN

## Comment créer le premier compte administrateur

### MÉTHODE 1 : Via Firebase Console (RECOMMANDÉ)

1. **Aller sur Firebase Console**
   - URL: https://console.firebase.google.com
   - Sélectionner votre projet "Mon Artisan"

2. **Créer l'utilisateur dans Authentication**
   - Aller dans "Authentication" → "Users"
   - Cliquer sur "Add user"
   - Email: `tossajean13@gmail.com`
   - Password: `TOSjea13#`
   - Copier l'UID généré (ex: `abc123def456`)

3. **Créer le document dans Firestore**
   - Aller dans "Firestore Database"
   - Collection: `users`
   - Cliquer sur "Add document"
   - Document ID: Coller l'UID copié ci-dessus
   - Ajouter les champs suivants:

```json
{
  "roles": ["admin"],
  "nom": "TOSSA",
  "prenom": "Jean",
  "email": "tossajean13@gmail.com",
  "telephone": "+22997000000",
  "ville": "Cotonou",
  "quartier": "Centre",
  "position": {
    "_latitude": 6.3703,
    "_longitude": 2.3912
  },
  "isActive": true,
  "contratAccepte": true,
  "paiementInscription": true,
  "createdAt": [Timestamp - Now],
  "updatedAt": [Timestamp - Now]
}
```

4. **Se connecter dans l'app**
   - Ouvrir l'application
   - Email: `tossajean13@gmail.com`
   - Password: `TOSjea13#`
   - L'app détecte automatiquement le rôle admin
   - Redirection vers le dashboard admin

---

### MÉTHODE 2 : Via l'application (Inscription normale puis modification)

1. **S'inscrire comme client**
   - Ouvrir l'app
   - S'inscrire avec email: `tossajean13@gmail.com`
   - Remplir les informations

2. **Modifier le rôle dans Firestore**
   - Aller sur Firebase Console
   - Firestore Database → Collection `users`
   - Trouver le document avec email `tossajean13@gmail.com`
   - Modifier le champ `roles`:
     - Avant: `["client"]`
     - Après: `["admin"]`

3. **Se reconnecter**
   - Fermer l'app complètement
   - Rouvrir l'app
   - Se connecter
   - Redirection automatique vers dashboard admin

---

## 🎯 ACCÈS AU DASHBOARD ADMIN

### Flux de connexion

```
┌─────────────────────────┐
│  Ouvrir l'application   │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  Écran de connexion     │
│  Email: admin@...       │
│  Password: ****         │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  Splash Screen          │
│  Détection du rôle      │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  roles.contains('admin')│
│  = true                 │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  Dashboard Admin        │
│  ✓ Statistiques         │
│  ✓ Validation artisans  │
│  ✓ Gestion agents       │
│  ✓ Signalements         │
│  ✓ Transactions         │
└─────────────────────────┘
```

---

## 👥 CRÉER D'AUTRES ADMINS

Pour créer des comptes admin supplémentaires :

1. Répéter la MÉTHODE 1 avec un nouvel email
2. Ou modifier un compte existant en ajoutant le rôle "admin"

**Exemple : Admin avec plusieurs rôles**
```json
{
  "roles": ["admin", "client"],
  ...
}
```

L'utilisateur pourra choisir son profil au démarrage.

---

## 🔒 SÉCURITÉ

### Règles Firestore à configurer

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
    
    // Seuls les admins peuvent lire tous les users
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId || hasRole('admin');
    }
    
    // Seuls les admins peuvent modifier les artisans (validation)
    match /artisans/{artisanId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if hasRole('admin') || 
                       get(/databases/$(database)/documents/artisans/$(artisanId))
                       .data.userId == request.auth.uid;
    }
    
    // Seuls les admins peuvent lire les agents
    match /agents/{agentId} {
      allow read, write: if hasRole('admin');
    }
    
    // Seuls les admins peuvent lire tous les paiements
    match /paiements/{paiementId} {
      allow read: if hasRole('admin') || 
                     resource.data.userId == request.auth.uid;
      allow write: if request.auth != null;
    }
  }
}
```

---

## 📱 FONCTIONNALITÉS DU DASHBOARD ADMIN

### Vue d'ensemble
- ✅ Nombre total d'artisans
- ✅ Artisans en attente de validation
- ✅ Nombre total de clients
- ✅ Nombre total de commandes
- ✅ Revenus totaux (commissions)

### Actions rapides
- ⏳ Valider les artisans (en développement)
- ⏳ Gérer les agents terrain (en développement)
- ⏳ Signalements et litiges (en développement)
- ⏳ Voir toutes les transactions (en développement)

---

## 🚀 PROCHAINES ÉTAPES

1. ✅ Dashboard admin créé
2. ✅ Détection automatique du rôle
3. ⏳ Écran de validation des artisans
4. ⏳ Écran de gestion des agents
5. ⏳ Écran des signalements
6. ⏳ Écran des transactions détaillées

---

## 📞 SUPPORT

En cas de problème :
1. Vérifier que le rôle "admin" est bien dans le tableau `roles`
2. Vérifier que l'UID dans Firestore correspond à l'UID dans Authentication
3. Se déconnecter et se reconnecter
4. Vider le cache de l'app

---

**Créé le : 5 Mai 2026**
**Version : 1.0.0**

