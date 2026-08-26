import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_cubit.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_state.dart';
import '../../../configuracion_documentos/domain/entities/configuracion_documento_completa.dart';
import '../../../configuracion_documentos/domain/entities/plantilla_documento.dart';
import '../../../configuracion_documentos/domain/usecases/get_configuracion_completa_usecase.dart';
import '../../domain/entities/compra.dart';
import '../../domain/usecases/actualizar_compra_usecase.dart';
import '../../domain/usecases/get_compra_usecase.dart';
import '../../domain/usecases/confirmar_compra_usecase.dart';
import '../widgets/confirmar_pago_compra_sheet.dart';
import '../widgets/gasto_factura_dialog.dart';
import '../../domain/usecases/anular_compra_usecase.dart';
import '../../domain/usecases/eliminar_compra_usecase.dart';
import 'documento_compra_preview_page.dart';

class CompraDetailPage extends StatefulWidget {
  final String empresaId;
  final Compra compra;

  const CompraDetailPage({
    super.key,
    required this.empresaId,
    required this.compra,
  });

  @override
  State<CompraDetailPage> createState() => _CompraDetailPageState();
}

class _CompraDetailPageState extends State<CompraDetailPage> {
  late Compra _compra;
  bool _isLoadingDetail = true;
  bool _guardandoGastos = false;

  @override
  void initState() {
    super.initState();
    _compra = widget.compra;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final result = await locator<GetCompraUseCase>()(
      empresaId: widget.empresaId,
      id: widget.compra.id,
    );

    if (!mounted) return;

    if (result is Success<Compra>) {
      setState(() {
        _compra = result.data;
        _isLoadingDetail = false;
      });
    } else {
      setState(() => _isLoadingDetail = false);
    }
  }

  /// Los gastos guardados, en la forma que espera el diálogo y el backend.
  List<Map<String, dynamic>> get _gastosEditables => (_compra.gastos ?? [])
      .map((g) => {
            'concepto': g.concepto,
            'monto': g.monto,
            'prorratea': g.prorratea,
            'criterio': g.criterio,
            'categoriaGastoId': g.categoriaGastoId,
            'categoriaNombre': g.categoriaNombre,
          })
      .toList();

