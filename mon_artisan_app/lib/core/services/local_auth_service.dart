import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class LocalAuthService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  // Clés pour SharedPreferences
  static const String _keyPinCode = 'user_pin_code';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyAuthConfigured = 'auth_configured';
  static const String _keyUserId = 'user_id';

  /// Vérifier si l'authentification locale est configurée
  static Future<bool> isAuthConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAuthConfigured) ?? false;
  }

  /// Sauvegarder le code PIN (6 chiffres)
  static Future<void> savePinCode(String pin) async {
    if (pin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw Exception('Le code PIN doit contenir exactement 6 chiffres');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPinCode, pin);
    await prefs.setBool(_keyAuthConfigured, true);
  }

  /// Vérifier le code PIN
  static Future<bool> verifyPinCode(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(_keyPinCode);
    return savedPin == pin;
  }

  /// Activer/Désactiver la biométrie
  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, enabled);
  }

  /// Vérifier si la biométrie est activée
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  /// Vérifier si la biométrie est disponible sur l'appareil
  static Future<bool> canUseBiometric() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      return false;
    }
  }

  /// Authentifier avec la biométrie
  static Future<bool> authenticateWithBiometric() async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Utilisez votre empreinte digitale pour vous connecter',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Erreur biométrique: ${e.message}');
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Sauvegarder l'ID utilisateur
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
  }

  /// Récupérer l'ID utilisateur
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  /// Réinitialiser toute l'authentification locale
  static Future<void> clearLocalAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPinCode);
    await prefs.remove(_keyBiometricEnabled);
    await prefs.remove(_keyAuthConfigured);
    await prefs.remove(_keyUserId);
  }

  /// Configuration complète de l'authentification locale
  static Future<void> setupLocalAuth({
    required String pin,
    required bool enableBiometric,
    required String userId,
  }) async {
    await savePinCode(pin);
    await setBiometricEnabled(enableBiometric);
    await saveUserId(userId);
  }
}
