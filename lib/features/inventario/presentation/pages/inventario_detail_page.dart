import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/widgets/barcode_scanner_sheet.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import '../../domain/entities/inventario.dart';
import '../bloc/inventario_detail_cubit.dart';
import '../bloc/inventario_detail_state.dart';
import '../widgets/conteo_bottom_sheet.dart';

class InventarioDetailPage extends StatefulWidget {
  final String inventarioId;

  const InventarioDetailPage({super.key, required this.inventarioId});

  @override
  State<InventarioDetailPage> createState() => _InventarioDetailPageState();
}

class _InventarioDetailPageState extends State<InventarioDetailPage> {
  late final InventarioDetailCubit _detailCubit;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _detailCubit = locator<InventarioDetailCubit>();
    _detailCubit.loadDetalle(widget.inventarioId);
  }

  @override
  void dispose() {
    _detailCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _detailCubit,
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop && _hasChanges) {
            // Return true to signal the list to reload
          }
        },
        child: BlocConsumer<InventarioDetailCubit, InventarioDetailState>(
          listener: (context, state) {
            if (state is InventarioDetailActionSuccess) {
              _hasChanges = true;
              SnackBarHelper.showSuccess(context, state.successMessage);
            } else if (state is InventarioDetailActionError) {
              SnackBarHelper.showError(context, state.errorMessage);
            }
          },
          builder: (context, state) {
            final inv = _extractInventario(state);
            final showScanner = inv != null && inv.estado == EstadoInventario.enProceso;
            return Scaffold(
              appBar: SmartAppBar(
                title: 'Detalle Inventario',
                backgroundColor: AppColors.blue1,
                foregroundColor: AppColors.white,
              ),
              floatingActionButton: showScanner
                  ? FloatingActionButton(
                      backgroundColor: AppColors.blue1,
                      onPressed: () => _onScanBarcode(context, inv!),
                      child: const Icon(Icons.qr_code_scanner, color: Colors.white),
                    )
                  : null,
              body: _buildBody(context, state),
            );
          },
        ),
      ),
    );
  }

  Inventario? _extractInventario(InventarioDetailState state) {
    if (state is InventarioDetailLoaded) return state.inventario;
    if (state is InventarioDetailActionLoading) return state.inventario;
    if (state is InventarioDetailActionSuccess) return state.inventario;
    if (state is InventarioDetailActionError) return state.inventario;
    return null;
  }

  Future<void> _onScanBarcode(BuildContext context, Inventario inv) async {
    final scannedCode = await showBarcodeScannerSheet(context);
    if (scannedCode == null || !mounted) return;

    final items = inv.items;
    if (items == null || items.isEmpty) {
      SnackBarHelper.showError(context, 'No hay productos en este inventario');
      return;
    }

    // Search for the item matching the scanned barcode
    final matchedItem = items.cast<InventarioItem?>().firstWhere(
      (item) =>
          (item!.codigoBarras != null && item.codigoBarras == scannedCode) ||
          (item.codigoProducto != null && item.codigoProducto == scannedCode),
      orElse: () => null,
    );

    if (matchedItem == null) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Producto no encontrado');
      }
      return;
    }

    if (!matchedItem.pendiente) {
      if (mounted) {
        SnackBarHelper.showInfo(context, 'Ya fue contado');
      }
      return;
    }

    // Open the conteo dialog
    if (mounted) {
      _showConteoSheet(context, inv, matchedItem);
    }
  }

  Widget _buildBody(BuildContext context, InventarioDetailState state) {
    if (state is InventarioDetailLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is InventarioDetailError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.red),
            const SizedBox(height: 12),
            Text(
              state.message,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _detailCubit.loadDetalle(widget.inventarioId),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    Inventario? inventario;
    bool isActionLoading = false;
    String? actionMessage;

    if (state is InventarioDetailLoaded) {
      inventario = state.inventario;
    } else if (state is InventarioDetailActionLoading) {
      inventario = state.inventario;
      isActionLoading = true;
      actionMessage = state.actionMessage;
    } else if (state is InventarioDetailActionSuccess) {
      inventario = state.inventario;
    } else if (state is InventarioDetailActionError) {
      inventario = state.inventario;
    }

    if (inventario == null) return const SizedBox.shrink();

    return GradientContainer(
      child: RefreshIndicator(
        onRefresh: () async {
          await _detailCubit.loadDetalle(widget.inventarioId);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header card
            _buildHeaderCard(inventario),
            const SizedBox(height: 16),
            // Progress card
            _buildProgressCard(inventario),
            const SizedBox(height: 16),
            // Action buttons
            _buildActionButtons(context, inventario, isActionLoading, actionMessage),
            const SizedBox(height: 16),
            // Items list
            if (inventario.items != null && inventario.items!.isNotEmpty) ...[
              AppSubtitle(
                'Productos (${inventario.items!.length})',
                fontSize: 16,
                color: AppColors.blue3,
              ),
              const SizedBox(height: 10),
              ...inventario.items!.map(
                (item) => _buildItemCard(context, inventario!, item),
              ),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: AppColors.textSecondary.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No hay productos en este inventario',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Inventario inv) {
    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppSubtitle(
                  inv.codigo,
                  fontSize: 18,
                  color: AppColors.blue3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: inv.estado.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  inv.estado.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: inv.estado.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            inv.nombre,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (inv.descripcion != null && inv.descripcion!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              inv.descripcion!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(Icons.category_rounded, 'Tipo', inv.tipoInventario.label),
              ),
              Expanded(
                child: _buildInfoRow(Icons.store_rounded, 'Sede', inv.sedeNombre ?? '-'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  Icons.person_rounded,
                  'Responsable',
                  inv.responsableNombre ?? '-',
                ),
              ),
              Expanded(
                child: _buildInfoRow(
                  Icons.calendar_today_rounded,
                  'Planificada',
                  inv.fechaPlanificada != null
                      ? DateFormatter.formatDateTime(inv.fechaPlanificada!)
                      : '-',
                ),
              ),
            ],
          ),
          if (inv.fechaInicio != null || inv.fechaFinConteo != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    Icons.play_arrow_rounded,
                    'Inicio',
                    inv.fechaInicio != null
                        ? DateFormatter.formatDateTime(inv.fechaInicio!)
                        : '-',
                  ),
                ),
                Expanded(
                  child: _buildInfoRow(
                    Icons.stop_rounded,
                    'Fin conteo',
                    inv.fechaFinConteo != null
                        ? DateFormatter.formatDateTime(inv.fechaFinConteo!)
                        : '-',
                  ),
                ),
              ],
            ),
          ],
          if (inv.observaciones != null && inv.observaciones!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              inv.observaciones!,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressCard(Inventario inv) {
    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSubtitle(
            'Progreso del Conteo',
            fontSize: 14,
            color: AppColors.blue3,
          ),
          const SizedBox(height: 12),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: inv.progreso,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      inv.progreso >= 1.0 ? Colors.green : AppColors.blue1,
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(inv.progreso * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              _buildStatChip(
                'Contados',
                '${inv.totalProductosContados}/${inv.totalProductosEsperados}',
                AppColors.blue1,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                'Diferencias',
                '${inv.totalDiferencias}',
                Colors.orange,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                'Sobrantes',
                '${inv.totalSobrantes}',
                Colors.green,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                'Faltantes',
                '${inv.totalFaltantes}',
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Inventario inv,
    bool isLoading,
    String? actionMessage,
  ) {
    final buttons = <Widget>[];

    switch (inv.estado) {
      case EstadoInventario.planificado:
        buttons.add(
          CustomButton(
            text: 'Iniciar Conteo',
            onPressed: isLoading
                ? null
                : () => _confirmAction(
                      context,
                      'Iniciar Conteo',
                      'Se iniciara el conteo de este inventario. Los productos quedaran listos para ser contados.',
                      () => _detailCubit.iniciar(inv.id),
                    ),
          ),
        );
        break;
      case EstadoInventario.enProceso:
        final allCounted = inv.items != null &&
            inv.items!.isNotEmpty &&
            inv.items!.every((item) => item.contado);
        buttons.add(
          CustomButton(
            text: 'Finalizar Conteo',
            onPressed: isLoading || !allCounted
                ? null
                : () => _confirmAction(
                      context,
                      'Finalizar Conteo',
                      'Se finalizara el conteo. Asegurese de que todos los productos hayan sido contados.',
                      () => _detailCubit.finalizarConteo(inv.id),
                    ),
          ),
        );
        if (!allCounted) {
          buttons.add(const SizedBox(height: 4));
          buttons.add(
            const Text(
              'Todos los productos deben ser contados para finalizar',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          );
        }
        break;
      case EstadoInventario.conteoCompleto:
        buttons.add(
          CustomButton(
            text: 'Aprobar Inventario',
            onPressed: isLoading
                ? null
                : () => _confirmAction(
                      context,
                      'Aprobar Inventario',
                      'Se aprobara este inventario. Revise las diferencias antes de continuar.',
                      () => _detailCubit.aprobar(inv.id),
                    ),
          ),
        );
        break;
      case EstadoInventario.aprobado:
        buttons.add(
          CustomButton(
            text: 'Aplicar Ajustes de Stock',
            onPressed: isLoading
                ? null
                : () => _confirmAction(
                      context,
                      'Aplicar Ajustes',
                      'Se ajustara el stock en el sistema segun las diferencias encontradas. Esta accion no se puede deshacer.',
                      () => _detailCubit.aplicarAjustes(inv.id),
                    ),
          ),
        );
        break;
      default:
        break;
    }

    // Cancel button (except AJUSTADO and CANCELADO)
    if (inv.estado != EstadoInventario.ajustado &&
        inv.estado != EstadoInventario.cancelado &&
        inv.estado != EstadoInventario.rechazado) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(height: 8));
      buttons.add(
        CustomButton(
          text: 'Cancelar Inventario',
          isOutlined: true,
          onPressed: isLoading
              ? null
              : () => _confirmAction(
                    context,
                    'Cancelar Inventario',
                    'Se cancelara este inventario. Esta accion no se puede deshacer.',
                    () => _detailCubit.cancelar(inv.id),
                  ),
        ),
      );
    }

    if (isLoading && actionMessage != null) {
      buttons.insert(
        0,
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                actionMessage,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Column(children: buttons);
  }

  void _confirmAction(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue1,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, Inventario inv, InventarioItem item) {
    final bool canCount = inv.estado == EstadoInventario.enProceso && item.pendiente;

    Color? diffColor;
    if (item.diferencia != null && item.diferencia != 0) {
      diffColor = item.diferencia! > 0 ? Colors.green : Colors.red;
    }

    return InkWell(
      onTap: canCount
          ? () => _showConteoSheet(context, inv, item)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: canCount
                ? AppColors.blue1.withValues(alpha: 0.3)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.pendiente
                    ? Colors.orange.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.pendiente ? Icons.pending_actions : Icons.check_circle,
                size: 18,
                color: item.pendiente ? Colors.orange : Colors.green,
              ),
            ),
            const SizedBox(width: 10),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nombreProducto,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.codigoProducto != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.codigoProducto!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Quantities
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Sistema: ${item.cantidadSistema}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.cantidadContada != null
                      ? 'Contado: ${item.cantidadContada}'
                      : 'Pendiente',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: item.cantidadContada != null
                        ? AppColors.textPrimary
                        : Colors.orange,
                  ),
                ),
                if (item.diferencia != null && item.diferencia != 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Dif: ${item.diferencia! > 0 ? '+' : ''}${item.diferencia}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: diffColor,
                    ),
                  ),
                ],
              ],
            ),
            if (canCount) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.blue1),
            ],
          ],
        ),
      ),
    );
  }

  void _showConteoSheet(
    BuildContext context,
    Inventario inv,
    InventarioItem item,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return ConteoBottomSheet(
          item: item,
          onSubmit: (cantidadContada, ubicacion, observaciones) {
            Navigator.of(sheetContext).pop();
            final data = <String, dynamic>{
              'cantidadContada': cantidadContada,
            };
            if (ubicacion != null && ubicacion.isNotEmpty) {
              data['ubicacionFisica'] = ubicacion;
            }
            if (observaciones != null && observaciones.isNotEmpty) {
              data['observaciones'] = observaciones;
            }
            _detailCubit.registrarConteo(
              inventarioId: inv.id,
              itemId: item.id,
              data: data,
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
