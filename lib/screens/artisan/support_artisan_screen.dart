import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/services/firebase_service.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/logger.dart';

class SupportArtisanScreen extends StatefulWidget {
  const SupportArtisanScreen({super.key});

  @override
  State<SupportArtisanScreen> createState() => _SupportArtisanScreenState();
}

class _SupportArtisanScreenState extends State<SupportArtisanScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _envoyerMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final artisanId = authProvider.userModel?.id;
    if (artisanId == null) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseService.firestore.collection('support_messages').add({
        'artisanId': artisanId,
        'message': message,
        'createdAt': Timestamp.now(),
        'status': 'nouveau',
        'reponse': '',
        'reponseAt': null,
      });

      _messageController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message envoyé au support. Nous vous répondrons sous peu.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      Logger.error('Erreur envoi message support', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final artisanId = authProvider.userModel?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Text(
          'Contacter le support',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.support_agent, color: AppColors.primaryBlue, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Support technique',
                                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Nous sommes là pour vous aider',
                                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyDark),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Décrivez votre problème ou votre question. Notre équipe vous répondra dans les plus brefs délais.',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.greyDark),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (artisanId != null)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseService.firestore
                          .collection('support_messages')
                          .where('artisanId', isEqualTo: artisanId)
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.greyMedium),
                                const SizedBox(height: 16),
                                Text('Aucun message', style: AppTextStyles.bodyLarge),
                              ],
                            ),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            final message = data['message'] ?? '';
                            final reponse = data['reponse'] ?? '';
                            final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                            final reponseAt = (data['reponseAt'] as Timestamp?)?.toDate();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.black.withOpacity(0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 16,
                                        color: AppColors.greyDark,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Vous',
                                        style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      const Spacer(),
                                      Text(
                                        DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
                                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyDark, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(message, style: AppTextStyles.bodyMedium),
                                  if (reponse.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.success.withOpacity(0.25)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.support_agent, size: 16, color: AppColors.success),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Réponse du support',
                                                style: AppTextStyles.bodySmall.copyWith(
                                                  color: AppColors.success,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              if (reponseAt != null) ...[
                                                const Spacer(),
                                                Text(
                                                  DateFormat('dd/MM/yyyy HH:mm').format(reponseAt),
                                                  style: AppTextStyles.bodySmall.copyWith(
                                                    color: AppColors.greyDark,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(reponse, style: AppTextStyles.bodyMedium.copyWith(color: Colors.black87)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Décrivez votre problème...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.greyLight,
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _isLoading ? null : _envoyerMessage,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.send, color: AppColors.primaryBlue),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
