import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/combo.dart';
import '../../domain/entities/componente_combo.dart';
import '../bloc/combo_cubit.dart';
import '../bloc/combo_state.dart';

class ComboDetallePage extends StatelessWidget {
  final String comboId;
  final String empresaId;

  const ComboDetallePage({
    super.key,
    required this.comboId,
    required this.empresaId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<ComboCubit>()
        ..loadCombo(comboId: comboId, empresaId: empresaId),
      child: _ComboDetalleView(empresaId: empresaId),
    );
  }
}

class _ComboDetalleView extends StatelessWidget {
  final String empresaId;

  const _ComboDetalleView({required this.empresaId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Combo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final state = context.read<ComboCubit>().state;
              if (state is ComboLoaded) {
                context.read<ComboCubit>().loadCombo(
                      comboId: state.combo.id,
                      empresaId: empresaId,
                    );
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<ComboCubit, ComboState>(
        builder: (context, state) {
          if (state is ComboLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ComboLoaded) {
            return _buildComboDetails(context, state.combo);
          }

          if (state is ComboError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar el combo',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return const Center(
            child: Text('No se pudo cargar el combo'),
          );
        },
      ),
    );
  }

  Widget _buildComboDetails(BuildContext context, Combo combo) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(context, combo),
          const SizedBox(height: 16),
          _buildPrecioCard(context, combo),
          const SizedBox(height: 16),
          _buildStockCard(context, combo),
          const SizedBox(height: 16),
          _buildComponentesSection(context, combo),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Combo combo) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Información del Combo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Nombre', combo.nombre),
            _buildInfoRow('ID', combo.id),
            if (combo.descripcion != null)
              _buildInfoRow('Descripción', combo.descripcion!),
          ],
        ),
      ),
    );
  }

  Widget _buildPrecioCard(BuildContext context, Combo combo) {
    final tipoPrecioLabel = _getTipoPrecioLabel(combo.tipoPrecioCombo);
    final bool tieneDescuento = combo.porcentajeAhorro != null && combo.porcentajeAhorro! > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_money, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Precio',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Precio Final (destacado)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sell, size: 20, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Precio de Venta',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '\$${combo.precioFinal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tipo de precio
            _buildInfoRow('Tipo de Precio', tipoPrecioLabel),

            // Precio de componentes
            if (combo.tipoPrecioCombo != TipoPrecioCombo.fijo) ...[
              _buildInfoRow(
                'Suma de Componentes',
                '\$${combo.precioCalculado.toStringAsFixed(2)}',
              ),
            ],

            // Mostrar precio fijo si es diferente
            if (combo.tipoPrecioCombo == TipoPrecioCombo.fijo &&
                combo.precio != combo.precioCalculado) ...[
              _buildInfoRow(
                'Suma de Componentes',
                '\$${combo.precioCalculado.toStringAsFixed(2)}',
              ),
            ],

            // Descuento
            if (combo.descuentoPorcentaje != null) ...[
              _buildInfoRow(
                'Descuento Aplicado',
                '${combo.descuentoPorcentaje}%',
              ),
            ],

            // Ahorro
            if (tieneDescuento) ...[
              const Divider(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.savings, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Ahorro: ${combo.porcentajeAhorro!.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '\$${combo.descuentoAplicado!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
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

  Widget _buildStockCard(BuildContext context, Combo combo) {
    final stockColor = combo.stockDisponible > 0 ? Colors.green : Colors.red;
    final bool tieneStock = combo.stockDisponible > 0;
    final bool tieneProblemas = combo.tieneProblemasStock;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Stock Disponible',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Stock disponible principal
            Row(
              children: [
                Icon(
                  tieneStock ? Icons.check_circle : Icons.warning_amber,
                  color: stockColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Puedes armar: ',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${combo.stockDisponible} ${combo.stockDisponible == 1 ? 'combo' : 'combos'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: stockColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Mensaje informativo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tieneStock ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: tieneStock ? Colors.green.shade200 : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    tieneStock ? Icons.info_outline : Icons.warning_amber_outlined,
                    size: 16,
                    color: tieneStock ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tieneStock
                          ? 'El stock se calcula automáticamente según el componente con menor disponibilidad'
                          : 'No hay stock suficiente para armar combos. Revisa los componentes.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Alerta de componentes sin stock
            if (tieneProblemas) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Componentes sin stock:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...combo.componentesSinStock!.map((nombre) => Padding(
                          padding: const EdgeInsets.only(left: 26, top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.circle, size: 6, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  nombre,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComponentesSection(BuildContext context, Combo combo) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.view_list, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Componentes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    context.push('/empresa/combos/${combo.id}/componentes?empresaId=$empresaId');
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Gestionar'),
                ),
              ],
            ),
            const Divider(height: 24),
            if (combo.componentes.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No hay componentes agregados',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ...combo.componentes.map(
                (componente) => _buildComponenteTile(componente),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildComponenteTile(ComponenteCombo componente) {
    final bool tieneStock = componente.tieneStockSuficiente;
    final stockColor = tieneStock ? Colors.green : Colors.red;
    final int maxCombos = componente.maxCombos;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  tieneStock ? Icons.check_circle : Icons.warning_amber,
                  color: stockColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getNombreComponente(componente),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (componente.categoriaComponente != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          componente.categoriaComponente!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (componente.esPersonalizable)
                  const Chip(
                    label: Text('Personalizable', style: TextStyle(fontSize: 10)),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.symmetric(horizontal: 4),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Cantidad requerida
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.numbers, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'x${componente.cantidad}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Stock disponible
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tieneStock ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: tieneStock ? Colors.green.shade200 : Colors.red.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2, size: 14, color: stockColor),
                      const SizedBox(width: 4),
                      Text(
                        'Stock: ${componente.stockDisponible}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: stockColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Máximo de combos
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: Colors.purple.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Máx: $maxCombos',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _getTipoPrecioLabel(TipoPrecioCombo tipo) {
    switch (tipo) {
      case TipoPrecioCombo.fijo:
        return 'Precio Fijo';
      case TipoPrecioCombo.calculado:
        return 'Precio Calculado';
      case TipoPrecioCombo.calculadoConDescuento:
        return 'Precio con Descuento';
    }
  }

  String _getNombreComponente(ComponenteCombo componente) {
    if (componente.componenteInfo != null) {
      final info = componente.componenteInfo!;

      // Si es una variante, mostrar: "Producto - Variante"
      if (info.esVariante && info.varianteNombre != null && info.productoNombre != null) {
        return '${info.productoNombre} - ${info.varianteNombre}';
      }

      // Si no es variante, usar el nombre general
      return info.nombre;
    }
    return 'Componente';
  }
}
