import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/firebase_service.dart';
import '../../providers/auth_provider.dart';
import '../../models/artisan_model.dart';
import '../../widgets/artisan_card.dart';
import '../../widgets/loading_widget.dart';

class FavorisScreen extends StatefulWidget {
  const FavorisScreen({super.key});

  @override
  State<FavorisScreen> createState() => _FavorisScreenState();
}

class _FavorisScreenState extends State<FavorisScreen> {
  List<ArtisanModel> _favoris = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoris();
  }

  Future<void> _loadFavoris() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userModel!.id;

      final favSnapshot = await FirebaseService.firestore
          .collection('favoris')
          .where('clientId', isEqualTo: userId)
          .get();

      final artisanIds = favSnapshot.docs
          .map((doc) => doc['artisanId'] as String)
          .toList();

      if (artisanIds.isEmpty) {
        setState(() {
          _favoris = [];
          _isLoading = false;
        });
        return;
      }

      final artisansSnapshot = await FirebaseService.firestore
          .collection('artisans')
          .where(FieldPath.documentId, whereIn: artisanIds)
          .get();

      setState(() {
        _favoris = artisansSnapshot.docs
            .map((doc) => ArtisanModel.fromFirestore(doc))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _removeFavori(String artisanId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userModel!.id;

      final snapshot = await FirebaseService.firestore
          .collection('favoris')
          .where('clientId', isEqualTo: userId)
          .where('artisanId', isEqualTo: artisanId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      await _loadFavoris();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Retiré des favoris'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Mes favoris',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Chargement...')
          : _favoris.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: AppColors.greyMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun favori',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.greyDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajoutez des artisans à vos favoris',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.greyMedium,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFavoris,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _favoris.length,
                    itemBuilder: (context, index) {
                      final artisan = _favoris[index];
                      return Dismissible(
                        key: Key(artisan.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: AppColors.white,
                          ),
                        ),
                        onDismissed: (direction) {
                          _removeFavori(artisan.id);
                        },
                        child: ArtisanCard(
                          artisan: artisan,
                          onTap: () {
                            context.push(AppRouter.artisanProfile, extra: artisan);
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
