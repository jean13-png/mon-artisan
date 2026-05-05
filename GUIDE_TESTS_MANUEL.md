# 🧪 GUIDE DE TESTS MANUEL - MON ARTISAN

## Date : 5 Mai 2026
## Version : 1.0.0 (MODE TEST)

---

## ⚠️ MODE TEST ACTIVÉ

**Configuration actuelle :**
- ✅ Clés FedaPay LIVE configurées
- ⚠️ Paiement artisan DÉSACTIVÉ pour tests
- ⚠️ Mode test activé (`isTestMode = true`)

**Pour activer le mode production :**
Modifier `mon_artisan_app/lib/core/constants/app_constants.dart` :
```dart
static const bool isTestMode = false;
static const bool requirePaymentForArtisan = true;
```

---

## 🚀 LANCEMENT DE L'APPLICATION

### Commande de lancement
```bash
cd mon_artisan_app
flutter run -d 11139373AQ003625
```

### Vérification avant lancement
```bash
# Vérifier qu'il n'y a pas d'erreurs
flutter analyze

# Résultat attendu : 0 errors, quelques warnings OK
```

---

## 📋 CHECKLIST COMPLÈTE DES TESTS

### ✅ PHASE 1 : INSCRIPTION ET AUTHENTIFICATION

#### Test 1.1 : Inscription Client
- [ ] Ouvrir l'app
- [ ] Cliquer sur "S'inscrire"
- [ ] Sélectionner "Client"
- [ ] Remplir le formulaire :
  - Nom : Test
  - Prénom : Client
  - Email : client.test@example.com
  - Téléphone : +22997000001
  - Ville : Cotonou
  - Mot de passe : Test123!
- [ ] Vérifier que l'inscription réussit
- [ ] Configurer le PIN (ex: 123456)
- [ ] Activer la biométrie (optionnel)
- [ ] Vérifier l'arrivée sur le dashboard client

**Résultat attendu :** ✅ Inscription réussie, dashboard client affiché

---

#### Test 1.2 : Inscription Artisan (MODE TEST)
- [ ] Retour à l'écran d'accueil
- [ ] Cliquer sur "S'inscrire"
- [ ] Sélectionner "Artisan"
- [ ] Remplir le formulaire :
  - Nom : Test
  - Prénom : Artisan
  - Email : artisan.test@example.com
  - Téléphone : +22997000002
  - Ville : Cotonou
  - Métier : Plombier
  - Mot de passe : Test123!
- [ ] Vérifier le message "MODE TEST : Paiement désactivé"
- [ ] Lire le contrat d'engagement (7 articles)
- [ ] Cocher "J'accepte les termes"
- [ ] Cliquer sur "Finaliser l'inscription"
- [ ] Configurer le PIN (ex: 654321)
- [ ] Vérifier l'arrivée sur le dashboard artisan
- [ ] Vérifier le message "7 jours pour compléter votre profil"

**Résultat attendu :** ✅ Inscription réussie sans paiement, message de grâce affiché

---

#### Test 1.3 : Connexion avec PIN
- [ ] Se déconnecter
- [ ] Se reconnecter avec email + mot de passe
- [ ] Entrer le PIN configuré
- [ ] Vérifier l'accès au dashboard

**Résultat attendu :** ✅ Connexion réussie avec PIN

---

#### Test 1.4 : Connexion avec Biométrie
- [ ] Se déconnecter
- [ ] Se reconnecter
- [ ] Utiliser l'empreinte digitale
- [ ] Vérifier l'accès au dashboard

**Résultat attendu :** ✅ Connexion réussie avec biométrie

---

### ✅ PHASE 2 : PROFIL ARTISAN

#### Test 2.1 : Complétion du profil artisan
- [ ] Connexion en tant qu'artisan
- [ ] Cliquer sur "Compléter mon profil maintenant"
- [ ] Remplir les informations :
  - CIP : 123456789
  - Adresse atelier : Akpakpa, Cotonou
  - Années d'expérience : 5
  - Description : Plombier professionnel...
