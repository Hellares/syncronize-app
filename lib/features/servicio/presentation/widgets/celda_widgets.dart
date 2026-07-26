import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Widgets para celdas de TABLA.
///
/// 🔴 GOTCHA: `Checkbox` y `DropdownButton` de Material imponen un tamaño
/// mínimo de interacción de 48px. Ni `visualDensity.compact` ni
/// `materialTapTargetSize.shrinkWrap` los bajan lo suficiente, así que
/// deformaban la celda de 34px de alto. Estos los reemplazan con control
/// total del tamaño; el área tocable es TODA la celda, que además es más
/// cómoda que un cuadradito de 18px.

/// Booleano de celda: toda la celda alterna el valor.
class CeldaBooleana extends StatelessWidget {
  final bool valor;
  final ValueChanged<bool> onChanged;

  const CeldaBooleana({
    super.key,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!valor),
      child: Center(
        child: Icon(
          valor ? Icons.check_box : Icons.check_box_outline_blank,
          size: 18,
          color: valor ? AppColors.blue1 : Colors.grey.shade400,
        ),
      ),
    );
  }
}

/// Selección de celda: abre el menú al tocar cualquier parte de la celda.
class CeldaSeleccion extends StatelessWidget {
  final String? valor;
  final List<String> opciones;
  final ValueChanged<String?> onChanged;

  const CeldaSeleccion({
    super.key,
    required this.valor,
    required this.opciones,
    required this.onChanged,
  });

  static const _limpiar = '__limpiar__';

  @override
  Widget build(BuildContext context) {
    final actual = valor != null && opciones.contains(valor) ? valor : null;

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      tooltip: '',
      position: PopupMenuPosition.under,
      onSelected: (v) => onChanged(v == _limpiar ? null : v),
      itemBuilder: (_) => [
        for (final o in opciones)
          PopupMenuItem(
            value: o,
            height: 34,
            child: Text(o, style: const TextStyle(fontSize: 12)),
          ),
        if (actual != null)
          const PopupMenuItem(
            value: _limpiar,
            height: 34,
            child: Text('Vaciar',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
      ],
      child: Row(
        children: [
          Expanded(
            child: Text(
              actual ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: actual == null ? Colors.grey.shade400 : Colors.black87,
              ),
            ),
          ),
          Icon(Icons.arrow_drop_down, size: 14, color: Colors.grey.shade500),
        ],
      ),
    );
  }
}
