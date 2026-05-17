import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class FedaPayService {
  static final String apiKey = AppConstants.fedapayApiKey;
  static final String baseUrl = AppConstants.fedapayBaseUrl;
  static final double commissionRate = AppConstants.commissionRate;

  // Créer une transaction
  static Future<Map<String, dynamic>> createTransaction({
    required double amount,
    required String description,
    required String customerEmail,
    required String customerPhone,
    required String commandeId,
  }) async {
    // ✅ MODE SIMULATION pour tester sans vraie API
    if (AppConstants.simulateFedaPay) {
      print('[FEDAPAY SIMULATION] Transaction simulée');
      print('[FEDAPAY SIMULATION] Montant: $amount XOF');
      
      await Future.delayed(const Duration(seconds: 2)); // Simuler délai réseau
      
      return {
        'v1': {
          'id': 'sim_${DateTime.now().millisecondsSinceEpoch}',
          'url': 'https://checkout.fedapay.com/simulation',
          'status': 'pending',
          'amount': amount,
          'description': description,
        }
      };
    }
    
    try {
      print('[FEDAPAY] Création transaction...');
      print('[FEDAPAY] Montant: $amount XOF');
      print('[FEDAPAY] Email: $customerEmail');
      print('[FEDAPAY] Téléphone: $customerPhone');
      
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

      print('[FEDAPAY] Status code: ${response.statusCode}');
      print('[FEDAPAY] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // ✅ Vérifier que la réponse contient les données attendues
        if (data == null) {
          throw Exception('Réponse FedaPay vide');
        }
        
        if (data['v1'] == null) {
          throw Exception('Format de réponse FedaPay invalide: ${response.body}');
        }
        
        if (data['v1']['id'] == null) {
          throw Exception('ID transaction manquant dans la réponse FedaPay');
        }
        
        print('[FEDAPAY] Transaction créée: ${data['v1']['id']}');
        return data;
      } else {
        print('[FEDAPAY ERROR] ${response.statusCode}: ${response.body}');
        throw Exception('Erreur FedaPay (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('[FEDAPAY ERROR] Exception: $e');
      throw Exception('Erreur FedaPay: $e');
    }
  }

  // Vérifier le statut d'une transaction
  static Future<String> checkTransactionStatus(String transactionId) async {
    // ✅ MODE SIMULATION
    if (AppConstants.simulateFedaPay) {
      print('[FEDAPAY SIMULATION] Vérification statut: $transactionId');
      await Future.delayed(const Duration(seconds: 1));
      return 'approved'; // Simuler succès
    }
    
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
