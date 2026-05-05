const Map<String, List<String>> villesBenin = {
  "Atlantique": [
    "Cotonou",
    "Abomey-Calavi",
    "Ouidah",
    "Allada",
    "Tori-Bossito"
  ],
  "Littoral": ["Cotonou"],
  "Ouémé": [
    "Porto-Novo",
    "Akpro-Missérété",
    "Adjarra",
    "Sèmè-Kpodji"
  ],
  "Borgou": [
    "Parakou",
    "Tchaourou",
    "N'Dali",
    "Bembèrèkè"
  ],
  "Alibori": [
    "Kandi",
    "Malanville",
    "Banikoara",
    "Gogounou"
  ],
  "Atacora": [
    "Natitingou",
    "Tanguiéta",
    "Kouandé",
    "Boukoumbé"
  ],
  "Donga": [
    "Djougou",
    "Bassila",
    "Copargo"
  ],
  "Zou": [
    "Abomey",
    "Bohicon",
    "Covè",
    "Zagnanado"
  ],
  "Collines": [
    "Savalou",
    "Savè",
    "Dassa-Zoumè",
    "Bantè"
  ],
  "Mono": [
    "Lokossa",
    "Athiémé",
    "Grand-Popo",
    "Comè"
  ],
  "Couffo": [
    "Aplahoué",
    "Dogbo",
    "Djakotomey",
    "Klouékanmè"
  ],
  "Plateau": [
    "Pobè",
    "Kétou",
    "Sakété",
    "Adja-Ouèrè"
  ],
};

// Liste plate de toutes les villes
List<String> getAllVilles() {
  List<String> allVilles = [];
  villesBenin.forEach((departement, villes) {
    allVilles.addAll(villes);
  });
  return allVilles.toSet().toList()..sort();
}

// Obtenir le département d'une ville
String? getDepartement(String ville) {
  for (var entry in villesBenin.entries) {
    if (entry.value.contains(ville)) {
      return entry.key;
    }
  }
  return null;
}
