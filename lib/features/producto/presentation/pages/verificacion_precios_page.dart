import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/currency/currency_textfield.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/domain/entities/sede.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/producto_stock.dart';
import '../../domain/repositories/producto_stock_repository.dart';
import '../bloc/configurar_precios/configurar_precios_cubit.dart';
import '../widgets/configurar_precios_dialog.dart';

/// Pantalla de auditoría/verificación de precios. Filtros por valor sobre
/// precio venta/costo/oferta/liquidación + sede + stock + activo. Tabla
/// estilo Excel con scroll horizontal. Click en fila abre el dialog de
/// configurar precios para corregir directamente.
class VerificacionPreciosPage extends StatefulWidget {
  const VerificacionPreciosPage({super.key});

  @override
  State<VerificacionPreciosPage> createState() =>
      _VerificacionPreciosPageState();
}

enum _CampoPrecio { precio, costo, oferta, liquidacion }

enum _ModoVerificacion { rango, exacto, sinValor }

enum _FiltroStock { ambos, con, sin }

extension on _CampoPrecio {
  String get api {
    switch (this) {
      case _CampoPrecio.precio:
        return 'PRECIO';
      case _CampoPrecio.costo:
        return 'COSTO';
      case _CampoPrecio.oferta:
        return 'OFERTA';
      case _CampoPrecio.liquidacion:
        return 'LIQUIDACION';
    }
  }

  String get label {
    switch (this) {
      case _CampoPrecio.precio:
        return 'Precio Venta';
      case _CampoPrecio.costo:
        return 'Precio Costo';
      case _CampoPrecio.oferta:
        return 'Precio Oferta';
      case _CampoPrecio.liquidacion:
        return 'Precio Liquidación';
    }
  }
}

extension on _ModoVerificacion {
  String get api {
    switch (this) {
      case _ModoVerificacion.rango:
        return 'RANGO';
      case _ModoVerificacion.exacto:
        return 'EXACTO';
      case _ModoVerificacion.sinValor:
        return 'SIN_VALOR';
    }
  }

  String get label {
    switch (this) {
      case _ModoVerificacion.rango:
        return 'Rango (min/max)';
      case _ModoVerificacion.exacto:
        return 'Exacto';
      case _ModoVerificacion.sinValor:
        return 'Sin valor';
    }
  }
}

extension on _FiltroStock {
  String get api {
    switch (this) {
      case _FiltroStock.ambos:
        return 'AMBOS';
      case _FiltroStock.con:
        return 'CON';
      case _FiltroStock.sin:
        return 'SIN';
    }
  }

  String get label {
    switch (this) {
      case _FiltroStock.ambos:
        return 'Todos';
      case _FiltroStock.con:
        return 'Con stock';
      case _FiltroStock.sin:
        return 'Sin stock';
    }
  }
}

class _VerificacionPreciosPageState extends State<VerificacionPreciosPage> {
  final DioClient _dio = locator<DioClient>();
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  final _exactoCtrl = TextEditingController();

  List<Sede> _sedes = [];
  String? _sedeId;
  _CampoPrecio _campo = _CampoPrecio.costo;
  _ModoVerificacion _modo = _ModoVerificacion.rango;
  _FiltroStock _stock = _FiltroStock.ambos;
  bool _soloActivos = true;
  bool _filtrosColapsados = false;

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _items = const [];
  bool _limitAlcanzado = false;
  bool _exportando = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<EmpresaContextCubit>().state;
    if (state is EmpresaContextLoaded) {
      _sedes = state.context.sedes;
      if (_sedes.length == 1) _sedeId = _sedes.first.id;
    }
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _exactoCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildQuery() {
    final q = <String, dynamic>{
      'campo': _campo.api,
      'modo': _modo.api,
      'stock': _stock.api,
      'soloActivos': _soloActivos.toString(),
      'limit': 500,
    };
    if (_sedeId != null) q['sedeId'] = _sedeId;
    if (_modo == _ModoVerificacion.rango) {
      final min = double.tryParse(_minCtrl.text.replaceAll(',', '.'));
      final max = double.tryParse(_maxCtrl.text.replaceAll(',', '.'));
      if (min != null) q['min'] = min;
      if (max != null) q['max'] = max;
    } else if (_modo == _ModoVerificacion.exacto) {
      final ex = double.tryParse(_exactoCtrl.text.replaceAll(',', '.'));
      if (ex != null) q['exacto'] = ex;
    }
    return q;
  }