- [ ] Uploader un diplôme (photo)
- [ ] Vérifier le message "Diplôme téléchargé avec succès"
- [ ] Uploader 3 photos d'atelier
- [ ] Vérifier le message "3 photo(s) téléchargée(s)"
- [ ] Cliquer sur "Soumettre"
- [ ] Vérifier le message de succès

**Résultat attendu :** ✅ Profil complété, photos uploadées

---

#### Test 2.2 : Bouton retour sur complétion profil
- [ ] Être sur l'écran de complétion
- [ ] Appuyer sur le bouton retour du téléphone
- [ ] Vérifier le retour au dashboard (pas de fermeture app)

**Résultat attendu :** ✅ Retour au dashboard, app ne se ferme pas

---

### ✅ PHASE 3 : RECHERCHE ET COMMANDES (CLIENT)

#### Test 3.1 : Recherche d'artisans
- [ ] Connexion en tant que client
- [ ] Cliquer sur "Rechercher un artisan"
- [ ] Sélectionner un métier : Plombier
- [ ] Sélectionner une ville : Cotonou
- [ ] Cliquer sur "Rechercher"
- [ ] Vérifier l'affichage des résultats
- [ ] Vérifier que le téléphone n'est PAS visible

**Résultat attendu :** ✅ Liste d'artisans affichée, téléphone masqué

---

#### Test 3.2 : Consultation profil artisan
- [ ] Cliquer sur un artisan
- [ ] Vérifier l'affichage :
  - Photo de profil
  - Nom et métier
  - Note moyenne
  - Description
  - Photos d'atelier
  - Avis clients
  - ❌ PAS de numéro de téléphone
- [ ] Cliquer sur "Contacter"
- [ ] Vérifier l'ouverture du chat

**Résultat attendu :** ✅ Profil complet affiché, téléphone masqué

---

#### Test 3.3 : Création de commande
- [ ] Sur le profil artisan, cliquer "Commander"
- [ ] Remplir le formulaire :
  - Titre : Réparation fuite d'eau
  - Description : Fuite sous l'évier de la cuisine
  - Date souhaitée : Demain
  - Budget : 15000 FCFA
- [ ] Ajouter 2 photos
- [ ] Cliquer sur "Créer la commande"
- [ ] Vérifier la redirection vers le paiement

**Résultat attendu :** ✅ Commande créée, redirection paiement

---

#### Test 3.4 : Paiement commande (Simulation)
- [ ] Sur l'écran de paiement
- [ ] Vérifier le montant : 15000 FCFA
- [ ] Vérifier la commission : 1500 FCFA (10%)
- [ ] Total : 16500 FCFA
- [ ] Cliquer sur "Payer avec FedaPay"
- [ ] Simuler le paiement (mode test)
- [ ] Vérifier le message de succès
- [ ] Vérifier le statut : "Paiement bloqué (escrow)"

**Résultat attendu :** ✅ Paiement simulé, argent bloqué

---

### ✅ PHASE 4 : GESTION COMMANDES (ARTISAN)

#### Test 4.1 : Réception de commande
- [ ] Se connecter en tant qu'artisan
- [ ] Vérifier la notification de nouvelle commande
- [ ] Voir la commande dans "Commandes en attente"
- [ ] Cliquer sur la commande
- [ ] Vérifier les détails :
  - Titre, description
  - Photos
  - Budget
  - Localisation client
- [ ] Cliquer sur "Accepter"
- [ ] Vérifier le changement de statut : "Acceptée"

**Résultat attendu :** ✅ Commande acceptée, statut mis à jour

---

#### Test 4.2 : Marquage terminé
- [ ] Sur la commande acceptée
- [ ] Cliquer sur "Marquer comme terminée"
- [ ] Confirmer
- [ ] Vérifier le statut : "Terminée"
- [ ] Vérifier que le paiement est toujours bloqué

