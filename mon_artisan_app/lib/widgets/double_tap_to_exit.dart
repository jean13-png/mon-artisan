import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget pour gérer le double tap pour quitter l'application
/// Affiche un SnackBar "Appuyez à nouveau pour quitter"
class DoubleTapToExit extends StatefulWidget {
  final Widget child;
  final String message;

  const DoubleTapToExit({
    super.key,
    required this.child,
    this.message = 'Appuyez à nouveau pour quitter',
  });

  @override
  State<DoubleTapToExit> createState() => _DoubleTapToExitState();
}

class _DoubleTapToExitState extends State<DoubleTapToExit> {
  DateTime? _lastPressedAt;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final now = DateTime.now();
        final backButtonHasNotBeenPressedOrSnackBarHasBeenClosed =
            _lastPressedAt == null ||
                now.difference(_lastPressedAt!) > const Duration(seconds: 2);

        if (backButtonHasNotBeenPressedOrSnackBarHasBeenClosed) {
          _lastPressedAt = now;
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.message),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
              ),
            );
          }
          return;
        }

        // Double tap détecté - minimiser l'app (ne pas la fermer)
        SystemNavigator.pop();
      },
      child: widget.child,
    );
  }
}
