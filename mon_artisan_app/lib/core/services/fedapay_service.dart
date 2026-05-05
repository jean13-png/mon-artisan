import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class FedaPayService {
  static const String apiKey = AppConstants.fedapayApiKey;
  static const String baseUrl = AppConstants.fedapayBaseUrl;
  static const double commissionRate = AppConstants.commissionRate;

  // Créer une transaction
  static Future<Map<String, dynamic>> createTransaction({
    required double amount,
    required String description,
    required String customerEmail,
    required String customerPhone,
    required String commandeId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'description': description,
          'amount': amount,
          'currency': {'iso': 'XOF'},
          'callback_url': 'https://yourapp.com/payment/callback',
          'customer': {
            'email': customerEmail,
            'phone_number': {'number': customerPhone, 'country': 'BJ'},
          },
          'custom_metadata': {
            'commande_id': commandeId,
          },
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors de la création de la transaction');
      }
    } catch (e) {
      throw Exception('Erreur FedaPay: $e');
    }
  }

  // Vérifier le statut d'une transaction
  static Future<String> checkTransactionStatus(String transactionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/$transactionId'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['v1']['status'] ?? 'unknown';
      } else {
        throw Exception('Erreur lors de la vérification du statut');
      }
    } catch (e) {
      throw Exception('Erreur FedaPay: $e');
    }
  }

  // Calculer la commission
  static double calculateCommission(double montant) {
    return montant * commissionRate;
  }

  // Calculer le montant artisan
  static double calculateArtisanAmount(double montant) {
    return montant - calculateCommission(montant);
  }
}
