import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';

/// Denominaciones de soles peruanos: billetes (200, 100, 50, 20, 10) y
/// monedas (5, 2, 1, 0.50, 0.20, 0.10). De mayor a menor para que el
/// cajero las recorra de arriba a abajo como cuenta fisicamente.
const List<double> _denominaciones = [
  200,
  100,
  50,
  20,
  10,
  5,
  2,
  1,
  0.50,
  0.20,
  0.10,
];

/// Resultado del sheet: cantidades por denominacion + total.
class DesgloseEfectivoResult {
  final Map<double, int> cantidades;
  final double total;

  const DesgloseEfectivoResult({
    required this.cantidades,
    required this.total,
  });
}

/// Bottom sheet para que el cajero ingrese cuantos billetes/monedas de
/// cada denominacion tiene fisicamente. Calcula subtotal y total en vivo.
/// `initial`: desglose previo (al editar) para precargar.
Future<DesgloseEfectivoResult?> showDesgloseEfectivoSheet(
  BuildContext context, {
  Map<double, int>? initial,
  double? esperado,
}) async {
  return showModalBottomSheet<DesgloseEfectivoResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _DesgloseEfectivoSheet(initial: initial, esperado: esperado),
  );
}

class _DesgloseEfectivoSheet extends StatefulWidget {
  final Map<double, int>? initial;

  /// Monto esperado en EFECTIVO (opcional). Si se pasa, la cabecera muestra
  /// el esperado y un indicador en vivo de falta/sobra/cuadra.
  final double? esperado;

  const _DesgloseEfectivoSheet({this.initial, this.esperado});

  @override
  State<_DesgloseEfectivoSheet> createState() => _DesgloseEfectivoSheetState();
}

