import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../constants/tipos_campo_servicio.dart';

/// Ajuste del ancho de TODAS las columnas de una tabla, con slider y presets.
///
/// Existe porque arrastrar un tirador de pocos píxeles entre columnas es un
/// blanco muy chico con el dedo y encima compite con el scroll horizontal de
/// la tabla. Este camino no depende de acertarle a nada: se abre desde un
/// botón rotulado en la cabecera de la tabla.
///
/// Devuelve un mapa {columna: ancho} con lo elegido, o null si se cancela.
class AjustarAnchoSheet extends StatefulWidget {
  /// Columnas tal como vienen de la plantilla: {nombre, tipo, ancho?}.
  final List<Map<String, dynamic>> columnas;

  /// Ancho vigente por columna (puede diferir del guardado si hay override).
  final Map<String, double> anchosActuales;

  const AjustarAnchoSheet({
    super.key,
    required this.columnas,
    required this.anchosActuales,
  });

  static Future<Map<String, double>?> show(
    BuildContext context, {
    required List<Map<String, dynamic>> columnas,
    required Map<String, double> anchosActuales,
  }) {
    return showModalBottomSheet<Map<String, double>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AjustarAnchoSheet(
        columnas: columnas,
        anchosActuales: anchosActuales,
      ),
    );
  }

  @override
  State<AjustarAnchoSheet> createState() => _AjustarAnchoSheetState();
}

class _AjustarAnchoSheetState extends State<AjustarAnchoSheet> {
  late final Map<String, double> _anchos = {
    for (final c in widget.columnas)
      (c['nombre'] as String): (widget.anchosActuales[c['nombre']] ??
              anchoColumna(c))
          .clamp(kAnchoColumnaMin, kAnchoColumnaMax),
  };

  static const _presets = <String, double>{
    'Angosta': 78,
    'Media': 132,
    'Ancha': 200,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
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
            const Row(
              children: [
                Icon(Icons.swap_horiz, size: 18, color: AppColors.blue1),
                SizedBox(width: 6),
                Text(
                  'Ancho de las columnas',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue1,
                  ),
                ),
              ],
            ),
            Text(
              'Se guarda en la plantilla: lo verán todos, en todas las órdenes.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.columnas.length,
                itemBuilder: (_, i) {
                  final col = widget.columnas[i];
                  final nombre = col['nombre'] as String;
                  final ancho = _anchos[nombre]!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${ancho.round()} px',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 2,
                                  overlayShape: SliderComponentShape.noOverlay,
                                ),
                                child: Slider(
                                  value: ancho,
                                  min: kAnchoColumnaMin,
                                  max: kAnchoColumnaMax,
                                  activeColor: AppColors.blue1,
                                  onChanged: (v) =>
                                      setState(() => _anchos[nombre] = v),
                                ),
                              ),
                            ),
                            for (final p in _presets.entries)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _anchos[nombre] = p.value),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: ancho.round() == p.value.round()
                                          ? AppColors.blue1
                                              .withValues(alpha: 0.15)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      p.key.substring(0, 1),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: ancho.round() == p.value.round()
                                            ? AppColors.blue1
                                            : Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // Vista previa del ancho real, para no elegir a ciegas.
                        Container(
                          height: 18,
                          width: ancho,
                          decoration: BoxDecoration(
                            color: AppColors.blue1.withValues(alpha: 0.07),
                            border: Border.all(
                                color: AppColors.blue1.withValues(alpha: 0.35)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
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
                  onPressed: () => Navigator.pop(context, _anchos),
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
