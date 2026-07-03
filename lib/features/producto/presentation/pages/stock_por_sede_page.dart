import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/network/dio_client.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/custom_loading.dart';
import 'package:syncronize/core/widgets/custom_search_field.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../sede/presentation/bloc/sede_list/sede_list_cubit.dart';
import '../../../sede/presentation/bloc/sede_list/sede_list_state.dart';
import '../bloc/stock_por_sede/stock_por_sede_cubit.dart';
import '../bloc/stock_por_sede/stock_por_sede_state.dart';
import '../bloc/ajustar_stock/ajustar_stock_cubit.dart';
import '../../domain/entities/producto_stock.dart';
import '../widgets/ajustar_stock_dialog.dart';
import '../widgets/historial_movimientos_bottom_sheet.dart';

class StockPorSedePage extends StatefulWidget {
  final String? sedeId; // Si es null, muestra selector de sede

  const StockPorSedePage({
    super.key,
    this.sedeId,
  });

  @override
  State<StockPorSedePage> createState() => _StockPorSedePageState();
}

class _StockPorSedePageState extends State<StockPorSedePage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String? _selectedSedeId;
  String? _empresaId;

  // Scroll horizontal sincronizado entre la cabecera sticky y el cuerpo de
  // filas (mismo patrón que la tabla de Verificación de Precios).
  final ScrollController _headerHCtrl = ScrollController();
  final ScrollController _bodyHCtrl = ScrollController();
  bool _syncingScroll = false;
  bool _exportando = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _headerHCtrl.addListener(() => _syncH(_headerHCtrl, _bodyHCtrl));
    _bodyHCtrl.addListener(() => _syncH(_bodyHCtrl, _headerHCtrl));
    _selectedSedeId = widget.sedeId;
    _loadInitialData();
  }

  void _syncH(ScrollController src, ScrollController dst) {
    if (_syncingScroll) return;
    if (!dst.hasClients) return;
    if (src.offset == dst.offset) return;
    _syncingScroll = true;
    dst.jumpTo(src.offset);
    _syncingScroll = false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _headerHCtrl.dispose();
    _bodyHCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<StockPorSedeCubit>().loadMore();
    }
  }

  void _loadInitialData() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _empresaId = empresaState.context.empresa.id;

      // Cargar sedes si no hay sede seleccionada
      if (_selectedSedeId == null) {
        context.read<SedeListCubit>().loadSedes(_empresaId!);
      } else {
        _loadStock();
      }
    }
  }

  void _loadStock() {
    if (_selectedSedeId != null && _empresaId != null) {
      context.read<StockPorSedeCubit>().loadStockPorSede(
            sedeId: _selectedSedeId!,
            empresaId: _empresaId!,
          );
    }
  }

  /// Descarga el XLSX con el inventario completo de la sede (respeta el
  /// filtro de búsqueda activo) desde el backend y lo abre con el share
  /// sheet del SO.
  Future<void> _exportar() async {
    if (_selectedSedeId == null) return;
    setState(() => _exportando = true);
    try {
      final dio = locator<DioClient>();
      final search = _searchController.text.trim();
      final resp = await dio.get(
        '/producto-stock/sede/$_selectedSedeId/export',
        queryParameters: {
          if (search.isNotEmpty) 'search': search,
        },
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(minutes: 5),
        ),
      );
      final bytes = resp.data as List<int>;
      final fileName =
          'inventario_${DateTime.now().toIso8601String().substring(0, 10)}.xlsx';
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        subject: 'Inventario por sede',
        text: 'Reporte de inventario',
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
        title: 'Inventario por Sede',
        actions: [
          if (_selectedSedeId != null)
            IconButton(
              tooltip: 'Exportar a Excel',
              icon: _exportando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download),
              onPressed: _exportando ? null : _exportar,
            ),
          if (_selectedSedeId != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<StockPorSedeCubit>().reload(),
            ),
        ],
      ),
      body: GradientBackground(
        child: Column(
          children: [
            // Selector de sede
            _buildSedeSelector(),

            // Buscador de productos (solo con sede seleccionada)
            if (_selectedSedeId != null) _buildSearchBar(),

            // Lista de stock
            Expanded(
              child: _selectedSedeId == null
                  ? _buildSedeSelectionPrompt()
                  : _buildStockList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSedeSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BlocBuilder<SedeListCubit, SedeListState>(
        builder: (context, state) {
          if (state is SedeListLoading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: 
              Center(
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 1,)
                )
              ),
            );
          }

          if (state is SedeListLoaded) {
            final sedes = state.sedes.where((s) => s.isActive).toList();

            if (sedes.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No hay sedes disponibles',
                  textAlign: TextAlign.center,
                ),
              );
            }

            return DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSedeId,
                isExpanded: true,
                hint: Text('Seleccione una sede'),
                items: sedes.map((sede) {
                  return DropdownMenuItem(
                    value: sede.id,
                    child: Row(
                      children: [
                        const Icon(Icons.store, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(sede.nombre),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  // Al cambiar de sede, limpiar el término de búsqueda previo.
                  _searchController.clear();
                  setState(() {
                    _selectedSedeId = value;
                  });
                  _loadStock();
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: CustomSearchField(
        controller: _searchController,
        hintText: 'Buscar por nombre o código…',
        borderColor: AppColors.blue1,
        // El backend filtra por nombre de producto/variante y código.
        // CustomSearchField ya trae debounce (500ms).
        onChanged: (q) => context.read<StockPorSedeCubit>().search(q),
      ),
    );
  }

  Widget _buildSedeSelectionPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Seleccione una sede',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'para ver su inventario',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildStockList() {
    return BlocBuilder<StockPorSedeCubit, StockPorSedeState>(
      builder: (context, state) {
        if (state is StockPorSedeLoading) {
          return const CustomLoading();
        }

        if (state is StockPorSedeError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadStock,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is StockPorSedeLoaded) {
          if (state.stocks.isEmpty) {
            final term = context.read<StockPorSedeCubit>().currentSearch;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(term != null ? Icons.search_off : Icons.inventory_2,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    term != null
                        ? 'Sin resultados para «$term»'
                        : 'No hay productos en esta sede',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return _buildTabla(state.stocks, loadingMore: false);
        }

        // Paginación: mantener la MISMA tabla con los items ya cargados +
        // un loader al final. Antes este estado caía en SizedBox.shrink(),
        // por eso la tabla desaparecía y reaparecía de golpe al paginar.
        if (state is StockPorSedeLoadingMore) {
          return _buildTabla(state.currentStocks, loadingMore: true);
        }

        return const SizedBox.shrink();
      },
    );
  }

  // ─── Tabla estilo Excel ───
  // Anchos fijos por columna. Header y filas usan EXACTAMENTE los mismos
  // para que la cabecera sticky se alinee al hacer scroll horizontal.
  static const double _wProducto = 190;
  static const double _wMarca = 100;
  static const double _wCategoria = 110;
  static const double _wFisico = 64;
  static const double _wDisponible = 80;
  static const double _wCompra = 72;
  static const double _wVenta = 72;
  static const double _wSede = 110;
  static const double _wAcciones = 92;
  static const double _rowH = 30;
  static const double _headerH = 28;

  static final Color _bgFisicoH = Colors.blue.shade100;
  static final Color _bgDispH = Colors.green.shade100;
  static final Color _bgFisico = Colors.blue.shade50;
  static final Color _bgDisp = Colors.green.shade50;
  // P. Compra (costo promedio ponderado) en naranja; P. Venta en teal
  // (distinto del verde de Disponible para no confundir columnas).
  static final Color _bgCompraH = Colors.orange.shade100;
  static final Color _bgVentaH = Colors.teal.shade100;
  static final Color _bgCompra = Colors.orange.shade50;
  static final Color _bgVenta = Colors.teal.shade50;

  double get _totalWidth =>
      _wProducto +
      _wMarca +
      _wCategoria +
      _wFisico +
      _wDisponible +
      _wCompra +
      _wVenta +
      _wSede +
      _wAcciones;

  /// Formatea un precio a 2 decimales, o "—" si es null.
  String _fmtPrecio(double? v) => v == null ? '—' : v.toStringAsFixed(2);

  Widget _buildTabla(List<ProductoStock> stocks, {required bool loadingMore}) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${stocks.length} producto(s)',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          // HEADER STICKY: solo scroll horizontal, espejado con el body.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _headerHCtrl,
            physics: const ClampingScrollPhysics(),
            child: _buildHeaderRow(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (mounted) context.read<StockPorSedeCubit>().reload();
              },
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _bodyHCtrl,
                physics: const ClampingScrollPhysics(),
                child: SizedBox(
                  width: _totalWidth,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: stocks.length + (loadingMore ? 1 : 0),
                    itemExtent: _rowH,
                    itemBuilder: (_, i) {
                      if (i >= stocks.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: SizedBox(
                              height: 18,
                              width: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      return _buildItemRow(stocks[i]);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    final s = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: AppColors.blue1,
    );
    return Container(
      width: _totalWidth,
      height: _headerH,
      color: AppColors.blue1.withValues(alpha: 0.08),
      child: Row(
        children: [
          _hCell('Producto', _wProducto, s),
          _hCell('Marca', _wMarca, s),
          _hCell('Categoría', _wCategoria, s),
          _hCell('Físico', _wFisico, s, alignRight: true, bgColor: _bgFisicoH),
          _hCell('Disp.', _wDisponible, s, alignRight: true, bgColor: _bgDispH),
          _hCell('P. Compra', _wCompra, s,
              alignRight: true, bgColor: _bgCompraH),
          _hCell('P. Venta', _wVenta, s, alignRight: true, bgColor: _bgVentaH),
          _hCell('Sede', _wSede, s),
          _hCell('Acciones', _wAcciones, s, center: true),
        ],
      ),
    );
  }

  Widget _hCell(String text, double width, TextStyle s,
      {bool alignRight = false, bool center = false, Color? bgColor}) {
    return Container(
      width: width,
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Align(
          alignment: center
              ? Alignment.center
              : (alignRight ? Alignment.centerRight : Alignment.centerLeft),
          child: Text(text, style: s),
        ),
      ),
    );
  }

  Widget _buildItemRow(ProductoStock stock) {
    const ts = TextStyle(fontSize: 9);
    // Color del disponible según estado: rojo (sin stock), naranja (bajo),
    // azul normal. Da lectura rápida de la salud del inventario.
    final dispColor = stock.esCritico
        ? Colors.red.shade700
        : (stock.esBajoMinimo ? Colors.orange.shade800 : AppColors.blue1);
    return Container(
      width: _totalWidth,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _dCell(stock.nombreProducto, _wProducto, ts, ellipsis: true),
          _dCell(stock.marca ?? '—', _wMarca, ts, ellipsis: true),
          _dCell(stock.categoria ?? '—', _wCategoria, ts, ellipsis: true),
          _dCell('${stock.stockActual}', _wFisico, ts,
              alignRight: true, bgColor: _bgFisico),
          _dCell('${stock.stockDisponibleVenta}', _wDisponible,
              TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: dispColor),
              alignRight: true, bgColor: _bgDisp),
          // P. Compra = precioCosto (ya es el costo promedio ponderado que
          // el backend recalcula en cada compra). P. Venta = precio.
          _dCell(_fmtPrecio(stock.precioCosto), _wCompra, ts,
              alignRight: true, bgColor: _bgCompra),
          _dCell(_fmtPrecio(stock.precio), _wVenta, ts,
              alignRight: true, bgColor: _bgVenta),
          _dCell(stock.sede?.nombre ?? '—', _wSede, ts, ellipsis: true),
          SizedBox(
            width: _wAcciones,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _accionIcon(
                  icon: Icons.history,
                  tooltip: 'Historial',
                  color: AppColors.blue1,
                  onTap: () => HistorialMovimientosBottomSheet.show(
                      context, stock),
                ),
                _accionIcon(
                  icon: Icons.edit,
                  tooltip: 'Ajustar',
                  color: Colors.green.shade700,
                  onTap: () => _showAjustarDialog(stock),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accionIcon({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18, color: color),
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
    );
  }

  Widget _dCell(String text, double width, TextStyle s,
      {bool alignRight = false, bool ellipsis = false, Color? bgColor}) {
    return Container(
      width: width,
      height: _rowH,
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Align(
          alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            text,
            style: s,
            overflow: ellipsis ? TextOverflow.ellipsis : TextOverflow.clip,
            maxLines: 1,
          ),
        ),
      ),
    );
  }

  void _showAjustarDialog(stock) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider(
        create: (context) => locator<AjustarStockCubit>(),
        child: AjustarStockDialog(
          stock: stock,
          empresaId: _empresaId!,
        ),
      ),
    ).then((result) {
      // Si se ajustó correctamente, recargar la lista
      if (result == true && mounted) {
        context.read<StockPorSedeCubit>().reload();
      }
    });
  }
}