class _DesgloseEfectivoSheetState extends State<_DesgloseEfectivoSheet> {
  final Map<double, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final d in _denominaciones) {
      final cantidad = widget.initial?[d] ?? 0;
      _controllers[d] = TextEditingController(
        text: cantidad > 0 ? cantidad.toString() : '',
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int _cantidad(double denom) {
    final txt = _controllers[denom]?.text ?? '';
    return int.tryParse(txt) ?? 0;
  }

  double get _total {
    double s = 0;
    for (final d in _denominaciones) {
      s += d * _cantidad(d);
    }
    return s;
  }

  Map<double, int> _cantidadesNoCero() {
    final result = <double, int>{};
    for (final d in _denominaciones) {
      final c = _cantidad(d);
      if (c > 0) result[d] = c;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ', decimalDigits: 2);

    // Tocar cualquier zona vacía del sheet quita el foco de los CustomText
    // y oculta el teclado. behavior: opaque para capturar taps sobre áreas
    // sin otro gesture (los taps en los campos siguen enfocándolos).
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 0),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 1, 16, 1),
              child: Row(
                children: [
                  const Icon(Icons.payments_rounded,
                      color: AppColors.blue3, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: AppSubtitle(
                      'Desglose de Efectivo',
                      fontSize: 11,
                      color: AppColors.blue3,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      for (final c in _controllers.values) {
                        c.clear();
                      }
                      setState(() {});
                    },
                    child: const Text(
                      'Limpiar',
                      style: TextStyle(fontSize: 10, color: AppColors.green),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 0.5, color: Colors.grey.withValues(alpha: 0.18)),
            // Esperado + estado del conteo (solo texto + chip, sin caja),
            // separado de la lista de conteo por un divider.
            if (widget.esperado != null) ...[
              _buildEsperadoBanner(currency),
              const SizedBox(height: 8),
              Divider(height: 1, thickness: 0.5, color: Colors.grey.withValues(alpha: 0.18)),
            ],
            // Grid de denominaciones
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                itemCount: _denominaciones.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, idx) {
                  final denom = _denominaciones[idx];
                  final cantidad = _cantidad(denom);
                  final subtotal = denom * cantidad;
                  return _buildFila(denom, subtotal, currency);
                },
              ),
            ),
            Divider(height: 1, thickness: 0.5, color: Colors.grey.withValues(alpha: 0.18)),
            // Total
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 5, 16, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    currency.format(_total),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      // Si hay esperado: verde al cuadrar, rojo si no. Sin
                      // esperado: verde neutro (comportamiento anterior).
                      color: widget.esperado == null
                          ? AppColors.green
                          : ((_total - widget.esperado!).abs() < 0.005
                              ? AppColors.green
                              : AppColors.red),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      onPressed: () => Navigator.pop(context),
                      text: 'Cancelar',
                      textColor: AppColors.red,
                      borderColor: AppColors.red,
                      borderWidth: 0.6,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(

                    child: CustomButton(
                      onPressed: (){
                        Navigator.pop(context, DesgloseEfectivoResult(cantidades: _cantidadesNoCero(), total: _total));
                      },
                      text: 'Aplicar',
                      borderColor: AppColors.green,
                      borderWidth: 0.6,
                      textColor: AppColors.green,
                    ),
                  ),
                ],
              ),
            ),
              ],
            ),
          ),
        ),
      );
  }

  /// Cabecera con el monto esperado y el estado del conteo en vivo:
  /// "Falta S/ X" (azul), "Sobra S/ X" (rojo) o "Cuadra" (verde).
  Widget _buildEsperadoBanner(NumberFormat currency) {
    final esperado = widget.esperado!;
    final restante = esperado - _total; // >0 falta, <0 sobra, ~0 cuadra
    final cuadra = restante.abs() < 0.005;
    final falta = restante > 0;
    final color =
        cuadra ? AppColors.green : (falta ? AppColors.blue3 : AppColors.red);
    final label = cuadra
        ? 'Cuadra con lo esperado'
        : (falta
            ? 'Falta ${currency.format(restante.abs())}'
            : 'Sobra ${currency.format(restante.abs())}');
    final icon = cuadra
        ? Icons.check_circle_rounded
        : (falta ? Icons.south_rounded : Icons.north_rounded);

    // Sin caja contenedora: solo el texto "Esperado" + valor y el chip de
    // estado, con un padding mínimo para alinearse con la lista.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 3, 16, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Esperado',
                style: TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
              ),
              Text(
                currency.format(esperado),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue3,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFila(double denom, double subtotal, NumberFormat currency) {
    final esBillete = denom >= 10;
    final label = denom >= 1
        ? 'S/ ${denom.toInt()}'
        : 'S/ ${denom.toStringAsFixed(2)}';

    return Row(
      children: [
        Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: (esBillete ? AppColors.green : AppColors.blue2)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: esBillete ? AppColors.green : AppColors.blue2,
                ),
              ),
              Text(
                esBillete ? 'Billete' : 'Moneda',
                style: TextStyle(
                  fontSize: 9,
                  color: esBillete ? AppColors.green : AppColors.blue2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: CustomText(
            controller: _controllers[denom],
            fieldType: FieldType.number,
            hintText: '0',
            textStyle: TextStyle(fontSize: 13, color: AppColors.blue1, fontWeight: FontWeight.w600),
            height: 38,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 8),
        // Flecha conectora LARGA: línea + punta dibujadas como UNA sola
        // figura (CustomPaint) para que la punta quede pegada a la línea.
        // Se estira hasta casi el monto y se enciende con el color de la
        // denominación cuando hay cantidad; tenue cuando está en cero.
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 12,
                  child: CustomPaint(
                    painter: _ArrowLinePainter(
                      subtotal > 0
                          ? (esBillete ? AppColors.green : AppColors.blue2)
                          : AppColors.textSecondary.withValues(alpha: 0.30),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                currency.format(subtotal),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: subtotal > 0
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dibuja una línea horizontal centrada que termina en una punta de flecha
/// rellena, ambas pegadas (sin separación). Apunta hacia la derecha (al monto).
class _ArrowLinePainter extends CustomPainter {
  final Color color;

  _ArrowLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    const head = 7.0; // largo de la punta
    const halfH = 4.0; // media altura de la punta

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;
    // Línea desde el inicio hasta la base de la punta.
    canvas.drawLine(
        Offset(0, cy), Offset(size.width - head, cy), linePaint);

    // Punta triangular rellena, con la base justo donde acaba la línea.
    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width, cy)
      ..lineTo(size.width - head, cy - halfH)
      ..lineTo(size.width - head, cy + halfH)
      ..close();
    canvas.drawPath(path, headPaint);
  }

  @override
  bool shouldRepaint(_ArrowLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
