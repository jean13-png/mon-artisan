1. PRÉSENTATION DU PROJET
1.1 Contexte
Le Bénin dispose d'un tissu artisanal riche et diversifié, mais les artisans restent souvent difficiles à
trouver pour les clients, faute de visibilité numérique. Il n'existe pas aujourd'hui de plateforme
centralisée permettant aux clients de localiser facilement un artisan par métier, ville ou quartier, ni de
commander et payer leurs prestations en ligne.
1.2 Objectif du projet
Mon Artisan est une application mobile disponible sur iOS et Android, destinée à rassembler les
artisans béninois sur une seule plateforme. Elle permet aux clients de rechercher rapidement un
artisan selon son métier, sa ville et son quartier, de consulter son profil, de lui commander une
prestation et de payer en ligne de manière sécurisée.
1.3 Valeur ajoutée
● Visibilité accrue pour les artisans béninois
● Facilité de recherche et de mise en relation pour les clients
● Paiement sécurisé et gestion des commissions en ligne
● Couverture nationale avec filtrage par ville et quartier
2. PUBLIC CIBLE
Les ArtisansLes Clients
Tout professionnel de l'artisanat au BéninToute
souhaitant s'inscrire, créer un profil et recevoircherchant un artisan pour une prestation de
des commandes via la plateforme.service, pouvant rechercher, contacter et payer
personne
(particulier
en ligne.
3. FONCTIONNALITÉS PRINCIPALES
3.1 Espace Artisan
● Inscription et création de profil (nom, métier, ville, quartier, photo, description)
● Gestion du profil et mise à jour des informations
● Réception et suivi des commandes clients
● Notification lors d'une nouvelle commande
● Accès au tableau de bord (commandes, revenus, avis)
● Retrait des gains après validation de la prestation
3.2 Espace Client
● Recherche d'artisans par métier, ville et quartier
● Consultation des profils artisans (photo, note, avis, tarifs)
● Sélection et commande d'un artisan
● Paiement sécurisé en ligne de la prestation
● Suivi de l'état de la commande en temps réel
● Notation et avis après la prestation
3.3 Espace Administrateur (Back-office)
● Validation et modération des comptes artisans
● Gestion des commandes et litiges
● Suivi des paiements et des commissions
● Tableau de bord statistiques (utilisateurs, revenus, commandes)
● Gestion des catégories de métiers
4. MODÈLE ÉCONOMIQUE
La plateforme applique un système de commission sur chaque transaction réalisée :
ÉtapeDescription
1. CommandeLe client sélectionne un artisan et passe commande
2. PaiementLe client paie le montant total directement sur la plateforme (paiement sécurisé)
3. PrestationL'artisan réalise le travail commandé
4. ValidationLe client valide la prestation terminée
5. ReversementLa plateforme reverse la part de l'artisan et conserve sa commission
Note : Le taux de commission sera défini par l'équipe projet avant le lancement.
5. EXIGENCES TECHNIQUES
CritèreDétail
PlateformesiOS (iPhone) et Android
Technologie recommandéeFlutter ou React Native (développement cross-platform)
AuthentificationInscription / Connexion par email ou numéro de téléphone
Paiement en ligneIntégration d'une solution de paiement locale (ex : MTN Mobile Money, Moov, carte ba
GéolocalisationFiltrage par ville et quartier (liste déroulante ou géolocalisation GPS)
Notifications PushAlertes en temps réel pour commandes, messages et paiements
Backend / APIAPI REST sécurisée (Node.js / Django / Laravel)
Base de donnéesBase de données relationnelle ou NoSQL (PostgreSQL / Firebase)
SécuritéChiffrement des données, HTTPS, tokens d'authentification JWT
PerformanceTemps de chargement < 3 secondes, disponibilité 99%
6. CHARTE GRAPHIQUE
L'application devra adopter une identité visuelle moderne, professionnelle et mémorable, basée sur
les couleurs suivantes :
Bleu principal #1A3C6E
Rouge accent #C0392B
Blanc #FFFFFF
● Police moderne et lisible : Poppins ou Montserrat
● Icônes simples et épurées représentant les métiers artisanaux
● Interface intuitive, adaptée à une utilisation mobile
● Logo Mon Artisan à créer avec les couleurs bleu et rouge
7. PLANNING DE RÉALISATION
Durée totale du projet : 2 semaines
PhaseTâches
Durée
Phase 1 — ConceptionMaquettes UI/UX, architecture technique, validation du cahierJours
des charges
1-3
Phase 2 — DéveloppementBackend API, base de données, interfaces iOS & Android, intégration
Jours 4-10
paiement
Phase 3 — TestsTests fonctionnels, corrections de bugs, tests utilisateurs
Phase 4 — LivraisonDéploiement sur App Store & Google Play, formation, documentation
Jours 13-14
Jours 11-12
8. CONTRAINTES ET EXIGENCES
● L'application doit fonctionner sur iOS et Android
● Le délai de livraison est fixé à 2 semaines à compter du démarrage du projet
● La solution de paiement doit être compatible avec les moyens de paiement populaires au Bénin
(Mobile Money, etc.)
● L'interface doit être disponible en français
● L'application doit être utilisable sans connexion internet très rapide (optimisation réseau 3G/4G)
● Les données des utilisateurs doivent être protégées conformément aux bonnes pratiques de
sécurité
● La plateforme doit pouvoir évoluer facilement (ajout de nouvelles villes, métiers, fonctionnalités)
9. LIVRABLES ATTENDUS
Application iOSFichier .ipa prêt pour soumission sur l'App Store
Application AndroidFichier .apk/.aab prêt pour soumission sur le Google Play Store
Back-office adminInterface web de gestion des artisans, commandes et paiements
Code sourceCode source complet, documenté et versionné (Git)
Documentation techniqueGuide d'installation, d'utilisation et de maintenance
Maquettes UI/UXMaquettes validées de toutes les interfaces de l'application
