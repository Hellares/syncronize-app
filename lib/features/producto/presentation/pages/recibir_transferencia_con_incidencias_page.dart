import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../domain/entities/transferencia_stock.dart';
import '../../domain/entities/transferencia_incidencia.dart';
import '../../domain/entities/incidencia_item_request.dart';
import '../bloc/recibir_transferencia_incidencias/recibir_transferencia_incidencias_cubit.dart';
import '../bloc/recibir_transferencia_incidencias/recibir_transferencia_incidencias_state.dart';

class RecibirTransferenciaConIncidenciasPage extends StatefulWidget {
  final TransferenciaStock transferencia;
  final String empresaId;

  const RecibirTransferenciaConIncidenciasPage({
    super.key,
    required this.transferencia,
    required this.empresaId,
  });

  @override
  State<RecibirTransferenciaConIncidenciasPage> createState() =>
      _RecibirTransferenciaConIncidenciasPageState();
}

class _RecibirTransferenciaConIncidenciasPageState
    extends State<RecibirTransferenciaConIncidenciasPage> {
  final _formKey = GlobalKey<FormState>();
  final _observacionesController = TextEditingController();

  // Estado de cada item
  final Map<String, _ItemRecepcionState> _itemsState = {};

  @override
  void initState() {
    super.initState();
    _initializeItemsState();
  }

  void _initializeItemsState() {
    if (widget.transferencia.items == null) return;

    for (final item in widget.transferencia.items!) {
      _itemsState[item.id] = _ItemRecepcionState(
        item: item,
        cantidadBuena: item.cantidadEnviada ?? 0,
        incidencias: [],
      );
    }
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Recibir con Incidencias',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
      ),
      body: GradientBackground(
        child: BlocListener<RecibirTransferenciaIncidenciasCubit,
            RecibirTransferenciaIncidenciasState>(
          listener: (context, state) {
            if (state is RecibirTransferenciaIncidenciasSuccess) {
              _showSuccess(state.message);
              Navigator.of(context).pop();
            } else if (state is RecibirTransferenciaIncidenciasError) {
              _showError(state.message);
            }
          },
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildTransferenciaInfo(),
                      const SizedBox(height: 16),
                      _buildInstrucciones(),
                      const SizedBox(height: 16),
                      ..._buildItemsList(),
                      const SizedBox(height: 16),
                      _buildObservacionesGenerales(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransferenciaInfo() {
    return GradientContainer(
      gradient: AppGradients.sinfondo,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.transferencia.codigo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.blue1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.upload, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Origen: ${widget.transferencia.sedeOrigen?.nombre ?? "N/A"}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.download, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Destino: ${widget.transferencia.sedeDestino?.nombre ?? "N/A"}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstrucciones() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instrucciones',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '1. Indica la cantidad recibida en buen estado\n'
                  '2. Reporta problemas agregando incidencias\n'
                  '3. La suma de cantidades buenas + incidencias debe ≤ enviadas',
                  style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildItemsList() {
    if (widget.transferencia.items == null ||
        widget.transferencia.items!.isEmpty) {
      return [
        const Center(
          child: Text('No hay items en esta transferencia'),
        ),
      ];
    }

    return widget.transferencia.items!.map((item) {
      final itemState = _itemsState[item.id]!;
      return _buildItemCard(item, itemState);
    }).toList();
  }

  Widget _buildItemCard(
      TransferenciaStockItem item, _ItemRecepcionState itemState) {
    final cantidadEnviada = item.cantidadEnviada ?? 0;
    final totalIncidencias =
        itemState.incidencias.fold<int>(0, (sum, inc) => sum + inc.cantidad);
    final totalContabilizado = itemState.cantidadBuena + totalIncidencias;
    final excedeLimite = totalContabilizado > cantidadEnviada;

    return GradientContainer(
      gradient: AppGradients.sinfondo,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del producto
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: AppColors.blue1,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nombreProducto,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.codigoProducto != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'SKU: ${item.codigoProducto}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Enviadas: $cantidadEnviada unidades',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Campo: Cantidad en buen estado
            TextFormField(
              initialValue: itemState.cantidadBuena.toString(),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Cantidad recibida en buen estado',
                hintText: '0',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.check_circle, color: Colors.green),
                errorText: excedeLimite
                    ? 'Excede cantidad enviada ($cantidadEnviada)'
                    : null,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Requerido';
                final num = int.tryParse(value);
                if (num == null || num < 0) return 'Cantidad inválida';
                return null;
              },
              onChanged: (value) {
                setState(() {
                  itemState.cantidadBuena = int.tryParse(value) ?? 0;
                });
              },
            ),

            const SizedBox(height: 12),

            // Incidencias del item
            if (itemState.incidencias.isNotEmpty) ...[
              Text(
                'Incidencias reportadas (${itemState.incidencias.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...itemState.incidencias.asMap().entries.map((entry) {
                final index = entry.key;
                final incidencia = entry.value;
                return _buildIncidenciaChip(itemState, index, incidencia);
              }),
              const SizedBox(height: 8),
            ],

            // Botón para agregar incidencia
            OutlinedButton.icon(
              onPressed: () => _showAgregarIncidenciaDialog(item, itemState),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar Incidencia'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
              ),
            ),

            // Resumen de contabilización
            if (totalIncidencias > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: excedeLimite
                      ? Colors.red.shade50
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: excedeLimite
                        ? Colors.red.shade200
                        : Colors.blue.shade200,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total contabilizado:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '$totalContabilizado / $cantidadEnviada',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: excedeLimite ? Colors.red : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIncidenciaChip(
    _ItemRecepcionState itemState,
    int index,
    _IncidenciaData incidencia,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, size: 18, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incidencia.tipo.descripcion,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                Text(
                  '${incidencia.cantidad} unidades',
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
                if (incidencia.descripcion.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    incidencia.descripcion,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete, size: 18, color: Colors.red.shade400),
            onPressed: () {
              setState(() {
                itemState.incidencias.removeAt(index);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildObservacionesGenerales() {
    return GradientContainer(
      gradient: AppGradients.sinfondo,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _observacionesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Observaciones generales (opcional)',
            hintText: 'Comentarios adicionales sobre la recepción...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return BlocBuilder<RecibirTransferenciaIncidenciasCubit,
        RecibirTransferenciaIncidenciasState>(
      builder: (context, state) {
        final isProcessing = state is RecibirTransferenciaIncidenciasProcessing;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isProcessing ? null : _completarRecepcion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue1,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Completar Recepción',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAgregarIncidenciaDialog(
    TransferenciaStockItem item,
    _ItemRecepcionState itemState,
  ) {
    TipoIncidenciaTransferencia? tipoSeleccionado;
    final cantidadController = TextEditingController();
    final descripcionController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Agregar Incidencia'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombreProducto,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TipoIncidenciaTransferencia>(
                  initialValue: tipoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de incidencia',
                    border: OutlineInputBorder(),
                  ),
                  items: TipoIncidenciaTransferencia.values.map((tipo) {
                    return DropdownMenuItem(
                      value: tipo,
                      child: Text(tipo.descripcion, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => tipoSeleccionado = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: cantidadController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Cantidad afectada',
                    border: OutlineInputBorder(),
                    hintText: '0',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descripcionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(),
                    hintText: 'Detalles del problema...',
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
                if (tipoSeleccionado == null) {
                  _showError('Selecciona el tipo de incidencia');
                  return;
                }
                final cantidad = int.tryParse(cantidadController.text) ?? 0;
                if (cantidad <= 0) {
                  _showError('Ingresa una cantidad válida');
                  return;
                }

                this.setState(() {
                  itemState.incidencias.add(_IncidenciaData(
                    tipo: tipoSeleccionado!,
                    cantidad: cantidad,
                    descripcion: descripcionController.text.trim(),
                  ));
                });

                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  void _completarRecepcion() {
    if (!_formKey.currentState!.validate()) {
      _showError('Completa todos los campos requeridos');
      return;
    }

    // Validar que no se exceda la cantidad enviada
    for (final entry in _itemsState.entries) {
      final itemState = entry.value;
      final cantidadEnviada = itemState.item.cantidadEnviada ?? 0;
      final totalIncidencias =
          itemState.incidencias.fold<int>(0, (sum, inc) => sum + inc.cantidad);
      final totalContabilizado = itemState.cantidadBuena + totalIncidencias;

      if (totalContabilizado > cantidadEnviada) {
        _showError(
          'El producto "${itemState.item.nombreProducto}" excede la cantidad enviada',
        );
        return;
      }
    }

    // Construir el request
    final items = _itemsState.values.map((itemState) {
      final incidencias = itemState.incidencias.map((inc) {
        return IncidenciaItemRequest(
          tipo: inc.tipo,
          cantidadAfectada: inc.cantidad,
          descripcion: inc.descripcion.isEmpty ? null : inc.descripcion,
          evidenciasUrls: [],
        );
      }).toList();

      return RecibirItemRequest(
        itemId: itemState.item.id,
        cantidadRecibidaBuenEstado: itemState.cantidadBuena,
        incidencias: incidencias,
      );
    }).toList();

    final request = RecibirTransferenciaConIncidenciasRequest(
      items: items,
      observacionesGenerales: _observacionesController.text.trim().isEmpty
          ? null
          : _observacionesController.text.trim(),
      marcarComoCompletada: true,
    );

    context.read<RecibirTransferenciaIncidenciasCubit>().recibir(
          transferenciaId: widget.transferencia.id,
          empresaId: widget.empresaId,
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

// ========================================
// CLASES DE ESTADO INTERNO
// ========================================

class _ItemRecepcionState {
  final TransferenciaStockItem item;
  int cantidadBuena;
  final List<_IncidenciaData> incidencias;

  _ItemRecepcionState({
    required this.item,
    required this.cantidadBuena,
    required this.incidencias,
  });
}

class _IncidenciaData {
  final TipoIncidenciaTransferencia tipo;
  final int cantidad;
  final String descripcion;

  _IncidenciaData({
    required this.tipo,
    required this.cantidad,
    required this.descripcion,
  });
}
