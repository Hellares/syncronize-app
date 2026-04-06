import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/date_formatter.dart';

/// Widget que muestra el flujo de documentos de una venta como árbol visual
class FlujoDocumentosWidget extends StatefulWidget {
  final String ventaId;

  const FlujoDocumentosWidget({super.key, required this.ventaId});

  @override
  State<FlujoDocumentosWidget> createState() => _FlujoDocumentosWidgetState();
}

class _FlujoDocumentosWidgetState extends State<FlujoDocumentosWidget> {
  bool _loading = true;
  bool _expanded = false;
  String? _error;
  List<dynamic> _nodos = [];
  int _totalDocs = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final dio = locator<DioClient>();
      final response = await dio.get('/ventas/${widget.ventaId}/flujo-documentos');
      final data = response.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _nodos = data['nodos'] as List<dynamic>? ?? [];
          _totalDocs = data['totalDocumentos'] as int? ?? 0;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar flujo';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con toggle
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  const Icon(Icons.account_tree, size: 16, color: AppColors.blue1),
                  const SizedBox(width: 8),
                  const AppSubtitle('Flujo de Documentos', fontSize: 13),
                  const Spacer(),
                  if (!_loading)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.blue1.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: AppText('$_totalDocs docs', size: 9, fontWeight: FontWeight.w600, color: AppColors.blue1),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const Divider(height: 16),
              if (_loading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ))
              else if (_error != null)
                Center(child: AppText(_error!, size: 11, color: Colors.red))
              else
                ..._nodos.map((nodo) => _buildNodo(context, nodo as Map<String, dynamic>, 0)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNodo(BuildContext context, Map<String, dynamic> nodo, int depth, {bool isLast = true}) {
    final tipo = nodo['tipo'] as String? ?? '';
    final codigo = nodo['codigo'] as String? ?? '';
    final estado = nodo['estado'] as String? ?? '';
    final sunatStatus = nodo['sunatStatus'] as String?;
    final fecha = nodo['fecha'] != null ? DateTime.tryParse(nodo['fecha'].toString()) : null;
    final monto = nodo['monto'];
    final moneda = nodo['moneda'] as String? ?? 'PEN';
    final detalle = nodo['detalle'] as String?;
    final ruta = nodo['ruta'] as String?;
    final hijos = nodo['hijos'] as List<dynamic>? ?? [];
    final pdfUrl = nodo['pdfUrl'] as String?;

    final config = _tipoConfig(tipo);
    final simbolo = moneda == 'USD' ? '\$' : 'S/';
    final esRaiz = depth == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nodo con conector
        InkWell(
          onTap: ruta != null ? () => context.push(ruta) : null,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Conector └─▶
              if (!esRaiz)
                SizedBox(
                  width: 24,
                  height: 36,
                  child: CustomPaint(
                    painter: _ConnectorPainter(
                      color: Colors.grey.shade400,
                      isLast: isLast,
                    ),
                  ),
                ),
              // Contenido del nodo
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  padding: EdgeInsets.symmetric(
                    horizontal: esRaiz ? 10 : 8,
                    vertical: esRaiz ? 8 : 5,
                  ),
                  decoration: null,
                  child: Row(
                    children: [
                      // Icono
                      Container(
                        width: esRaiz ? 28 : 22,
                        height: esRaiz ? 28 : 22,
                        decoration: BoxDecoration(
                          color: config.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(esRaiz ? 6 : 4),
                        ),
                        child: Icon(config.icon, size: esRaiz ? 16 : 13, color: config.color),
                      ),
                      const SizedBox(width: 8),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(child: AppText(codigo, size: esRaiz ? 11 : 10, fontWeight: FontWeight.w700)),
                                const SizedBox(width: 6),
                                _buildEstadoChip(estado, sunatStatus),
                              ],
                            ),
                            Row(
                              children: [
                                AppText(config.label, size: 8, color: config.color, fontWeight: FontWeight.w600),
                                if (fecha != null) ...[
                                  const SizedBox(width: 4),
                                  AppText(DateFormatter.formatDate(fecha), size: 8, color: Colors.grey),
                                ],
                              ],
                            ),
                            if (detalle != null && detalle.isNotEmpty)
                              AppText(detalle, size: 8, color: Colors.grey.shade600),
                          ],
                        ),
                      ),
                      if (monto != null)
                        AppText('$simbolo ${_formatMonto(monto)}', size: esRaiz ? 11 : 10, fontWeight: FontWeight.w700, color: config.color),
                      if (pdfUrl != null)
                        Padding(padding: const EdgeInsets.only(left: 4), child: Icon(Icons.picture_as_pdf, size: 12, color: Colors.red.shade300)),
                      if (ruta != null)
                        const Padding(padding: EdgeInsets.only(left: 2), child: Icon(Icons.chevron_right, size: 14, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Hijos con indent
        if (hijos.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: esRaiz ? 14.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < hijos.length; i++)
                  _buildNodo(context, hijos[i] as Map<String, dynamic>, depth + 1, isLast: i == hijos.length - 1),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEstadoChip(String estado, String? sunatStatus) {
    final display = sunatStatus ?? estado;
    final chipConfig = _estadoConfig(display);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: chipConfig.bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipConfig.borderColor, width: 0.5),
      ),
      child: Text(
        chipConfig.label,
        style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: chipConfig.textColor),
      ),
    );
  }

  String _formatMonto(dynamic monto) {
    if (monto is num) return monto.toStringAsFixed(2);
    final parsed = double.tryParse(monto.toString());
    return parsed?.toStringAsFixed(2) ?? '0.00';
  }

  _TipoConfig _tipoConfig(String tipo) {
    switch (tipo) {
      case 'COTIZACION':
        return _TipoConfig('Cotización', Icons.request_quote, Colors.purple);
      case 'VENTA':
        return _TipoConfig('Venta', Icons.shopping_cart, AppColors.blue1);
      case 'FACTURA':
        return _TipoConfig('Factura', Icons.description, Colors.teal);
      case 'BOLETA':
        return _TipoConfig('Boleta', Icons.receipt, Colors.teal.shade700);
      case 'NOTA_CREDITO':
        return _TipoConfig('Nota Crédito', Icons.remove_circle_outline, Colors.orange);
      case 'NOTA_DEBITO':
        return _TipoConfig('Nota Débito', Icons.add_circle_outline, Colors.deepOrange);
      case 'GUIA_REMISION':
        return _TipoConfig('Guía Remisión', Icons.local_shipping, Colors.indigo);
      case 'PAGO':
        return _TipoConfig('Pago', Icons.payments, Colors.green);
      case 'CUOTA':
        return _TipoConfig('Cuota', Icons.event, Colors.amber.shade800);
      case 'DEVOLUCION':
        return _TipoConfig('Devolución', Icons.assignment_return, Colors.red);
      default:
        return _TipoConfig(tipo, Icons.insert_drive_file, Colors.grey);
    }
  }

  _EstadoChipConfig _estadoConfig(String estado) {
    switch (estado.toUpperCase()) {
      case 'ACEPTADO':
      case 'ACEPTADA':
      case 'COBRADA':
      case 'COMPLETADO':
      case 'PAGADA':
      case 'PROCESADA':
      case 'APROBADA':
      case 'CONVERTIDA':
        return _EstadoChipConfig(estado, Colors.green.shade50, Colors.green.shade300, Colors.green.shade800);
      case 'PENDIENTE':
      case 'BORRADOR':
      case 'PAGADA_PARCIAL':
        return _EstadoChipConfig(estado, Colors.orange.shade50, Colors.orange.shade300, Colors.orange.shade800);
      case 'PROCESANDO':
      case 'ENVIADO':
      case 'REGISTRADO':
        return _EstadoChipConfig(estado, Colors.blue.shade50, Colors.blue.shade300, Colors.blue.shade800);
      case 'RECHAZADO':
      case 'RECHAZADA':
      case 'ANULADO':
      case 'ANULADA':
      case 'CANCELADA':
      case 'VENCIDA':
        return _EstadoChipConfig(estado, Colors.red.shade50, Colors.red.shade300, Colors.red.shade800);
      case 'ERROR_COMUNICACION':
        return _EstadoChipConfig('ERROR', Colors.red.shade50, Colors.red.shade300, Colors.red.shade800);
      default:
        return _EstadoChipConfig(estado, Colors.grey.shade100, Colors.grey.shade300, Colors.grey.shade700);
    }
  }
}

