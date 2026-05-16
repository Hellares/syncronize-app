import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';

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
}) async {
  return showModalBottomSheet<DesgloseEfectivoResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _DesgloseEfectivoSheet(initial: initial),
  );
}

class _DesgloseEfectivoSheet extends StatefulWidget {
  final Map<double, int>? initial;

  const _DesgloseEfectivoSheet({this.initial});

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

    return Padding(
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
              padding: const EdgeInsets.only(top: 10, bottom: 4),
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
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.payments_rounded,
                      color: AppColors.blue3, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: AppSubtitle(
                      'Desglose de Efectivo',
                      fontSize: 15,
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
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
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
            const Divider(height: 1),
            // Total
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    currency.format(_total),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green,
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
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue1,
                        foregroundColor: AppColors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(
                          context,
                          DesgloseEfectivoResult(
                            cantidades: _cantidadesNoCero(),
                            total: _total,
                          ),
                        );
                      },
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          padding: const EdgeInsets.symmetric(vertical: 8),
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
                  fontSize: 13,
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
          child: TextField(
            controller: _controllers[denom],
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '0',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            currency.format(subtotal),
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: subtotal > 0
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
