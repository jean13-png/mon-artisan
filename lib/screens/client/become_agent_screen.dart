import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/auth_provider.dart';

class BecomeAgentScreen extends StatefulWidget {
  const BecomeAgentScreen({super.key});

  @override
  State<BecomeAgentScreen> createState() => _BecomeAgentScreenState();
}

class _BecomeAgentScreenState extends State<BecomeAgentScreen> {
  bool _isLoading = false;
  bool _acceptedConditions = false;

  Future<void> _submitRequest() async {
    if (!_acceptedConditions) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.userModel;

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.id).update({
          'agentStatus': 'pending',
          'agentRequestDate': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Demande envoyée !'),
              content: const Text('Votre demande pour devenir agent commercial a été soumise. L\'administrateur va l\'étudier et vous recevrez une notification sous peu.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devenir Agent Commercial'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.business_center, size: 64, color: AppColors.primaryBlue),
            const SizedBox(height: 24),
            Text('Rejoignez notre équipe de prospection !', style: AppTextStyles.h2),
            const SizedBox(height: 16),
            const Text(
              'En tant qu\'agent commercial, votre mission est de prospecter et d\'inscrire de nouveaux artisans sur la plateforme.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            _buildConditionItem(Icons.check_circle_outline, 'Gagnez 300 FCFA sur chaque inscription d\'artisan payée.'),
            _buildConditionItem(Icons.check_circle_outline, 'Bénéficiez d\'un code promo personnalisé à partager.'),
            _buildConditionItem(Icons.check_circle_outline, 'Suivez vos revenus et vos performances en temps réel.'),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptedConditions,
                        onChanged: (v) => setState(() => _acceptedConditions = v ?? false),
                        activeColor: AppColors.primaryBlue,
                      ),
                      const Expanded(
                        child: Text('J\'accepte les conditions de partenariat agent commercial.'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _acceptedConditions && !_isLoading ? _submitRequest : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: AppColors.white)
                  : const Text('Envoyer ma demande', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.success, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
