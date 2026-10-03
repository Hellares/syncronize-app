import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Una ficha de la rejilla de pagos del cobro: el método arriba (logo o
/// ícono + nombre) y el monto grande abajo.
///
/// El monto lo escribe el numpad de la página, no el teclado: el campo es
/// `readOnly` y solo sirve para tomar el foco (tocar la ficha entera lo da).
/// [seleccionada] la pinta la página según a qué campo está atado el numpad,
/// así que la ficha resaltada es siempre donde va a caer lo que se teclee.
class FichaPago extends StatelessWidget {
  final String label;

  /// El logo (Yape, Plin). Sin él se muestra [icono] + [label] en texto.
  final Widget? logo;
  final IconData? icono;
  final Color color;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool seleccionada;

  /// Color del monto: el del método (efectivo verde, Yape morado, Plin
  /// azul), para leer de un vistazo cuánto va por cada uno.
  final Color colorMonto;

  /// Cuánto del color va al fondo (1 = normal). El verde del efectivo es más
  /// saturado que el morado o el azul y con la misma dosis pesaba de más.
  final double intensidadFondo;

  /// Null = ficha fija (efectivo, Yape, Plin): sin ✕.
  final VoidCallback? onQuitar;

  /// N° de operación EN la ficha, a la derecha del logo (Yape, Plin): ahí
  /// sobra lugar y queda pegado a su monto. Null = sin casilla.
  final TextEditingController? refController;
  final FocusNode? refFocusNode;

  /// Resaltada cuando el numpad está escribiendo en la casilla del N° op.
  final bool refSeleccionada;

  const FichaPago({
    super.key,
    required this.label,
    required this.controller,
    required this.focusNode,
    this.logo,
    this.icono,
    this.color = AppColors.greendark,
    this.seleccionada = false,
    this.colorMonto = Colors.black87,
    this.intensidadFondo = 1,
    this.onQuitar,
    this.refController,
    this.refFocusNode,
    this.refSeleccionada = false,
  });

  static const alto = 68.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: focusNode.requestFocus,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: alto,
          padding: EdgeInsets.fromLTRB(
              10, 6, onQuitar != null ? 2 : 10, 4),
          decoration: BoxDecoration(
            // Sin borde: el fondo es el color del monto (verde, morado,
            // azul) suavizado, y la seleccionada lo lleva más intenso.
            color: colorMonto.withValues(
                alpha: (seleccionada ? 0.16 : 0.07) * intensidadFondo),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 26,
                child: Row(
                  children: [
                    Expanded(child: _cabecera()),
                    if (onQuitar != null)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onQuitar,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.close,
                              size: 16, color: Colors.red.shade400),
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('S/',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      // Lo escribe el numpad: sin teclado del sistema.
                      readOnly: true,
                      showCursor: true,
                      // El cursor por defecto toma el alto de la línea entera y
                      // con letra de 20 se veía enorme: más bajo y fino.
                      cursorHeight: 16,
                      cursorWidth: 1.5,
                      cursorColor: colorMonto,
                      enableInteractiveSelection: false,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colorMonto,
                      ),
                      // Sin caja propia: el InputDecorationTheme del app
                      // pinta borde y relleno si no se anulan todos.
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade300,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cabecera() {
    if (logo != null) {
      if (refController == null || refFocusNode == null) {
        return Align(alignment: Alignment.centerLeft, child: logo);
      }
      return Row(
        children: [
          logo!,
          const SizedBox(width: 8),
          Expanded(child: _casillaRef()),
        ],
      );
    }
    return Row(
      children: [
        if (icono != null) ...[
          Icon(icono, size: 18, color: color),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  /// La casilla del N° de operación: un toque le da el foco (el numpad
  /// escribe ahí, con su tope de 6 dígitos) sin pasar por el monto.
  Widget _casillaRef() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: refFocusNode!.requestFocus,
      // Fondo blanco sin borde. Que se está escribiendo ahí lo dice el
      // "Op." en azul (y el cursor).
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Text('Op.',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      refSeleccionada ? FontWeight.w700 : FontWeight.normal,
                  color: refSeleccionada
                      ? AppColors.blue1
                      : Colors.grey.shade600,
                )),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: refController,
                focusNode: refFocusNode,
                readOnly: true,
                showCursor: true,
                cursorHeight: 12,
                cursorWidth: 1.2,
                enableInteractiveSelection: false,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: Colors.black87,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  filled: false,
                  hintText: '000',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La ficha punteada "Otro método": abre el menú (tarjeta, transferencia).
class FichaAgregarPago extends StatelessWidget {
  final VoidCallback onTap;

  const FichaAgregarPago({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: FichaPago.alto,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.blueborder, width: 0.5),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 20, color: AppColors.blue1),
              SizedBox(height: 2),
              Text(
                'Otro método',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
