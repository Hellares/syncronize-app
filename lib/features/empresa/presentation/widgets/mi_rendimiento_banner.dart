import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Banner que invita al rol operativo (vendedor / cajero) a entrar a su
/// dashboard personal con métricas propias (ventas del día, ranking).
/// Se muestra arriba de los accesos rápidos en `empresa_dashboard_page`
/// solo cuando aplica.
///
/// Decisión: visible solo cuando el usuario tiene `canViewVentas` pero
/// NO es admin. Para admins el dashboard general ya cubre todo y este
/// banner sería ruido.
class MiRendimientoBanner extends StatelessWidget {
  const MiRendimientoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.green.shade400,
            Colors.green.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/empresa/dashboard-vendedor'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Mi rendimiento',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Ventas del día y ranking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper para decidir si mostrar el banner según los permisos.
  /// Reglas:
  ///  - Debe poder ver ventas (es operativo).
  ///  - NO es admin (los admins ya tienen el dashboard general).
  static bool debeMostrar({
    required bool canViewVentas,
    required bool canManageUsers,
    required bool canManageSettings,
  }) {
    if (!canViewVentas) return false;
    final esAdmin = canManageUsers || canManageSettings;
    return !esAdmin;
  }

}
