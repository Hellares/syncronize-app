import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/custom_loading.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../bloc/alertas_stock/alertas_stock_cubit.dart';
import '../bloc/alertas_stock/alertas_stock_state.dart';
import '../bloc/ajustar_stock/ajustar_stock_cubit.dart';
import '../widgets/stock_card.dart';
import '../widgets/ajustar_stock_dialog.dart';
import '../widgets/historial_movimientos_bottom_sheet.dart';
import '../widgets/abrir_bulto_dialog.dart';
import 'package:dio/dio.dart';
import 'package:syncronize/core/network/dio_client.dart';

/// Un bulto cerrado que puede reponer a un granel bajo mínimo.
class _BultoDisponible {
  final String bultoVarianteId;
  final String bultoNombre;
  final int bultoStock;
  final String destinoNombre;
  final double? destinoFactor;
  final String? destinoSimbolo;
  final double rendimiento;
  final int destinoStock;

  _BultoDisponible({
    required this.bultoVarianteId,
    required this.bultoNombre,
    required this.bultoStock,
    required this.destinoNombre,
    required this.destinoFactor,
    required this.destinoSimbolo,
    required this.rendimiento,
    required this.destinoStock,
  });
}

class AlertasStockBajoPage extends StatefulWidget {
  final String? sedeId; // Si es null, muestra alertas de todas las sedes

  const AlertasStockBajoPage({
    super.key,
    this.sedeId,
  });

  @override
  State<AlertasStockBajoPage> createState() => _AlertasStockBajoPageState();
}

