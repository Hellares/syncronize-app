import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/features/reporte_incidencia/domain/entities/reporte_incidencia.dart';
import 'package:syncronize/features/reporte_incidencia/presentation/bloc/gestionar_reporte/gestionar_reporte_cubit.dart';

class ReporteActionsSection extends StatelessWidget {
  final ReporteIncidencia reporte;

  const ReporteActionsSection({
    super.key,
    required this.reporte,
  });

  @override
  Widget build(BuildContext context) {
    final actions = _getAvailableActions();

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acciones Disponibles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...actions.map((action) => _buildActionButton(context, action)),
          ],
        ),
      ),
    );
  }

  List<_ReporteAction> _getAvailableActions() {
    final actions = <_ReporteAction>[];

    switch (reporte.estado) {
      case EstadoReporteIncidencia.borrador:
        if (reporte.items != null && reporte.items!.isNotEmpty) {
          actions.add(_ReporteAction(
            label: 'Enviar para Revisión',
            icon: Icons.send,
            color: Colors.blue,
            onTap: (context) {
              _showConfirmDialog(
                context,
                'Enviar para Revisión',
                '¿Está seguro de enviar este reporte para revisión?',
                () {
                  context.read<GestionarReporteCubit>().enviarParaRevision(reporte.id);
                },
              );
            },
          ));
        }
        actions.add(_ReporteAction(
          label: 'Cancelar Reporte',
          icon: Icons.cancel,
          color: Colors.red,
          onTap: (context) {
            // TODO: Implement cancelar
          },
        ));
        break;

      case EstadoReporteIncidencia.enviado:
      case EstadoReporteIncidencia.enRevision:
        actions.add(_ReporteAction(
          label: 'Aprobar Reporte',
          icon: Icons.check_circle,
          color: Colors.green,
          onTap: (context) {
            _showConfirmDialog(
              context,
              'Aprobar Reporte',
              '¿Está seguro de aprobar este reporte?',
              () {
                context.read<GestionarReporteCubit>().aprobarReporte(reporte.id);
              },
            );
          },
        ));
        actions.add(_ReporteAction(
          label: 'Rechazar Reporte',
          icon: Icons.cancel,
          color: Colors.red,
          onTap: (context) {
            _showRejectDialog(context, reporte.id);
          },
        ));
        break;

      case EstadoReporteIncidencia.aprobado:
        final hasUnresolvedItems = reporte.items != null &&
            reporte.items!.any((item) => item.accionTomada == null);
        if (hasUnresolvedItems) {
          actions.add(_ReporteAction(
            label: 'Resolver Productos',
            icon: Icons.build,
            color: Colors.orange,
            onTap: (context) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Use el botón "Resolver" en cada producto'),
                ),
              );
            },
          ));
        }
        break;

      case EstadoReporteIncidencia.enProceso:
        // No actions available in this state
        break;

      case EstadoReporteIncidencia.resuelto:
      case EstadoReporteIncidencia.rechazado:
      case EstadoReporteIncidencia.cancelado:
        // No actions for final states
        break;
    }

    return actions;
  }

  Widget _buildActionButton(BuildContext context, _ReporteAction action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => action.onTap(context),
          icon: Icon(action.icon),
          label: Text(action.label),
          style: ElevatedButton.styleFrom(
            backgroundColor: action.color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String reporteId) {
    final motivoController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rechazar Reporte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Por qué está rechazando este reporte?'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              decoration: const InputDecoration(
                labelText: 'Motivo de rechazo',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final motivo = motivoController.text.trim();
              Navigator.of(dialogContext).pop();
              context.read<GestionarReporteCubit>().rechazarReporte(
                    reporteId,
                    motivo.isEmpty ? null : motivo,
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }
}

class _ReporteAction {
  final String label;
  final IconData icon;
  final Color color;
  final Function(BuildContext) onTap;

  _ReporteAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
