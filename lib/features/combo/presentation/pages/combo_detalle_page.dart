import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/container_large.dart';
import 'package:syncronize/core/widgets/floating_button_text.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../producto/presentation/bloc/sede_selection/sede_selection_cubit.dart';
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
    final sedeId = _resolveSedeId(context);
    return BlocProvider(
      create: (_) => locator<ComboCubit>()
        ..loadCombo(comboId: comboId, empresaId: empresaId, sedeId: sedeId),
      child: _ComboDetalleView(comboId: comboId, empresaId: empresaId, sedeId: sedeId),
    );
  }

  static String _resolveSedeId(BuildContext ctx) {
    final selected = ctx.read<SedeSelectionCubit>().selectedSedeId;
    if (selected != null) return selected;
    final empresaState = ctx.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded && empresaState.context.sedes.isNotEmpty) {
      return empresaState.context.sedePrincipal!.id;
    }
    return '';
  }
}

class _ComboDetalleView extends StatelessWidget {
  final String comboId;
  final String empresaId;
  final String sedeId;

  const _ComboDetalleView({required this.comboId, required this.empresaId, required this.sedeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'DETALLE DEL COMBO',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: (){
              context.read<ComboCubit>().loadCombo(comboId: comboId, empresaId: empresaId, sedeId: sedeId);
            },
          )
        ],
      ),
      body: BlocConsumer<ComboCubit, ComboState>(
        listener: (context, state) {
          if (state is ReservacionUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), duration: const Duration(seconds: 2)),
            );
            context.read<ComboCubit>().loadCombo(comboId: comboId, empresaId: empresaId, sedeId: sedeId);
          }
          if (state is ComboError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red, duration: const Duration(seconds: 3)),
            );
          }
        },
        buildWhen: (previous, current) => current is! ReservacionUpdated,
        builder: (context, state) {
          if (state is ComboLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ComboLoaded) {
            return _buildComboDetails(context, state.combo, state.reservacionCantidad);
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

  Widget _buildComboDetails(BuildContext context, Combo combo, int reservacionCantidad) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(context, combo),
          const SizedBox(height: 16),
          _buildPrecioCard(context, combo),
          const SizedBox(height: 16),
          _buildStockCard(context, combo),
          const SizedBox(height: 16),
          _buildReservacionSection(context, combo, reservacionCantidad),
          const SizedBox(height: 16),
          _buildComponentesSection(context, combo),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Combo combo) {
    return GradientContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: AppColors.blue1, size: 16,),
                const SizedBox(width: 8),
                AppSubtitle('INFORMACION DEL COMBO')
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

    return GradientContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_money, size: 18,color: AppColors.blue1,),
                const SizedBox(width: 8),
                AppSubtitle('PRECIO')
              ],
            ),
            const Divider(height: 24),

            // Precio Final (destacado)
            ContainerLarge(
              leftIcon: Icons.sell,
              leftText: 'Precio Venta',
              rightText: 'S/ ${combo.precioFinal.toStringAsFixed(2)}',
              backgroundColor: AppColors.greenContainer,
              borderColor: AppColors.greenBorder,
              textAndIconColor: AppColors.greendark,
              fontSizeRight: 14,
              fontRight: AppFont.oxygenBold,
            ),
            const SizedBox(height: 12),

            // Tipo de precio
            _buildInfoRow('Tipo de Precio', tipoPrecioLabel),

            // Precio por separado (sin combo)
            _buildInfoRow(
              'Sin combo',
              'S/ ${combo.precioRegularTotal.toStringAsFixed(2)}',
            ),

            // Precio calculado del combo (con overrides por componente)
            if (combo.precioCalculado != combo.precioRegularTotal) ...[
              _buildInfoRow(
                'Con precios combo',
                'S/ ${combo.precioCalculado.toStringAsFixed(2)}',
              ),
            ],

            // Descuento global (solo CALCULADO_CON_DESCUENTO)
            if (combo.descuentoPorcentaje != null) ...[
              _buildInfoRow(
                'Descuento global',
                '${combo.descuentoPorcentaje}%',
              ),
            ],

            // Ahorro total
            if (tieneDescuento) ...[
              const Divider(height: 16),
              ContainerLarge(
                leftIcon: Icons.savings,
                leftText: 'Ahorro: ${combo.porcentajeAhorro!.toStringAsFixed(1)}%',
                rightText: 'S/ ${combo.descuentoAplicado!.toStringAsFixed(2)}',
              )
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

    return GradientContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory, color: AppColors.blue1, size: 18,),
                const SizedBox(width: 8),
                AppSubtitle('STOCK DISPONIBLE')
              ],
            ),
            const Divider(height: 24),

            // Stock disponible principal
            Row(
              children: [
                Icon(
                  tieneStock ? Icons.check_circle : Icons.warning_amber,
                  color: stockColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                AppSubtitle('Puedes armar: '),
                AppSubtitle('${combo.stockDisponible} ${combo.stockDisponible == 1 ? 'combo' : 'combos'}', fontSize: 12, color: AppColors.green,)
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
                  width: 0.6
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
                    child: AppSubtitle(tieneStock ? 'El stock se calcula automáticamente según el componente con menor disponibilidad': 'No hay stock suficiente para armar combos. Revisa los componentes.', color: AppColors.greendark,),
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
    return GradientContainer(
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
                    Icon(Icons.view_list, color: AppColors.blue1),
                    const SizedBox(width: 8),
                    AppSubtitle('COMPONENTES')
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    context.push('/empresa/combos/${combo.id}/componentes?empresaId=$empresaId');
                  },
                  icon: const Icon(Icons.edit, size: 16, color: AppColors.blue1,),
                  label: AppSubtitle('Gestionar')
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

    return GradientContainer(
      // borderColor: AppColors.blueborder,
      margin: const EdgeInsets.only(bottom: 8),
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
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSubtitle(_getNombreComponente(componente)),
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

                // Precio: muestra precio regular tachado si tiene override
                if (componente.componenteInfo?.tienePrecioOverride == true) ...[
                  Text(
                    '\$${componente.precioUnitarioRegular.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '\$${componente.precioUnitario.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  Text(
                    '\$${componente.precioUnitario.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

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

                // Máximo de combos con este componente
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

  Widget _buildReservacionSection(BuildContext context, Combo combo, int reservacionCantidad) {
    final bool tieneReserva = reservacionCantidad > 0;

    return GradientContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, color: AppColors.blue1, size: 18,),
                const SizedBox(width: 8),
                AppSubtitle('RESERVA DE STOCK')
              ],
            ),
            const Divider(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Combos reservados:',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$reservacionCantidad',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: tieneReserva ? Colors.blue.shade700 : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FloatingButtonText(
                      onPressed: () => _showReservarDialog(context, combo.id, reservacionCantidad),
                      icon: tieneReserva ? Icons.edit : Icons.lock,
                      label: tieneReserva ? 'Modificar' : 'Reservar',
                      width: 110,
                      borderColor: AppColors.blue1,
                    ),
                    if (tieneReserva) ...[
                      const SizedBox(height: 8),
                      FloatingButtonText(
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.blue1,
                        onPressed: () => context.read<ComboCubit>().liberarReserva(comboId: combo.id, sedeId: sedeId),
                        icon: Icons.lock_open,
                        label: 'Liberar',
                        width: 110,
                      )
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppSubtitle(
                      tieneReserva 
                      ? 'Se inhabilitan componentes para venta individual, asegurando stock para $reservacionCantidad combo${reservacionCantidad == 1 ? '' : 's'}.' 
                      : 'Reserva stock de componentes para garantizar que se puedan armar combos sin que se vendan por separado.', color: AppColors.blue
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReservarDialog(BuildContext context, String comboId, int cantidadActual) {
    final controller = TextEditingController(text: cantidadActual.toString());
    final cubit = context.read<ComboCubit>();

    showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: AppColors.blue1),
            const SizedBox(width: 8),
            const Text('Reservar Stock'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cantidad actual reservada: $cantidadActual combo${cantidadActual == 1 ? '' : 's'}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Stock disponible: ${comboStockDisponible(context)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text('Nueva cantidad a reservar:'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2),
                suffixText: 'combos',
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
              final val = int.tryParse(controller.text);
              if (val != null && val >= 0) {
                Navigator.pop(ctx, val);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue1, foregroundColor: AppColors.white),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ).then((result) {
      if (result != null) {
        cubit.reservarStock(
              comboId: comboId,
              sedeId: sedeId,
              cantidad: result,
            );
      }
    });
  }

  int comboStockDisponible(BuildContext context) {
    final state = context.read<ComboCubit>().state;
    if (state is ComboLoaded) return state.combo.stockDisponible;
    return 0;
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: AppSubtitle('$label:',color: AppColors.blueGrey,),
          ),
          Expanded(
            child: AppSubtitle(value),
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