class _AlertasStockBajoPageState extends State<AlertasStockBajoPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _empresaId;

  /// Bultos abribles, indexados por `sedeId|varianteId` del GRANEL: es la
  /// clave con la que se busca desde cada fila de alerta.
  final Map<String, _BultoDisponible> _bultosPorDestino = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAlertas();
  }

  /// Cruza las alertas con `/apertura-bulto/disponibles`.
  ///
  /// La pantalla puede estar en "todas las sedes", y el endpoint es por sede,
  /// así que se consulta una vez por cada sede que aparezca en las alertas —
  /// en la práctica una o dos. Si falla, se ignora en silencio: es información
  /// ADICIONAL y no puede tumbar la pantalla de alertas.
  Future<void> _cargarBultosDisponibles(Iterable<String> sedeIds) async {
    final dio = locator<DioClient>();
    final nuevos = <String, _BultoDisponible>{};
    for (final sedeId in sedeIds.toSet()) {
      try {
        final resp = await dio.get(
          '/apertura-bulto/disponibles',
          queryParameters: {'sedeId': sedeId},
        );
        for (final e in (resp.data as List<dynamic>? ?? [])) {
          final j = e as Map<String, dynamic>;
          final bulto = j['bulto'] as Map<String, dynamic>;
          final destino = j['destino'] as Map<String, dynamic>;
          final cerrados = (bulto['stock'] as num?)?.toInt() ?? 0;
          // Sin bultos cerrados no hay nada que ofrecer: ahí sí toca comprar.
          if (cerrados <= 0) continue;
          nuevos['$sedeId|${destino['varianteId']}'] = _BultoDisponible(
            bultoVarianteId: bulto['varianteId'].toString(),
            bultoNombre: bulto['nombre'].toString(),
            bultoStock: cerrados,
            destinoNombre: destino['nombre'].toString(),
            destinoFactor: (destino['factorPresentacion'] as num?)?.toDouble(),
            destinoSimbolo: destino['simbolo']?.toString(),
            rendimiento: (j['rendimiento'] as num?)?.toDouble() ?? 0,
            destinoStock: (destino['stock'] as num?)?.toInt() ?? 0,
          );
        }
      } on DioException {
        // Ignorado a propósito: ver doc de arriba.
      }
    }
    if (!mounted) return;
    setState(() {
      _bultosPorDestino
        ..clear()
        ..addAll(nuevos);
    });
  }

  Future<void> _abrirBulto(_BultoDisponible b, String sedeId) async {
    final r = await AbrirBultoDialog.show(
      context: context,
      bultoVarianteId: b.bultoVarianteId,
      bultoNombre: b.bultoNombre,
      destinoNombre: b.destinoNombre,
      destinoFactor: b.destinoFactor,
      destinoSimbolo: b.destinoSimbolo,
      rendimiento: b.rendimiento,
      sedeId: sedeId,
      stockBultos: b.bultoStock,
      stockDestino: b.destinoStock,
    );
    // Tras abrir, el granel ya no está bajo mínimo: recargar saca la alerta.
    if (r != null) _loadAlertas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAlertas() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _empresaId = empresaState.context.empresa.id;
      context.read<AlertasStockCubit>().loadAlertas(
            empresaId: _empresaId!,
            sedeId: widget.sedeId,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Alertas de Stock',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlertas,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Críticos'),
            Tab(text: 'Bajo Mínimo'),
          ],
        ),
      ),
      body: GradientBackground(
        child: BlocConsumer<AlertasStockCubit, AlertasStockState>(
          listener: (context, state) {
            // Los bultos se cruzan DESPUÉS de tener las alertas: recién ahí se
            // sabe qué sedes hay que consultar. Va en el listener y no en el
            // builder para no disparar una consulta por cada repintado.
            if (state is AlertasStockLoaded) {
              final sedes = [
                ...state.productosBajoMinimo.map((s) => s.sedeId),
                ...state.productosCriticos.map((s) => s.sedeId),
              ];
              if (sedes.isNotEmpty) _cargarBultosDisponibles(sedes);
            }
          },
          builder: (context, state) {
            if (state is AlertasStockLoading) {
              return const CustomLoading();
            }

            if (state is AlertasStockError) {
              return _buildError(state.message);
            }

            if (state is AlertasStockEmpty) {
              return _buildEmpty();
            }

            if (state is AlertasStockLoaded) {
              return Column(
                children: [
                  // Resumen de alertas
                  _buildSummaryCard(state),

                  // Tabs con listas
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab de críticos
                        _buildProductsList(
                          state.productosCriticos,
                          emptyMessage: 'No hay productos sin stock',
                          emptyIcon: Icons.check_circle,
                          emptyColor: Colors.green,
                        ),

                        // Tab de bajo mínimo
                        _buildProductsList(
                          state.productosBajoMinimo,
                          emptyMessage: 'No hay productos bajo el mínimo',
                          emptyIcon: Icons.check_circle,
                          emptyColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(AlertasStockLoaded state) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            // AppColors.primary.withValues(alpha: 0.1),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // color: AppColors.primary.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resumen de Alertas'),
                    Text(
                      widget.sedeId == null
                          ? 'Todas las sedes'
                          : 'Sede seleccionada',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  label: 'Productos\nsin stock',
                  value: state.criticos.toString(),
                  color: Colors.red,
                  icon: Icons.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  label: 'Productos\nbajo mínimo',
                  value: (state.total - state.criticos).toString(),
                  color: Colors.orange,
                  icon: Icons.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  label: 'Total\nalertas',
                  value: state.total.toString(),
                  color: AppColors.blue1,
                  icon: Icons.inventory,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(
    List stocks, {
    required String emptyMessage,
    required IconData emptyIcon,
    required Color emptyColor,
  }) {
    if (stocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: emptyColor),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadAlertas(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stocks.length,
        itemBuilder: (context, index) {
          final stock = stocks[index];
          // Solo las filas de VARIANTE pueden ser el granel de un bulto.
          final bulto = stock.varianteId != null
              ? _bultosPorDestino['${stock.sedeId}|${stock.varianteId}']
              : null;
          return StockCard(
            stock: stock,
            onAjustar: () => _showAjustarDialog(stock),
            onHistorial: () => HistorialMovimientosBottomSheet.show(
              context,
              stock,
            ),
            onAbrirBulto:
                bulto != null ? () => _abrirBulto(bulto, stock.sedeId) : null,
            bultosCerrados: bulto?.bultoStock ?? 0,
            nombreBulto: bulto?.bultoNombre,
          );
        },
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadAlertas,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            'Todo está bien',
            style: TextStyle(color: Colors.green),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay productos con stock bajo',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
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
      if (result == true) {
        _loadAlertas();
      }
    });
  }
}
