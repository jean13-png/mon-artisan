import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/constants/colors.dart';
import 'core/routes/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/artisan_provider.dart';
import 'providers/commande_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ArtisanProvider()),
        ChangeNotifierProvider(create: (_) => CommandeProvider()),
      ],
      child: const _AppRouter(),
    );
  }
}

class _AppRouter extends StatefulWidget {
  const _AppRouter();

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _router = AppRouter.create(authProvider);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseText = GoogleFonts.poppinsTextTheme(
      ThemeData(brightness: Brightness.light).textTheme,
    );

    final colorScheme = ColorScheme.light(
      primary: AppColors.primaryBlue,
      onPrimary: AppColors.white,
      secondary: AppColors.accentRed,
      onSecondary: AppColors.white,
      surface: AppColors.surfaceCard,
      onSurface: AppColors.onSurface,
      error: AppColors.error,
      onError: AppColors.white,
    );

    final appTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      primaryColor: AppColors.primaryBlue,
      textTheme: baseText.copyWith(
        bodyLarge: baseText.bodyLarge?.copyWith(color: AppColors.onSurface),
        bodyMedium: baseText.bodyMedium?.copyWith(color: AppColors.onSurfaceMuted),
        bodySmall: baseText.bodySmall?.copyWith(color: AppColors.onSurfaceMuted),
        titleLarge: baseText.titleLarge?.copyWith(color: AppColors.primaryBlue),
        titleMedium: baseText.titleMedium?.copyWith(color: AppColors.primaryBlue),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        iconTheme: const IconThemeData(color: AppColors.white),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 1,
        shadowColor: AppColors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerColor: AppColors.greyMedium.withValues(alpha: 0.6),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryBlue,
        contentTextStyle: GoogleFonts.poppins(
          color: AppColors.white,
          fontSize: 14,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCard,
        labelStyle: GoogleFonts.poppins(color: AppColors.onSurfaceMuted),
        hintStyle: GoogleFonts.poppins(color: AppColors.greyDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.greyMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.greyMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentRed,
        foregroundColor: AppColors.white,
      ),
    );

    return MaterialApp.router(
      title: 'Mon Artisan',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: appTheme,
      routerConfig: _router,
    );
  }
}
