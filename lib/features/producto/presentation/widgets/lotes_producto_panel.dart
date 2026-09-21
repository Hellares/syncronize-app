/// Qué lotes hay de este producto y CUÁL SALE PRIMERO.
///
/// Es el espejo de `LotesCard` de la web. Solo muestra los lotes PRESENTES —los
/// que están en el estante—: los agotados son historia y para eso está la
/// pantalla de Trazabilidad.
///
/// Se esconde solo si el producto no maneja lotes, que hoy es la mayoría del
/// catálogo.
library;

import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/fecha_calendario.dart';
import '../../../compra/domain/orden_fefo.dart';

class LotesProductoPanel extends StatefulWidget {
  final String productoId;

  /// Acota a una variante cuando el producto las tiene.
  final String? varianteId;

  const LotesProductoPanel({
    super.key,
    required this.productoId,
    this.varianteId,
  });

  @override
  State<LotesProductoPanel> createState() => _LotesProductoPanelState();
}

class _LotesProductoPanelState extends State<LotesProductoPanel> {
  final _dio = locator<DioClient>();

  /// null = cargando todavía; vacía = no hay lotes (o no se pudo traer).
  List<Map<String, dynamic>>? _lotes;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(LotesProductoPanel old) {
    super.didUpdateWidget(old);
    // Cambiar de variante tiene que traer SUS lotes: sin esto la ficha
    // seguiría mostrando los de la variante anterior.
    if (old.varianteId != widget.varianteId ||
        old.productoId != widget.productoId) {
      setState(() => _lotes = null);
      _cargar();
    }
  }

  Future<void> _cargar() async {
    try {
      final resp = await _dio.get(
        '/productos/${widget.productoId}/trazabilidad',
        queryParameters: {
          if (widget.varianteId != null) 'varianteId': widget.varianteId,
        },
      );
      final data = resp.data as Map<String, dynamic>;
      final lotes = ((data['lotes'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .where(lotePresente)
          .toList()
        ..sort(ordenFefo);
      if (mounted) setState(() => _lotes = lotes);
    } catch (_) {
      if (mounted) setState(() => _lotes = const []);
    }
  }

  /// "VENCIDO", "VENCE HOY" o "vence en N d" (≤ 30), por día de calendario.
  String? _aviso(String? iso) {
    final d = diasParaVencerIso(iso);
    if (d == null) return null;
    if (d < 0) return 'VENCIDO';
    if (d == 0) return 'VENCE HOY';
    if (d <= 30) return 'vence en $d d';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final lotes = _lotes;
    if (lotes == null || lotes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GradientContainer(
        gradient: AppGradients.blueWhiteDialog(),
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 16, color: AppColors.blue1),
                const SizedBox(width: 6),
                AppSubtitle(
                  'Lotes en stock',
                  fontSize: 13,
                  color: AppColors.blue1,
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${lotes.length}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < lotes.length; i++) _fila(lotes[i], i == 0),
          ],
        ),
      ),
    );
  }

  Widget _fila(Map<String, dynamic> l, bool primero) {
    final aviso = _aviso(l['fechaVencimiento']?.toString());
    final vencido = aviso == 'VENCIDO' || aviso == 'VENCE HOY';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${l['codigo'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    // El que toca agarrar del estante. Es la respuesta a "¿cuál
                    // se vende ahora?", y por eso va marcado y no solo primero.
                    if (primero) ...[
                      const SizedBox(width: 5),
                      _chip('SALE PRIMERO', AppColors.blue1),
                    ],
                    if (aviso != null) ...[
                      const SizedBox(width: 5),
                      _chip(
                        aviso,
                        vencido ? Colors.red.shade700 : Colors.orange.shade800,
                      ),
                    ],
                  ],
                ),
                Text(
                  [
                    if (l['proveedor'] != null) '${l['proveedor']}',
                    if (l['fechaVencimiento'] != null)
                      'vence ${formatearDiaEnvaseIso(l['fechaVencimiento']?.toString())}',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${l['cantidadActual'] ?? 0}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String texto, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );
}
