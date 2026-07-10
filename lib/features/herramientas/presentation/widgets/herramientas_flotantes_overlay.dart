import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import 'calculadora_mostrador_sheet.dart';
import 'calculadora_simple_sheet.dart';

/// Botón FLOTANTE de herramientas visible en TODAS las pantallas de la
/// empresa (rutas `/empresa*`): semitransparente y arrastrable (recuerda
/// su posición durante la sesión). Al tocarlo actúa como DIALER RADIAL:
/// las herramientas salen en abanico circular alrededor del botón
/// (animación escalonada con rebote). El cuadrante del abanico se elige
/// según dónde esté el botón (pegado a la derecha abre hacia la
/// izquierda, cerca del borde superior abre hacia abajo, etc.). Para
/// sumar una herramienta nueva basta con agregar una entrada a
/// [_herramientas].
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
    extends State<HerramientasFlotantesOverlay>
    with SingleTickerProviderStateMixin {
  /// Posición recordada entre aperturas (solo memoria de la sesión).
  static Offset? _posGuardada;

  bool _visible = false;

  /// Menú de herramientas desplegado (dialer abierto).
  bool _menuAbierto = false;

  /// Progreso del abanico: 0 = cerrado, 1 = desplegado. Los items se
  /// escalonan sobre este mismo controller con [Interval].
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
    reverseDuration: const Duration(milliseconds: 180),
  );

  /// Radio del abanico (distancia del centro del botón al de cada item).
  static const double _radio = 86;

  /// Lado del botón flotante.
  static const double _btn = 46;

  /// Ancho reservado por item (la etiqueta es más ancha que el círculo).
  static const double _itemW = 96;

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_onRouteChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onRouteChanged());
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_onRouteChanged);
    _anim.dispose();
    super.dispose();
  }

  void _onRouteChanged() {
    final loc =
        widget.router.routerDelegate.currentConfiguration.uri.toString();
    final visible = loc.startsWith('/empresa');
    if (visible != _visible && mounted) {
      setState(() {
        _visible = visible;
        if (!visible) {
          _menuAbierto = false;
          _anim.value = 0;
        }
      });
    }
  }

  /// Contexto DENTRO del navigator raíz (el del overlay está por encima).
  BuildContext? get _navCtx =>
      widget.router.routerDelegate.navigatorKey.currentContext;

  void _toggleMenu() {
    HapticFeedback.selectionClick();
    setState(() => _menuAbierto = !_menuAbierto);
    _menuAbierto ? _anim.forward() : _anim.reverse();
  }

  void _cerrarMenu() {
    if (_menuAbierto) {
      setState(() => _menuAbierto = false);
      _anim.reverse();
    }
  }

  void _abrir(void Function(BuildContext) show) {
    _cerrarMenu();
    final ctx = _navCtx;
    if (ctx == null) return;
    show(ctx);
  }

  late final List<_Herramienta> _herramientas = [
    _Herramienta(
      icono: Icons.sell_outlined,
      label: 'Calc. precio',
      onTap: () => _abrir(CalculadoraMostradorSheet.show),
    ),
    _Herramienta(
      icono: Icons.calculate_outlined,
      label: 'Calculadora',
      onTap: () => _abrir(CalculadoraSimpleSheet.show),
    ),
  ];

  /// Ángulos (en grados) del inicio y fin del abanico según el cuadrante
  /// libre alrededor del botón. Pantalla: y crece hacia abajo, así que
  /// -90° es "arriba".
  (double, double) _arcoParaPosicion(Offset pos, Size size) {
    final haciaIzq = pos.dx > size.width / 2;
    // Cerca del borde superior no hay sitio arriba → abrir hacia abajo.
    final haciaAbajo = pos.dy < _radio + 70;
    if (!haciaAbajo) {
      return haciaIzq ? (-95.0, -175.0) : (-85.0, -5.0);
    }
    return haciaIzq ? (95.0, 175.0) : (85.0, 5.0);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return widget.child;
    final size = MediaQuery.of(context).size;
    final pos = _posGuardada ?? Offset(size.width - 58, size.height * 0.58);
    final centro = pos + const Offset(_btn / 2, _btn / 2);
    final (degA, degB) = _arcoParaPosicion(pos, size);

    return Stack(
      children: [
        widget.child,

        // Velo sutil + cierre al tocar fuera (se desvanece con el abanico).
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            if (_anim.isDismissed) return const SizedBox.shrink();
            return Positioned.fill(
              child: IgnorePointer(
                ignoring: !_menuAbierto,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _cerrarMenu,
                  child: Container(
                    color: Colors.black
                        .withValues(alpha: 0.10 * _anim.value),
                  ),
                ),
              ),
            );
          },
        ),

        // Items del dialer en abanico radial.
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            if (_anim.isDismissed) return const SizedBox.shrink();
            return Positioned.fill(
              child: Stack(
                children: [
                  for (var i = 0; i < _herramientas.length; i++)
                    _itemRadial(i, centro, degA, degB, size),
                ],
              ),
            );
          },
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
              width: _btn,
              height: _btn,
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
              // Giro de 45° al abrir: el "+" implícito del dialer.
              child: AnimatedRotation(
                turns: _menuAbierto ? 0.125 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Icon(
                  _menuAbierto ? Icons.close : Icons.calculate_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Un item del abanico: viaja del centro del botón a su posición en el
  /// arco con stagger + rebote (easeOutBack), la etiqueta aparece al final.
  Widget _itemRadial(
      int i, Offset centro, double degA, double degB, Size size) {
    final n = _herramientas.length;
    final t = n == 1 ? 0.5 : i / (n - 1);
    final ang = (degA + (degB - degA) * t) * math.pi / 180;

    // Stagger: cada item arranca un poco después del anterior.
    final v = CurvedAnimation(
      parent: _anim,
      curve: Interval(0.10 * i, 1.0, curve: Curves.easeOutBack),
      reverseCurve: Interval(0.10 * i, 1.0, curve: Curves.easeIn),
    ).value;

    final centroItem = centro +
        Offset(math.cos(ang), math.sin(ang)) * _radio * v.clamp(0.0, 1.2);
    // La etiqueta entra al final del despliegue.
    final opLabel = ((_anim.value - 0.6) / 0.4).clamp(0.0, 1.0);

    final h = _herramientas[i];
    return Positioned(
      left: (centroItem.dx - _itemW / 2).clamp(2.0, size.width - _itemW - 2),
      top: centroItem.dy - 24,
      child: Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: v.clamp(0.0, 1.15),
          child: SizedBox(
            width: _itemW,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 5,
                  shadowColor: Colors.black.withValues(alpha: 0.25),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _menuAbierto ? h.onTap : null,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(h.icono, size: 20, color: AppColors.blue1),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Opacity(
                  opacity: opLabel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      h.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
