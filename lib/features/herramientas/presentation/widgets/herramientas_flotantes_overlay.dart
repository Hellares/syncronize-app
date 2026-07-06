import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import 'calculadora_mostrador_sheet.dart';
import 'calculadora_simple_sheet.dart';

/// Botón FLOTANTE de herramientas visible en TODAS las pantallas de la
/// empresa (rutas `/empresa*`): semitransparente y arrastrable (recuerda
/// su posición durante la sesión). Al tocarlo actúa como DIALER: despliega
/// un mini-menú con las herramientas disponibles (calculadora de precio y
/// calculadora aritmética). Para sumar una herramienta nueva basta con
/// agregar una entrada a [_herramientas].
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

  /// Menú de herramientas desplegado (dialer abierto).
  bool _menuAbierto = false;

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
      setState(() {
        _visible = visible;
        if (!visible) _menuAbierto = false;
      });
    }
  }

  /// Contexto DENTRO del navigator raíz (el del overlay está por encima).
  BuildContext? get _navCtx =>
      widget.router.routerDelegate.navigatorKey.currentContext;

  void _toggleMenu() {
    HapticFeedback.selectionClick();
    setState(() => _menuAbierto = !_menuAbierto);
  }

  void _cerrarMenu() {
    if (_menuAbierto) setState(() => _menuAbierto = false);
  }

  void _abrir(void Function(BuildContext) show) {
    setState(() => _menuAbierto = false);
    final ctx = _navCtx;
    if (ctx == null) return;
    show(ctx);
  }

  late final List<_Herramienta> _herramientas = [
    _Herramienta(
      icono: Icons.sell_outlined,
      label: 'Calc. de precio',
      onTap: () => _abrir(CalculadoraMostradorSheet.show),
    ),
    _Herramienta(
      icono: Icons.calculate_outlined,
      label: 'Calculadora',
      onTap: () => _abrir(CalculadoraSimpleSheet.show),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_visible) return widget.child;
    final size = MediaQuery.of(context).size;
    final pos = _posGuardada ?? Offset(size.width - 58, size.height * 0.58);

    // El menú crece hacia arriba y se ancla al lado del botón; si el botón
    // está en la mitad derecha, el menú se alinea a su borde derecho.
    final anclaDerecha = pos.dx > size.width / 2;

    return Stack(
      children: [
        widget.child,

        // Capa invisible para cerrar el menú al tocar fuera.
        if (_menuAbierto)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _cerrarMenu,
            ),
          ),

        // Mini-menú (dialer) — aparece encima del botón.
        if (_menuAbierto)
          Positioned(
            right: anclaDerecha ? (size.width - pos.dx - 46) : null,
            left: anclaDerecha ? null : pos.dx,
            top: (pos.dy - 8 - _herramientas.length * 52).clamp(60.0, size.height),
            child: _MenuHerramientas(
              herramientas: _herramientas,
              alinearDerecha: anclaDerecha,
            ),
          ),

        // Botón flotante arrastrable.
        Positioned(
          left: pos.dx,
          top: pos.dy,
          child: GestureDetector(
            onPanStart: (_) => _cerrarMenu(),
            onPanUpdate: (d) {
              final nueva = Offset(
                (pos.dx + d.delta.dx).clamp(4.0, size.width - 50),
                (pos.dy + d.delta.dy).clamp(60.0, size.height - 120),
              );
              setState(() => _posGuardada = nueva);
            },
            onTap: _toggleMenu,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.blue1
                    .withValues(alpha: _menuAbierto ? 0.95 : 0.5),
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
              child: Icon(
                _menuAbierto ? Icons.close : Icons.calculate_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Descriptor de una herramienta del dialer.
class _Herramienta {
  final IconData icono;
  final String label;
  final VoidCallback onTap;

  const _Herramienta({
    required this.icono,
    required this.label,
    required this.onTap,
  });
}

/// Tarjeta con la lista de herramientas, anclada al lado del botón.
class _MenuHerramientas extends StatelessWidget {
  final List<_Herramienta> herramientas;
  final bool alinearDerecha;

  const _MenuHerramientas({
    required this.herramientas,
    required this.alinearDerecha,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: alinearDerecha
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < herramientas.length; i++) ...[
              _item(herramientas[i]),
              if (i < herramientas.length - 1)
                const Divider(height: 1, thickness: 1, color: Color(0xFFF0F1F4)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _item(_Herramienta h) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: h.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(h.icono, size: 18, color: AppColors.blue1),
            const SizedBox(width: 10),
            Text(
              h.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
