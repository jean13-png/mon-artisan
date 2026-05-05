# 🔒 GUIDE D'INSTALLATION DES RÈGLES DE SÉCURITÉ FIREBASE

## Date : 5 Mai 2026

---

## 📋 FICHIERS CRÉÉS

1. **FIRESTORE_SECURITY_RULES.txt** - Règles Firestore Database
2. **STORAGE_SECURITY_RULES.txt** - Règles Firebase Storage
3. **GUIDE_REGLES_SECURITE.md** - Ce guide

---

## 🚀 INSTALLATION DES RÈGLES FIRESTORE

### Méthode 1 : Via Firebase Console (RECOMMANDÉ)

1. **Aller sur Firebase Console**
   - URL : https://console.firebase.google.com
   - Sélectionner votre projet "Mon Artisan"

2. **Accéder à Firestore Database**
   - Menu latéral → "Firestore Database"
   - Onglet "Règles" (Rules)

3. **Copier-coller les règles**
   - Ouvrir le fichier `FIRESTORE_SECURITY_RULES.txt`
   - Copier tout le contenu
   - Coller dans l'éditeur Firebase Console
   - Cliquer sur "Publier" (Publish)

4. **Vérifier la publication**
   - Attendre le message "Règles publiées avec succès"
   - Vérifier la date de dernière modification

### Méthode 2 : Via Firebase CLI

```bash
# 1. Installer Firebase CLI (si pas déjà fait)
npm install -g firebase-tools

# 2. Se connecter à Firebase
firebase login

# 3. Initialiser Firebase dans le projet
cd mon_artisan_app
firebase init firestore

# 4. Copier les règles dans firestore.rules
cp ../FIRESTORE_SECURITY_RULES.txt firestore.rules

# 5. Déployer les règles
firebase deploy --only firestore:rules
```

---

## 🗄️ INSTALLATION DES RÈGLES STORAGE

### Méthode 1 : Via Firebase Console (RECOMMANDÉ)

1. **Aller sur Firebase Console**
   - URL : https://console.firebase.google.com
   - Sélectionner votre projet "Mon Artisan"

2. **Accéder à Storage**
   - Menu latéral → "Storage"
   - Onglet "Règles" (Rules)

3. **Copier-coller les règles**
   - Ouvrir le fichier `STORAGE_SECURITY_RULES.txt`
   - Copier tout le contenu
   - Coller dans l'éditeur Firebase Console
   - Cliquer sur "Publier" (Publish)

4. **Vérifier la publication**
   - Attendre le message "Règles publiées avec succès"
   - Vérifier la date de dernière modification

### Méthode 2 : Via Firebase CLI

```bash
# 1. Copier les règles dans storage.rules
cp ../STORAGE_SECURITY_RULES.txt storage.rules

# 2. Déployer les règles
firebase deploy --only storage
```

---

## 🔍 EXPLICATION DES RÈGLES FIRESTORE

### Fonctions Helper

```javascript
// Vérifier si l'utilisateur a un rôle spécifique
function hasRole(role) {
  return request.auth != null && 
         get(/databases/$(database)/documents/users/$(request.auth.uid))
         .data.roles.hasAny([role]);
}
```

Cette fonction vérifie si l'utilisateur connecté possède un rôle spécifique (admin, client, artisan).

### Collection: users

```javascript
match /users/{userId} {
  allow read: if isAuthenticated();
  allow create: if isAuthenticated() && isOwner(userId);
  allow update: if isOwner(userId) || isAdmin();
  allow delete: if isAdmin();
}
```

- **Lecture** : Tous les utilisateurs authentifiés
- **Création** : Seulement pour créer son propre profil
- **Mise à jour** : Propriétaire ou admin
- **Suppression** : Admin seulement

### Collection: artisans

```javascript
match /artisans/{artisanId} {
  allow read: if isAuthenticated();
  allow create: if isAuthenticated() && isArtisan();
  allow update: if resource.data.userId == request.auth.uid || isAdmin();
  allow delete: if isAdmin();
}
```

- **Lecture** : Tous (pour recherche)
- **Création** : Utilisateurs avec rôle artisan
- **Mise à jour** : Propriétaire ou admin (pour validation)
- **Suppression** : Admin seulement

### Collection: commandes

```javascript
match /commandes/{commandeId} {
  allow read: if resource.data.clientId == request.auth.uid ||
                 resource.data.artisanId == request.auth.uid ||
                 isAdmin();
  allow create: if isAuthenticated() && isClient();
  allow update: if resource.data.clientId == request.auth.uid ||
                   resource.data.artisanId == request.auth.uid ||
                   isAdmin();
}
```

- **Lecture** : Client, artisan concerné, ou admin
- **Création** : Clients seulement
- **Mise à jour** : Client, artisan concerné, ou admin

### Collection: agents

```javascript
match /agents/{agentId} {
  allow read, write: if isAdmin();
}
```

- **Toutes opérations** : Admin seulement

### Collection: chats et messages

```javascript
match /chats/{chatId} {
  allow read, write: if request.auth.uid in resource.data.participants;
  
  match /messages/{messageId} {
    allow read: if request.auth.uid in get(...).data.participants;
    allow create: if request.auth.uid in get(...).data.participants;
  }
}
```