**Résultat attendu :** ✅ Commande terminée, paiement toujours bloqué

---

### ✅ PHASE 5 : SYSTÈME ESCROW

#### Test 5.1 : Validation par le client
- [ ] Se connecter en tant que client
- [ ] Aller dans "Mes commandes"
- [ ] Trouver la commande terminée
- [ ] Vérifier le statut : "Paiement bloqué (escrow)"
- [ ] Cliquer sur "Valider la prestation"
- [ ] Lire le dialogue de confirmation
- [ ] Confirmer la validation
- [ ] Vérifier le message de succès
- [ ] Vérifier le nouveau statut : "Paiement débloqué"

**Résultat attendu :** ✅ Paiement débloqué, artisan crédité

---

#### Test 5.2 : Crédit portefeuille artisan
- [ ] Se connecter en tant qu'artisan
- [ ] Vérifier la notification "Paiement débloqué"
- [ ] Aller dans "Mes revenus"
- [ ] Vérifier le solde disponible : 13500 FCFA (15000 - 10%)
- [ ] Vérifier l'historique des transactions

**Résultat attendu :** ✅ Portefeuille crédité correctement

---

### ✅ PHASE 6 : MESSAGERIE SÉCURISÉE

#### Test 6.1 : Message d'avertissement
- [ ] Ouvrir un chat (client ou artisan)
- [ ] Vérifier l'affichage de la bannière rouge :
  - "AVERTISSEMENT IMPORTANT"
  - Texte complet visible
  - Bouton fermer (X)
- [ ] Cliquer sur X
- [ ] Vérifier que la bannière disparaît
- [ ] Fermer et rouvrir le chat
- [ ] Vérifier que la bannière réapparaît

**Résultat attendu :** ✅ Bannière affichée à chaque session

---

#### Test 6.2 : Filtre anti-contournement - Numéros
- [ ] Dans le chat, essayer d'envoyer :
  - "Mon numéro est 97123456"
  - "Appelle-moi au +22997123456"
  - "WhatsApp : 97 12 34 56"
- [ ] Vérifier que chaque message est bloqué
- [ ] Vérifier l'affichage du dialogue d'alerte
- [ ] Lire le message d'explication

**Résultat attendu :** ✅ Tous les numéros bloqués

---

#### Test 6.3 : Filtre anti-contournement - Apps
- [ ] Essayer d'envoyer :
  - "Contacte-moi sur WhatsApp"
  - "J'ai Telegram"
  - "Viber ou Signal"
- [ ] Vérifier que chaque message est bloqué

**Résultat attendu :** ✅ Toutes les apps bloquées

---

#### Test 6.4 : Filtre anti-contournement - Liens
- [ ] Essayer d'envoyer :
  - "www.monsite.com"
  - "http://example.com"
  - "Visite monsite.bj"
- [ ] Vérifier que chaque message est bloqué

**Résultat attendu :** ✅ Tous les liens bloqués

---

#### Test 6.5 : Messages normaux
- [ ] Envoyer des messages normaux :
  - "Bonjour, je suis disponible demain"
  - "Le travail est terminé"
  - "Merci pour votre confiance"
- [ ] Vérifier que les messages passent
- [ ] Vérifier la réception côté destinataire

**Résultat attendu :** ✅ Messages normaux envoyés

---

### ✅ PHASE 7 : NAVIGATION ET BOUTONS RETOUR

#### Test 7.1 : Retour sur dashboard client
- [ ] Être sur le dashboard client
- [ ] Appuyer sur le bouton retour du téléphone
- [ ] Vérifier l'affichage du dialogue "Quitter l'application ?"
- [ ] Cliquer sur "Annuler"
- [ ] Vérifier que l'app reste ouverte
- [ ] Réessayer et cliquer sur "Quitter"
- [ ] Vérifier que l'app se ferme

