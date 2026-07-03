import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import 'calculadora_mostrador_sheet.dart';

/// Botón FLOTANTE de herramientas visible en TODAS las pantallas de la
/// empresa (rutas `/empresa*`): semitransparente y arrastrable (recuerda
/// su posición durante la sesión). Hoy abre directo la calculadora de
/// mostrador; cuando haya más herramientas se convierte en el dialer.
///
/// Se monta como `builder` del MaterialApp.router — envuelve al navigator
/// completo, por eso escucha el GoRouter para saber en qué ruta estamos.
class HerramientasFlotantesOverlay extends StatefulWidget {
  final GoRouter router;
  final Widget child;

  const HerramientasFlotantesOverlay({
    super.key,
    required this.router,
    required this.child,
  });

  @override
  State<HerramientasFlotantesOverlay> createState() =>
      _HerramientasFlotantesOverlayState();
}

class _HerramientasFlotantesOverlayState
    extends State<HerramientasFlotantesOverlay> {
  /// Posición recordada entre aperturas (solo memoria de la sesión).
  static Offset? _posGuardada;

  bool _visible = false;

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_onRouteChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onRouteChanged());
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    final loc =
        widget.router.routerDelegate.currentConfiguration.uri.toString();
    final visible = loc.startsWith('/empresa');
    if (visible != _visible && mounted) {
      setState(() => _visible = visible);
    }
  }

  void _abrirCalculadora() {
    // Contexto DENTRO del navigator raíz (el del overlay está por encima).
    final navCtx = widget.router.routerDelegate.navigatorKey.currentContext;
    if (navCtx == null) return;
    CalculadoraMostradorSheet.show(navCtx);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return widget.child;
    final size = MediaQuery.of(context).size;
    final pos = _posGuardada ?? Offset(size.width - 58, size.height * 0.58);

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: pos.dx,
          top: pos.dy,
          child: GestureDetector(
            onPanUpdate: (d) {
              final nueva = Offset(
                (pos.dx + d.delta.dx).clamp(4.0, size.width - 50),
                (pos.dy + d.delta.dy).clamp(60.0, size.height - 120),
              );
              setState(() => _posGuardada = nueva);
            },
            onTap: _abrirCalculadora,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.blue1.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.calculate_outlined,
                  color: Colors.white, size: 24),
            ),
          ),
        ),
      ],
    );
  }
}
