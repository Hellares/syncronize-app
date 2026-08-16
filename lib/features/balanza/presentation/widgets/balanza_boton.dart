import 'package:flutter/material.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/utils/unidad_presentacion.dart';

import '../../domain/services/balanzas_manager.dart';
import 'balanza_visor_sheet.dart';

/// Ícono que abre el visor de la balanza al lado de un campo de cantidad.
///
/// 🔑 Vive en un solo lugar porque los puntos donde se teclea un peso son DOS
/// —el campo de granel del sheet de variantes al agregar, y el del carrito al
/// editar— y la regla de cuándo mostrarlo tiene que ser la misma en los dos.
///
/// **Se esconde solo si no hay ninguna balanza configurada.** Un ícono que al
/// tocarlo dice "no hay balanza" es ruido permanente en la pantalla más usada
/// del sistema; el que no tiene balanza no se entera de que esto existe.
class BalanzaBoton extends StatefulWidget {
  /// Recibe la cantidad YA en la unidad en la que se cobra (kg), lista para el
  /// mismo camino que el teclado.
  final ValueChanged<double> onPeso;

  final UnidadPresentacion presentacion;
  final double iconSize;

  /// Área tocable. Se achica en el carrito, donde la fila ya está apretada
  /// entre nombre, precio, stock, cantidad y total.
  final double boxSize;

  const BalanzaBoton({
    super.key,
    required this.onPeso,
    required this.presentacion,
    this.iconSize = 18,
    this.boxSize = 34,
  });

  @override
  State<BalanzaBoton> createState() => _BalanzaBotonState();
}

class _BalanzaBotonState extends State<BalanzaBoton> {
  bool _hay = false;

  @override
  void initState() {
    super.initState();
    _verificar();
  }

  Future<void> _verificar() async {
    final lista = await locator<BalanzasManager>().listar();
    if (mounted) setState(() => _hay = lista.isNotEmpty);
  }

  Future<void> _abrir() async {
    final kilos = await showBalanzaVisor(
      context,
      pres: widget.presentacion,
    );
    if (kilos != null) widget.onPeso(kilos);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hay) return const SizedBox.shrink();
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: _abrir,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: widget.boxSize,
          height: widget.boxSize,
          child: Center(
            child: Icon(Icons.scale, size: widget.iconSize, color: AppColors.blue1),
          ),
        ),
      ),
    );
  }
}
