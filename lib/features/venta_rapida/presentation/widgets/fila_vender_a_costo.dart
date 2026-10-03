import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_switch_tile.dart';

/// La fila de "vender a costo" de Venta Rápida: el interruptor y el botón
/// "Vender compra", juntos porque son las dos entradas al mismo modo.
///
/// Solo pinta: recibe el estado y dos acciones, y la página la conecta al
/// cubit. Está aparte para poder montarla en un test sin el cubit (el repo no
/// tiene librería de mocking).
///
/// 🔴 `CustomSwitchTile` usa un Expanded adentro: en esta Row va envuelto en
/// Expanded, o el layout revienta sin que `flutter analyze` lo vea.
class FilaVenderACosto extends StatelessWidget {
  final bool activo;
  final bool cargando;
  final int lineasACosto;
  final VoidCallback onToggle;
  final VoidCallback onVenderCompra;

  const FilaVenderACosto({
    super.key,
    required this.activo,
    required this.cargando,
    required this.lineasACosto,
    required this.onToggle,
    required this.onVenderCompra,
  });

  /// Alto fijo de las dos piezas: la fila no salta cuando el interruptor suma
  /// el subtítulo con las líneas a costo.
  static const double alto = 40;

  /// Para medir cada pieza en el test de montaje sin depender de lo que
  /// `CustomSwitchTile` tenga adentro (su Container interno mide 38: los 40
  /// menos el borde).
  static const keyInterruptor = ValueKey('fila-vender-a-costo:interruptor');
  static const keyBoton = ValueKey('fila-vender-a-costo:boton');

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _interruptor()),
        const SizedBox(width: 8),
        _botonVenderCompra(),
      ],
    );
  }

  Widget _interruptor() {
    return Container(
      key: keyInterruptor,
      height: alto,
      padding: const EdgeInsets.only(left: 10, right: 4),
      decoration: BoxDecoration(
        // Prendido: un tinte, no el bloque azul oscuro de antes.
        color: activo
            ? AppColors.blue1.withValues(alpha: 0.06)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: activo
              ? AppColors.blue1.withValues(alpha: 0.4)
              : Colors.grey.shade300,
        ),
      ),
      child: CustomSwitchTile(
        // El título NO cambia al prender: en una pantalla angosta "Vendiendo
        // a costo" partía en dos renglones y desbordaba el alto fijo. Lo que
        // cambia va abajo, corto.
        title: cargando ? 'Buscando costos…' : 'Vender a costo',
        subtitle: activo && !cargando
            ? '$lineasACosto ${lineasACosto == 1 ? 'línea' : 'líneas'} a costo'
            : null,
        value: activo,
        onChanged: cargando ? null : (_) => onToggle(),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _botonVenderCompra() {
    return SizedBox(
      key: keyBoton,
      height: alto,
      child: Material(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onVenderCompra,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            // Tamaño MÍNIMO: comparte la fila con el interruptor, así que acá
            // no hay ancho sobrante para un Expanded.
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 16, color: AppColors.blue1),
                SizedBox(width: 6),
                Text(
                  'Vender compra',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blue1,
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
