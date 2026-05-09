# Changelog - Mon Artisan

## [Non publié] - 2026-05-06

### ✨ Améliorations - Profil Artisan (Simplification pour utilisateurs illettrés)

#### Interface simplifiée
- **Dropdowns au lieu de champs texte** : Ville et Quartier sélectionnables facilement
- **Bouton GPS optionnel** : "📍 Utiliser ma position actuelle" pour localisation précise
- **Messages avec emojis** : ❌ pour erreurs, ✅ pour succès, 📍 pour localisation
- **Terminologie adaptée** :
  - "Zone de travail" au lieu de "Atelier" (plus général)
  - "Photos de votre matériel" au lieu de "Photos de l'atelier"
  - Messages courts et simples

#### Amélioration des uploads
- **Logs détaillés** : 📤 Upload, ✅ Succès, ❌ Erreur pour faciliter le debug
- **Vérifications avant upload** :
  - Taille fichier (max 5MB)
  - Existence du fichier
  - Connexion internet
- **Messages d'erreur clairs** :
  - "Pas de connexion internet" au lieu de "Network error"
  - "Fichier trop volumineux" au lieu de "File size exceeded"
  - "Pas d'autorisation" au lieu de "Permission denied"
- **Chemins Storage corrects** : `artisans/{userId}/diplome/` et `artisans/{userId}/atelier/`

#### Géolocalisation intelligente
- **Sélection simple** : Ville → Quartier → GPS (optionnel)
- **Géolocalisation automatique** : Si GPS non utilisé, l'adresse est géolocalisée
- **Position précise** : Si GPS activé, coordonnées exactes enregistrées
- **Fonctionne sans GPS** : Pas obligatoire, juste optionnel

### 📚 Documentation
- **DEBUG_RECHERCHE.md** : Ajout section "Upload de fichiers"
  - Guide de vérification des règles Firebase Storage
  - Checklist de test complète
  - Commandes utiles pour debug
  - Problèmes courants et solutions

### 🔧 Fichiers Modifiés
- `lib/screens/artisan/complete_profile_screen.dart` - Interface simplifiée
- `lib/providers/artisan_provider.dart` - Meilleure gestion des uploads
- `DEBUG_RECHERCHE.md` - Documentation étendue

---

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
