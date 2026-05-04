# Mon Artisan - Application Mobile

Application mobile cross-platform (Android/iOS) pour connecter clients et artisans au Bénin.

## Description

Mon Artisan est une plateforme qui permet aux clients de trouver facilement des artisans qualifiés près de chez eux, de passer commande et de payer en ligne de manière sécurisée.

## Fonctionnalités principales

### Pour les clients
- Recherche d'artisans par métier, ville et quartier
- Consultation des profils et avis
- Commande et paiement sécurisé (FedaPay)
- Suivi en temps réel des commandes
- Notation des artisans

### Pour les artisans
- Création de profil professionnel
- Réception de commandes géolocalisées
- Gestion des prestations
- Suivi des revenus
- Retrait des gains

## Technologies utilisées

- **Framework** : Flutter 3.41.6
- **Backend** : Firebase (Firestore, Authentication, Storage, Cloud Functions)
- **Paiement** : FedaPay
- **Géolocalisation** : Google Maps API
- **Notifications** : Firebase Cloud Messaging

## Charte graphique

- Bleu principal : #1A3C6E
- Rouge accent : #C0392B
- Blanc : #FFFFFF
- Police : Poppins

## Documentation

- [Cahier des charges](cahier_des_charges.md)
- [Spécifications techniques](SPECIFICATIONS_TECHNIQUES.md)

## Installation

```bash
# Cloner le repository
git clone https://github.com/[username]/mon-artisan.git

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run
```

## Configuration Firebase

1. Créer un projet Firebase
2. Ajouter les fichiers de configuration :
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
3. Activer Authentication, Firestore, Storage, Cloud Messaging

## Configuration FedaPay

Ajouter votre clé API FedaPay dans les variables d'environnement.

## Licence

Tous droits réservés - Mon Artisan © 2026

## Contact

Pour toute question, contactez l'équipe de développement.
