import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../constants/tipos_campo_servicio.dart';

/// Tirador para redimensionar una columna, como el borde del encabezado en
/// Excel.
///
/// 🔴 GOTCHA: vive DENTRO de un `SingleChildScrollView` horizontal. Con un
/// `GestureDetector.onHorizontalDrag` el arrastre se lo queda el Scrollable
/// —ambos son reconocedores de arrastre horizontal y compiten en la arena de
/// gestos— y la columna nunca se movía. Por eso aquí se usa `Listener`, que
/// trabaja con eventos de puntero crudos y NO entra en la arena, más
/// [onInicio]/[onFin] para que el padre congele el scroll mientras dura el
/// arrastre. Sin ese bloqueo la tabla se desplaza al mismo tiempo.
///
/// Reporta el ancho en vivo por [onArrastre] y el definitivo por [onFin],
/// que es donde conviene persistir: guardar en cada píxel dispararía una
/// petición por frame.
class ColumnaResizeHandle extends StatefulWidget {
  final double anchoActual;
  final ValueChanged<double> onArrastre;
  final ValueChanged<double> onFin;
  final VoidCallback? onInicio;

  const ColumnaResizeHandle({
    super.key,
    required this.anchoActual,
    required this.onArrastre,
    required this.onFin,
    this.onInicio,
  });

  @override
  State<ColumnaResizeHandle> createState() => _ColumnaResizeHandleState();
}

class _ColumnaResizeHandleState extends State<ColumnaResizeHandle> {
  double? _xInicial;
  double? _anchoInicial;
  double? _anchoActualArrastre;

  bool get _arrastrando => _xInicial != null;

  void _terminar() {
    final fin = _anchoActualArrastre;
    setState(() {
      _xInicial = null;
      _anchoInicial = null;
      _anchoActualArrastre = null;
    });
    if (fin != null) widget.onFin(fin);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) {
          setState(() {
            _xInicial = e.position.dx;
            _anchoInicial = widget.anchoActual;
            _anchoActualArrastre = widget.anchoActual;
          });
          widget.onInicio?.call();
        },
        onPointerMove: (e) {
          if (_xInicial == null) return;
          final nuevo = (_anchoInicial! + (e.position.dx - _xInicial!))
              .clamp(kAnchoColumnaMin, kAnchoColumnaMax);
          setState(() => _anchoActualArrastre = nuevo);
          widget.onArrastre(nuevo);
        },
        onPointerUp: (_) => _terminar(),
        onPointerCancel: (_) => _terminar(),
        // Zona de agarre mucho más ancha que la línea visible: 1px es
        // imposible de tomar con el dedo.
        child: SizedBox(
          width: 16,
          child: Center(
            child: Container(
              width: _arrastrando ? 2 : 1.2,
              color: _arrastrando
                  ? AppColors.blue1
                  : AppColors.blue1.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}
