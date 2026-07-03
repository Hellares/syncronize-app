import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';

/// Popup estilo Temu para el DASHBOARD DE EMPRESA: avisa que hay pedidos del
/// marketplace que requieren acción (validar comprobante o preparar pedidos ya
/// pagados) y lleva directo a la gestión de pedidos.
///
/// Se muestra una vez por sesión y por empresa, ~2s después de abrir el
/// dashboard, solo si `requierenAccion > 0` (GET /pedidos-marketplace/resumen).
class PedidosMarketplaceAlertPopup {
  PedidosMarketplaceAlertPopup._();

  /// Empresas a las que ya se les mostró el aviso en esta sesión.
  static final Set<String> _mostrado = {};

  static Future<void> mostrarSiHayPendientes(
    BuildContext context, {
    required String empresaId,
  }) async {
    if (_mostrado.contains(empresaId)) return;

    int requieren = 0;
    int porValidar = 0;
    int porPreparar = 0;
    try {
      final resp = await locator<DioClient>().get('/pedidos-marketplace/resumen');
      final data = resp.data as Map<String, dynamic>;
      requieren = (data['requierenAccion'] as num?)?.toInt() ?? 0;
      porValidar = (data['pagoEnviado'] as num?)?.toInt() ?? 0;
      porPreparar = (data['pagoValidado'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return; // sin permisos / sin red → silencioso
    }

    if (requieren <= 0 || !context.mounted) return;
    _mostrado.add(empresaId);

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Pedidos marketplace',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return Opacity(
          opacity: anim.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.85 + 0.15 * curved.value,
            child: _AlertaDialog(
              total: requieren,
              porValidar: porValidar,
              porPreparar: porPreparar,
            ),
          ),
        );
      },
    );
  }
}

class _AlertaDialog extends StatelessWidget {
  final int total;
  final int porValidar;
  final int porPreparar;

  const _AlertaDialog({
    required this.total,
    required this.porValidar,
    required this.porPreparar,
  });

  Widget _fila(IconData icon, Color color, String texto) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 12.5, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Encabezado degradé con ícono + contador grande.
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.blue1, AppColors.blue2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.storefront_rounded,
                                size: 40, color: Colors.white),
                            const SizedBox(height: 6),
                            Text(
                              '$total pedido${total == 1 ? '' : 's'} por revisar',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            '¡Tienes ventas del marketplace!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (porValidar > 0) ...[
                            _fila(
                              Icons.receipt_long_rounded,
                              Colors.orange.shade700,
                              '$porValidar con comprobante por validar',
                            ),
                            const SizedBox(height: 6),
                          ],
                          if (porPreparar > 0)
                            _fila(
                              Icons.inventory_2_rounded,
                              AppColors.green,
                              '$porPreparar pagado${porPreparar == 1 ? '' : 's'} — listo${porPreparar == 1 ? '' : 's'} para preparar',
                            ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              context.push('/empresa/pedidos-marketplace');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.blue2,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Ver pedidos',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'Más tarde',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Botón cerrar (X) flotante.
              Positioned(
                top: -12,
                right: -12,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 20, color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
