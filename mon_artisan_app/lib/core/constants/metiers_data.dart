// Répertoire officiel des corps d'artisans au Bénin — 2026

import 'package:flutter/material.dart';

const Map<String, List<String>> metiersData = {
  "Construction & Bâtiment": [
    "Maçon", "Carreleur", "Peintre en bâtiment", "Plâtrier / Stucateur",
    "Couvreur (toiture)", "Charpentier bois", "Menuisier bois",
    "Menuisier aluminium / PVC", "Serrurier / Métallier", "Soudeur",
    "Ferrailleur / Bétonneur", "Plombier", "Technicien sanitaire",
    "Poseur de faux plafond", "Technicien revêtement sol", "Démolisseur",
    "Conducteur de travaux", "Métreur / Estimateur de coûts",
  ],
  "Topographie & Géométrie": [
    "Géomètre-topographe", "Arpenteur", "Technicien en bornage de terrain",
    "Opérateur drone / relevé aérien", "Dessinateur en génie civil / DAO",
    "Technicien cadastre", "Technicien SIG", "Nivelleur / Technicien altimétrie",
  ],
  "Énergie & Électricité": [
    "Électricien bâtiment", "Électricien industriel",
    "Technicien solaire / photovoltaïque", "Technicien groupe électrogène",
    "Bobiniste (moteurs électriques)", "Technicien climatisation / HVAC",
    "Frigoriste", "Technicien onduleur / batteries",
    "Installateur de panneaux solaires", "Câbleur réseau électrique",
  ],
  "Automobile & Mécanique": [
    "Mécanicien auto", "Mécanicien moto / zemidjan", "Mécanicien engins lourds",
    "Vulcanisateur (pneus)", "Tôlier-carrossier", "Peintre auto",
    "Électricien auto", "Technicien injection électronique",
    "Garagiste vélos / cycles", "Mécanicien diesel", "Mécanicien groupe froid",
    "Laveur auto / moto", "Technicien climatisation auto",
    "Réparateur de radiateurs auto",
  ],
  "Couture, Textile & Mode": [
    "Tailleur homme", "Couturière / Styliste femme", "Brodeur (main & machine)",
    "Tisserand (pagnes kita, sème)", "Batikeur (impressions sur tissu)",
    "Teinturier (tie-dye, indigo)", "Tapissier (meubles & décoration)",
    "Cordonnier-chaussures", "Maroquinier (sacs, ceintures)",
    "Créateur de bijoux fantaisie", "Repasseur professionnel",
    "Retoucheur / Réparateur de vêtements", "Fabricant de pagnes & tissus locaux",
    "Créateur de mode / Designer",
  ],
  "Coiffure & Beauté": [
    "Coiffeur homme", "Coiffeuse / Salon de coiffure femme", "Barbier",
    "Tresseuse / Natteuse", "Poseur de perruques / Extensions", "Esthéticienne",
    "Manucure / Pédicure", "Maquilleuse professionnelle", "Tatoueur au henné",
    "Spa / Masseur bien-être", "Technicien sourcing cheveux naturels",
    "Coloriste capillaire",
  ],
  "Alimentation & Agroalimentaire": [
    "Boulanger", "Pâtissier / Confiseur", "Boucher / Chevillard", "Charcutier",
    "Transformateur de céréales (gari, akassa)", "Fabricant d'huile de palme / de soja",
    "Brasseur de boissons locales (sodabi)", "Fabricant de fromage wagashi",
    "Fumeur de poisson / viande", "Fabricant de jus naturels & sirops",
    "Transformateur de karité", "Fabricant de savon local",
    "Torréfacteur de café / cacao artisanal",
    "Fabricant de condiments (soumbala, piment)",
  ],
  "Ameublement & Décoration": [
    "Menuisier-ébéniste", "Tapissier d'ameublement",
    "Fabricant de matelas & sommiers", "Décorateur intérieur",
    "Fabricant de nattes / paniers", "Fabricant de meubles en bambou / rotin",
    "Poseur de rideaux / stores / voilages", "Fabricant de cadres & encadreur",
    "Créateur de luminaires artisanaux", "Peintre décorateur / fresquiste intérieur",
  ],
  "Électronique, Informatique & Réparation": [
    "Technicien portable / smartphones", "Maintenancier informatique (PC, laptops)",
    "Technicien réseaux / WiFi / fibre optique", "Réparateur TV / home cinéma / son",
    "Réparateur appareils électroménagers", "Technicien audiovisuel (ampli, enceintes)",
    "Réparateur consoles de jeux vidéo", "Installateur systèmes de sécurité / CCTV",
    "Technicien imprimantes & photocopieurs", "Recycleur de matériel électronique",
    "Technicien domotique (maison connectée)", "Réparateur de tablettes & e-readers",
  ],
  "Communication Visuelle & Graphisme": [
    "Graphiste (logo, flyers, affiches)", "Infographiste / Designer print & digital",
    "Photographe professionnel", "Vidéaste / Caméraman",
    "Monteur vidéo / Motion designer", "Sérigraphe (impression sur tissu, T-shirts)",
    "Imprimeur (offset, numérique, grand format)",
    "Enseigniste (panneaux, banderoles, signalétique)",
    "Opérateur DAO / Dessinateur technique", "Créateur de contenu / Réels & vidéos",
    "Webdesigner / Intégrateur web", "Community manager / Gestionnaire réseaux sociaux",
  ],
  "Artisanat d'Art & Culture Béninoise": [
    "Potier / Céramiste", "Bronzier / Fondeur (cire perdue)",
    "Forgeron traditionnel", "Bijoutier traditionnel (or, argent, bronze)",
    "Perlier (fabrication de perles)", "Peintre artiste / Fresquiste",
    "Graveur sur métal / bois / pierre", "Tisserand kita / sème",
    "Sculpteur sur bois", "Sculpteur sur pierre",
    "Fabricant de tam-tams & instruments traditionnels",
    "Fabricant de masques & statuettes vodoun",
    "Fabricant de pirogues", "Luthier / Fabricant d'instruments modernes",
  ],
  "Agriculture Artisanale & Élevage": [
    "Maraîcher artisanal", "Apiculteur / Transformateur de miel",
    "Aviculteur artisanal", "Éleveur de lapins / cobayes",
    "Pisciculteur artisanal", "Producteur de champignons",
    "Pépiniériste (plants, arbres, fleurs)", "Producteur de compost / engrais organique",
    "Jardinier paysagiste", "Herboriste / Transformateur de plantes médicinales",
  ],
  "Autres Services Artisanaux": [
    "Cordonnier-réparateur (chaussures, sandales)",
    "Horloger (réparation montres & pendules)",
    "Affûteur / Rémouleur (couteaux, ciseaux)", "Réparateur de parapluies & sacs",
    "Fabricant de briques (briques cuites, parpaings)", "Puisatier / Foreur de puits",
    "Carrier (extraction sable, gravier, latérite)", "Lieur / Tresseur de rotin & bambou",
    "Fabricant de cercueils", "Réparateur de valises & bagages",
    "Fabricant de filets de pêche", "Blanchisseur / Pressing artisanal",
    "Réparateur de machines à coudre", "Fabricant d'articles de deuil & funéraires",
  ],
};

