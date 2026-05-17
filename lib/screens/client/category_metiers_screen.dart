import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/metiers_data.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';

/// Liste des métiers d'une catégorie, puis navigation vers la recherche d'artisans.
class CategoryMetiersScreen extends StatelessWidget {
  final String categorie;
  final String? initialVille;

  const CategoryMetiersScreen({
    super.key,
    required this.categorie,
    this.initialVille,
  });

  List<String> get _metiers => getMetiersByCategorie(categorie);

  @override
  Widget build(BuildContext context) {
    final metiers = _metiers;
    final titre = categorie.trim().isEmpty ? 'Catégorie' : categorie;

    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          titre,
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: metiers.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.category_outlined,
                        size: 64, color: AppColors.greyDark),
                    const SizedBox(height: 16),
                    Text(
                      'Catégorie introuvable',
                      style:
                          AppTextStyles.h3.copyWith(color: AppColors.onSurface),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Choisissez une autre catégorie depuis l'accueil.",
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.greyDark),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: categoryImageUrl(categorie),
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: AppColors.primaryBlue.withValues(alpha: 0.12),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.primaryBlue.withValues(alpha: 0.12),
                                child: Icon(
                                  categoryIcon(categorie),
                                  size: 48,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                            Container(
                              color: Colors.black.withValues(alpha: 0.38),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  Icon(
                                    categoryIcon(categorie),
                                    color: AppColors.white,
                                    size: 36,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      titre,
                                      style: AppTextStyles.h2.copyWith(
                                        color: AppColors.white,
                                        fontSize: 20,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.55),
                                            offset: const Offset(0, 1),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final m = metiers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _MetierListingCard(
                            nom: m,
                            onTap: () => context.push(
                              '${AppRouter.searchArtisan}?metier=${Uri.encodeComponent(m)}'
                              '&ville=${Uri.encodeComponent(initialVille ?? '')}',
                            ),
                          ),
                        );
                      },
                      childCount: metiers.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MetierListingCard extends StatelessWidget {
  final String nom;
  final VoidCallback onTap;

  const _MetierListingCard({
    required this.nom,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.work_outline_rounded,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.onSurface,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Voir les artisans',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.greyDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primaryBlue,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