**Résultat attendu :** ✅ Dialogue de confirmation affiché

---

#### Test 7.2 : Retour sur dashboard artisan
- [ ] Être sur le dashboard artisan
- [ ] Appuyer sur le bouton retour du téléphone
- [ ] Vérifier le dialogue de confirmation
- [ ] Tester Annuler et Quitter

**Résultat attendu :** ✅ Dialogue de confirmation affiché

---

#### Test 7.3 : Retour sur contrat d'engagement
- [ ] Créer un nouveau compte artisan
- [ ] Arriver sur l'écran du contrat
- [ ] Appuyer sur le bouton retour
- [ ] Vérifier le dialogue "Annuler l'inscription ?"
- [ ] Cliquer sur "Oui"
- [ ] Vérifier le retour à la sélection de rôle

**Résultat attendu :** ✅ Retour à la sélection de rôle

---

#### Test 7.4 : Navigation normale
- [ ] Tester la navigation sur tous les écrans :
  - Recherche → Profil artisan → Retour
  - Mes commandes → Détail → Retour
  - Favoris → Retour
  - Notifications → Retour
  - Profil → Modifier → Retour
- [ ] Vérifier que le retour fonctionne comme dans Chrome

**Résultat attendu :** ✅ Navigation fluide, retour à l'écran précédent

---

### ✅ PHASE 8 : ADMINISTRATION

#### Test 8.1 : Connexion admin
- [ ] Se déconnecter
- [ ] Se connecter avec :
  - Email : tossajean13@gmail.com
  - Password : TOSjea13#
- [ ] Vérifier la redirection automatique vers le dashboard admin

**Résultat attendu :** ✅ Accès au dashboard admin

---

#### Test 8.2 : Dashboard admin - Statistiques
- [ ] Vérifier l'affichage des statistiques :
  - Nombre total d'artisans
  - Artisans en attente de validation
  - Nombre total de clients
  - Nombre total de commandes
  - Revenus totaux (commissions)
- [ ] Vérifier que les chiffres sont corrects

**Résultat attendu :** ✅ Statistiques affichées correctement

---

#### Test 8.3 : Validation des artisans
- [ ] Cliquer sur "Valider les artisans"
- [ ] Voir la liste des artisans en attente
- [ ] Cliquer sur un artisan
- [ ] Vérifier les informations :
  - Profil complet
  - Diplôme
  - Photos d'atelier
- [ ] Cliquer sur "Approuver"
- [ ] Vérifier le changement de statut
- [ ] Vérifier la notification envoyée à l'artisan

**Résultat attendu :** ✅ Artisan approuvé, notification envoyée

---

#### Test 8.4 : Gestion des agents
- [ ] Cliquer sur "Gérer les agents"
- [ ] Cliquer sur "Ajouter un agent"
- [ ] Remplir le formulaire :
  - Nom : Agent
  - Prénom : Test
  - Email : agent.test@example.com
  - Téléphone : +22997000003
  - Code parrainage : AGENT001
- [ ] Créer l'agent
- [ ] Vérifier l'affichage dans la liste
- [ ] Tester l'activation/désactivation
- [ ] Vérifier les statistiques de l'agent

**Résultat attendu :** ✅ Agent créé et géré

---

### ✅ PHASE 9 : MULTI-RÔLES

#### Test 9.1 : Utilisateur avec plusieurs rôles
- [ ] Créer un compte client
- [ ] Se déconnecter
- [ ] S'inscrire avec le MÊME email en tant qu'artisan
- [ ] Vérifier le message "Email déjà utilisé, ajout du rôle"
- [ ] Se connecter
- [ ] Vérifier l'affichage du dialogue de sélection de rôle
- [ ] Choisir "Client"
- [ ] Vérifier l'accès au dashboard client
- [ ] Se déconnecter et reconnecter
- [ ] Choisir "Artisan"
- [ ] Vérifier l'accès au dashboard artisan

