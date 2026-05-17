class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide';
    }
    return null;
  }

  // Phone validation (Benin format - 10 chiffres)
  // Accepte: 01XXXXXXXX, 229 01XXXXXXXX, +229 01XXXXXXXX, +22901XXXXXXXX
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de téléphone est requis';
    }
    
    // Enlever les espaces et le signe +
    String cleanedPhone = value.replaceAll(' ', '').replaceAll('+', '');
    
    // Vérifier si commence par 229 (indicatif Bénin)
    if (cleanedPhone.startsWith('229')) {
      cleanedPhone = cleanedPhone.substring(3); // Enlever le 229
    }
    
    // Doit avoir exactement 10 chiffres et commencer par 01, 40-69, 90-97
    final phoneRegex = RegExp(r'^(01|4[0-9]|5[0-9]|6[0-9]|9[0-7])[0-9]{8}$');
    
    if (!phoneRegex.hasMatch(cleanedPhone)) {
      return 'Numéro invalide. Format: 01XXXXXXXX ou 229 01XXXXXXXX';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ce champ est requis';
    }
    if (value.length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Ce champ'} est requis';
    }
    return null;
  }

  // Amount validation
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le montant est requis';
    }
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Montant invalide';
    }
    return null;
  }
}
