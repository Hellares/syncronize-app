import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

/// La cantidad de una línea del carrito: `[−] 3 [+]`, con el número escribible.
///
/// En un POS la cantidad casi siempre cambia de a uno: los botones lo hacen
/// sin abrir el teclado, y mantenerlos apretados repite. Tocar el número abre
/// el teclado con todo seleccionado, así "48" reemplaza en vez de sumarse.
///
/// Solo pinta: el texto, el foco y qué hace cada botón los pone la fila. Sin
/// [onMas]/[onMenos] (lo que va a granel) queda el campo solo, con decimales.
class CantidadStepper extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  /// Null = sin botones (granel: se escriben kilos o se pesa).
  final VoidCallback? onMas;
  final VoidCallback? onMenos;

  /// El `+` se apaga al llegar al stock y el `−` en el mínimo: se ve antes de
  /// tocar, en vez de enterarse por el aviso.
  final bool puedeMas;
  final bool puedeMenos;

  /// En rojo cuando la cantidad pasa el stock (igual que el campo de antes).
  final bool excede;

  /// Con presentación se tipean kilos: "1.5".
  final bool decimales;

  const CantidadStepper({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.onMas,
    this.onMenos,
    this.puedeMas = true,
    this.puedeMenos = true,
    this.excede = false,
    this.decimales = false,
  });

  static const alto = 27.0;
  static const anchoBoton = 20.0;
  static const keyMas = ValueKey('cantidad-stepper:mas');
  static const keyMenos = ValueKey('cantidad-stepper:menos');

  @override
  State<CantidadStepper> createState() => _CantidadStepperState();
}

class _CantidadStepperState extends State<CantidadStepper> {
  Timer? _repetir;

  @override
  void dispose() {
    _repetir?.cancel();
    super.dispose();
  }

  void _empezarRepeticion(bool mas) {
    _repetir?.cancel();
    _repetir = Timer.periodic(const Duration(milliseconds: 110), (_) {
      // Se relee el widget en cada tick: el tope llega a mitad de la ráfaga
      // y ahí se corta, en vez de seguir disparando avisos de stock.
      final puede = mas ? widget.puedeMas : widget.puedeMenos;
      final accion = mas ? widget.onMas : widget.onMenos;
      if (!mounted || !puede || accion == null) {
        _pararRepeticion();
        return;
      }
      accion();
    });
  }

  void _pararRepeticion() {
    _repetir?.cancel();
    _repetir = null;
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.excede ? Colors.red : AppColors.blue1;
    final conBotones = widget.onMas != null && widget.onMenos != null;

    return Container(
      height: CantidadStepper.alto,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Row(
        children: [
          if (conBotones)
            _boton(
              key: CantidadStepper.keyMenos,
              icono: Icons.remove,
              habilitado: widget.puedeMenos,
              mas: false,
              color: color,
            ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: widget.excede ? Colors.red : Colors.black87,
              ),
              keyboardType: widget.decimales
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.number,
              inputFormatters: [
                widget.decimales
                    ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                    : FilteringTextInputFormatter.digitsOnly,
              ],
              textInputAction: TextInputAction.done,
              // Sin caja propia: el marco es el del stepper. `border: none`
              // solo NO alcanza: el InputDecorationTheme del app pinta igual
              // el borde de habilitado/foco y el relleno.
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () {
                // Primer toque: todo seleccionado, lo tecleado reemplaza.
                if (!widget.focusNode.hasFocus) {
                  widget.controller.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: widget.controller.text.length,
                  );
                }
              },
              onChanged: widget.onChanged,
              onSubmitted: widget.onChanged,
            ),
          ),
          if (conBotones)
            _boton(
              key: CantidadStepper.keyMas,
              icono: Icons.add,
              habilitado: widget.puedeMas,
              mas: true,
              color: color,
            ),
        ],
      ),
    );
  }

  Widget _boton({
    required Key key,
    required IconData icono,
    required bool habilitado,
    required bool mas,
    required Color color,
  }) {
    final accion = mas ? widget.onMas! : widget.onMenos!;
    // `GestureDetector` y no `IconButton`: el IconButton de Material 3 reserva
    // 48 px de toque y no entra en la columna.
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onTap: habilitado ? accion : null,
      onLongPressStart: habilitado ? (_) => _empezarRepeticion(mas) : null,
      onLongPressEnd: (_) => _pararRepeticion(),
      onLongPressCancel: _pararRepeticion,
      child: SizedBox(
        width: CantidadStepper.anchoBoton,
        height: CantidadStepper.alto,
        child: Icon(
          icono,
          size: 15,
          color: habilitado ? color : Colors.grey.shade400,
        ),
      ),
    );
  }
}