**Résultat attendu :** ✅ Changement de rôle fonctionnel

---

### ✅ PHASE 10 : FONCTIONNALITÉS AVANCÉES

#### Test 10.1 : Favoris
- [ ] En tant que client
- [ ] Consulter un profil artisan
- [ ] Cliquer sur l'icône cœur
- [ ] Vérifier l'ajout aux favoris
- [ ] Aller dans "Mes favoris"
- [ ] Vérifier l'affichage de l'artisan
- [ ] Retirer des favoris
- [ ] Vérifier la suppression

**Résultat attendu :** ✅ Favoris fonctionnels

---

#### Test 10.2 : Notation artisan
- [ ] Après validation d'une commande
- [ ] Cliquer sur "Noter l'artisan"
- [ ] Donner une note (1-5 étoiles)
- [ ] Écrire un commentaire
- [ ] Soumettre
- [ ] Vérifier l'affichage sur le profil artisan
- [ ] Vérifier la mise à jour de la note moyenne

**Résultat attendu :** ✅ Notation enregistrée et affichée

---

#### Test 10.3 : Demande de retrait artisan
- [ ] En tant qu'artisan avec solde > 5000 FCFA
- [ ] Aller dans "Mes revenus"
- [ ] Cliquer sur "Demander un retrait"
- [ ] Entrer le montant (ex: 10000 FCFA)
- [ ] Entrer le numéro de téléphone
- [ ] Soumettre
- [ ] Vérifier le message de succès
- [ ] Vérifier la mise à jour du solde

**Résultat attendu :** ✅ Demande de retrait enregistrée

---

#### Test 10.4 : Notifications
- [ ] Vérifier les notifications pour :
  - Nouvelle commande (artisan)
  - Commande acceptée (client)
  - Commande terminée (client)
  - Paiement débloqué (artisan)
  - Nouveau message (client/artisan)
  - Validation compte (artisan)
- [ ] Cliquer sur une notification
- [ ] Vérifier la redirection vers l'écran approprié

**Résultat attendu :** ✅ Notifications reçues et fonctionnelles

---

## 📊 RÉSUMÉ DES TESTS

### Statistiques
- **Total de tests** : 40+
- **Durée estimée** : 2-3 heures
- **Testeurs recommandés** : 2-3 personnes

### Priorités
1. **CRITIQUE** : Inscription, connexion, paiement, escrow
2. **HAUTE** : Commandes, chat, navigation
3. **MOYENNE** : Favoris, notifications, multi-rôles
4. **BASSE** : Administration, statistiques

---

## 🐛 RAPPORT DE BUGS

### Template de rapport
```
**Titre** : [Description courte]
**Sévérité** : Critique / Haute / Moyenne / Basse
**Étapes** :
1. ...
2. ...
**Résultat attendu** : ...
**Résultat obtenu** : ...
**Captures d'écran** : [Si possible]
**Device** : TECNO KJ5 / Android X.X
```

---

## ✅ VALIDATION FINALE

Avant de passer en production, vérifier :

- [ ] Tous les tests critiques passés
- [ ] Aucun bug bloquant
- [ ] Performance acceptable (< 3s chargement)
- [ ] Pas de crash
- [ ] Notifications fonctionnelles
- [ ] Paiements testés (mode sandbox)
- [ ] Navigation fluide
- [ ] Sécurité validée (filtre chat, escrow)

---

## 🚀 PASSAGE EN PRODUCTION

Une fois tous les tests validés :

1. Modifier `app_constants.dart` :
```dart
static const bool isTestMode = false;
static const bool requirePaymentForArtisan = true;
```

2. Nettoyer les `print()` de debug
3. Configurer Firebase Security Rules
4. Build production :
```bash
flutter build appbundle --release
```

5. Déployer sur Play Store

---

**Créé le : 5 Mai 2026**
**Version : 1.0.0**
**Statut : MODE TEST**
