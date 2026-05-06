# Changelog - Mon Artisan

## [1.0.0] - 2026-05-06

### ✨ Nouvelles Fonctionnalités
- **Verrouillage biométrique** : L'app demande maintenant l'authentification (empreinte/PIN) quand on revient après l'avoir mise en arrière-plan
- **Widget AuthLockWrapper** : Système de sécurité pour les écrans principaux (Client, Artisan, Admin)

### 🐛 Corrections de Bugs
- **home_artisan_screen.dart** : Correction erreur de syntaxe (accolade en trop ligne 703)
- **home_client_screen.dart** : Correction erreur dropdown avec valeurs null
- **Firestore notifications** : Gestion d'erreur améliorée quand l'index n'existe pas
- **Navigation** : Fix du problème de retour arrière qui fermait l'app

### 🔧 Améliorations Techniques
- Configuration Java 17 pour Android (au lieu de Java 8)
- Ajout du package `cupertino_icons` manquant
- Configuration TLS optimisée pour Gradle
- Amélioration de gradle.properties (mémoire, parallélisation)

### 📚 Documentation
- Nettoyage de 18 fichiers MD redondants
- Consolidation dans le dossier `docs/`
- README.md amélioré et simplifié
- Ajout de `firestore.indexes.json` pour automatiser la création des index

### 📦 Nouveaux Fichiers
- `lib/widgets/auth_lock_wrapper.dart` - Widget de verrouillage biométrique
- `docs/ADMIN_SETUP.md` - Guide configuration admin
- `docs/GUIDE_DEVELOPPEMENT.md` - Guide développeur
- `docs/GUIDE_REGLES_SECURITE.md` - Règles Firestore
- `docs/FIRESTORE_INDEXES_REQUIRED.md` - Index requis
- `firestore.indexes.json` - Configuration automatique des index

### 🗑️ Fichiers Supprimés
- 18 fichiers de documentation redondants
- Fichiers temporaires de corrections
- Doublons de guides

### 📊 Statistiques
- **Lignes supprimées** : 4,290
- **Lignes ajoutées** : 454
- **Fichiers modifiés** : 31
- **Commit** : `4903d2b`

### 🔗 Liens
- **Repository** : https://github.com/jean13-png/mon-artisan
- **Commit** : https://github.com/jean13-png/mon-artisan/commit/4903d2b

---

## Prochaines Étapes

### À faire immédiatement
1. ✅ Créer les index Firestore (voir `docs/FIRESTORE_INDEXES_REQUIRED.md`)
2. ✅ Tester le build APK
3. ✅ Tester l'authentification biométrique

### Améliorations futures
- [ ] Ajouter des tests unitaires
- [ ] Optimiser les images
- [ ] Ajouter un système de cache
- [ ] Implémenter le mode hors ligne
- [ ] Ajouter des animations de transition