class _TipoConfig {
  final String label;
  final IconData icon;
  final Color color;
  _TipoConfig(this.label, this.icon, this.color);
}

class _EstadoChipConfig {
  final String label;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  _EstadoChipConfig(this.label, this.bgColor, this.borderColor, this.textColor);
}

/// Dibuja el conector └─▶ para hijos del árbol
class _ConnectorPainter extends CustomPainter {
  final Color color;
  final bool isLast;

  _ConnectorPainter({required this.color, required this.isLast});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Línea vertical (desde arriba hasta el centro)
    canvas.drawLine(
      Offset(6, 0),
      Offset(6, size.height / 2),
      paint,
    );

    // Línea horizontal (desde la vertical hasta la punta)
    canvas.drawLine(
      Offset(6, size.height / 2),
      Offset(size.width - 4, size.height / 2),
      paint,
    );

    // Flecha ▶ al final
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final arrowPath = Path()
      ..moveTo(size.width - 4, size.height / 2 - 3)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width - 4, size.height / 2 + 3)
      ..close();
    canvas.drawPath(arrowPath, arrowPaint);

    // Si no es el último hijo, extender línea vertical hacia abajo
    if (!isLast) {
      canvas.drawLine(
        Offset(6, size.height / 2),
        Offset(6, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter oldDelegate) =>
      color != oldDelegate.color || isLast != oldDelegate.isLast;
}
