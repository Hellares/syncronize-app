import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../constants/tipos_campo_servicio.dart';

/// Tirador para redimensionar una columna, como el borde del encabezado en
/// Excel. Se coloca al final de cada celda de encabezado.
///
/// Reporta el ancho en vivo por [onArrastre] (para que la tabla se redibuje
/// mientras se arrastra) y el definitivo por [onFin], que es donde conviene
/// persistir: guardar en cada píxel dispararía una petición por frame.
class ColumnaResizeHandle extends StatefulWidget {
  final double anchoActual;
  final ValueChanged<double> onArrastre;
  final ValueChanged<double> onFin;

  const ColumnaResizeHandle({
    super.key,
    required this.anchoActual,
    required this.onArrastre,
    required this.onFin,
  });

  @override
  State<ColumnaResizeHandle> createState() => _ColumnaResizeHandleState();
}

class _ColumnaResizeHandleState extends State<ColumnaResizeHandle> {
  double? _anchoArrastre;

  @override
  Widget build(BuildContext context) {
    final arrastrando = _anchoArrastre != null;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) =>
            setState(() => _anchoArrastre = widget.anchoActual),
        onHorizontalDragUpdate: (d) {
          final nuevo = ((_anchoArrastre ?? widget.anchoActual) + d.delta.dx)
              .clamp(kAnchoColumnaMin, kAnchoColumnaMax);
          setState(() => _anchoArrastre = nuevo);
          widget.onArrastre(nuevo);
        },
        onHorizontalDragEnd: (_) {
          final fin = _anchoArrastre;
          setState(() => _anchoArrastre = null);
          if (fin != null) widget.onFin(fin);
        },
        // Zona de agarre más ancha que la línea visible: 4px son
        // imposibles de tomar con el dedo.
        child: SizedBox(
          width: 14,
          child: Center(
            child: Container(
              width: arrastrando ? 2 : 1,
              color: arrastrando
                  ? AppColors.blue1
                  : AppColors.blue1.withValues(alpha: 0.28),
            ),
          ),
        ),
      ),
    );
  }
}
