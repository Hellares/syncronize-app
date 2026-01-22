import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/custom_loading.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/transferencia_stock.dart';
import '../bloc/transferencia_detail/transferencia_detail_cubit.dart';
import '../bloc/transferencia_detail/transferencia_detail_state.dart';
import '../bloc/gestionar_transferencia/gestionar_transferencia_cubit.dart';
import '../bloc/gestionar_transferencia/gestionar_transferencia_state.dart';

class TransferenciaDetailPage extends StatefulWidget {
  final String transferenciaId;

  const TransferenciaDetailPage({
    super.key,
    required this.transferenciaId,
  });

  @override
  State<TransferenciaDetailPage> createState() =>
      _TransferenciaDetailPageState();
}

class _TransferenciaDetailPageState extends State<TransferenciaDetailPage> {
  String? _empresaId;

  @override
  void initState() {
    super.initState();
    _loadDetalle();
  }

  void _loadDetalle() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _empresaId = empresaState.context.empresa.id;
      context.read<TransferenciaDetailCubit>().loadDetalle(
            transferenciaId: widget.transferenciaId,
            empresaId: _empresaId!,
          );
    }
  }

  void _reload() {
    if (_empresaId != null) {
      context.read<TransferenciaDetailCubit>().reload(
            transferenciaId: widget.transferenciaId,
            empresaId: _empresaId!,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Detalle de Transferencia',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: GradientBackground(
        child:
            BlocListener<GestionarTransferenciaCubit, GestionarTransferenciaState>(
          listener: (context, state) {
            if (state is GestionarTransferenciaSuccess) {
              _showSuccess(state.message);
              _reload();
            } else if (state is GestionarTransferenciaError) {
              _showError(state.message);
            }
          },
          child:
              BlocBuilder<TransferenciaDetailCubit, TransferenciaDetailState>(
            builder: (context, state) {
              if (state is TransferenciaDetailLoading) {
                return const CustomLoading();
              }

              if (state is TransferenciaDetailError) {
                return _buildError(state.message);
              }

              if (state is TransferenciaDetailLoaded) {
                return _buildContent(state.transferencia);
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(TransferenciaStock transferencia) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Código y estado
        _buildHeader(transferencia),
        const SizedBox(height: 16),

        // Timeline del estado
        _buildTimeline(transferencia),
        const SizedBox(height: 16),

        // Información de sedes
        _buildSedesInfo(transferencia),
        const SizedBox(height: 16),

        // Información del producto
        _buildProductoInfo(transferencia),
        const SizedBox(height: 16),

        // Motivo y observaciones
        if (transferencia.motivo != null || transferencia.observaciones != null)
          _buildMotivosCard(transferencia),

        if (transferencia.motivo != null || transferencia.observaciones != null)
          const SizedBox(height: 16),

        // Acciones disponibles
        _buildActions(transferencia),
      ],
    );
  }

  Widget _buildHeader(TransferenciaStock transferencia) {
    return GradientContainer(
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
                  child: Text(
                    transferencia.codigo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blue1,
                    ),
                  ),
                ),
                _buildEstadoBadge(transferencia.estado),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Creada el ${DateFormat('dd/MM/yyyy HH:mm').format(transferencia.creadoEn)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(TransferenciaStock transferencia) {
    return GradientContainer(
      gradient: AppGradients.sinfondo,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estado de la Transferencia',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _TimelineItem(
              icon: Icons.create,
              title: 'Creada',
              subtitle: DateFormat('dd/MM/yyyy HH:mm')
                  .format(transferencia.creadoEn),
              isCompleted: true,
              isActive: transferencia.estado == EstadoTransferencia.borrador,
            ),
            _TimelineItem(
              icon: Icons.schedule,
              title: 'Pendiente de Aprobación',
              subtitle: 'Esperando revisión',
              isCompleted: transferencia.estado != EstadoTransferencia.borrador,
              isActive: transferencia.estado == EstadoTransferencia.pendiente,
            ),
            _TimelineItem(
              icon: Icons.check_circle,
              title: 'Aprobada',
              subtitle: transferencia.fechaAprobacion != null
                  ? DateFormat('dd/MM/yyyy HH:mm')
                      .format(transferencia.fechaAprobacion!)
                  : null,
              isCompleted: transferencia.fechaAprobacion != null,
              isActive: transferencia.estado == EstadoTransferencia.aprobada,
            ),
            _TimelineItem(
              icon: Icons.local_shipping,
              title: 'En Tránsito',
              subtitle: transferencia.fechaEnvio != null
                  ? DateFormat('dd/MM/yyyy HH:mm')
                      .format(transferencia.fechaEnvio!)
                  : null,
              isCompleted: transferencia.fechaEnvio != null,
              isActive: transferencia.estado == EstadoTransferencia.enTransito,
            ),
            _TimelineItem(
              icon: Icons.done_all,
              title: 'Recibida',
              subtitle: transferencia.fechaRecepcion != null
                  ? DateFormat('dd/MM/yyyy HH:mm')
                      .format(transferencia.fechaRecepcion!)
                  : null,
              isCompleted: transferencia.fechaRecepcion != null,
              isActive: transferencia.estado == EstadoTransferencia.recibida,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSedesInfo(TransferenciaStock transferencia) {
    return GradientContainer(
      gradient: AppGradients.sinfondo,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sedes Involucradas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSedeCard(
                    'Origen',
                    transferencia.sedeOrigen?.nombre ?? 'N/A',
                    Icons.upload,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.arrow_forward, color: Colors.grey[400]),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSedeCard(
                    'Destino',
                    transferencia.sedeDestino?.nombre ?? 'N/A',
                    Icons.download,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSedeCard(
      String label, String nombre, IconData icon, Color color) {
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
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nombre,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductoInfo(TransferenciaStock transferencia) {
    return GradientContainer(
      gradient: AppGradients.sinfondo,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Producto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: AppColors.blue1,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transferencia.nombreProducto,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${transferencia.cantidad} unidades',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivosCard(TransferenciaStock transferencia) {
    return GradientContainer(
      gradient: AppGradients.sinfondo,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Adicional',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (transferencia.motivo != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.description, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Motivo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transferencia.motivo!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (transferencia.observaciones != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Observaciones',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transferencia.observaciones!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActions(TransferenciaStock transferencia) {
    return BlocBuilder<GestionarTransferenciaCubit,
        GestionarTransferenciaState>(
      builder: (context, gestionState) {
        final isProcessing = gestionState is GestionarTransferenciaProcessing;

        return GradientContainer(
          gradient: AppGradients.sinfondo,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Acciones',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Aprobar
                if (transferencia.puedeAprobar)
                  _ActionButton(
                    label: 'Aprobar Transferencia',
                    icon: Icons.check_circle,
                    color: Colors.green,
                    onPressed: isProcessing
                        ? null
                        : () => _showAprobarDialog(transferencia),
                    isProcessing:
                        isProcessing && gestionState.action == 'aprobar',
                  ),

                // Enviar
                if (transferencia.puedeEnviar) ...[
                  if (transferencia.puedeAprobar) const SizedBox(height: 8),
                  _ActionButton(
                    label: 'Marcar como Enviada',
                    icon: Icons.local_shipping,
                    color: Colors.purple,
                    onPressed: isProcessing
                        ? null
                        : () => _showEnviarDialog(transferencia),
                    isProcessing:
                        isProcessing && gestionState.action == 'enviar',
                  ),
                ],

                // Recibir
                if (transferencia.puedeRecibir) ...[
                  if (transferencia.puedeAprobar || transferencia.puedeEnviar)
                    const SizedBox(height: 8),
                  _ActionButton(
                    label: 'Registrar Recepción',
                    icon: Icons.done_all,
                    color: Colors.blue,
                    onPressed: isProcessing
                        ? null
                        : () => _showRecibirDialog(transferencia),
                    isProcessing:
                        isProcessing && gestionState.action == 'recibir',
                  ),
                ],

                // Rechazar
                if (transferencia.puedeRechazar) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  _ActionButton(
                    label: 'Rechazar Transferencia',
                    icon: Icons.cancel,
                    color: Colors.red,
                    isOutlined: true,
                    onPressed: isProcessing
                        ? null
                        : () => _showRechazarDialog(transferencia),
                    isProcessing:
                        isProcessing && gestionState.action == 'rechazar',
                  ),
                ],

                // Cancelar
                if (transferencia.puedeCancelar) ...[
                  const SizedBox(height: 8),
                  _ActionButton(
                    label: 'Cancelar Transferencia',
                    icon: Icons.block,
                    color: Colors.grey,
                    isOutlined: true,
                    onPressed: isProcessing
                        ? null
                        : () => _showCancelarDialog(transferencia),
                    isProcessing:
                        isProcessing && gestionState.action == 'cancelar',
                  ),
                ],

                // Sin acciones disponibles
                if (!transferencia.puedeAprobar &&
                    !transferencia.puedeEnviar &&
                    !transferencia.puedeRecibir &&
                    !transferencia.puedeRechazar &&
                    !transferencia.puedeCancelar)
                  Text(
                    'No hay acciones disponibles para esta transferencia',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEstadoBadge(EstadoTransferencia estado) {
    Color backgroundColor;
    Color textColor;

    switch (estado) {
      case EstadoTransferencia.pendiente:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case EstadoTransferencia.aprobada:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      case EstadoTransferencia.enTransito:
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        break;
      case EstadoTransferencia.recibida:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case EstadoTransferencia.rechazada:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      case EstadoTransferencia.cancelada:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado.descripcion,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
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
            'Error al cargar transferencia',
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
            onPressed: _reload,
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

  void _showAprobarDialog(TransferenciaStock transferencia) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aprobar Transferencia'),
        content: Text(
            '¿Está seguro que desea aprobar la transferencia ${transferencia.codigo}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<GestionarTransferenciaCubit>().aprobar(
                    transferenciaId: transferencia.id,
                    empresaId: _empresaId!,
                  );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
  }

  void _showEnviarDialog(TransferenciaStock transferencia) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enviar Transferencia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '¿Confirma que la transferencia ${transferencia.codigo} ha sido enviada?'),
            const SizedBox(height: 8),
            const Text(
              'Se descontará el stock de la sede origen.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<GestionarTransferenciaCubit>().enviar(
                    transferenciaId: transferencia.id,
                    empresaId: _empresaId!,
                  );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Confirmar Envío'),
          ),
        ],
      ),
    );
  }

  void _showRecibirDialog(TransferenciaStock transferencia) {
    final cantidadController =
        TextEditingController(text: transferencia.cantidad.toString());
    final ubicacionController = TextEditingController();
    final observacionesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recibir Transferencia'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transferencia: ${transferencia.codigo}'),
              const SizedBox(height: 16),
              TextField(
                controller: cantidadController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Cantidad Recibida',
                  hintText: 'Enviados: ${transferencia.cantidad}',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ubicacionController,
                decoration: const InputDecoration(
                  labelText: 'Ubicación (opcional)',
                  hintText: 'Ej: Estante A2',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: observacionesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Observaciones (opcional)',
                  border: OutlineInputBorder(),
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
            onPressed: () {
              final cantidad = int.tryParse(cantidadController.text) ?? 0;
              if (cantidad <= 0) {
                _showError('Cantidad inválida');
                return;
              }
              Navigator.pop(ctx);
              context.read<GestionarTransferenciaCubit>().recibir(
                    transferenciaId: transferencia.id,
                    empresaId: _empresaId!,
                    cantidadRecibida: cantidad,
                    ubicacion: ubicacionController.text.trim().isEmpty
                        ? null
                        : ubicacionController.text.trim(),
                    observaciones: observacionesController.text.trim().isEmpty
                        ? null
                        : observacionesController.text.trim(),
                  );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Confirmar Recepción'),
          ),
        ],
      ),
    );
  }

  void _showRechazarDialog(TransferenciaStock transferencia) {
    final motivoController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar Transferencia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Está seguro que desea rechazar ${transferencia.codigo}?'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo del rechazo',
                hintText: 'Explique por qué rechaza esta transferencia',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (motivoController.text.trim().isEmpty) {
                _showError('Debe ingresar un motivo');
                return;
              }
              Navigator.pop(ctx);
              context.read<GestionarTransferenciaCubit>().rechazar(
                    transferenciaId: transferencia.id,
                    empresaId: _empresaId!,
                    motivo: motivoController.text.trim(),
                  );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  void _showCancelarDialog(TransferenciaStock transferencia) {
    final motivoController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Transferencia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Está seguro que desea cancelar ${transferencia.codigo}?'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo de la cancelación',
                hintText: 'Explique por qué cancela esta transferencia',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (motivoController.text.trim().isEmpty) {
                _showError('Debe ingresar un motivo');
                return;
              }
              Navigator.pop(ctx);
              context.read<GestionarTransferenciaCubit>().cancelar(
                    transferenciaId: transferencia.id,
                    empresaId: _empresaId!,
                    motivo: motivoController.text.trim(),
                  );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            child: const Text('Cancelar Transferencia'),
          ),
        ],
      ),
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

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isCompleted;
  final bool isActive;
  final bool isLast;

  const _TimelineItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.isCompleted,
    required this.isActive,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? Colors.green
        : isActive
            ? Colors.blue
            : Colors.grey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.green : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: color,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              if (!isLast) const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool isProcessing;
  final bool isOutlined;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
    this.isProcessing = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: isProcessing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            : Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isProcessing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }
}
