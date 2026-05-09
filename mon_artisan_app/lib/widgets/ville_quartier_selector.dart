import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../core/constants/villes_benin.dart';

/// Widget réutilisable pour sélectionner une ville + quartier.
///
/// - La ville est saisie avec autocomplétion (Autocomplete).
/// - Les quartiers sont proposés en dropdown avec "Autre" en bas.
/// - Si "Autre" est choisi, un champ texte libre apparaît.
/// - La ville saisie librement est acceptée si elle n'est pas dans la liste.
class VilleQuartierSelector extends StatefulWidget {
  final String? initialVille;
  final String? initialQuartier;
  final void Function(String ville, String quartier) onChanged;
  final bool required;

  const VilleQuartierSelector({
    super.key,
    this.initialVille,
    this.initialQuartier,
    required this.onChanged,
    this.required = true,
  });

  @override
  State<VilleQuartierSelector> createState() => _VilleQuartierSelectorState();
}

class _VilleQuartierSelectorState extends State<VilleQuartierSelector> {
  final _villeController = TextEditingController();
  final _quartierAutreController = TextEditingController();

  String? _selectedVille;
  String? _selectedQuartier;
  List<String> _quartiersDispo = [];
  bool _quartierAutre = false; // "Autre" sélectionné

  static const String _autreLabel = 'Autre (saisir manuellement)';

  @override
  void initState() {
    super.initState();
    if (widget.initialVille != null) {
      _selectedVille = widget.initialVille;
      _villeController.text = widget.initialVille!;
      _quartiersDispo = getQuartiers(widget.initialVille!);
    }
    if (widget.initialQuartier != null) {
      final q = widget.initialQuartier!;
      if (_quartiersDispo.contains(q)) {
        _selectedQuartier = q;
      } else if (q.isNotEmpty) {
        _quartierAutre = true;
        _quartierAutreController.text = q;
        _selectedQuartier = q;
      }
    }
  }

  @override
  void dispose() {
    _villeController.dispose();
    _quartierAutreController.dispose();
    super.dispose();
  }

  void _onVilleSelected(String ville) {
    setState(() {
      _selectedVille = ville;
      _villeController.text = ville;
      _selectedQuartier = null;
      _quartierAutre = false;
      _quartierAutreController.clear();
      _quartiersDispo = getQuartiers(ville);
    });
    _notify();
  }

  void _onQuartierChanged(String? value) {
    if (value == _autreLabel) {
      setState(() {
        _quartierAutre = true;
        _selectedQuartier = null;
      });
    } else {
      setState(() {
        _quartierAutre = false;
        _selectedQuartier = value;
      });
      _notify();
    }
  }

  void _onQuartierAutreChanged(String value) {
    setState(() => _selectedQuartier = value.trim());
    _notify();
  }

  void _notify() {
    if (_selectedVille != null && _selectedVille!.isNotEmpty &&
        _selectedQuartier != null && _selectedQuartier!.isNotEmpty) {
      widget.onChanged(_selectedVille!, _selectedQuartier!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allVilles = getAllVilles();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Ville avec autocomplétion ──────────────────────────────────────
        _label('Ville${widget.required ? ' *' : ''}'),
        const SizedBox(height: 8),
        Autocomplete<String>(
          initialValue: TextEditingValue(text: widget.initialVille ?? ''),
          optionsBuilder: (TextEditingValue textEditingValue) {
            final query = _normalize(textEditingValue.text);
            if (query.isEmpty) return allVilles;
            return allVilles.where((v) => _normalize(v).contains(query));
          },
          displayStringForOption: (v) => v,
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            // Synchroniser le controller interne avec le nôtre
            if (controller.text != _villeController.text &&
                _villeController.text.isNotEmpty) {
              controller.text = _villeController.text;
            }
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: _inputDecoration(
                hint: 'Tapez votre ville...',
                icon: Icons.location_city,
              ),
              validator: widget.required
                  ? (v) => (v == null || v.trim().isEmpty)
                      ? 'Veuillez indiquer votre ville'
                      : null
                  : null,
              onChanged: (value) {
                // Accepter la saisie libre (ville hors liste)
                setState(() {
                  _selectedVille = value.trim();
                  _selectedQuartier = null;
                  _quartierAutre = false;
                  _quartierAutreController.clear();
                  // Charger les quartiers si la ville est connue
                  _quartiersDispo = getQuartiers(value.trim());
                });
                _notify();
              },
            );
          },
          onSelected: _onVilleSelected,
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.location_city,
                                  size: 18, color: AppColors.greyDark),
                              const SizedBox(width: 12),
                              Text(option, style: AppTextStyles.bodyMedium),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // ── Quartier ───────────────────────────────────────────────────────
        _label('Quartier${widget.required ? ' *' : ''}'),
        const SizedBox(height: 4),

        if (_selectedVille == null || _selectedVille!.isEmpty)
          // Ville pas encore saisie
          _disabledField('Sélectionnez d\'abord une ville')
        else if (_quartiersDispo.isEmpty)
          // Ville hors liste → saisie libre directe
          _champLibreQuartier(hint: 'Entrez votre quartier')
        else ...[
          // Ville connue → dropdown + "Autre"
          DropdownButtonFormField<String>(
            value: _quartierAutre ? _autreLabel : _selectedQuartier,
            isExpanded: true,
            decoration: _inputDecoration(
              hint: 'Sélectionnez votre quartier',
              icon: Icons.location_on_outlined,
            ),
            items: [
              ..._quartiersDispo.map(
                (q) => DropdownMenuItem(value: q, child: Text(q)),
              ),
              // Séparateur visuel
              const DropdownMenuItem(
                enabled: false,
                child: Divider(height: 1),
              ),
              // Option "Autre"
              DropdownMenuItem(
                value: _autreLabel,
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined,
                        size: 18, color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    Text(
                      'Autre (saisir manuellement)',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryBlue,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            validator: widget.required
                ? (v) => (v == null || v.isEmpty)
                    ? 'Veuillez sélectionner un quartier'
                    : null
                : null,
            onChanged: _onQuartierChanged,
          ),

          // Champ texte libre si "Autre" sélectionné
          if (_quartierAutre) ...[
            const SizedBox(height: 12),
            _champLibreQuartier(
              hint: 'Précisez votre quartier',
              autofocus: true,
            ),
          ],
        ],

        // Compteur de quartiers disponibles
        if (_selectedVille != null &&
            _selectedVille!.isNotEmpty &&
            _quartiersDispo.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${_quartiersDispo.length} quartiers disponibles pour $_selectedVille',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.greyDark),
            ),
          ),
      ],
    );
  }

  Widget _champLibreQuartier({required String hint, bool autofocus = false}) {
    return TextFormField(
      controller: _quartierAutreController,
      autofocus: autofocus,
      decoration: _inputDecoration(hint: hint, icon: Icons.location_on_outlined),
      validator: widget.required
          ? (v) => (v == null || v.trim().isEmpty)
              ? 'Veuillez indiquer votre quartier'
              : null
          : null,
      onChanged: _onQuartierAutreChanged,
    );
  }

  Widget _disabledField(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.greyMedium),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined,
              color: AppColors.greyMedium, size: 20),
          const SizedBox(width: 12),
          Text(text,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.greyMedium)),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
      );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.greyMedium),
        prefixIcon: Icon(icon, color: AppColors.greyDark, size: 20),
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.greyMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.greyMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      );

  String _normalize(String s) => s
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ô', 'o')
      .replaceAll('î', 'i')
      .replaceAll('ù', 'u')
      .replaceAll('û', 'u')
      .replaceAll('ç', 'c');
}