  Future<void> _buscar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await _dio.get(
        '/producto-stock/verificacion-precios',
        queryParameters: _buildQuery(),
      );
      final data = resp.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _items = (data['items'] as List).cast<Map<String, dynamic>>();
          _limitAlcanzado = data['limitAlcanzado'] as bool? ?? false;
          _loading = false;
          _filtrosColapsados = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is DioException
              ? (e.response?.data?['message']?.toString() ??
                  e.message ??
                  'Error al buscar')
              : e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _exportar() async {
    setState(() => _exportando = true);
    try {
      final query = Map<String, dynamic>.from(_buildQuery());
      query['limit'] = 5000;
      final resp = await _dio.get(
        '/producto-stock/verificacion-precios/export',
        queryParameters: query,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(minutes: 5),
        ),
      );
      final bytes = resp.data as List<int>;
      final fileName =
          'verificacion_precios_${DateTime.now().toIso8601String().substring(0, 10)}.xlsx';
      String path;
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          path = '${downloadDir.path}/$fileName';
        } else {
          final ext = await getExternalStorageDirectory();
          path = '${ext?.path ?? (await getApplicationDocumentsDirectory()).path}/$fileName';
        }
      } else {
        final dir = await getApplicationDocumentsDirectory();
        path = '${dir.path}/$fileName';
      }
      await File(path).writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exportado: $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al exportar: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  /// Abre el dialog de Configurar Precios para corregir desde la fila.
  Future<void> _abrirEdicion(Map<String, dynamic> item) async {
    final repo = locator<ProductoStockRepository>();
    final stockResult = item['productoId'] != null
        ? await repo.getStockProductoEnSede(
            productoId: item['productoId'] as String,
            sedeId: item['sedeId'] as String,
          )
        : await repo.getStockVarianteEnSede(
            varianteId: item['varianteId'] as String,
            sedeId: item['sedeId'] as String,
          );
    if (!mounted) return;
    if (stockResult is! Success<ProductoStock>) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cargar el stock')),
      );
      return;
    }
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;
    final empresaId = empresaState.context.empresa.id;
    final cambio = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => locator<ConfigurarPreciosCubit>(),
        child: ConfigurarPreciosDialog(
          stock: stockResult.data,
          empresaId: empresaId,
        ),
      ),
    );
    if (cambio == true) _buscar(); // refresh tras editar
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Verificación de precios',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          showLogo: false,
          actions: [
            if (_items.isNotEmpty)
              IconButton(
                tooltip: 'Exportar a Excel',
                icon: _exportando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download),
                onPressed: _exportando ? null : _exportar,
              ),
            IconButton(
              tooltip: _filtrosColapsados ? 'Mostrar filtros' : 'Ocultar filtros',
              icon: Icon(_filtrosColapsados
                  ? Icons.filter_alt
                  : Icons.filter_alt_off),
              onPressed: () =>
                  setState(() => _filtrosColapsados = !_filtrosColapsados),
            ),
          ],
        ),
        body: Column(
          children: [
            if (!_filtrosColapsados) _buildFiltros(),
            if (_limitAlcanzado)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                color: Colors.amber.shade100,
                child: Text(
                  'Solo se muestran los primeros 500. Refiná los filtros o usá Exportar para obtener todo.',
                  style:
                      TextStyle(fontSize: 11, color: Colors.amber.shade900),
                ),
              ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        children: [
          if (_sedes.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CustomDropdown<String?>(
                value: _sedeId,
                items: [
                  const DropdownItem(value: null, label: 'Todas las sedes'),
                  ..._sedes.map((s) => DropdownItem(value: s.id, label: s.nombre)),
                ],
                onChanged: (v) => setState(() => _sedeId = v),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: CustomDropdown<_CampoPrecio>(
                  value: _campo,
                  items: _CampoPrecio.values
                      .map((c) => DropdownItem(value: c, label: c.label))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _campo = v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomDropdown<_ModoVerificacion>(
                  value: _modo,
                  items: _ModoVerificacion.values
                      .map((m) => DropdownItem(value: m, label: m.label))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _modo = v);
                  },
                ),
              ),
            ],
          ),
          if (_modo == _ModoVerificacion.rango) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CurrencyTextField(
                    controller: _minCtrl,
                    label: 'Mínimo',
                    allowZero: true,
                    requiredField: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CurrencyTextField(
                    controller: _maxCtrl,
                    label: 'Máximo',
                    allowZero: true,
                    requiredField: false,
                  ),
                ),
              ],
            ),
          ] else if (_modo == _ModoVerificacion.exacto) ...[
            const SizedBox(height: 8),
            CurrencyTextField(
              controller: _exactoCtrl,
              label: 'Valor exacto',
              allowZero: true,
              requiredField: false,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CustomDropdown<_FiltroStock>(
                  value: _stock,
                  items: _FiltroStock.values
                      .map((s) => DropdownItem(value: s, label: s.label))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _stock = v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Solo activos',
                        style: TextStyle(fontSize: 12)),
                    value: _soloActivos,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (v) =>
                        setState(() => _soloActivos = v ?? true),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _buscar,
              icon: _loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search, size: 16),
              label: const Text('Buscar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue1,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  color: Colors.red.shade400, size: 40),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: _buscar, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, color: Colors.grey.shade400, size: 50),
              const SizedBox(height: 8),
              Text(
                _loading
                    ? 'Buscando…'
                    : 'Ajustá los filtros y tocá Buscar',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }
    return _buildTabla();
  }

  Widget _buildTabla() {
    final dataColor = AppColors.blue1;
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Text(
                  '${_items.length} resultado(s)',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width),
                child: DataTable(
                  headingRowColor:
                      WidgetStatePropertyAll(dataColor.withValues(alpha: 0.08)),
                  headingTextStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: dataColor,
                  ),
                  dataTextStyle: const TextStyle(fontSize: 11),
                  columnSpacing: 18,
                  horizontalMargin: 12,
                  columns: const [
                    DataColumn(label: Text('Código')),
                    DataColumn(label: Text('Producto')),
                    DataColumn(label: Text('Sede')),
                    DataColumn(label: Text('Stock'), numeric: true),
                    DataColumn(label: Text('Venta'), numeric: true),
                    DataColumn(label: Text('Costo'), numeric: true),
                    DataColumn(label: Text('Oferta'), numeric: true),
                    DataColumn(label: Text('Liquid.'), numeric: true),
                  ],
                  rows: _items.map((item) {
                    final precio = (item['precio'] as num?)?.toDouble();
                    final costo = (item['precioCosto'] as num?)?.toDouble();
                    final oferta =
                        (item['precioOferta'] as num?)?.toDouble();
                    final liq =
                        (item['precioLiquidacion'] as num?)?.toDouble();
                    final enLiq = item['enLiquidacion'] as bool? ?? false;
                    return DataRow(
                      onSelectChanged: (_) => _abrirEdicion(item),
                      cells: [
                        DataCell(Text(item['codigoEmpresa']?.toString() ?? '')),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Text(
                              item['nombre']?.toString() ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(Text(item['sedeNombre']?.toString() ?? '')),
                        DataCell(Text('${item['stockActual']}')),
                        DataCell(Text(precio != null
                            ? precio.toStringAsFixed(2)
                            : '—')),
                        DataCell(Text(costo != null
                            ? costo.toStringAsFixed(2)
                            : '—')),
                        DataCell(Text(oferta != null
                            ? oferta.toStringAsFixed(2)
                            : '—')),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(liq != null ? liq.toStringAsFixed(2) : '—'),
                              if (enLiq) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.local_fire_department,
                                    size: 12,
                                    color: Colors.deepOrange.shade700),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
