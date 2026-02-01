import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/widgets/floating_button_text.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../domain/entities/reporte_incidencia.dart';
import '../bloc/reportes_incidencia_list/reportes_incidencia_list_cubit.dart';

class ReportesIncidenciaPage extends StatefulWidget {
  const ReportesIncidenciaPage({super.key});

  @override
  State<ReportesIncidenciaPage> createState() =>
      _ReportesIncidenciaPageState();
}

class _ReportesIncidenciaPageState extends State<ReportesIncidenciaPage> {
  EstadoReporteIncidencia? _estadoFiltro;

  @override
  void initState() {
    super.initState();
    _cargarReportes();
  }

  void _cargarReportes() {
    context.read<ReportesIncidenciaListCubit>().cargarReportes(
          estado: _estadoFiltro,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Reportes de Incidencias',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<EstadoReporteIncidencia?>(
            icon: const Icon(Icons.filter_list, size: 18,),
            tooltip: 'Filtrar por estado',
            onSelected: (estado) {
              setState(() {
                _estadoFiltro = estado;
              });
              _cargarReportes();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Todos'),
              ),
              ...EstadoReporteIncidencia.values.map((estado) {
                return PopupMenuItem(
                  value: estado,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getEstadoColor(estado),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(estado.descripcion),
                    ],
                  ),
                );
              }),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: 'Recargar',
            onPressed: _cargarReportes,
          ),
        ],
      ),
      body: BlocBuilder<ReportesIncidenciaListCubit,
          ReportesIncidenciaListState>(
        builder: (context, state) {
          if (state is ReportesIncidenciaListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ReportesIncidenciaListError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _cargarReportes,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue1,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is ReportesIncidenciaListLoaded) {
            final reportes = state.reportes;

            if (reportes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _estadoFiltro != null
                          ? 'No hay reportes con estado "${_estadoFiltro!.descripcion}"'
                          : 'No hay reportes de incidencias',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _cargarReportes(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reportes.length,
                itemBuilder: (context, index) {
                  final reporte = reportes[index];
                  return _ReporteCard(
                    reporte: reporte,
                    onTap: () async {
                      await context.push(
                        '/empresa/reportes-incidencia/${reporte.id}',
                      );
                      if (context.mounted) {
                        _cargarReportes();
                      }
                    },
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingButtonText(
        label: 'Nuevo Reporte',
        width: 120,
        onPressed: () async {
          await context.push('/empresa/reportes-incidencia/crear');
          if (context.mounted) {
            _cargarReportes();
          }
        }, 
        icon: Icons.add
        ),
    );
  }

  Color _getEstadoColor(EstadoReporteIncidencia estado) {
    switch (estado) {
      case EstadoReporteIncidencia.borrador:
        return Colors.grey;
      case EstadoReporteIncidencia.enviado:
        return Colors.blue;
      case EstadoReporteIncidencia.enRevision:
        return Colors.orange;
      case EstadoReporteIncidencia.aprobado:
        return Colors.green;
      case EstadoReporteIncidencia.enProceso:
        return Colors.purple;
      case EstadoReporteIncidencia.resuelto:
        return Colors.teal;
      case EstadoReporteIncidencia.rechazado:
        return Colors.red;
      case EstadoReporteIncidencia.cancelado:
        return Colors.grey.shade800;
    }
  }
}

class _ReporteCard extends StatelessWidget {
  final ReporteIncidencia reporte;
  final VoidCallback onTap;

  const _ReporteCard({
    required this.reporte,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.blueborder,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reporte.titulo,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reporte.codigo,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontFamily: 'Cascadia',
                          ),
                        ),
                      ],
                    ),
                  ),
                  _EstadoBadge(estado: reporte.estado),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      reporte.sede?.nombre ?? 'Sin sede',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Incidente: ${DateFormatter.formatDate(reporte.fechaIncidente)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatChip(
                      icon: Icons.inventory_2,
                      label: 'Productos',
                      value: reporte.totalProductosAfectados.toString(),
                      color: Colors.blue,
                    ),
                    _StatChip(
                      icon: Icons.shopping_cart,
                      label: 'Cantidad',
                      value: reporte.totalCantidadAfectada.toString(),
                      color: Colors.orange,
                    ),
                    _StatChip(
                      icon: Icons.warning,
                      label: 'Dañados',
                      value: reporte.totalDanados.toString(),
                      color: Colors.red,
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
}

class _EstadoBadge extends StatelessWidget {
  final EstadoReporteIncidencia estado;

  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (estado) {
      case EstadoReporteIncidencia.borrador:
        color = Colors.grey;
        break;
      case EstadoReporteIncidencia.enviado:
        color = Colors.blue;
        break;
      case EstadoReporteIncidencia.enRevision:
        color = Colors.orange;
        break;
      case EstadoReporteIncidencia.aprobado:
        color = Colors.green;
        break;
      case EstadoReporteIncidencia.enProceso:
        color = Colors.purple;
        break;
      case EstadoReporteIncidencia.resuelto:
        color = Colors.teal;
        break;
      case EstadoReporteIncidencia.rechazado:
        color = Colors.red;
        break;
      case EstadoReporteIncidencia.cancelado:
        color = Colors.grey.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        estado.descripcion,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