// ── Helpers ────────────────────────────────────────────────────────────────

/// Toutes les catégories triées
List<String> getAllCategories() => metiersData.keys.toList();

/// Tous les métiers en liste plate avec leur catégorie
List<Map<String, String>> getAllMetiers() {
  final result = <Map<String, String>>[];
  metiersData.forEach((categorie, metiers) {
    for (final m in metiers) {
      result.add({'nom': m, 'categorie': categorie});
    }
  });
  return result;
}

/// Métiers d'une catégorie
List<String> getMetiersByCategorie(String categorie) =>
    metiersData[categorie] ?? [];

/// Recherche insensible à la casse et aux accents
List<Map<String, String>> searchMetiers(String query) {
  if (query.trim().isEmpty) return getAllMetiers();
  final q = _norm(query);
  return getAllMetiers()
      .where((m) => _norm(m['nom']!).contains(q) || _norm(m['categorie']!).contains(q))
      .toList();
}

List<String> searchCategories(String query) {
  if (query.trim().isEmpty) return getAllCategories();
  final q = _norm(query);
  return getAllCategories().where((c) => _norm(c).contains(q)).toList();
}

String _norm(String s) => s
    .toLowerCase()
    .replaceAll('é', 'e').replaceAll('è', 'e').replaceAll('ê', 'e')
    .replaceAll('à', 'a').replaceAll('â', 'a')
    .replaceAll('ô', 'o').replaceAll('î', 'i')
    .replaceAll('ù', 'u').replaceAll('û', 'u')
    .replaceAll('ç', 'c').replaceAll('&', 'et');

/// Icône Material pour chaque catégorie
IconData categoryIcon(String categorie) {
  switch (categorie) {
    case "Construction & Bâtiment": return Icons.construction;
    case "Topographie & Géométrie": return Icons.map_outlined;
    case "Énergie & Électricité": return Icons.bolt;
    case "Automobile & Mécanique": return Icons.directions_car;
    case "Couture, Textile & Mode": return Icons.checkroom;
    case "Coiffure & Beauté": return Icons.face_retouching_natural;
    case "Alimentation & Agroalimentaire": return Icons.restaurant;
    case "Ameublement & Décoration": return Icons.chair;
    case "Électronique, Informatique & Réparation": return Icons.devices;
    case "Communication Visuelle & Graphisme": return Icons.palette;
    case "Artisanat d'Art & Culture Béninoise": return Icons.museum;
    case "Agriculture Artisanale & Élevage": return Icons.grass;
    case "Autres Services Artisanaux": return Icons.handyman;
    default: return Icons.work_outline;
  }
}

/// URL d'image Unsplash réelle pour chaque catégorie
String categoryImageUrl(String categorie) {
  switch (categorie) {
    case "Construction & Bâtiment":
      return 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400&q=80';
    case "Topographie & Géométrie":
      return 'https://images.unsplash.com/photo-1581094794329-c8112a89af12?w=400&q=80';
    case "Énergie & Électricité":
      return 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=400&q=80';
    case "Automobile & Mécanique":
      return 'https://images.unsplash.com/photo-1530046339160-ce3e530c7d2f?w=400&q=80';
    case "Couture, Textile & Mode":
      return 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80';
    case "Coiffure & Beauté":
      return 'https://images.unsplash.com/photo-1560066984-138daaa0c0e4?w=400&q=80';
    case "Alimentation & Agroalimentaire":
      return 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&q=80';
    case "Ameublement & Décoration":
      return 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400&q=80';
    case "Électronique, Informatique & Réparation":
      return 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=400&q=80';
    case "Communication Visuelle & Graphisme":
      return 'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=400&q=80';
    case "Artisanat d'Art & Culture Béninoise":
      return 'https://images.unsplash.com/photo-1578301978693-85fa9c0320b9?w=400&q=80';
    case "Agriculture Artisanale & Élevage":
      return 'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=400&q=80';
    case "Autres Services Artisanaux":
      return 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400&q=80';
    default:
      return 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400&q=80';
  }
}
