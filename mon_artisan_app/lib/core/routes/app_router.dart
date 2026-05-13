import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../screens/shared/splash_screen.dart';
import '../../screens/auth/role_selection_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/contrat_engagement_screen.dart';
import '../../screens/auth/artisan_payment_screen.dart';
import '../../screens/client/home_client_screen.dart';
import '../../screens/client/category_metiers_screen.dart';
import '../../screens/client/search_artisan_screen.dart';
import '../../screens/client/artisan_profile_screen.dart';
import '../../screens/client/select_commande_type_screen.dart';
import '../../screens/client/create_commande_screen.dart';
import '../../screens/client/payment_screen.dart';
import '../../screens/artisan/home_artisan_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/artisans_validation_screen.dart';
import '../../screens/admin/agents_management_screen.dart';
import '../../screens/admin/users_management_screen.dart';
import '../../screens/admin/admin_reports_screen.dart';
import '../../screens/admin/admin_transactions_screen.dart';
import '../../screens/artisan/commande_detail_screen.dart';
import '../../screens/artisan/revenus_screen.dart';
import '../../screens/artisan/complete_profile_screen.dart';
import '../../screens/client/commandes_history_screen.dart';
import '../../screens/client/rate_artisan_screen.dart';
import '../../screens/shared/notifications_screen.dart';
import '../../screens/shared/edit_profile_screen.dart';
import '../../screens/shared/settings_screen.dart';
import '../../screens/shared/chat_screen.dart';
import '../../screens/shared/location_picker_screen.dart';
import '../../screens/shared/privacy_policy_screen.dart';
import '../../screens/shared/terms_of_use_screen.dart';
import '../../models/artisan_model.dart';
import '../../models/commande_model.dart';

class AppRouter {
  // ── Routes publiques ───────────────────────────────────────────────────────
  static const String splash = '/';
  static const String roleSelection = '/role-selection';
  static const String login = '/login';
  static const String register = '/register';
  static const String contratEngagement = '/contrat-engagement';
  static const String artisanPayment = '/artisan-payment';

  // ── Routes protégées : client ──────────────────────────────────────────────
  static const String homeClient = '/home-client';
  static const String categoryMetiers = '/category-metiers';
  static const String searchArtisan = '/search-artisan';
  static const String artisanProfile = '/artisan-profile';
  static const String selectCommandeType = '/select-commande-type';
  static const String createCommande = '/create-commande';
  static const String payment = '/payment';
  static const String commandesHistory = '/commandes-history';
  static const String rateArtisan = '/rate-artisan';
  static const String locationPicker = '/location-picker';


  // ── Routes protégées : artisan ─────────────────────────────────────────────
  static const String homeArtisan = '/home-artisan';
  static const String commandeDetail = '/commande-detail';
  static const String revenus = '/revenus';
  static const String completeProfile = '/complete-profile';

  // ── Routes protégées : admin ───────────────────────────────────────────────
  static const String adminDashboard = '/admin-dashboard';
  static const String adminValidateArtisans = '/admin/validate-artisans';
  static const String adminManageAgents = '/admin/manage-agents';
  static const String adminManageUsers = '/admin/manage-users';
  static const String adminReports = '/admin/reports';
  static const String adminTransactions = '/admin/transactions';

  // ── Routes protégées : communes ────────────────────────────────────────────
  static const String notifications = '/notifications';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';
  static const String chat = '/chat';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfUse = '/terms-of-use';

  // ── Ensembles de routes par niveau d'accès ────────────────────────────────
  static const _publicRoutes = {
    splash, roleSelection, login, register, contratEngagement, artisanPayment, privacyPolicy, termsOfUse,
  };
  static const _adminRoutes = {
    adminDashboard, adminValidateArtisans, adminManageAgents, adminManageUsers, adminReports, adminTransactions,
  };
  static const _clientRoutes = {
    homeClient, categoryMetiers, searchArtisan, artisanProfile, selectCommandeType,
    createCommande, payment, commandesHistory, rateArtisan, locationPicker,
  };
  static const _artisanRoutes = {
    homeArtisan, commandeDetail, revenus, completeProfile,
  };

