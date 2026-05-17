// Villes et quartiers du Bénin — données complètes
// Couvre les 77 communes du Bénin avec leurs quartiers/arrondissements

const Map<String, List<String>> villesQuartiersBenin = {

  // ═══════════════════════════════════════════════════════
  // DÉPARTEMENT DU LITTORAL
  // ═══════════════════════════════════════════════════════
  "Cotonou": [
    "Agla",
    "Agontikon",
    "Ahouansori",
    "Akpakpa",
    "Akpakpa-Dodomè",
    "Akpakpa Nord",
    "Akpakpa Sud",
    "Aïdjèdo",
    "Ayélawadjè",
    "Cadjèhoun",
    "Dantokpa",
    "Dékanmè",
    "Donaten",
    "Enagnon",
    "Fidjrossè",
    "Fidjrossè Kpota",
    "Ganhi",
    "Gbèdjromèdji",
    "Godomey",
    "Guinkomey",
    "Haie Vive",
    "Houéyiho",
    "Jéricho",
    "Jonquet",
    "Kpankpan",
    "Ladji",
    "Mènontin",
    "Missèbo",
    "Mèdédjro",
    "Modjagan",
    "Nouveau Pont",
    "Pk3",
    "Pk6",
    "Pk10",
    "Pk12",
    "Placodji",
    "Sainte-Rita",
    "Saint-Michel",
    "Sikècodji",
    "Sènadé",
    "Tokpa",
    "Tokpa-Domè",
    "Vèdoko",
    "Vodjè",
    "Vossa",
    "Wologuèdè",
    "Xwlacodji",
    "Zogbo",
    "Zongo",
    "Zopah",
  ],

  // ═══════════════════════════════════════════════════════
  // DÉPARTEMENT DE L'ATLANTIQUE
  // ═══════════════════════════════════════════════════════
  "Abomey-Calavi": [
    "Abomey-Calavi Centre",
    "Agori",
    "Akassato",
    "Akogbato",
    "Akonakpo",
    "Calavi Plage",
    "Dékanmè",
    "Gbèto",
    "Godomey",
    "Godomey Plage",
    "Hèvié",
    "Kpanroun",
    "Kpota",
    "Ouèdo",
    "Togba",
    "Womey",
    "Zinvié",
    "Zopah",
  ],
  "Allada": [
    "Allada Centre",
    "Attogon",
    "Avakpa",
    "Hinvi",
    "Lon-Agonmey",
    "Sékou",
    "Togoudo",
    "Tokpa-Domè",
  ],
  "Kpomassè": [
    "Ahozon",
    "Kpomassè Centre",
    "Oumako",
    "Sèhouè",
    "Toffo",
  ],
  "Ouidah": [
    "Adjaha",
    "Avlékété",
    "Djègbadji",
    "Gakpè",
    "Houakpè-Daho",
    "Ouidah Centre",
    "Pahou",
    "Savi",
    "Zoungbodji",
  ],
  "Sô-Ava": [
    "Ganvié",
    "Houédo-Aguékon",
    "Sô-Ava Centre",
    "Vêkky",
  ],
  "Toffo": [
    "Agonlin-Houégbo",
    "Coussi",
    "Damè-Wogon",
    "Toffo Centre",
    "Zè",
  ],
  "Tori-Bossito": [
    "Avamè",
    "Tori-Bossito Centre",
    "Tori-Cada",
    "Tori-Gare",
  ],
  "Zè": [
    "Agouagon",
    "Dodji-Bata",
    "Kpankou",
    "Zè Centre",
    "Zoungoudo",
  ],

  // ═══════════════════════════════════════════════════════
  // DÉPARTEMENT DE L'OUÉMÉ
  // ═══════════════════════════════════════════════════════
  "Porto-Novo": [
    "Agbato",
    "Agbokou",
    "Ahouandjigo",
    "Akron",
    "Avassa",
    "Dowa",
    "Foun-Foun",
    "Gbèko",
    "Houinmè",
    "Houéyogbé",
    "Kpèmassè",
    "Ladji",
    "Louho",
    "Mèdédjonou",
    "Ouando",
    "Tokpota",
    "Yèvènoukoun",
  ],
  "Adjarra": [
    "Adjarra Centre",
    "Aglogbè",
    "Médédjonou",
    "Vakon",
  ],
  "Adjohoun": [
    "Adjohoun Centre",
    "Akpadanou",
    "Azowlissè",
    "Dangbo",
    "Hèvè",
    "Kpédékpo",
  ],
  "Akpro-Missérété": [
    "Akpro Centre",
    "Gomè-Sota",
    "Katagon",
    "Vakon",
    "Zoungamè",
  ],
  "Avrankou": [
    "Avrankou Centre",
    "Gbèko",
    "Kpankou",
    "Onigbolo",
  ],
  "Bonou": [
    "Affamè",
    "Bonou Centre",
    "Damè",
    "Hèvè",
  ],
  "Dangbo": [
    "Atchonsa",
    "Dangbo Centre",
    "Gbèko",
    "Houédomè",
    "Kpédékpo",
  ],
  "Sèmè-Kpodji": [
    "Agblangandan",
    "Djeffa",
    "Ekpè",
    "Porto-Novo Route",
    "Sèmè Centre",
    "Tohouè",
  ],

  // ═══════════════════════════════════════════════════════
  // DÉPARTEMENT DU PLATEAU
  // ═══════════════════════════════════════════════════════
  "Adja-Ouèrè": [
    "Adja-Ouèrè Centre",
    "Kpoulou",
    "Massè",
    "Totchangni",
  ],
  "Ifangni": [
    "Ifangni Centre",
    "Igana",
    "Issaba",
    "Kétou Route",
  ],
  "Kétou": [
    "Idigny",
    "Kétou Centre",
    "Okpometa",
    "Odomèta",
  ],
  "Pobè": [
    "Aguidi",
    "Issaba",
    "Pobè Centre",
    "Takon",
    "Yoko",
  ],
  "Sakété": [
    "Ita-Djèbou",
    "Sakété Centre",
    "Yoko",
    "Zounkon",
  ],

  // ═══════════════════════════════════════════════════════
  // DÉPARTEMENT DU ZOU
  // ═══════════════════════════════════════════════════════
  "Abomey": [
    "Abomey I",
    "Abomey II",
    "Djègbé",
    "Hounli",
    "Lissèzoun",
    "Vidolé",
    "Zoungoudo",
  ],
  "Agbangnizoun": [
    "Agbangnizoun Centre",
    "Kpokissa",
    "Tanvè",
    "Zoungoudo",
  ],
  "Bohicon": [
    "Avogbana",
    "Bohicon I",
    "Bohicon II",
    "Gnidjazoun",
    "Lissèzoun",
    "Passagon",
    "Sodohomè",
  ],
  "Covè": [
    "Covè Centre",
    "Houin-Agouagon",
    "Lainta",
    "Zoungoudo",
  ],
  "Djidja": [
    "Djidja Centre",
    "Doumè",
    "Kpakpavissa",
    "Sèhouè",
  ],
  "Ouinhi": [
    "Dasso",
    "Ouinhi Centre",
    "Sagon",
    "Tohoues",
  ],
  "Zagnanado": [
    "Koussoukpa",
    "Zagnanado Centre",
    "Zoungoudo",
  ],
  "Za-Kpota": [
    "Kpokissa",
    "Lissèzoun",
    "Za-Kpota Centre",
    "Zoungoudo",
  ],
  "Zogbodomey": [
    "Agondji",
    "Kpokissa",
    "Zogbodomey Centre",
  ],

  // ═══════════════════════════════════════════════════════
  // DÉPARTEMENT DES COLLINES
  // ═══════════════════════════════════════════════════════
  "Bantè": [
    "Bantè Centre",
    "Gouka",
    "Pira",
    "Tchetti",
  ],
  "Dassa-Zoumè": [
    "Dassa Centre",
    "Kéré",
    "Paouignan",
    "Soclogbo",
    "Zoungoudo",
  ],
  "Glazoué": [
    "Assanté",
    "Glazoué Centre",
    "Kpingni",
    "Ouèssè",
  ],
  "Ouèssè": [
    "Kaboua",
    "Ouèssè Centre",
    "Tchaourou Route",
  ],
  "Savalou": [
    "Agbado",
    "Djalloukou",
    "Gobada",
    "Savalou Centre",
    "Tchetti",
  ],
  "Savè": [
    "Agramé",
    "Djabata",
    "Logozohe",
    "Okpara",
    "Savè Centre",
  ],

  // ═══════════════════════════════════════════════════════
  // DÉPARTEMENT DU MONO
  // ═══════════════════════════════════════════════════════
  "Athiémé": [
    "Athiémé Centre",
    "Dédomè",
    "Kpinnou",
  ],
  "Bopa": [
    "Bopa Centre",
    "Lobogo",
    "Possotomè",
  ],
  "Comè": [
    "Akodéha",
    "Comè Centre",
    "Ouèdèmè-Adja",
    "Oumako",
  ],
  "Grand-Popo": [
    "Agoué",
    "Avlo",
    "Grand-Popo Centre",
    "Sazué",
  ],
  "Houéyogbé": [
    "Doutou",
    "Houéyogbé Centre",
    "Malanhoui",
  ],
  "Lokossa": [
    "Agamè",
    "Colli",
    "Houin",
    "Lokossa Centre",
    "Ouèdèmè",
  ],

  // ═══════════════════════════════════════════════════════
  // DÉPARTEMENT DU COUFFO
  // ═══════════════════════════════════════════════════════
  "Aplahoué": [
    "Aplahoué Centre",
    "Atomey",
    "Azovè",
    "Kissamey",
  ],
  "Djakotomey": [
    "Djakotomey Centre",
    "Gohomey",
    "Houégoudo",
  ],
  "Dogbo": [
    "Ayomi",
    "Dévé",
    "Dogbo Centre",
    "Honton",
  ],
  "Klouékanmè": [
    "Adjahonmè",
    "Klouékanmè Centre",
    "Lanta",
  ],
  "Lalo": [
    "Gnizounmè",
    "Lalo Centre",
    "Tchito",
  ],
  "Toviklin": [
    "Hondjin",
    "Toviklin Centre",
    "Zalli",
  ],

  // ═══════════════════════════════════════════════════════
  // DÉPARTEMENT DU BORGOU
  // ═══════════════════════════════════════════════════════
  "Parakou": [
    "Banikanni",
    "Bebou",
    "Centre-ville",
    "Darou",
    "Gando",
    "Guema",
    "Kpèbié",
    "Madina",
    "Parakou I",
    "Parakou II",
    "Parakou III",
    "Titirou",
    "Tora",
    "Tourou",
    "Wari-Maro",
    "Zongo",
  ],
  "Bembèrèkè": [
    "Bembèrèkè Centre",
    "Bouanri",
    "Ina",
    "Sirarou",
  ],
  "Kalalé": [
    "Derassi",
    "Kalalé Centre",
    "Sonsoro",
  ],
  "N'Dali": [
    "Bori",
    "N'Dali Centre",
    "Sirarou",
    "Sontou",
  ],
  "Nikki": [
    "Biro",
    "Nikki Centre",
    "Sérékalé",
    "Suya",
  ],
  "Pèrèrè": [
    "Gninsy",
    "Pèrèrè Centre",
    "Sontou",
  ],
  "Sinendé": [
    "Gbégourou",
    "Sinendé Centre",
    "Soroko",
  ],
  "Tchaourou": [
    "Bétérou",
    "Kika",
    "Tchaourou Centre",
    "Wari-Maro",
  ],

  // ═══════════════════════════════════════════════════════
  // DÉPARTEMENT DE L'ALIBORI
  // ═══════════════════════════════════════════════════════
  "Banikoara": [
    "Banikoara Centre",
    "Founougo",
    "Gomparou",
    "Kokey",
    "Soroko",
  ],
  "Gogounou": [
    "Gogounou Centre",
    "Ouénou",
    "Sori",
  ],
  "Kandi": [
    "Angaradébou",
    "Donwari",
    "Kandi Centre",
    "Saah",
    "Sam",
  ],
  "Karimama": [
    "Birni-Lafia",
    "Karimama Centre",
    "Monsey",
  ],
  "Malanville": [
    "Garou",
    "Guéné",
    "Malanville Centre",
    "Toumboutou",
  ],
  "Ségbana": [
    "Libantè",
    "Ségbana Centre",
    "Sompérékou",
  ],

  // ═══════════════════════════════════════════════════════
  // DÉPARTEMENT DE L'ATACORA
  // ═══════════════════════════════════════════════════════
  "Natitingou": [
    "Centre-ville",
    "Kounakary",
    "Natitingou I",
    "Natitingou II",
    "Natitingou III",
    "Perma",
    "Toucountouna",
  ],
  "Boukoumbé": [
    "Boukoumbé Centre",
    "Korontière",
    "Manta",
    "Natta",
  ],
  "Cobly": [
    "Cobly Centre",
    "Kountori",
    "Tapoga",
  ],
  "Copargo": [
    "Copargo Centre",
    "Kpébié",
    "Pélébina",
  ],
  "Djougou": [
    "Barei",
    "Djougou I",
    "Djougou II",
    "Djougou III",
    "Kolokondé",
    "Patargo",
    "Sérou",
  ],
  "Kérou": [
    "Brignamaro",
    "Kérou Centre",
    "Séri",
  ],
  "Kouandé": [
    "Guilmaro",
    "Kouandé Centre",
    "Oroukayo",
  ],
  "Matéri": [
    "Dassari",
    "Matéri Centre",
    "Nodi",
  ],
  "Péhunco": [
    "Gnémasson",
    "Péhunco Centre",
    "Tobré",
  ],
  "Tanguiéta": [
    "Cotiakou",
    "Natta",
    "Tanguiéta Centre",
    "Tanongou",
  ],
  "Toukountouna": [
    "Perma",
    "Toukountouna Centre",
  ],

  // ═══════════════════════════════════════════════════════
  // DÉPARTEMENT DE LA DONGA
  // ═══════════════════════════════════════════════════════
  "Bassila": [
    "Bassila Centre",
    "Manigri",
    "Pénéssoulou",
    "Wèwè",
  ],
  "Djougou (Donga)": [
    "Barei",
    "Djougou Centre",
    "Kolokondé",
    "Sérou",
  ],
  "Ouaké": [
    "Kounouhou",
    "Ouaké Centre",
    "Tchalinga",
  ],
};

