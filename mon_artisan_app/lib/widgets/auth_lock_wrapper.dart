import 'package:flutter/material.dart';
import '../core/services/local_auth_service.dart';
import '../screens/auth/verify_local_auth_screen.dart';

/// Wrapper qui gère le verrouillage de l'app lors du retour arrière
/// et demande l'authentification biométrique/PIN
class AuthLockWrapper extends StatefulWidget {
  final Widget child;
  final bool isMainScreen; // true pour les dashboards principaux

  const AuthLockWrapper({
    super.key,
    required this.child,
    this.isMainScreen = false,
  });

  @override
  State<AuthLockWrapper> createState() => _AuthLockWrapperState();
}

class _AuthLockWrapperState extends State<AuthLockWrapper> with WidgetsBindingObserver {
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Verrouiller l'app quand elle passe en arrière-plan
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (widget.isMainScreen) {
        setState(() {
          _isLocked = true;
        });
      }
    }
  }

  Future<void> _unlock() async {
    // Vérifier si l'authentification locale est configurée
    final isConfigured = await LocalAuthService.isAuthConfigured();
    
    if (!isConfigured) {
      // Si pas configuré, déverrouiller directement
      setState(() {
        _isLocked = false;
      });
      return;
    }

    // Afficher l'écran de vérification
    if (mounted) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => const VerifyLocalAuthScreen(),
          fullscreenDialog: true,
        ),
      );

      if (result == true && mounted) {
        setState(() {
          _isLocked = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      // Afficher un écran de verrouillage
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Application verrouillée',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Authentifiez-vous pour continuer',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _unlock,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Déverrouiller'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFE53935),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
