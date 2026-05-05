// Liste des métiers organisés par catégorie
const Map<String, List<Map<String, String>>> metiersData = {
  "BTP & Construction": [
    {"nom": "Électricien", "icon": "bolt"},
    {"nom": "Plombier", "icon": "wrench"},
    {"nom": "Maçon", "icon": "hammer"},
    {"nom": "Peintre", "icon": "paint-roller"},
    {"nom": "Menuisier", "icon": "saw"},
    {"nom": "Carreleur", "icon": "grid"},
    {"nom": "Charpentier", "icon": "ruler-combined"},
    {"nom": "Soudeur", "icon": "fire"},
    {"nom": "Plafonneur", "icon": "layer-group"},
    {"nom": "Serrurier / Métallier", "icon": "key"},
    {"nom": "Couvreur / Zingueur", "icon": "home"},
    {"nom": "Vitrier / Miroitier", "icon": "window-maximize"},
    {"nom": "Poseur de Parquet", "icon": "th-large"},
    {"nom": "Poseur Faux-Plafond", "icon": "border-all"},
  ],
  "Énergie & Climatisation": [
    {"nom": "Panneaux Solaires", "icon": "solar-panel"},
    {"nom": "Climatisation", "icon": "snowflake"},
    {"nom": "Chauffagiste", "icon": "temperature-high"},
    {"nom": "Installateur Gaz", "icon": "fire-alt"},
    {"nom": "Électricité Industrielle", "icon": "industry"},
  ],
  "Aménagement & Finitions": [
    {"nom": "Paysagiste", "icon": "tree"},
    {"nom": "Étanchéité", "icon": "tint"},
    {"nom": "Isolation Thermique", "icon": "shield-alt"},
    {"nom": "Plâtrier / Stucateur", "icon": "palette"},
    {"nom": "Peintre Industriel", "icon": "spray-can"},
  ],
  "Gros Œuvre": [
    {"nom": "Démolition", "icon": "hammer-war"},
    {"nom": "Terrassement", "icon": "mountain"},
    {"nom": "Béton Armé / Ferrailleur", "icon": "cubes"},
    {"nom": "Coffreur / Bancheur", "icon": "box"},
    {"nom": "Échafaudeur", "icon": "ladder"},
  ],
  "Études & Conception": [
    {"nom": "Architecte / Dessinateur", "icon": "drafting-compass"},
    {"nom": "Bureau d'étude BTP", "icon": "building"},
    {"nom": "Géotechnicien", "icon": "map-marked-alt"},
    {"nom": "Topographe", "icon": "map"},
    {"nom": "Expert en Bâtiment", "icon": "user-tie"},
  ],
  "Équipements & Installations": [
    {"nom": "Ascensoriste", "icon": "elevator"},
    {"nom": "Domotique / Smart Home", "icon": "home-lg-alt"},
    {"nom": "Alarme / Sécurité", "icon": "bell"},
    {"nom": "Technicien Fibre Optique", "icon": "network-wired"},
  ],
  "Eau & Assainissement": [
    {"nom": "Foreur / Puits", "icon": "water"},
    {"nom": "Assainissement", "icon": "recycle"},
    {"nom": "Construction Piscine", "icon": "swimming-pool"},
  ],
  "Services & Maintenance": [
    {"nom": "Rénovation Générale", "icon": "tools"},
    {"nom": "Nettoyage Chantier", "icon": "broom"},
    {"nom": "Location Engins BTP", "icon": "truck"},
    {"nom": "Monteur Préfabriqué", "icon": "puzzle-piece"},
  ],
  "Services à la personne": [
    {"nom": "Coiffeuse", "icon": "cut"},
    {"nom": "Maquilleuse", "icon": "magic"},
    {"nom": "Esthéticienne", "icon": "spa"},
    {"nom": "Tresse africaine", "icon": "user-alt"},
    {"nom": "Femme de ménage", "icon": "broom"},
    {"nom": "Nounou", "icon": "baby"},
    {"nom": "Garde malade", "icon": "user-nurse"},
  ],
  "Événementiel": [
    {"nom": "Traiteur", "icon": "utensils"},
    {"nom": "Pâtissier", "icon": "birthday-cake"},
    {"nom": "Décorateur", "icon": "gift"},
    {"nom": "Photographe", "icon": "camera"},
    {"nom": "Vidéaste", "icon": "video"},
    {"nom": "DJ", "icon": "music"},
    {"nom": "Wedding planner", "icon": "heart"},
  ],
  "Réparation": [
    {"nom": "Mécanicien", "icon": "car"},
    {"nom": "Carrossier", "icon": "car-side"},
    {"nom": "Réparateur téléphone", "icon": "mobile-alt"},
  ],
};

// Obtenir tous les métiers en liste plate
List<Map<String, String>> getAllMetiers() {
  List<Map<String, String>> allMetiers = [];
  metiersData.forEach((categorie, metiers) {
    for (var metier in metiers) {
      allMetiers.add({
        ...metier,
        "categorie": categorie,
      });
    }
  });
  return allMetiers;
}

// Obtenir les métiers d'une catégorie
List<Map<String, String>> getMetiersByCategorie(String categorie) {
  return metiersData[categorie] ?? [];
}