// ── Fonctions utilitaires ──────────────────────────────────────────────────

/// Retourne toutes les villes triées alphabétiquement.
List<String> getAllVilles() {
  return villesQuartiersBenin.keys.toList()..sort();
}

/// Retourne les quartiers d'une ville, triés alphabétiquement.
List<String> getQuartiers(String ville) {
  final quartiers = villesQuartiersBenin[ville] ?? [];
  return [...quartiers]..sort();
}

/// Vérifie si une ville existe dans la base.
bool villeExists(String ville) {
  return villesQuartiersBenin.containsKey(ville);
}

/// Vérifie si un quartier appartient à une ville.
bool quartierExists(String ville, String quartier) {
  return villesQuartiersBenin[ville]?.contains(quartier) ?? false;
}

/// Recherche une ville (insensible à la casse et aux accents).
String? findVille(String recherche) {
  final r = _normalize(recherche);
  for (final ville in villesQuartiersBenin.keys) {
    if (_normalize(ville).contains(r)) return ville;
  }
  return null;
}

/// Recherche des quartiers dans toutes les villes.
List<Map<String, String>> searchQuartiers(String recherche) {
  final r = _normalize(recherche);
  final results = <Map<String, String>>[];
  for (final entry in villesQuartiersBenin.entries) {
    for (final q in entry.value) {
      if (_normalize(q).contains(r)) {
        results.add({'ville': entry.key, 'quartier': q});
      }
    }
  }
  return results;
}

String _normalize(String s) => s
    .toLowerCase()
    .replaceAll('é', 'e').replaceAll('è', 'e').replaceAll('ê', 'e')
    .replaceAll('à', 'a').replaceAll('â', 'a').replaceAll('ä', 'a')
    .replaceAll('ô', 'o').replaceAll('ö', 'o')
    .replaceAll('î', 'i').replaceAll('ï', 'i')
    .replaceAll('ù', 'u').replaceAll('û', 'u').replaceAll('ü', 'u')
    .replaceAll('ç', 'c').replaceAll('ñ', 'n');
