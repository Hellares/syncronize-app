import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/custom_loading.dart';
import 'package:syncronize/core/widgets/custom_radio_group.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/transferencia_incidencia.dart';
import '../../domain/entities/incidencia_item_request.dart';
import '../bloc/listar_incidencias/listar_incidencias_cubit.dart';
import '../bloc/listar_incidencias/listar_incidencias_state.dart';
import '../bloc/resolver_incidencia/resolver_incidencia_cubit.dart';
import '../bloc/resolver_incidencia/resolver_incidencia_state.dart';

class IncidenciasTransferenciasPage extends StatefulWidget {
  const IncidenciasTransferenciasPage({super.key});

  @override
  State<IncidenciasTransferenciasPage> createState() =>
      _IncidenciasTransferenciasPageState();
}

class _IncidenciasTransferenciasPageState
    extends State<IncidenciasTransferenciasPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _empresaId;
  bool? _filtroResuelto;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _onTabChanged(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _empresaId = empresaState.context.empresa.id;
      _loadIncidencias();
    }
  }

  void _loadIncidencias() {
    if (_empresaId != null) {
      context.read<ListarIncidenciasCubit>().loadIncidencias(
            empresaId: _empresaId!,
            resuelto: _filtroResuelto,
          );
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _filtroResuelto = index == 0 ? null : (index == 2);
    });
    _loadIncidencias();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
        title: 'Incidencias de Transferencias',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ListarIncidenciasCubit>().reload(),
          ),
        ],
      ),
      body: GradientBackground(
        child: BlocListener<ResolverIncidenciaCubit, ResolverIncidenciaState>(
          listener: (context, state) {
            if (state is ResolverIncidenciaSuccess) {
              _showSuccess(state.message);
              context.read<ListarIncidenciasCubit>().reload();
            } else if (state is ResolverIncidenciaError) {
              _showError(state.message);
            }
          },
          child: Column(
            children: [
              Container(
                height: 35,
                color: AppColors.blue1,
                child: TabBar(
                  controller: _tabController,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  dividerHeight: 0,
                  labelColor: AppColors.white,
                  unselectedLabelColor: Colors.grey,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                  indicatorPadding: const EdgeInsets.only(bottom: 8),
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 2,
                  indicator: const UnderlineTabIndicator(
                    borderSide: BorderSide(width: 2, color: AppColors.white),
                  ),
                  tabs: const [
                    Tab(text: 'Todas'),
                    Tab(text: 'Pendientes'),
                    Tab(text: 'Resueltas'),
                  ],
                ),
              ),
              Expanded(
                child:
                    BlocBuilder<ListarIncidenciasCubit, ListarIncidenciasState>(
                  builder: (context, state) {
                    if (state is ListarIncidenciasLoading) {
                      return const CustomLoading();
                    }
                    if (state is ListarIncidenciasError) {
                      return _buildError(state.message);
                    }
                    if (state is ListarIncidenciasLoaded) {
                      if (state.incidencias.isEmpty) {
                        return _buildEmpty();
                      }
                      return _buildList(state);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(ListarIncidenciasLoaded state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCards(state),
        const SizedBox(height: 16),
        ...state.incidencias.map((incidencia) => _buildIncidenciaCard(incidencia)),
      ],
    );
  }

  Widget _buildSummaryCards(ListarIncidenciasLoaded state) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Pendientes',
            state.totalPendientes.toString(),
            Icons.warning_amber,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Resueltas',
            state.totalResueltas.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String label, String value, IconData icon, Color color) {
    return GradientContainer(
      gradient: AppGradients.sinfondo,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 25, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidenciaCard(TransferenciaIncidencia incidencia) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GradientContainer(
        gradient: AppGradients.sinfondo,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incidencia.tipo.descripcion,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        incidencia.nombreProducto ?? 'Producto desconocido',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildEstadoBadge(incidencia.resuelto),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.inventory_2,
              'Cantidad afectada',
              '${incidencia.cantidadAfectada} unidades',
            ),
            if (incidencia.descripcion != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.description,
                'Descripción',
                incidencia.descripcion!,
              ),
            ],
            if (incidencia.tieneEvidencias) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.attach_file,
                'Evidencias',
                '${incidencia.evidenciasUrls.length} archivo(s)',
              ),
            ],
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.calendar_today,
              'Registrada',
              DateFormatter.formatDateTime(incidencia.creadoEn),
            ),
            if (incidencia.resuelto && incidencia.fechaResolucion != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.check_circle,
                'Resuelta',
                DateFormatter.formatDateTime(incidencia.fechaResolucion!),
              ),
            ],
            if (incidencia.resuelto && incidencia.accionTomada != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.settings,
                'Acción tomada',
                incidencia.accionTomada!.descripcion,
              ),
            ],
            if (incidencia.estaPendiente) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showResolverDialog(incidencia),
                  icon: const Icon(Icons.build),
                  label: const Text('Resolver Incidencia'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue1,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoBadge(bool resuelto) {
    final color = resuelto ? Colors.green : Colors.orange;
    final backgroundColor = resuelto ? Colors.green.shade100 : Colors.orange.shade100;
    final label = resuelto ? 'Resuelta' : 'Pendiente';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay incidencias',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Todas las transferencias se han recibido sin problemas',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error al cargar incidencias',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.read<ListarIncidenciasCubit>().reload(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue1,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showResolverDialog(TransferenciaIncidencia incidencia) {
    AccionResolucionIncidencia? accionSeleccionada;
    final observacionesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Resolver Incidencia'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${incidencia.tipo.descripcion} - ${incidencia.cantidadAfectada} unidades',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                CustomRadioGroup<AccionResolucionIncidencia>(
                  label: 'Seleccione la acción a tomar:',
                  value: accionSeleccionada,
                  options: AccionResolucionIncidencia.values
                      .map((accion) => RadioOption(
                            value: accion,
                            label: accion.descripcion,
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => accionSeleccionada = value);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: observacionesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones (opcional)',
                    border: OutlineInputBorder(),
                    hintText: 'Detalles adicionales sobre la resolución',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: accionSeleccionada == null
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _resolverIncidencia(
                        incidencia,
                        accionSeleccionada!,
                        observacionesController.text.trim(),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue1,
              ),
              child: const Text('Resolver'),
            ),
          ],
        ),
      ),
    );
  }

  void _resolverIncidencia(
    TransferenciaIncidencia incidencia,
    AccionResolucionIncidencia accion,
    String observaciones,
  ) {
    if (_empresaId == null) return;

    final request = ResolverIncidenciaRequest(
      accion: accion,
      observaciones: observaciones.isEmpty ? null : observaciones,
    );

    context.read<ResolverIncidenciaCubit>().resolver(
          incidenciaId: incidencia.id,
          empresaId: _empresaId!,
          request: request,
        );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}
