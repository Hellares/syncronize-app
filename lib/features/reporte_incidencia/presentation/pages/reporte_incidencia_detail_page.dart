import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/features/reporte_incidencia/domain/entities/reporte_incidencia.dart';
import 'package:syncronize/features/reporte_incidencia/presentation/bloc/reporte_incidencia_detail/reporte_incidencia_detail_cubit.dart';
import 'package:syncronize/features/reporte_incidencia/presentation/bloc/resolver_item/resolver_item_cubit.dart';
import 'package:syncronize/features/reporte_incidencia/presentation/bloc/eliminar_item/eliminar_item_cubit.dart';
import 'package:syncronize/features/reporte_incidencia/presentation/bloc/gestionar_reporte/gestionar_reporte_cubit.dart';
import 'package:syncronize/features/reporte_incidencia/presentation/widgets/reporte_header_card.dart';
import 'package:syncronize/features/reporte_incidencia/presentation/widgets/reporte_items_list.dart';
import 'package:syncronize/features/reporte_incidencia/presentation/widgets/reporte_actions_section.dart';
import 'package:syncronize/features/reporte_incidencia/presentation/widgets/resolver_item_dialog.dart';

class ReporteIncidenciaDetailPage extends StatefulWidget {
  final String reporteId;

  const ReporteIncidenciaDetailPage({
    super.key,
    required this.reporteId,
  });

  @override
  State<ReporteIncidenciaDetailPage> createState() =>
      _ReporteIncidenciaDetailPageState();
}

class _ReporteIncidenciaDetailPageState
    extends State<ReporteIncidenciaDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<ReporteIncidenciaDetailCubit>().cargarReporte(widget.reporteId);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ResolverItemCubit, ResolverItemState>(
          listener: (context, state) {
            if (state is ResolverItemSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item resuelto exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
              context.read<ReporteIncidenciaDetailCubit>().cargarReporte(widget.reporteId);
            } else if (state is ResolverItemError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        BlocListener<EliminarItemCubit, EliminarItemState>(
          listener: (context, state) {
            if (state is EliminarItemSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item eliminado exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
              context.read<ReporteIncidenciaDetailCubit>().cargarReporte(widget.reporteId);
            } else if (state is EliminarItemError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        BlocListener<GestionarReporteCubit, GestionarReporteState>(
          listener: (context, state) {
            if (state is GestionarReporteSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
              context.read<ReporteIncidenciaDetailCubit>().actualizarReporte(state.reporte);
            } else if (state is GestionarReporteError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
      child: const _ReporteIncidenciaDetailView(),
    );
  }
}

class _ReporteIncidenciaDetailView extends StatelessWidget {
  const _ReporteIncidenciaDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
        title: 'Detalle de Reporte',
        actions: [
          BlocBuilder<ReporteIncidenciaDetailCubit,
              ReporteIncidenciaDetailState>(
            builder: (context, state) {
              if (state is ReporteIncidenciaDetailLoaded) {
                final reporte = state.reporte;
                if (reporte.estado == EstadoReporteIncidencia.borrador) {
                  return IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // TODO: Navigate to edit page
                    },
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<ReporteIncidenciaDetailCubit,
          ReporteIncidenciaDetailState>(
        builder: (context, state) {
          if (state is ReporteIncidenciaDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ReporteIncidenciaDetailError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      final pageState = context
                          .findAncestorStateOfType<
                              _ReporteIncidenciaDetailPageState>();
                      if (pageState != null) {
                        context
                            .read<ReporteIncidenciaDetailCubit>()
                            .cargarReporte(pageState.widget.reporteId);
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (state is ReporteIncidenciaDetailLoaded) {
            final reporte = state.reporte;

            return RefreshIndicator(
              onRefresh: () async {
                await context
                    .read<ReporteIncidenciaDetailCubit>()
                    .cargarReporte(reporte.id);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReporteHeaderCard(reporte: reporte),
                    const SizedBox(height: 16),
                    _buildInfoSection(reporte),
                    const SizedBox(height: 16),
                    _buildItemsSection(context, reporte),
                    const SizedBox(height: 16),
                    ReporteActionsSection(reporte: reporte),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildInfoSection(ReporteIncidencia reporte) {
    return GradientContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información General',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildInfoRow('Tipo:', _getTipoReporteLabel(reporte.tipoReporte)),
            _buildInfoRow(
              'Fecha Incidente:',
              _formatDate(reporte.fechaIncidente),
            ),
            _buildInfoRow('Sede:', reporte.sede?.nombre ?? 'No especificado'),
            if (reporte.supervisor != null)
              _buildInfoRow('Supervisor:', reporte.supervisor!.nombre),
            if (reporte.descripcionGeneral != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Descripción General:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(reporte.descripcionGeneral!),
            ],
            if (reporte.observacionesFinales != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Observaciones Finales:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(reporte.observacionesFinales!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildItemsSection(BuildContext context, ReporteIncidencia reporte) {
    return GradientContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Productos Afectados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (reporte.estado == EstadoReporteIncidencia.borrador)
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: () async {
                      final result = await context.push(
                        '/empresa/reportes-incidencia/${reporte.id}/agregar-item?sedeId=${reporte.sedeId}',
                      );
                      if (result == true && context.mounted) {
                        context
                            .read<ReporteIncidenciaDetailCubit>()
                            .cargarReporte(reporte.id);
                      }
                    },
                  ),
              ],
            ),
            const Divider(),
            if (reporte.items == null || reporte.items!.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No hay productos agregados',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ReporteItemsList(
                items: reporte.items!,
                reporteEstado: reporte.estado,
                onDeleteItem: (itemId) {
                  _showDeleteItemDialog(context, reporte.id, itemId);
                },
                onResolveItem: (itemId) {
                  _showResolverItemDialog(context, reporte, itemId);
                },
              ),
          ],
        ),
      ),
    );
  }

  String _getTipoReporteLabel(TipoReporteIncidencia tipo) {
    switch (tipo) {
      case TipoReporteIncidencia.inventarioCompleto:
        return 'Inventario Completo';
      case TipoReporteIncidencia.incidenciaPuntual:
        return 'Incidencia Puntual';
      case TipoReporteIncidencia.revisionRutinaria:
        return 'Revisión Rutinaria';
      case TipoReporteIncidencia.eventoEspecifico:
        return 'Evento Específico';
      case TipoReporteIncidencia.auditoria:
        return 'Auditoría';
      case TipoReporteIncidencia.otro:
        return 'Otro';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showDeleteItemDialog(BuildContext context, String reporteId, String itemId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: const Text('¿Está seguro de eliminar este producto del reporte?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<EliminarItemCubit>().eliminarItem(
                    reporteId: reporteId,
                    itemId: itemId,
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showResolverItemDialog(BuildContext context, ReporteIncidencia reporte, String itemId) {
    final item = reporte.items!.firstWhere((item) => item.id == itemId);

    showDialog(
      context: context,
      builder: (dialogContext) => ResolverItemDialog(
        reporteId: reporte.id,
        itemId: itemId,
        productoNombre: item.nombreProducto,
        onResolve: (accion, observaciones, sedeDestinoId) {
          context.read<ResolverItemCubit>().resolverItem(
                reporteId: reporte.id,
                itemId: itemId,
                accionTomada: accion,
                observaciones: observaciones,
                sedeDestinoId: sedeDestinoId,
              );
        },
      ),
    );
  }
}