  // ── Factory ───────────────────────────────────────────────────────────────
  static GoRouter create(AuthProvider authProvider) => GoRouter(
    initialLocation: splash,
    refreshListenable: authProvider,
    // Utiliser uri.path : matchedLocation peut être obsolète pendant la résolution
    // (et GoRouter du hot reload peut rester sans les routes nouvellement ajoutées — redémarrage complet conseillé).
    redirect: (context, state) => _guard(authProvider, state.uri.path),
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: roleSelection,
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: register,
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'client';
          return RegisterScreen(role: role);
        },
      ),
      GoRoute(
        path: contratEngagement,
        builder: (context, state) => const ContratEngagementScreen(),
      ),
      GoRoute(
        path: artisanPayment,
        builder: (context, state) {
          final codeAgent = state.uri.queryParameters['codeAgent'] ?? '';
          return ArtisanPaymentScreen(codeAgent: codeAgent);
        },
      ),
      GoRoute(
        path: homeClient,
        builder: (context, state) => const HomeClientScreen(),
      ),
      GoRoute(
        path: homeArtisan,
        builder: (context, state) => const HomeArtisanScreen(),
      ),
      GoRoute(
        path: adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: adminValidateArtisans,
        builder: (context, state) => const ArtisansValidationScreen(),
      ),
      GoRoute(
        path: adminManageAgents,
        builder: (context, state) => const AgentsManagementScreen(),
      ),
      GoRoute(
        path: adminManageUsers,
        builder: (context, state) => const UsersManagementScreen(),
      ),
      GoRoute(
        path: adminReports,
        builder: (context, state) => const AdminReportsScreen(),
      ),
      GoRoute(
        path: adminTransactions,
        builder: (context, state) => const AdminTransactionsScreen(),
      ),
      GoRoute(
        path: categoryMetiers,
        builder: (context, state) {
          final p = state.uri.queryParameters;
          return CategoryMetiersScreen(
            categorie: p['categorie'] ?? '',
            initialVille: p['ville'],
          );
        },
      ),
      GoRoute(
        path: searchArtisan,
        builder: (context, state) {
          final p = state.uri.queryParameters;
          return SearchArtisanScreen(
            metier: p['metier'],
            categorie: p['categorie'],
            ville: p['ville'],
            quartier: p['quartier'],
            query: p['query'],
            rayon: int.tryParse(p['rayon'] ?? '50') ?? 50,
          );
        },
      ),
      // C7 — Casts sécurisés : state.extra peut être null (deep-link, rechargement)
      GoRoute(
        path: artisanProfile,
        builder: (context, state) {
          final artisan = state.extra as ArtisanModel?;
          if (artisan == null) return const _ErrorScreen(message: 'Artisan introuvable');
          return ArtisanProfileScreen(artisan: artisan);
        },
      ),
      GoRoute(
        path: selectCommandeType,
        builder: (context, state) {
          final artisan = state.extra as ArtisanModel?;
          if (artisan == null) return const _ErrorScreen(message: 'Artisan introuvable');
          return SelectCommandeTypeScreen(artisan: artisan);
        },
      ),
      GoRoute(
        path: createCommande,
        builder: (context, state) {
          final artisan = state.extra as ArtisanModel?;
          if (artisan == null) return const _ErrorScreen(message: 'Artisan introuvable');
          return CreateCommandeScreen(artisan: artisan);
        },
      ),
      GoRoute(
        path: payment,
        builder: (context, state) {
          final commandeId = state.uri.queryParameters['commandeId'] ?? '';
          final montant = state.uri.queryParameters['montant'] ?? '0';
          return PaymentScreen(commandeId: commandeId, montant: montant);
        },
      ),
      GoRoute(
        path: commandeDetail,
        builder: (context, state) {
          final commande = state.extra as CommandeModel?;
          if (commande == null) return const _ErrorScreen(message: 'Commande introuvable');
          return CommandeDetailScreen(commande: commande);
        },
      ),
      GoRoute(
        path: commandesHistory,
        builder: (context, state) {
          final isArtisan = state.uri.queryParameters['role'] == 'artisan';
          return CommandesHistoryScreen(isArtisan: isArtisan);
        },
      ),
      GoRoute(
        path: notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: revenus,
        builder: (context, state) => const RevenusScreen(),
      ),
      GoRoute(
        path: editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: completeProfile,
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: chat,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) return const _ErrorScreen(message: 'Paramètres de chat manquants');
          return ChatScreen(
            otherUserId: extra['otherUserId'] as String,
            otherUserName: extra['otherUserName'] as String,
          );
        },
      ),
      GoRoute(
        path: rateArtisan,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) return const _ErrorScreen(message: 'Paramètres manquants');
          return RateArtisanScreen(
            commandeId: extra['commandeId'] as String,
            artisanId: extra['artisanId'] as String,
            artisanName: extra['artisanName'] as String,
          );
        },
      ),
      GoRoute(
        path: locationPicker,
        builder: (context, state) => const LocationPickerScreen(),
      ),
      GoRoute(
        path: privacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: termsOfUse,
        builder: (context, state) => const TermsOfUseScreen(),
      ),
    ],
  );

  // ── Auth guard ────────────────────────────────────────────────────────────
  static String? _guard(AuthProvider auth, String location) {
    final path = Uri.parse(location).path;

    // 1. Routes publiques → toujours autorisées
    if (_publicRoutes.contains(path)) return null;

    // 3. Non authentifié → sélection de rôle
    if (!auth.isAuthenticated) {
      debugPrint('[GUARD] Non authentifié → roleSelection ($path)');
      return roleSelection;
    }

    // 4. Authentifié mais userModel pas encore chargé → splash (attente)
    if (auth.userModel == null) {
      debugPrint('[GUARD] userModel null → splash ($path)');
      return splash;
    }

    final user = auth.userModel!;

    // 5. Routes admin
    if (_adminRoutes.any((r) => path.startsWith(r))) {
      if (!user.hasRole('admin')) {
        debugPrint('[GUARD] Accès admin refusé pour ${user.email} ($path)');
        return _defaultRouteForUser(user);
      }
      return null;
    }

    // 6. Routes client
    if (_clientRoutes.contains(path)) {
      if (!user.hasRole('client') && !user.hasRole('admin')) {
        debugPrint('[GUARD] Accès client refusé pour ${user.email} ($path)');
        return _defaultRouteForUser(user);
      }
      return null;
    }

    // 7. Routes artisan
    if (_artisanRoutes.contains(path)) {
      if (!user.hasRole('artisan') && !user.hasRole('admin')) {
        debugPrint('[GUARD] Accès artisan refusé pour ${user.email} ($path)');
        return _defaultRouteForUser(user);
      }
      return null;
    }

    // 8. Routes communes protégées → tout utilisateur connecté
    return null;
  }

  static String _defaultRouteForUser(dynamic user) {
    if (user.hasRole('admin')) return adminDashboard;
    if (user.hasRole('artisan')) return homeArtisan;
    if (user.hasRole('client')) return homeClient;
    return roleSelection;
  }
}

// ── Widget d'erreur de navigation (C7) ────────────────────────────────────
class _ErrorScreen extends StatelessWidget {
  final String message;
  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            context.go(AppRouter.roleSelection);
          }
        }),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.canPop(context)
                  ? Navigator.pop(context)
                  : context.go(AppRouter.roleSelection),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}
