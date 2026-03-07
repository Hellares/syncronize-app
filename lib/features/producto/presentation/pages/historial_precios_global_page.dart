import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/widgets/custom_loading.dart';
import 'package:syncronize/core/widgets/custom_sede_selector.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/precio_historial_sede.dart';
import '../bloc/historial_precios/historial_precios_cubit.dart';
import '../bloc/historial_precios/historial_precios_state.dart';

class HistorialPreciosGlobalPage extends StatelessWidget {
  final String empresaId;

  const HistorialPreciosGlobalPage({super.key, required this.empresaId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<HistorialPreciosCubit>()..load(empresaId: empresaId),
      child: _HistorialPreciosView(empresaId: empresaId),
    );
  }
}

class _HistorialPreciosView extends StatefulWidget {
  final String empresaId;

  const _HistorialPreciosView({required this.empresaId});

  @override
  State<_HistorialPreciosView> createState() => _HistorialPreciosViewState();
}

class _HistorialPreciosViewState extends State<_HistorialPreciosView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _dfApi = DateFormat('yyyy-MM-dd');
  final _df = DateFormat('dd/MM/yyyy');
  final _nf = NumberFormat('#,##0.00');

  String? _selectedSedeId;
  String? _selectedTipoCambio;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _exporting = false;
  double _exportProgress = 0;
  bool _isTableView = false;

  static const _tiposCambio = [
    'MANUAL',
    'OFERTA',
    'COSTO',
    'MASIVO',
    'AJUSTE_MERCADO',
    'COMPETENCIA',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<HistorialPreciosCubit>().loadMore();
    }
  }

  void _applyFilters() {
    context.read<HistorialPreciosCubit>().load(
          empresaId: widget.empresaId,
          sedeId: _selectedSedeId,
          fechaInicio: _fechaInicio != null ? _dfApi.format(_fechaInicio!) : null,
          fechaFin: _fechaFin != null ? _dfApi.format(_fechaFin!) : null,
          tipoCambio: _selectedTipoCambio,
          search: _searchController.text.isEmpty ? null : _searchController.text,
        );
  }

  Future<void> _selectDate(bool isInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isInicio ? (_fechaInicio ?? DateTime.now()) : (_fechaFin ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isInicio) {
          _fechaInicio = picked;
          if (_fechaFin != null && _fechaInicio!.isAfter(_fechaFin!)) _fechaFin = _fechaInicio;
        } else {
          _fechaFin = picked;
          if (_fechaInicio != null && _fechaFin!.isBefore(_fechaInicio!)) _fechaInicio = _fechaFin;
        }
      });
      _applyFilters();
    }
  }

  Future<void> _export() async {
    if (_fechaInicio == null || _fechaFin == null) {
      _showMessage('Selecciona un rango de fechas para exportar', isError: true);
      return;
    }

    final inicio = _fechaInicio!;
    final fin = _fechaFin!;
    final maxFin = DateTime(inicio.year, inicio.month + 3, inicio.day);
    if (fin.isAfter(maxFin)) {
      _showMessage('El rango maximo de exportacion es de 3 meses', isError: true);
      return;
    }

    setState(() {
      _exporting = true;
      _exportProgress = 0;
    });

    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        final manage = await Permission.manageExternalStorage.request();
        if (!manage.isGranted) {
          _showMessage('Se necesita permiso de almacenamiento', isError: true);
          setState(() => _exporting = false);
          return;
        }
      }
    }

    if (!mounted) return;
    final cubit = context.read<HistorialPreciosCubit>();
    final result = await cubit.exportExcel(
          fechaInicio: _dfApi.format(_fechaInicio!),
          fechaFin: _dfApi.format(_fechaFin!),
          onReceiveProgress: (received, total) {
            if (total > 0 && mounted) {
              setState(() => _exportProgress = received / total);
            }
          },
        );

    if (result is Success<List<int>>) {
      final fileName = 'historial_precios_${_dfApi.format(_fechaInicio!)}_${_dfApi.format(_fechaFin!)}.xlsx';
      String filePath;
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          filePath = '${downloadDir.path}/$fileName';
        } else {
          final extDir = await getExternalStorageDirectory();
          filePath = '${extDir?.path ?? (await getApplicationDocumentsDirectory()).path}/$fileName';
        }
      } else {
        final dir = await getApplicationDocumentsDirectory();
        filePath = '${dir.path}/$fileName';
      }
      final file = File(filePath);
      await file.writeAsBytes(result.data);
      _showMessage('Exportado: $filePath');
    } else if (result is Error<List<int>>) {
      _showMessage(result.message, isError: true);
    }

    setState(() => _exporting = false);
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 12)),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        duration: Duration(seconds: isError ? 4 : 6),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
        title: 'Historial de Precios',
        actions: [
          IconButton(
            icon: Icon(_isTableView ? Icons.view_agenda : Icons.table_chart, size: 20),
            onPressed: () => setState(() => _isTableView = !_isTableView),
            tooltip: _isTableView ? 'Vista Cards' : 'Vista Tabla',
          ),
          if (_exporting)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.download, size: 20),
              onPressed: _export,
              tooltip: 'Exportar Excel',
            ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _applyFilters,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: GradientBackground(
        style: GradientStyle.minimal,
        child: Column(
          children: [
            _buildFilters(),
            if (_exporting && _exportProgress > 0)
              LinearProgressIndicator(
                value: _exportProgress,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue1),
                minHeight: 3,
              ),
            Expanded(
              child: BlocBuilder<HistorialPreciosCubit, HistorialPreciosState>(
                builder: (context, state) {
                  if (state is HistorialPreciosLoading) {
                    return CustomLoading.small(message: 'Cargando historial...');
                  }
                  if (state is HistorialPreciosError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(state.message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _applyFilters,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state is HistorialPreciosLoaded) {
                    if (state.items.isEmpty) return _buildEmptyState();
                    return _isTableView
                        ? _buildTableView(state.items, state.hasMore)
                        : _buildCardView(state.items, state.hasMore);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return BlocBuilder<HistorialPreciosCubit, HistorialPreciosState>(
      buildWhen: (prev, curr) {
        if (curr is HistorialPreciosLoaded && prev is! HistorialPreciosLoaded) return true;
        if (curr is HistorialPreciosLoaded && prev is HistorialPreciosLoaded) {
          return curr.sedes.length != prev.sedes.length;
        }
        return false;
      },
      builder: (context, state) {
        final sedes = state is HistorialPreciosLoaded ? state.sedes : [];

        // Auto-seleccionar sede principal si aún no hay selección
        if (_selectedSedeId == null && sedes.isNotEmpty) {
          final principal = sedes.where((s) => s.esPrincipal);
          _selectedSedeId = principal.isNotEmpty ? principal.first.id : sedes.first.id;
        }

        final currentSede = _selectedSedeId != null && sedes.isNotEmpty
            ? (sedes.any((s) => s.id == _selectedSedeId) ? sedes.firstWhere((s) => s.id == _selectedSedeId) : sedes.first)
            : null;

        return GradientContainer(
          margin: const EdgeInsets.all(10),
          shadowStyle: ShadowStyle.neumorphic,
          borderColor: AppColors.blueborder,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar producto...',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  style: const TextStyle(fontSize: 12),
                  onSubmitted: (_) => _applyFilters(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: sedes.length > 1 && currentSede != null
                          ? CustomSedeSelector(
                              sedes: sedes,
                              currentSede: currentSede,
                              onSelected: (sedeId) {
                                if (sedeId == _selectedSedeId) return;
                                setState(() => _selectedSedeId = sedeId);
                                _applyFilters();
                              },
                            )
                          : CustomDropdown<String>(
                              label: 'Sede',
                              hintText: 'Todas',
                              value: _selectedSedeId,
                              borderColor: AppColors.blueborder,
                              items: [
                                const DropdownItem(value: '', label: 'Todas'),
                                ...sedes.map((s) => DropdownItem(value: s.id, label: s.nombre)),
                              ],
                              onChanged: (v) {
                                final newId = (v == null || v.isEmpty) ? null : v;
                                if (newId == _selectedSedeId) return;
                                setState(() => _selectedSedeId = newId);
                                _applyFilters();
                              },
                            ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomDropdown<String>(
                        label: 'Tipo Cambio',
                        hintText: 'Todos',
                        value: _selectedTipoCambio,
                        borderColor: AppColors.blueborder,
                        items: [
                          const DropdownItem(value: '', label: 'Todos'),
                          ..._tiposCambio.map((t) => DropdownItem(value: t, label: t)),
                        ],
                        onChanged: (v) {
                          setState(() => _selectedTipoCambio = (v == null || v.isEmpty) ? null : v);
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(true),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Desde',
                            labelStyle: const TextStyle(fontSize: 11),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            suffixIcon: _fechaInicio != null
                                ? GestureDetector(
                                    onTap: () {
                                      setState(() => _fechaInicio = null);
                                      _applyFilters();
                                    },
                                    child: const Icon(Icons.clear, size: 14),
                                  )
                                : const Icon(Icons.calendar_today, size: 14),
                          ),
                          child: Text(
                            _fechaInicio != null ? _df.format(_fechaInicio!) : '-',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(false),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Hasta',
                            labelStyle: const TextStyle(fontSize: 11),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            suffixIcon: _fechaFin != null
                                ? GestureDetector(
                                    onTap: () {
                                      setState(() => _fechaFin = null);
                                      _applyFilters();
                                    },
                                    child: const Icon(Icons.clear, size: 14),
                                  )
                                : const Icon(Icons.calendar_today, size: 14),
                          ),
                          child: Text(
                            _fechaFin != null ? _df.format(_fechaFin!) : '-',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Sin registros', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text(
            'No se encontraron cambios de precios\ncon los filtros seleccionados',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ─── Vista Cards ───────────────────────────────────────────────────

  Widget _buildCardView(List<PrecioHistorialSede> items, bool hasMore) {
    return RefreshIndicator(
      onRefresh: () async => _applyFilters(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: items.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return _HistorialTile(item: items[index], nf: _nf);
        },
      ),
    );
  }

  // ─── Vista Tabla ───────────────────────────────────────────────────

  Widget _buildTableView(List<PrecioHistorialSede> items, bool hasMore) {
    const headerStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white);
    const cellStyle = TextStyle(fontSize: 10);

    return RefreshIndicator(
      onRefresh: () async => _applyFilters(),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
            child: DataTable(
              headingRowHeight: 36,
              dataRowMinHeight: 34,
              dataRowMaxHeight: 48,
              horizontalMargin: 10,
              columnSpacing: 12,
              headingRowColor: WidgetStateProperty.all(AppColors.blue1),
              columns: const [
                DataColumn(label: Text('Fecha', style: headerStyle)),
                DataColumn(label: Text('Producto', style: headerStyle)),
                DataColumn(label: Text('Sede', style: headerStyle)),
                DataColumn(label: Text('Tipo', style: headerStyle)),
                DataColumn(label: Text('Venta Ant.', style: headerStyle), numeric: true),
                DataColumn(label: Text('Venta Nvo.', style: headerStyle), numeric: true),
                DataColumn(label: Text('Costo Ant.', style: headerStyle), numeric: true),
                DataColumn(label: Text('Costo Nvo.', style: headerStyle), numeric: true),
                DataColumn(label: Text('Oferta Ant.', style: headerStyle), numeric: true),
                DataColumn(label: Text('Oferta Nvo.', style: headerStyle), numeric: true),
                DataColumn(label: Text('Usuario', style: headerStyle)),
                DataColumn(label: Text('Razon', style: headerStyle)),
              ],
              rows: [
                ...items.map((item) {
                  final color = _getColor(item.tipoCambio);
                  final productoLabel = _productoLabel(item);

                  return DataRow(
                    cells: [
                      DataCell(Text(DateFormatter.formatDateTime(item.creadoEn), style: cellStyle)),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(productoLabel, style: cellStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      DataCell(Text(item.sedeName, style: cellStyle)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(item.tipoCambio, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      DataCell(_priceCell(item.precioAnterior, isOld: true)),
                      DataCell(_priceCell(item.precioNuevo, isOld: false)),
                      DataCell(_priceCell(item.precioCostoAnterior, isOld: true)),
                      DataCell(_priceCell(item.precioCostoNuevo, isOld: false)),
                      DataCell(_priceCell(item.precioOfertaAnterior, isOld: true)),
                      DataCell(_priceCell(item.precioOfertaNuevo, isOld: false)),
                      DataCell(Text(item.usuarioNombre ?? '-', style: cellStyle)),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Text(item.razon ?? '-', style: cellStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  );
                }),
                if (hasMore)
                  DataRow(cells: List.generate(12, (i) {
                    if (i == 0) {
                      return const DataCell(
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      );
                    }
                    return const DataCell(SizedBox.shrink());
                  })),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _priceCell(double? value, {required bool isOld}) {
    if (value == null) return const Text('-', style: TextStyle(fontSize: 10, color: Colors.grey));
    return Text(
      _nf.format(value),
      style: TextStyle(
        fontSize: 10,
        color: isOld ? Colors.red : Colors.green.shade700,
        decoration: isOld ? TextDecoration.lineThrough : null,
        fontWeight: isOld ? FontWeight.w400 : FontWeight.w600,
      ),
    );
  }

  String _productoLabel(PrecioHistorialSede item) {
    final nombre = item.productoNombre ?? 'Producto';
    if (item.varianteNombre != null) {
      return '$nombre - ${item.varianteNombre}';
    }
    return nombre;
  }

  static Color _getColor(String tipo) {
    switch (tipo) {
      case 'MANUAL': return Colors.blue;
      case 'OFERTA': case 'OFERTA_ACTIVADA': case 'OFERTA_DESACTIVADA': return Colors.orange;
      case 'COSTO': case 'COSTO_ACTUALIZADO': return Colors.green;
      case 'MASIVO': case 'AJUSTE_MASIVO': return Colors.purple;
      case 'AJUSTE_MERCADO': return Colors.teal;
      case 'COMPETENCIA': return Colors.red;
      default: return Colors.grey;
    }
  }
}

// ─── Card Tile ─────────────────────────────────────────────────────

class _HistorialTile extends StatelessWidget {
  final PrecioHistorialSede item;
  final NumberFormat nf;

  const _HistorialTile({required this.item, required this.nf});

  @override
  Widget build(BuildContext context) {
    final color = _HistorialPreciosViewState._getColor(item.tipoCambio);
    final icon = _getIcon(item.tipoCambio);
    final productoLabel = item.productoNombre ?? 'Producto';
    final varianteLabel = item.varianteNombre != null
        ? ' - ${item.varianteNombre}${item.varianteSku != null ? ' (${item.varianteSku})' : ''}'
        : '';

    return GradientContainer(
      margin: const EdgeInsets.only(bottom: 8),
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$productoLabel$varianteLabel',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          if (item.productoCodigo != null) ...[
                            Text(item.productoCodigo!, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                            const SizedBox(width: 8),
                          ],
                          Text(item.sedeName, style: const TextStyle(fontSize: 10, color: AppColors.blue1)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.tipoCambio,
                        style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormatter.formatDateTime(item.creadoEn),
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildPriceChanges(),
            if (item.razon != null && item.razon!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.notes, size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(item.razon!, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  ),
                ],
              ),
            ],
            if (item.usuarioNombre != null && item.usuarioNombre!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(item.usuarioNombre!, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceChanges() {
    final changes = <Widget>[];

    if (item.precioAnterior != null || item.precioNuevo != null) {
      changes.add(_buildPriceRow('Venta', item.precioAnterior, item.precioNuevo));
    }
    if (item.precioCostoAnterior != null || item.precioCostoNuevo != null) {
      changes.add(_buildPriceRow('Costo', item.precioCostoAnterior, item.precioCostoNuevo));
    }
    if (item.precioOfertaAnterior != null || item.precioOfertaNuevo != null) {
      changes.add(_buildPriceRow('Oferta', item.precioOfertaAnterior, item.precioOfertaNuevo));
    }

    if (changes.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 12, runSpacing: 4, children: changes);
  }

  Widget _buildPriceRow(String label, double? anterior, double? nuevo) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
        if (anterior != null) ...[
          Text(nf.format(anterior), style: const TextStyle(fontSize: 10, color: Colors.red, decoration: TextDecoration.lineThrough)),
          const Icon(Icons.arrow_right_alt, size: 14, color: Colors.grey),
        ],
        if (nuevo != null)
          Text(nf.format(nuevo), style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600)),
      ],
    );
  }

  IconData _getIcon(String tipo) {
    switch (tipo) {
      case 'MANUAL': return Icons.edit;
      case 'OFERTA': case 'OFERTA_ACTIVADA': case 'OFERTA_DESACTIVADA': return Icons.local_offer;
      case 'COSTO': case 'COSTO_ACTUALIZADO': return Icons.attach_money;
      case 'MASIVO': case 'AJUSTE_MASIVO': return Icons.tune;
      case 'AJUSTE_MERCADO': return Icons.trending_up;
      case 'COMPETENCIA': return Icons.people;
      default: return Icons.history;
    }
  }
}
