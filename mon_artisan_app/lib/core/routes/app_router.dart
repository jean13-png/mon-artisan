import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/shared/splash_screen.dart';
import '../../screens/auth/role_selection_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/setup_local_auth_screen.dart';
import '../../screens/auth/verify_local_auth_screen.dart';
import '../../screens/auth/contrat_engagement_screen.dart';
import '../../screens/auth/artisan_payment_screen.dart';
import '../../screens/client/home_client_screen.dart';
import '../../screens/client/search_artisan_screen.dart';
import '../../screens/client/artisan_profile_screen.dart';
import '../../screens/client/create_commande_screen.dart';
import '../../screens/client/payment_screen.dart';
import '../../screens/artisan/home_artisan_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/artisans_validation_screen.dart';
import '../../screens/admin/agents_management_screen.dart';
import '../../screens/artisan/commande_detail_screen.dart';
import '../../screens/artisan/revenus_screen.dart';
import '../../screens/artisan/complete_profile_screen.dart';
import '../../screens/client/commandes_history_screen.dart';
import '../../screens/shared/notifications_screen.dart';
import '../../screens/shared/edit_profile_screen.dart';
import '../../models/artisan_model.dart';
import '../../models/commande_model.dart';

class AppRouter {
  static const String splash = '/';
  static const String roleSelection = '/role-selection';
  static const String login = '/login';
  static const String register = '/register';
  static const String setupLocalAuth = '/setup-local-auth';
  static const String verifyLocalAuth = '/verify-local-auth';
  static const String contratEngagement = '/contrat-engagement';
  static const String artisanPayment = '/artisan-payment';
  static const String homeClient = '/home-client';
  static const String homeArtisan = '/home-artisan';
  static const String adminDashboard = '/admin-dashboard';
  static const String adminValidateArtisans = '/admin/validate-artisans';
  static const String adminManageAgents = '/admin/manage-agents';
  static const String searchArtisan = '/search-artisan';
  static const String artisanProfile = '/artisan-profile';
  static const String createCommande = '/create-commande';
  static const String payment = '/payment';
  static const String commandeDetail = '/commande-detail';
  static const String commandesHistory = '/commandes-history';
  static const String notifications = '/notifications';
  static const String revenus = '/revenus';
  static const String editProfile = '/edit-profile';
  static const String completeProfile = '/complete-profile';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
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
        path: setupLocalAuth,
        builder: (context, state) => const SetupLocalAuthScreen(),
      ),
      GoRoute(
        path: verifyLocalAuth,
        builder: (context, state) => const VerifyLocalAuthScreen(),
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
        path: searchArtisan,
        builder: (context, state) {
          final metier = state.uri.queryParameters['metier'];
          final ville = state.uri.queryParameters['ville'];
          final query = state.uri.queryParameters['query'];
          return SearchArtisanScreen(
            metier: metier,
            ville: ville,
            query: query,
          );
        },
      ),
      GoRoute(
        path: artisanProfile,
        builder: (context, state) {
          final artisan = state.extra as ArtisanModel;
          return ArtisanProfileScreen(artisan: artisan);
        },
      ),
      GoRoute(
        path: createCommande,
        builder: (context, state) {
          final artisan = state.extra as ArtisanModel;
          return CreateCommandeScreen(artisan: artisan);
        },
      ),
      GoRoute(
        path: payment,
        builder: (context, state) {
          final commandeId = state.uri.queryParameters['commandeId'] ?? '';
          final montant = state.uri.queryParameters['montant'] ?? '0';
          return PaymentScreen(
            commandeId: commandeId,
            montant: montant,
          );
        },
      ),
      GoRoute(
        path: commandeDetail,
        builder: (context, state) {
          final commande = state.extra as CommandeModel;
          return CommandeDetailScreen(commande: commande);
        },
      ),
      GoRoute(
        path: commandesHistory,
        builder: (context, state) => const CommandesHistoryScreen(),
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
        path: completeProfile,
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: revenus,
        builder: (context, state) => const RevenusScreen(),
      ),
    ],
  );
}
