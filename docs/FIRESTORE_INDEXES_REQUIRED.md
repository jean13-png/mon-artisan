# Index Firestore Requis

## Problème
Erreur : `[cloud_firestore/failed-precondition] The query requires an index`

## Solution

### Index à créer dans Firebase Console

#### 1. Index pour les Notifications

**Collection** : `notifications`

**Champs à indexer** :
- `userId` (Ascending)
- `createdAt` (Descending)

**Comment créer l'index** :

1. Va sur [Firebase Console](https://console.firebase.google.com)
2. Sélectionne ton projet : **mon-artisan-6eccb**
3. Va dans **Firestore Database** → **Indexes**
4. Clique sur **Create Index**
5. Configure :
   - Collection ID: `notifications`
   - Champ 1: `userId` → Ascending
   - Champ 2: `createdAt` → Descending
   - Query scope: Collection
6. Clique sur **Create**

**OU utilise le lien direct** :

Quand tu lances l'app et que l'erreur apparaît, Firebase te donne un lien direct dans l'erreur. Clique dessus et l'index sera créé automatiquement !

Le lien ressemble à :
```
https://console.firebase.google.com/v1/r/project/mon-artisan-6eccb/firestore/indexes?create_composite=...
```

### Temps de création

⏱️ La création de l'index prend **2-5 minutes**. Pendant ce temps :
- L'app ne crashera pas (correction appliquée)
- Les notifications retourneront une liste vide
- Une fois l'index créé, tout fonctionnera automatiquement

### Vérification

Pour vérifier que l'index est créé :

1. Va dans Firebase Console → Firestore → Indexes
2. Vérifie que le statut est **"Enabled"** (vert)
3. Relance l'app

### Autres index potentiellement nécessaires

Si tu rencontres d'autres erreurs similaires, voici les index recommandés :

#### 2. Index pour les Commandes (Artisan)
- Collection: `commandes`
- Champs: `artisanId` (Ascending) + `createdAt` (Descending)

#### 3. Index pour les Commandes (Client)
- Collection: `commandes`
- Champs: `clientId` (Ascending) + `createdAt` (Descending)

#### 4. Index pour les Artisans par métier et ville
- Collection: `artisans`
- Champs: `metier` (Ascending) + `ville` (Ascending) + `isVerified` (Ascending)

## Note importante

✅ **Correction appliquée** : L'app ne crashera plus si l'index n'existe pas. Elle affichera simplement "Aucune notification" jusqu'à ce que l'index soit créé.

## Fichier firestore.indexes.json

Tu peux aussi créer les index automatiquement avec Firebase CLI :

```bash
firebase deploy --only firestore:indexes
```

Contenu du fichier `firestore.indexes.json` (à créer à la racine du projet) :

```json
{
  "indexes": [
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "commandes",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "artisanId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "commandes",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "clientId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "artisans",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "metier", "order": "ASCENDING" },
        { "fieldPath": "ville", "order": "ASCENDING" },
        { "fieldPath": "isVerified", "order": "ASCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```
