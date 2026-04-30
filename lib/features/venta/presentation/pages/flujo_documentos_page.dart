import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../../../../core/widgets/smart_appbar.dart';

class FlujoDocumentosPage extends StatefulWidget {
  final String? codigoInicial;

  const FlujoDocumentosPage({super.key, this.codigoInicial});

  @override
  State<FlujoDocumentosPage> createState() => _FlujoDocumentosPageState();
}

class _FlujoDocumentosPageState extends State<FlujoDocumentosPage> {
  final _codigoController = TextEditingController();
  final _dio = locator<DioClient>();

  bool _buscando = false;
  bool _buscado = false;
  String? _error;
  List<dynamic> _nodos = [];
  int _totalDocs = 0;
  String _ventaCodigo = '';

  // Autocomplete
  List<Map<String, dynamic>> _sugerencias = [];
  bool _mostrarSugerencias = false;

  @override
  void initState() {
    super.initState();
    if (widget.codigoInicial != null && widget.codigoInicial!.isNotEmpty) {
      _codigoController.text = widget.codigoInicial!;
      _buscar();
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _autocompletar(String texto) async {
    if (texto.trim().length < 2) {
      if (mounted) setState(() { _sugerencias = []; _mostrarSugerencias = false; });
      return;
    }
    try {
      final response = await _dio.get(
        '/ventas/flujo-documentos/autocomplete',
        queryParameters: {'q': texto.trim()},
      );
      final data = response.data as List<dynamic>;
      if (mounted) {
        setState(() {
          _sugerencias = data.cast<Map<String, dynamic>>();
          _mostrarSugerencias = _sugerencias.isNotEmpty;
        });
      }
    } catch (_) {}
  }

  void _seleccionarSugerencia(String codigo) {
    _codigoController.text = codigo;
    setState(() => _mostrarSugerencias = false);
    _buscar();
  }

  Future<void> _buscar() async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _buscando = true;
      _error = null;
      _nodos = [];
      _buscado = false;
    });

