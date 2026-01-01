import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/bloc/auth/auth_bloc.dart';

/// Helper para verificar autenticación y manejar acciones protegidas
class AuthHelper {
  /// Verifica si el usuario está autenticado
  static bool isAuthenticated(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    return authState is Authenticated;
  }

  /// Ejecuta una acción solo si el usuario está autenticado
  /// Si no está autenticado, muestra un diálogo
  static void requireAuth(
    BuildContext context, {
    required VoidCallback onAuthenticated,
    String? returnTo,
    String title = 'Inicia Sesión',
    String message = 'Necesitas iniciar sesión para continuar',
  }) {
    if (isAuthenticated(context)) {
      // Usuario autenticado, ejecutar acción
      onAuthenticated();
    } else {
      // Usuario no autenticado, mostrar diálogo
      _showAuthRequiredDialog(
        context,
        title: title,
        message: message,
        returnTo: returnTo,
      );
    }
  }

  /// Muestra un diálogo indicando que se requiere autenticación
  static void _showAuthRequiredDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? returnTo,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Usar el context original para navegar
              if (context.mounted) {
                final loginPath = returnTo != null
                    ? '/login?returnTo=$returnTo'
                    : '/login';
                context.push(loginPath);
              }
            },
            child: const Text('Iniciar Sesión'),
          ),
        ],
      ),
    );
  }

  /// Muestra un SnackBar indicando que se requiere autenticación
  static void showAuthRequiredSnackBar(
    BuildContext context, {
    String message = 'Necesitas iniciar sesión para continuar',
    String? returnTo,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        action: SnackBarAction(
          label: 'Iniciar Sesión',
          textColor: Colors.white,
          onPressed: () {
            final loginPath =
                returnTo != null ? '/login?returnTo=$returnTo' : '/login';
            context.push(loginPath);
          },
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Verifica autenticación y navega a una ruta protegida
  /// Si no está autenticado, muestra diálogo y guarda la ruta para después del login
  static void navigateToProtectedRoute(
    BuildContext context,
    String route, {
    String title = 'Inicia Sesión',
    String message = 'Necesitas iniciar sesión para acceder a esta sección',
  }) {
    if (isAuthenticated(context)) {
      context.push(route);
    } else {
      _showAuthRequiredDialog(
        context,
        title: title,
        message: message,
        returnTo: route,
      );
    }
  }
}
