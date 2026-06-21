import 'package:flutter/material.dart';

import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';

/// Selector Contado/Crédito para compras. Emite (terminosPago, diasCredito):
///  - Contado  → ('CONTADO', null)
///  - Crédito  → ('CREDITO_N' si N en {7,15,30,45,60,90}, sino 'PERSONALIZADO', N)
/// El backend calcula la fecha de vencimiento = fechaBase + díasCrédito; acá
/// solo mostramos el preconteo para el cajero.
class CreditoSelector extends StatefulWidget {
  final DateTime fechaBase;
  final String? initialTerminos;
  final int? initialDias;
  final void Function(String terminos, int? dias) onChanged;

  const CreditoSelector({
    super.key,
    required this.fechaBase,
    required this.onChanged,
    this.initialTerminos,
    this.initialDias,
  });

  @override
  State<CreditoSelector> createState() => _CreditoSelectorState();
}

class _CreditoSelectorState extends State<CreditoSelector> {
  static const _opciones = [7, 15, 30, 45, 60, 90];
  late bool _credito;
  late int _dias;

  @override
  void initState() {
    super.initState();
    final t = widget.initialTerminos;
    _credito = t != null && t != 'CONTADO';
    _dias = widget.initialDias ?? _diasDeTerminos(t) ?? 30;
  }

  int? _diasDeTerminos(String? t) {
    switch (t) {
      case 'CREDITO_7': return 7;
      case 'CREDITO_15': return 15;
      case 'CREDITO_30': return 30;
      case 'CREDITO_45': return 45;
      case 'CREDITO_60': return 60;
      case 'CREDITO_90': return 90;
      default: return null;
    }
  }

  void _emit() {
    if (!_credito) {
      widget.onChanged('CONTADO', null);
    } else {
      final terminos = _opciones.contains(_dias) ? 'CREDITO_$_dias' : 'PERSONALIZADO';
      widget.onChanged(terminos, _dias);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vence = widget.fechaBase.add(Duration(days: _dias));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSubtitle('Condición de pago', fontSize: 10, color: AppColors.blue1),
        // const SizedBox(height: 6),
        SegmentedButton<bool>(
          style: SegmentedButton.styleFrom(
            minimumSize: const Size(0, 32),
            backgroundColor: AppColors.blue1.withValues(alpha: 0.08),
            selectedBackgroundColor: AppColors.blue1,
            foregroundColor: AppColors.blue3,
            selectedForegroundColor: Colors.white,
            side: BorderSide(color: AppColors.blue1, width: 0.6),
            textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            visualDensity: VisualDensity.compact
          ),
          segments: const [
            ButtonSegment(value: false, label: Text('Contado'), icon: Icon(Icons.payments, size: 15)),
            ButtonSegment(value: true, label: Text('Crédito'), icon: Icon(Icons.schedule, size: 15)),
          ],
          selected: {_credito},
          onSelectionChanged: (s) {
            setState(() => _credito = s.first);
            _emit();
          },
        ),
        if (_credito) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _opciones.map((d) {
              final sel = _dias == d;
              return ChoiceChip(
                label: Text('$d días', style: TextStyle(fontSize: 11, color: sel ? Colors.white : AppColors.blue1)),
                selected: sel,
                selectedColor: AppColors.blue1,
                backgroundColor: Colors.white,
                side: BorderSide(color: sel ? AppColors.blue1 : Colors.grey.shade300),
                visualDensity: VisualDensity.compact,
                onSelected: (_) {
                  setState(() => _dias = d);
                  _emit();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.event, size: 14, color: Colors.orange.shade700),
              const SizedBox(width: 4),
              Text(
                'Vence el ${DateFormatter.formatDate(vence)} (a $_dias días)',
                style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
