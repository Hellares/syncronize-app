import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../constants/tipos_campo_servicio.dart';

/// Ajuste del ancho de una columna con slider y presets.
///
/// Existe porque arrastrar un tirador de pocos píxeles entre columnas es un
/// blanco muy chico con el dedo, y encima compite con el scroll horizontal
/// de la tabla. Esto siempre funciona: se toca el encabezado y listo.
///
/// Devuelve el ancho elegido, o null si se cancela.
class AjustarAnchoSheet extends StatefulWidget {
  final String nombreColumna;
  final double anchoActual;

  const AjustarAnchoSheet({
    super.key,
    required this.nombreColumna,
    required this.anchoActual,
  });

  static Future<double?> show(
    BuildContext context, {
    required String nombreColumna,
    required double anchoActual,
  }) {
    return showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AjustarAnchoSheet(
        nombreColumna: nombreColumna,
        anchoActual: anchoActual,
      ),
    );
  }

  @override
  State<AjustarAnchoSheet> createState() => _AjustarAnchoSheetState();
}

class _AjustarAnchoSheetState extends State<AjustarAnchoSheet> {
  late double _ancho = widget.anchoActual.clamp(
    kAnchoColumnaMin,
    kAnchoColumnaMax,
  );

  static const _presets = <String, double>{
    'Angosta': 78,
    'Media': 132,
    'Ancha': 200,
    'Muy ancha': 280,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.swap_horiz, size: 18, color: AppColors.blue1),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ancho de "${widget.nombreColumna}"',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue1,
                    ),
                  ),
                ),
                Text(
                  '${_ancho.round()} px',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            Text(
              'Se guarda en la plantilla: lo verán todos, en todas las órdenes.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 10),
            // Vista previa del ancho real, para no elegir a ciegas.
            Container(
              height: 34,
              width: _ancho,
              decoration: BoxDecoration(
                color: AppColors.blue1.withValues(alpha: 0.07),
                border: Border.all(color: AppColors.blue1.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                widget.nombreColumna,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue1,
                ),
              ),
            ),
            Slider(
              value: _ancho,
              min: kAnchoColumnaMin,
              max: kAnchoColumnaMax,
              activeColor: AppColors.blue1,
              onChanged: (v) => setState(() => _ancho = v),
            ),
            Wrap(
              spacing: 6,
              children: _presets.entries
                  .map((p) => ChoiceChip(
                        label: Text(p.key,
                            style: const TextStyle(fontSize: 11)),
                        selected: _ancho.round() == p.value.round(),
                        onSelected: (_) => setState(() => _ancho = p.value),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomButton(
                  text: 'Cancelar',
                  onPressed: () => Navigator.pop(context),
                  backgroundColor: Colors.transparent,
                  borderColor: AppColors.blue3,
                  borderWidth: 0.6,
                  textColor: AppColors.blue3,
                  enableShadows: false,
                ),
                const SizedBox(width: 8),
                CustomButton(
                  text: 'Aplicar',
                  onPressed: () => Navigator.pop(context, _ancho),
                  backgroundColor: AppColors.blue1,
                  borderColor: AppColors.blue1,
                  borderWidth: 0.6,
                  textColor: Colors.white,
                  enableShadows: false,
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