  /// Guarda la lista COMPLETA de gastos y se queda con la compra que devuelve
  /// el backend (trae los totales ya recalculados).
  ///
  /// Se guarda en el momento, sin borrador: un sheet con cambios sin guardar
  /// se pierde al arrastrarlo hacia abajo sin pasar por ninguna guarda.
  /// Ver feedback_bottomsheet_arrastre_saltea_popscope.
  Future<void> _guardarGastos(
    List<Map<String, dynamic>> gastos,
    String mensajeOk,
  ) async {
    setState(() => _guardandoGastos = true);

    final result = await locator<ActualizarCompraUseCase>()(
      empresaId: widget.empresaId,
      id: _compra.id,
      // Por el mapeo compartido: los mapas llevan el nombre de la categoría
      // para poder mostrarlo, y esa clave de más sería un 400.
      data: {'gastos': gastos.map(gastoAPayload).toList()},
    );

    if (!mounted) return;
    setState(() {
      _guardandoGastos = false;
      if (result is Success<Compra>) _compra = result.data;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result is Error<Compra> ? result.message : mensajeOk,
        ),
        backgroundColor:
            result is Error<Compra> ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _editarGasto({int? index}) async {
    final actuales = _gastosEditables;
    final gasto = await mostrarDialogoGastoFactura(
      context,
      inicial: index != null ? actuales[index] : null,
    );
    if (gasto == null) return;

    if (index == null) {
      actuales.add(gasto);
    } else {
      actuales[index] = gasto;
    }
    await _guardarGastos(
      actuales,
      index == null ? 'Gasto agregado' : 'Gasto actualizado',
    );
  }

  Future<void> _eliminarGasto(int index) async {
    final actuales = _gastosEditables;
    final concepto = actuales[index]['concepto'];
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar gasto'),
        content: Text(
          '¿Quitar "$concepto" de la factura? El costo de los productos se '
          'vuelve a calcular sin ese monto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quitar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    actuales.removeAt(index);
    await _guardarGastos(actuales, 'Gasto quitado');
  }

  IconData _estadoIcon() {
    switch (_compra.estado) {
      case EstadoCompra.BORRADOR:
        return Icons.edit_note;
      case EstadoCompra.CONFIRMADA:
        return Icons.check_circle;
      case EstadoCompra.ANULADA:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: _compra.codigo,
        // El subtítulo del SmartAppBar existe para esto: la metadata breve
        // que antes ocupaba una franja entera abajo.
        subtitle: DateFormatter.formatDate(_compra.fechaRecepcion),
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _mostrarOpcionesPDF(),
            tooltip: 'Generar PDF',
          ),
          if (_compra.puedeConfirmar ||
              _compra.puedeAnular ||
              _compra.esBorrador)
            PopupMenuButton<String>(
              onSelected: (action) => _handleAction(context, action),
              itemBuilder: (context) => [
                if (_compra.puedeConfirmar)
                  const PopupMenuItem(
                    value: 'confirmar',
                    child: ListTile(
                      leading:
                          Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Confirmar'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (_compra.puedeAnular)
                  const PopupMenuItem(
                    value: 'anular',
                    child: ListTile(
                      leading: Icon(Icons.cancel, color: Colors.red),
                      title: Text('Anular'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (_compra.esBorrador)
                  const PopupMenuItem(
                    value: 'eliminar',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Eliminar'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDetail,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildProveedorCard(),
                    const SizedBox(height: 12),
                    _buildInfoCard(),
                    const SizedBox(height: 12),
                    _buildMontosCard(),
                    const SizedBox(height: 12),
                    _buildDetallesSection(),
                    if (_compra.observaciones != null &&
                        _compra.observaciones!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildNotasCard(
                        'Observaciones',
                        _compra.observaciones!,
                        Icons.notes,
                      ),
                    ],
                    if (_compra.estado == EstadoCompra.CONFIRMADA) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(
                            '/empresa/guias-remision/nueva',
                            extra: {
                              'compraId': _compra.id,
                              'motivoTraslado': 'COMPRA',
                            },
                          ),
                          icon: const Icon(Icons.local_shipping, size: 18),
                          label: const Text('Guía Remisión'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.indigo,
                            side: const BorderSide(color: Colors.indigo),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                    // 🔴 El último botón queda bajo la barra de navegación
                    // del celular. Va SUMADO al padding del contenido y no
                    // como SafeArea envolvente, que cortaría el scroll.
                    // Ver feedback_safearea_bottom_nav_custom.
                    SizedBox(
                      height: 24 + MediaQuery.of(context).padding.bottom,
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

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.blue1,
            AppColors.blue1.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estado y total en la MISMA fila: son las dos cosas que se
              // miran de un vistazo, y apiladas se comían media pantalla.
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_estadoIcon(), size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          _compra.estadoTexto,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_compra.moneda} ${_compra.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              // La fecha ya vive en el subtítulo del AppBar; acá queda solo
              // lo que no entra ahí.
              if (_compra.sedeNombre.isNotEmpty ||
                  _compra.ordenCompraCodigo != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (_compra.sedeNombre.isNotEmpty)
                      _buildHeaderChip(Icons.store, _compra.sedeNombre),
                    if (_compra.ordenCompraCodigo != null)
                      _buildHeaderChip(Icons.receipt_long,
                          'OC: ${_compra.ordenCompraCodigo}'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProveedorCard() {
    // Documento del proveedor (factura/boleta)
    String? docProveedor;
    if (_compra.tipoDocumentoProveedor != null) {
      final serie = _compra.serieDocumentoProveedor ?? '';
      final numero = _compra.numeroDocumentoProveedor ?? '';
      docProveedor =
          '${_compra.tipoDocumentoProveedor} $serie-$numero'.trim();
    }

    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      shadowStyle: ShadowStyle.colorful,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.business,
                    size: 18, color: AppColors.blue1),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText('PROVEEDOR',
                        size: 10, color: AppColors.blueGrey),
                    const SizedBox(height: 2),
                    Text(
                      _compra.nombreProveedor,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_compra.documentoProveedor != null || docProveedor != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (_compra.documentoProveedor != null &&
                    _compra.documentoProveedor!.isNotEmpty)
                  _buildMiniInfo(
                      Icons.badge_outlined, _compra.documentoProveedor!),
                if (docProveedor != null)
                  _buildMiniInfo(Icons.description_outlined, docProveedor),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.blueGrey),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.blueGrey),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      shadowStyle: ShadowStyle.colorful,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.info_outline, 'INFORMACION'),
          const SizedBox(height: 12),
          _buildInfoRow('Fecha Recepcion',
              DateFormatter.formatDate(_compra.fechaRecepcion)),
          _buildInfoRow('Moneda', _compra.moneda),
          if (_compra.sedeNombre.isNotEmpty)
            _buildInfoRow('Sede', _compra.sedeNombre),
          if (_compra.terminosPago != null &&
              _compra.terminosPago!.isNotEmpty)
            _buildInfoRow('Terminos de Pago', _compra.terminosPago!),
          if (_compra.diasCredito != null)
            _buildInfoRow('Dias Credito', '${_compra.diasCredito} dias'),
          if (_compra.fechaVencimientoPago != null)
            _buildInfoRow('Venc. Pago',
                DateFormatter.formatDate(_compra.fechaVencimientoPago!)),
          if (_compra.confirmadoEn != null)
            _buildInfoRow(
                'Confirmada', DateFormatter.formatDateTime(_compra.confirmadoEn!)),
        ],
      ),
    );
  }

  /// Un gasto dentro del resumen. En BORRADOR se toca para editarlo y trae
  /// su propia X para quitarlo; confirmada, es solo lectura.
  Widget _buildGastoRow(int index, CompraGasto g) {
    final editable = _compra.esBorrador && !_guardandoGastos;
    final fila = Row(
      children: [
        Icon(
          g.prorratea ? Icons.call_split : Icons.remove_circle_outline,
          size: 11,
          color: g.prorratea ? Colors.green.shade700 : Colors.grey.shade500,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: AppSubtitle(
            [
              g.concepto,
              if (g.categoriaNombre != null) g.categoriaNombre!,
              if (g.prorratea)
                'al costo ${g.criterio == 'CANTIDAD' ? 'por cantidad' : 'por valor'}'
              else
                'no toca el costo',
            ].join(' · '),
            fontSize: 10,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          '${_compra.moneda} ${g.monto.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
        ),
        if (_compra.esBorrador)
          // 🔴 Sin `shrinkWrap` el IconButton reserva ~48px y mete separación
          // fantasma en una fila de 10px de fuente.
          // Ver feedback_iconbutton_m3_tap_target_minimo.
          IconButton(
            onPressed: editable ? () => _eliminarGasto(index) : null,
            icon: const Icon(Icons.close, size: 14),
            color: Colors.grey.shade500,
            tooltip: 'Quitar gasto',
            style: IconButton.styleFrom(
              minimumSize: Size.zero,
              fixedSize: const Size(30, 30),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 2),
      child: editable
          ? InkWell(
              onTap: () => _editarGasto(index: index),
              borderRadius: BorderRadius.circular(6),
              child: fila,
            )
          : fila,
    );
  }

  Widget _buildAgregarGastoLink(bool sinGastos) {
    return Padding(
      padding: EdgeInsets.only(top: sinGastos ? 6 : 2, left: 6),
      child: InkWell(
        onTap: _guardandoGastos ? null : () => _editarGasto(),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_guardandoGastos)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.6),
                )
              else
                const Icon(Icons.add, size: 14, color: AppColors.blue1),
              const SizedBox(width: 4),
              AppSubtitle(
                sinGastos ? 'Agregar flete o movilidad' : 'Agregar otro gasto',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.blue1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMontosCard() {
    // 🔴 `subtotal` e `impuestos` del backend YA traen adentro la base y el
    // IGV de los gastos (`subtotal = Σdetalle.subtotal + Σgasto.base`). Si se
    // los muestra tal cual y abajo se lista "Gastos" como un renglón más, la
    // columna no cierra: parece que el flete se cobra dos veces. Restándolos,
    // Mercadería + IGV + Gastos da exactamente el total.
    final gastos = _compra.gastos ?? [];
    final baseGastos = gastos.fold<double>(0, (s, g) => s + g.base);
    final igvGastos = gastos.fold<double>(0, (s, g) => s + g.igv);
    final mercaderia = _compra.subtotal - baseGastos;
    final igvMercaderia = _compra.impuestos - igvGastos;

    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      shadowStyle: ShadowStyle.colorful,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.receipt_long, 'RESUMEN DE MONTOS'),
          const SizedBox(height: 12),
          _buildMontoRow(gastos.isEmpty ? 'Subtotal' : 'Mercadería',
              '${_compra.moneda} ${mercaderia.toStringAsFixed(2)}'),
          if (_compra.descuento > 0)
            _buildMontoRow(
              'Descuento',
              '- ${_compra.moneda} ${_compra.descuento.toStringAsFixed(2)}',
              valueColor: Colors.red.shade600,
            ),
          _buildMontoRow('Impuestos (IGV)',
              '${_compra.moneda} ${igvMercaderia.toStringAsFixed(2)}'),
          // Gastos de la factura que no son productos. Van con su monto
          // ENTERO (el IGV del gasto, si lo tiene, va adentro y por eso se
          // descontó del renglón de impuestos).
          if (gastos.isNotEmpty) ...[
            _buildMontoRow('Gastos (flete, movilidad)',
                '${_compra.moneda} ${_compra.totalGastos.toStringAsFixed(2)}'),
            ...gastos.asMap().entries.map(
                  (e) => _buildGastoRow(e.key, e.value),
                ),
          ],
          // Mientras la compra sea BORRADOR el flete todavía se puede
          // arreglar: al confirmar se congela dentro del precioCosto y ya no
          // hay vuelta atrás sin anular la compra entera.
          if (_compra.esBorrador) _buildAgregarGastoLink(gastos.isEmpty),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue3,
                ),
              ),
              Text(
                '${_compra.moneda} ${_compra.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetallesSection() {
    if (_isLoadingDetail) {
      return GradientContainer(
        gradient: AppGradients.blueWhiteBlue(),
        borderColor: AppColors.blueborder,
        shadowStyle: ShadowStyle.colorful,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.inventory_2_outlined, 'PRODUCTOS'),
            const SizedBox(height: 24),
            const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    final detalles = _compra.detalles;
    if (detalles == null || detalles.isEmpty) {
      return GradientContainer(
        gradient: AppGradients.blueWhiteBlue(),
        borderColor: AppColors.blueborder,
        shadowStyle: ShadowStyle.colorful,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.inventory_2_outlined, 'PRODUCTOS'),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(
                    'Sin productos',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      shadowStyle: ShadowStyle.colorful,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSectionHeader(
                  Icons.inventory_2_outlined,
                  'PRODUCTOS (${detalles.length})',
                ),
              ),
              // La moneda una vez arriba y no repetida en cada celda: con
              // cuatro columnas angostas, el "S/" delante de cada número se
              // come el ancho que necesitan los importes.
              AppSubtitle(_compra.moneda, fontSize: 10, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 10),
          _buildDetallesTabla(detalles),
        ],
      ),
    );
  }

  /// Las líneas en tabla y no en cards: una card por producto obliga a saltar
  /// de bloque en bloque para comparar precios, y en una compra de diez
  /// líneas ocupa media pantalla por ítem. Es la misma tabla del formulario
  /// de compra, para que la línea se lea igual antes y después de guardar.
  Widget _buildDetallesTabla(List<CompraDetalle> detalles) {
    final headerStyle = TextStyle(
      fontSize: 9,
      color: Colors.grey.shade600,
      fontWeight: FontWeight.w700,
    );
    final cellStyle = TextStyle(fontSize: 9.5, color: Colors.grey.shade800);

    Widget celda(String texto, TextStyle estilo,
        {TextAlign align = TextAlign.left}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        child: Text(
          texto,
          style: estilo,
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    final header = TableRow(
      decoration:
          BoxDecoration(color: AppColors.blue1.withValues(alpha: 0.07)),
      children: [
        celda('Producto', headerStyle),
        celda('Cant.', headerStyle, align: TextAlign.right),
        celda('P.Unit', headerStyle, align: TextAlign.right),
        celda('Total', headerStyle, align: TextAlign.right),
      ],
    );

    final filas = detalles.asMap().entries.map((entry) {
      final i = entry.key;
      final d = entry.value;
      final loteCodigo = d.lote?['codigo'] as String?;

      // Si la línea entró por unidad de compra, la columna habla en la unidad
      // en la que se compró (el saco) y el equivalente atómico va abajo.
      final usaUC = d.usaUnidadCompra && d.unidadOriginalSimbolo != null;
      final cantTxt = usaUC
          ? '${_fmtCant(d.cantidadOriginal ?? d.cantidad.toDouble())} '
              '${d.unidadOriginalSimbolo}'
          : '${d.cantidad}';
      final precioTxt = usaUC
          ? (d.precioUnitario * (d.factorAplicado ?? 1)).toStringAsFixed(2)
          : d.precioUnitario.toStringAsFixed(2);

      return TableRow(
        decoration: BoxDecoration(
          color: i.isOdd ? Colors.grey.withValues(alpha: 0.04) : Colors.white,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.nombreProducto,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (usaUC)
                  Text(
                    '= ${d.cantidad} u @ ${d.precioUnitario.toStringAsFixed(2)}/u',
                    style: TextStyle(
                      fontSize: 8,
                      fontStyle: FontStyle.italic,
                      color: Colors.green.shade700,
                    ),
                  ),
                // Explica por qué el costo del producto no es el precio que
                // facturó el proveedor.
                if (d.gastoProrrateado > 0 && d.cantidad > 0)
                  Text(
                    '+ ${d.gastoProrrateado.toStringAsFixed(2)} gastos → costo '
                    '${((d.total + d.gastoProrrateado) / d.cantidad).toStringAsFixed(2)}/u',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade800,
                    ),
                  ),
                if (loteCodigo != null || d.descuento > 0)
                  Text(
                    [
                      if (loteCodigo != null) 'Lote $loteCodigo',
                      if (d.descuento > 0)
                        'desc. -${d.descuento.toStringAsFixed(2)}',
                    ].join(' · '),
                    style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          celda(cantTxt, cellStyle, align: TextAlign.right),
          celda(precioTxt, cellStyle, align: TextAlign.right),
          celda(
            d.total.toStringAsFixed(2),
            const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: AppColors.blue1,
            ),
            align: TextAlign.right,
          ),
        ],
      );
    }).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade200, width: 0.6),
        columnWidths: const {
          0: FlexColumnWidth(3.1),
          1: FlexColumnWidth(0.85),
          2: FlexColumnWidth(1.0),
          3: FlexColumnWidth(1.05),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [header, ...filas],
      ),
    );
  }

  /// Sin decimales cuando la cantidad es entera: "10 sacos", no "10.00 sacos".
  String _fmtCant(double v) =>
      v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  Widget _buildNotasCard(String title, String content, IconData icon) {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      shadowStyle: ShadowStyle.none,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(icon, title.toUpperCase()),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
                fontSize: 13, color: AppColors.blueGrey, height: 1.4),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.blue1),
        const SizedBox(width: 6),
        AppSubtitle(title, fontSize: 11, color: AppColors.blue3),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Text(
            value,
            style:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMontoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // --- PDF ---

  void _mostrarOpcionesPDF() {
    FormatoPapel selectedFormato = FormatoPapel.A4;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Generar PDF',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Formato de papel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<FormatoPapel>(
                      segments: FormatoPapel.values
                          .map((f) => ButtonSegment(value: f, label: Text(f.label)))
                          .toList(),
                      selected: {selectedFormato},
                      onSelectionChanged: (v) {
                        setModalState(() => selectedFormato = v.first);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Generar documento'),
                subtitle: const Text('PDF con todos los detalles de la compra'),
                onTap: () {
                  Navigator.pop(ctx);
                  _generarDocumentoPDF(formato: selectedFormato);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generarDocumentoPDF({FormatoPapel formato = FormatoPapel.A4}) async {
    final empresaState = context.read<EmpresaContextCubit>().state;

    if (empresaState is! EmpresaContextLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener la empresa')),
      );
      return;
    }

    final empresa = empresaState.context.empresa;

    String nombreImpuesto = 'IGV';
    double porcentajeImpuesto = 18.0;
    final configState = context.read<ConfiguracionEmpresaCubit>().state;
    if (configState is ConfiguracionEmpresaLoaded) {
      nombreImpuesto = configState.configuracion.nombreImpuesto;
      porcentajeImpuesto = configState.configuracion.impuestoDefaultPorcentaje;
    }

    ConfiguracionDocumentoCompleta? documentConfig;
    try {
      final result = await locator<GetConfiguracionCompletaUseCase>()(
        tipo: 'COMPRA',
        formato: formato.apiValue,
        sedeId: _compra.sedeId,
      );
      if (result is Success<ConfiguracionDocumentoCompleta>) {
        documentConfig = result.data;
      }
    } catch (_) {}

    Uint8List? logoBytes;
    final logoUrl = documentConfig?.configuracion.logoUrl ?? empresa.logo;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(logoUrl));
        if (response.statusCode == 200) {
          logoBytes = response.bodyBytes;
        }
      } catch (_) {}
    }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentoCompraPreviewPage(
          compra: _compra,
          empresaNombre: empresa.nombre,
          empresaRuc: empresa.ruc,
          nombreImpuesto: nombreImpuesto,
          porcentajeImpuesto: porcentajeImpuesto,
          documentConfig: documentConfig,
          formatoPapel: formato,
          logoEmpresa: logoBytes,
        ),
      ),
    );
  }

  // --- Acciones ---

  void _handleAction(BuildContext context, String action) async {
    switch (action) {
      case 'confirmar':
        final t = _compra.terminosPago?.toUpperCase() ?? '';
        final esContado = t.isEmpty || t == 'CONTADO';
        Map<String, dynamic>? pago;

        if (esContado) {
          // Contado: ofrecer registrar el pago; si lo omite, cae en CxP.
          final res = await ConfirmarPagoCompraSheet.mostrar(
            context,
            total: _compra.total,
            moneda: _compra.moneda,
          );
          if (res == null) break; // canceló → no confirma
          pago = res.omitir ? null : res.pago;
        } else {
          // Crédito: confirma directo (va a Cuentas por Pagar).
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Confirmar compra'),
              content: const Text(
                  'Al confirmar, se actualizara el stock y se crearan los lotes. La compra quedará en Cuentas por Pagar. Continuar?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
              ],
            ),
          );
          if (confirm != true) break;
        }

        if (context.mounted) {
          final result = await locator<ConfirmarCompraUseCase>()(
            empresaId: widget.empresaId,
            id: _compra.id,
            pago: pago,
          );
          if (result is Success<Compra> && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Compra confirmada - Stock actualizado'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop(true);
          } else if (result is Error<Compra> && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
      case 'anular':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Anular compra'),
            content: const Text(
                'Se revertiran los cambios de stock y los lotes creados. Continuar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Si, anular'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          final result = await locator<AnularCompraUseCase>()(
            empresaId: widget.empresaId,
            id: _compra.id,
          );
          if (result is Success<Compra> && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Compra anulada'),
                backgroundColor: Colors.orange,
              ),
            );
            context.pop(true);
          } else if (result is Error<Compra> && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
      case 'eliminar':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Eliminar compra'),
            content: const Text(
                'Esta seguro de eliminar esta compra? Esta accion no se puede deshacer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Si, eliminar'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          final result = await locator<EliminarCompraUseCase>()(
            empresaId: widget.empresaId,
            id: _compra.id,
          );
          if (result is Success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Compra eliminada'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop(true);
          } else if (result is Error<void> && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
    }
  }
}