- **Accès** : Seulement les participants du chat

---

## 🗄️ EXPLICATION DES RÈGLES STORAGE

### Dossier: artisans/{userId}/

```javascript
match /artisans/{userId}/{allPaths=**} {
  allow read: if true;  // Public
  allow write: if isOwner(userId) && isValidSize() && isImage();
}
```

- **Lecture** : Public (profils visibles par tous)
- **Écriture** : Propriétaire seulement, max 5MB, images seulement

### Dossier: commandes/{commandeId}/

```javascript
match /commandes/{commandeId}/{allPaths=**} {
  allow read: if isAuthenticated();
  allow write: if isAuthenticated() && isValidSize() && isImage();
}
```

- **Lecture** : Utilisateurs authentifiés
- **Écriture** : Utilisateurs authentifiés, max 5MB, images seulement

### Validations

```javascript
function isValidSize() {
  return request.resource.size < 5 * 1024 * 1024;  // 5MB max
}

function isImage() {
  return request.resource.contentType.matches('image/.*');
}
```

---

## ✅ TESTS DES RÈGLES

### Test 1 : Lecture users (authentifié)

```javascript
// Devrait réussir
firebase.firestore().collection('users').get()
```

### Test 2 : Création artisan (sans rôle artisan)

```javascript
// Devrait échouer
firebase.firestore().collection('artisans').add({...})
```

### Test 3 : Lecture commande (non concerné)

```javascript
// Devrait échouer
firebase.firestore().collection('commandes').doc('autre_commande').get()
```

### Test 4 : Upload image (trop grande)

```javascript
// Devrait échouer si > 5MB
firebase.storage().ref('artisans/userId/photo.jpg').put(file)
```

---

## 🔧 SIMULATEUR DE RÈGLES

Firebase Console propose un simulateur pour tester les règles :

1. **Aller dans Firestore → Règles**
2. **Cliquer sur "Simulateur de règles"**
3. **Configurer le test** :
   - Type : get, list, create, update, delete
   - Chemin : /users/abc123
   - Authentification : Simuler un utilisateur
4. **Exécuter le test**
5. **Vérifier le résultat** : Autorisé / Refusé

---

## 🚨 ERREURS COURANTES

### Erreur 1 : "Missing or insufficient permissions"

**Cause** : L'utilisateur n'a pas les droits nécessaires

**Solution** :
- Vérifier que l'utilisateur est authentifié
- Vérifier que le rôle est correct dans Firestore
- Vérifier que les règles sont bien déployées

### Erreur 2 : "Function get() requires 1 argument"

**Cause** : Erreur de syntaxe dans les règles

**Solution** :
- Vérifier la syntaxe de la fonction `get()`
- S'assurer que le chemin est correct

### Erreur 3 : "Property roles is undefined"

**Cause** : Le champ `roles` n'existe pas dans le document user

**Solution** :
- Vérifier que tous les users ont un champ `roles` (array)
- Migrer les anciens users si nécessaire

---

## 📊 MONITORING DES RÈGLES

### Vérifier les refus

1. **Aller dans Firestore → Utilisation**
2. **Voir les "Lectures refusées"**
3. **Analyser les patterns**
4. **Ajuster les règles si nécessaire**

### Logs Cloud Functions

```javascript
// Dans vos Cloud Functions
console.log('Tentative d\'accès:', context.auth.uid);
```

---

## 🔄 MISE À JOUR DES RÈGLES

### Processus recommandé

1. **Tester en local** avec l'émulateur Firebase
2. **Déployer sur un projet de test**
3. **Valider avec des tests automatisés**
4. **Déployer en production**
5. **Monitorer les erreurs**

### Commandes

```bash
# Démarrer l'émulateur
firebase emulators:start

# Déployer sur le projet de test
firebase use test-project
firebase deploy --only firestore:rules

# Déployer en production
firebase use production-project
firebase deploy --only firestore:rules
```

---

## 📝 CHECKLIST DE DÉPLOIEMENT

Avant de déployer en production :

- [ ] Règles Firestore copiées et publiées
- [ ] Règles Storage copiées et publiées
- [ ] Tests effectués avec le simulateur
- [ ] Compte admin créé avec rôle correct
- [ ] Tous les users ont un champ `roles` (array)
- [ ] Monitoring activé
- [ ] Backup des anciennes règles effectué

---

## 🆘 SUPPORT

En cas de problème :

1. **Vérifier les logs Firebase Console**
2. **Utiliser le simulateur de règles**
3. **Consulter la documentation** : https://firebase.google.com/docs/rules
4. **Contacter le support Firebase** si nécessaire

---

## 📚 RESSOURCES

- [Documentation Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Documentation Storage Security Rules](https://firebase.google.com/docs/storage/security)
- [Guide des bonnes pratiques](https://firebase.google.com/docs/rules/rules-and-auth)
- [Exemples de règles](https://firebase.google.com/docs/rules/rules-language)

---

**Créé le : 5 Mai 2026**
**Version : 1.0.0**
**Statut : PRÊT POUR DÉPLOIEMENT**