    try {
      final response = await _dio.get(
        '/ventas/flujo-documentos/buscar',
        queryParameters: {'codigo': codigo},
      );
      final data = response.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _nodos = data['nodos'] as List<dynamic>? ?? [];
          _totalDocs = data['totalDocumentos'] as int? ?? 0;
          _ventaCodigo = data['ventaCodigo'] as String? ?? '';
          _buscando = false;
          _buscado = true;
        });
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Error al buscar';
        if (e.toString().contains('404') || e.toString().contains('No se encontr')) {
          msg = 'No se encontró documento con ese código';
        }
        setState(() {
          _error = msg;
          _buscando = false;
          _buscado = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const SmartAppBar(title: 'Flujo de Documentos'),
          body: Column(
            children: [
              // Barra de búsqueda
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: GradientContainer(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppText(
                          'Ingrese el código de cualquier documento',
                          size: 11,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        const AppText(
                          'Venta, Factura, Boleta, Guía, Cotización, Nota Crédito/Débito, Devolución',
                          size: 9,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 10),
                        CustomSearchField(
                          controller: _codigoController,
                          hintText: 'Ej: 52, F001, VTA-SED-00052',
                          borderColor: AppColors.blue1,
                          debounceDelay: const Duration(milliseconds: 350),
                          onChanged: _autocompletar,
                          onSubmitted: (_) {
                            setState(() => _mostrarSugerencias = false);
                            _buscar();
                          },
                          onClear: () {
                            setState(() {
                              _sugerencias = [];
                              _mostrarSugerencias = false;
                              _buscado = false;
                              _nodos = [];
                            });
                          },
                        ),
                        // Sugerencias
                        if (_mostrarSugerencias)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.blue1.withValues(alpha: 0.3)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: _sugerencias.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                              itemBuilder: (context, index) {
                                final s = _sugerencias[index];
                                final codigo = s['codigo'] as String? ?? '';
                                final tipo = s['tipo'] as String? ?? '';
                                final estado = s['estado'] as String? ?? '';
                                final detalle = s['detalle'] as String?;
                                final monto = s['monto'];
                                final config = _tipoConfig(tipo);
                                return InkWell(
                                  onTap: () => _seleccionarSugerencia(codigo),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    child: Row(
                                      children: [
                                        Icon(config.icon, size: 16, color: config.color),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  AppText(codigo, size: 11, fontWeight: FontWeight.w700),
                                                  const SizedBox(width: 6),
                                                  AppText(config.label, size: 8, color: config.color, fontWeight: FontWeight.w600),
                                                ],
                                              ),
                                              if (detalle != null && detalle.isNotEmpty)
                                                AppText(detalle, size: 9, color: Colors.grey),
                                            ],
                                          ),
                                        ),
                                        if (monto != null)
                                          AppText('S/ ${_formatMonto(monto)}', size: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                                        const SizedBox(width: 4),
                                        _buildEstadoChip(estado, null),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Resultados
              Expanded(
                child: _buildResultados(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultados() {
    if (_buscando) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            AppText('Buscando documentos...', size: 12, color: Colors.grey),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            AppText(_error!, size: 13, color: Colors.grey),
          ],
        ),
      );
    }

    if (!_buscado) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_tree, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const AppText('Busque un documento para ver su flujo', size: 13, color: Colors.grey),
            const SizedBox(height: 4),
            const AppText('Ingrese cualquier código y presione Buscar', size: 11, color: Colors.grey),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info del resultado
          Row(
            children: [
              const Icon(Icons.account_tree, size: 16, color: AppColors.blue1),
              const SizedBox(width: 6),
              AppSubtitle('Flujo: $_ventaCodigo', fontSize: 13),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AppText('$_totalDocs documentos', size: 10, fontWeight: FontWeight.w600, color: AppColors.blue1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Árbol
          ..._nodos.map((nodo) => _buildNodo(context, nodo as Map<String, dynamic>, 0)),
        ],
      ),
    );
  }

  Widget _buildNodo(BuildContext context, Map<String, dynamic> nodo, int depth, {bool isLast = true}) {
    final tipo = nodo['tipo'] as String? ?? '';
    final codigo = nodo['codigo'] as String? ?? '';
    final estado = nodo['estado'] as String? ?? '';
    final sunatStatus = nodo['sunatStatus'] as String?;
    // El backend marca `anulado=true` cuando se aplicó CDB/RC sobre el comprobante o la nota.
    // El sunatStatus original (ACEPTADO) no cambia; la anulación es flag aparte.
    final anulado = (nodo['anulado'] as bool?) ?? (estado == 'ANULADO');
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
        InkWell(
          onTap: ruta != null ? () => context.push(ruta) : null,
          borderRadius: BorderRadius.circular(8),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Conector └─▶ — altura sigue la del contenido (IntrinsicHeight)
                if (!esRaiz)
                  SizedBox(
                    width: 26,
                    child: CustomPaint(
                      painter: _ConnectorPainter(
                          color: Colors.grey.shade400, isLast: isLast),
                    ),
                  ),
              // Contenido
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  padding: EdgeInsets.symmetric(horizontal: esRaiz ? 10 : 8, vertical: esRaiz ? 8 : 6),
                  decoration: null,
                  child: Row(
                    children: [
                      Container(
                        width: esRaiz ? 32 : 24,
                        height: esRaiz ? 32 : 24,
                        decoration: BoxDecoration(
                          color: config.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(esRaiz ? 8 : 5),
                        ),
                        child: Icon(config.icon, size: esRaiz ? 18 : 14, color: config.color),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    codigo,
                                    style: TextStyle(
                                      fontSize: esRaiz ? 12 : 11,
                                      fontWeight: FontWeight.w700,
                                      color: anulado ? Colors.grey.shade600 : null,
                                      decoration: anulado
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _buildEstadoChip(estado, sunatStatus, anulado: anulado),
                              ],
                            ),
                            Row(
                              children: [
                                AppText(config.label, size: 8, color: config.color, fontWeight: FontWeight.w600),
                                if (fecha != null) ...[
                                  AppText('  •  ', size: 8, color: Colors.grey.shade400),
                                  AppText(DateFormatter.formatDate(fecha), size: 8, color: Colors.grey),
                                ],
                              ],
                            ),
                            if (detalle != null && detalle.isNotEmpty)
                              AppText(detalle, size: 8, color: Colors.grey.shade600),
                            if (anulado)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        size: 9, color: Colors.red.shade700),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Anulado oficialmente ante SUNAT',
                                      style: TextStyle(
                                          fontSize: 8.5,
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (monto != null)
                        Text(
                          '$simbolo ${_formatMonto(monto)}',
                          style: TextStyle(
                            fontSize: esRaiz ? 12 : 11,
                            fontWeight: FontWeight.w700,
                            color: anulado ? Colors.grey.shade500 : config.color,
                            decoration:
                                anulado ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      if (pdfUrl != null)
                        Padding(padding: const EdgeInsets.only(left: 4), child: Icon(Icons.picture_as_pdf, size: 13, color: Colors.red.shade300)),
                      if (ruta != null)
                        const Padding(padding: EdgeInsets.only(left: 2), child: Icon(Icons.chevron_right, size: 15, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
        if (hijos.isNotEmpty)
          Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(left: esRaiz ? 16.0 : 26.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < hijos.length; i++)
                      _buildNodo(context, hijos[i] as Map<String, dynamic>, depth + 1, isLast: i == hijos.length - 1),
                  ],
                ),
              ),
              // Continuación vertical del depth actual cuando este nodo
              // (a) no es raíz y (b) no es el último sibling. Cubre la zona
              // de los sub-hijos para conectar con el siguiente sibling al
              // mismo nivel de profundidad.
              if (!esRaiz && !isLast)
                Positioned(
                  left: 6,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 1.2,
                    color: Colors.grey.shade400,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildEstadoChip(String estado, String? sunatStatus, {bool anulado = false}) {
    // Cuando está anulado priorizamos mostrar "ANULADO" sobre el sunatStatus
    // (que sigue siendo ACEPTADO porque la anulación es flag aparte).
    final display = anulado ? 'ANULADO' : (sunatStatus ?? estado);
    final c = anulado
        ? _EC(Colors.red.shade50, Colors.red.shade300, Colors.red.shade800)
        : _estadoConfig(display);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (anulado) ...[
            Icon(Icons.cancel, size: 8, color: c.text),
            const SizedBox(width: 2),
          ],
          Text(display,
              style: TextStyle(
                  fontSize: 7.5, fontWeight: FontWeight.w700, color: c.text)),
        ],
      ),
    );
  }

  String _formatMonto(dynamic m) {
    if (m is num) return m.toStringAsFixed(2);
    return (double.tryParse(m.toString()) ?? 0).toStringAsFixed(2);
  }

  _TC _tipoConfig(String t) {
    switch (t) {
      case 'COTIZACION': return _TC('Cotización', Icons.request_quote, Colors.purple);
      case 'VENTA': return _TC('Venta', Icons.shopping_cart, AppColors.blue1);
      case 'FACTURA': return _TC('Factura', Icons.description, Colors.teal);
      case 'BOLETA': return _TC('Boleta', Icons.receipt, Colors.teal.shade700);
      case 'NOTA_CREDITO': return _TC('Nota Crédito', Icons.remove_circle_outline, Colors.orange);
      case 'NOTA_DEBITO': return _TC('Nota Débito', Icons.add_circle_outline, Colors.deepOrange);
      case 'GUIA_REMISION': return _TC('Guía Remisión', Icons.local_shipping, Colors.indigo);
      case 'PAGO': return _TC('Pago', Icons.payments, Colors.green);
      case 'CUOTA': return _TC('Cuota', Icons.event, Colors.amber.shade800);
      case 'DEVOLUCION': return _TC('Devolución', Icons.assignment_return, Colors.red);
      default: return _TC(t, Icons.insert_drive_file, Colors.grey);
    }
  }

  _EC _estadoConfig(String e) {
    switch (e.toUpperCase()) {
      case 'ACEPTADO': case 'COBRADA': case 'COMPLETADO': case 'PAGADA': case 'PROCESADA': case 'APROBADA': case 'CONVERTIDA':
        return _EC(Colors.green.shade50, Colors.green.shade300, Colors.green.shade800);
      case 'PENDIENTE': case 'BORRADOR': case 'PAGADA_PARCIAL':
        return _EC(Colors.orange.shade50, Colors.orange.shade300, Colors.orange.shade800);
      case 'PROCESANDO': case 'ENVIADO': case 'REGISTRADO':
        return _EC(Colors.blue.shade50, Colors.blue.shade300, Colors.blue.shade800);
      case 'RECHAZADO': case 'ANULADO': case 'CANCELADA': case 'VENCIDA': case 'ERROR_COMUNICACION':
        return _EC(Colors.red.shade50, Colors.red.shade300, Colors.red.shade800);
      default:
        return _EC(Colors.grey.shade100, Colors.grey.shade300, Colors.grey.shade700);
    }
  }
}

class _TC { final String label; final IconData icon; final Color color; _TC(this.label, this.icon, this.color); }
class _EC { final Color bg; final Color border; final Color text; _EC(this.bg, this.border, this.text); }

class _ConnectorPainter extends CustomPainter {
  final Color color;
  final bool isLast;
  // Y donde sale la flecha hacia el contenido. Fijo para que se alinee con la
  // primera línea del nodo, sin importar cuántas líneas tenga la card.
  static const double _elbowY = 18.0;
  _ConnectorPainter({required this.color, required this.isLast});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    // Vertical desde el top hasta el elbow
    canvas.drawLine(const Offset(6, 0), const Offset(6, _elbowY), paint);
    // Horizontal hacia el contenido
    canvas.drawLine(
        const Offset(6, _elbowY), Offset(size.width - 4, _elbowY), paint);
    // Flecha
    final arrowPaint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width - 4, _elbowY - 3)
      ..lineTo(size.width, _elbowY)
      ..lineTo(size.width - 4, _elbowY + 3)
      ..close();
    canvas.drawPath(path, arrowPaint);
    // Si no es el último, extender vertical hasta el bottom para que conecte
    // con el siguiente sibling.
    if (!isLast) {
      canvas.drawLine(
          const Offset(6, _elbowY), Offset(6, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      color != old.color || isLast != old.isLast;
}
