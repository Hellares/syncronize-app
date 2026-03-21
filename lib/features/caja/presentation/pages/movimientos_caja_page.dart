import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/widgets/autorizacion_dialog.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../domain/entities/movimiento_caja.dart';
import '../bloc/caja_movimientos_cubit.dart';
import '../bloc/caja_movimientos_state.dart';
import 'nuevo_movimiento_page.dart';

class MovimientosCajaPage extends StatefulWidget {
  final String cajaId;

  const MovimientosCajaPage({super.key, required this.cajaId});

  @override
  State<MovimientosCajaPage> createState() => _MovimientosCajaPageState();
}

class _MovimientosCajaPageState extends State<MovimientosCajaPage> {
  TipoMovimientoCaja? _filtroTipo;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'S/ ',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: SmartAppBar(
        title: 'Movimientos',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
      ),
      body: GradientContainer(
        child: Column(
          children: [
            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildFilterChip(null, 'Todos'),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    TipoMovimientoCaja.ingreso,
                    'Ingresos',
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    TipoMovimientoCaja.egreso,
                    'Egresos',
                  ),
                ],
              ),
            ),
            // Movements list
            Expanded(
              child: BlocBuilder<CajaMovimientosCubit, CajaMovimientosState>(
                builder: (context, state) {
                  if (state is CajaMovimientosLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is CajaMovimientosError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }

                  if (state is CajaMovimientosLoaded) {
                    final filteredMovimientos = _filtroTipo != null
                        ? state.movimientos
                            .where((m) => m.tipo == _filtroTipo)
                            .toList()
                        : state.movimientos;

                    if (filteredMovimientos.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 48,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Sin movimientos',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        await context
                            .read<CajaMovimientosCubit>()
                            .loadMovimientos(widget.cajaId);
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: filteredMovimientos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return _buildMovimientoCard(
                            filteredMovimientos[index],
                            currencyFormat,
                          );
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blue1,
        onPressed: () {
          Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (_) => NuevoMovimientoPage(cajaId: widget.cajaId),
            ),
          )
              .then((result) {
            if (result == true && mounted) {
              context
                  .read<CajaMovimientosCubit>()
                  .loadMovimientos(widget.cajaId);
            }
          });
        },
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Widget _buildFilterChip(TipoMovimientoCaja? tipo, String label) {
    final isSelected = _filtroTipo == tipo;

    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isSelected ? AppColors.white : AppColors.blue3,
        ),
      ),
      selectedColor: AppColors.blue1,
      backgroundColor: AppColors.white,
      side: BorderSide(
        color: isSelected ? AppColors.blue1 : AppColors.greyLight,
      ),
      onSelected: (_) {
        setState(() => _filtroTipo = tipo);
      },
    );
  }

  Widget _buildMovimientoCard(
    MovimientoCaja mov,
    NumberFormat currencyFormat,
  ) {
    final isIngreso = mov.tipo == TipoMovimientoCaja.ingreso;
    final isAnulado = mov.anulado;
    final canAnular = mov.esManual && !mov.anulado;

    return GestureDetector(
      onLongPress: canAnular ? () => _showAnularMovimientoMenu(mov) : null,
      child: Opacity(
        opacity: isAnulado ? 0.5 : 1.0,
        child: GradientContainer(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isAnulado
                      ? Colors.grey.withValues(alpha: 0.1)
                      : mov.tipo.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isAnulado ? Icons.cancel : mov.categoria.icon,
                  size: 22,
                  color: isAnulado ? Colors.grey : mov.tipo.color,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            mov.descripcion ?? mov.categoria.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isAnulado ? Colors.grey : AppColors.textPrimary,
                              decoration: isAnulado ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAnulado) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              'ANULADO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Payment method badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bluechip,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                mov.metodoPago.icon,
                                size: 12,
                                color: AppColors.blue3,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                mov.metodoPago.label,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.blue3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Time
                        Text(
                          DateFormatter.formatDateTime(mov.fechaMovimiento),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    // Reference codes
                    if (mov.ventaCodigo != null || mov.pedidoCodigo != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        mov.ventaCodigo != null
                            ? 'Venta: ${mov.ventaCodigo}'
                            : 'Pedido: ${mov.pedidoCodigo}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    // Motivo anulacion
                    if (isAnulado && mov.motivoAnulacion != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Motivo: ${mov.motivoAnulacion}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red[300],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIngreso ? '+' : '-'} ${currencyFormat.format(mov.monto)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isAnulado
                          ? Colors.grey
                          : (isIngreso ? AppColors.green : AppColors.red),
                      decoration: isAnulado ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (canAnular)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.more_horiz,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnularMovimientoMenu(MovimientoCaja mov) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Anular movimiento',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              subtitle: Text(
                mov.descripcion ?? mov.categoria.label,
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _requestAnularMovimiento(mov);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _requestAnularMovimiento(MovimientoCaja mov) async {
    final result = await showAutorizacionDialog(
      context,
      operacion: 'ANULAR_MOVIMIENTO_CAJA',
      titulo: 'Autorizar anulacion',
      descripcion: 'Un administrador debe autorizar la anulacion de este movimiento',
    );

    if (result != null && mounted) {
      final cubit = context.read<CajaMovimientosCubit>();
      final success = await cubit.anularMovimiento(
        cajaId: widget.cajaId,
        movimientoId: mov.id,
        autorizadoPorId: result.autorizadoPorId,
        motivo: result.autorizadoPorNombre.isNotEmpty
            ? 'Anulacion - Autorizado por ${result.autorizadoPorNombre}'
            : 'Anulacion de movimiento',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Movimiento anulado' : 'Error al anular movimiento'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
