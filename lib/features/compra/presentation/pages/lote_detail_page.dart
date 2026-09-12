import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/theme/app_colors.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/fecha_calendario.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../data/datasources/compra_remote_datasource.dart';
import '../../domain/entities/lote.dart';
import '../widgets/baja_lote_dialog.dart';
import '../widgets/corregir_vencimiento_dialog.dart';

/// Detalle de un lote, con las dos acciones que resuelven un bloqueo por
/// vencimiento: darlo de baja (la mercadería no sirve) o corregir la fecha
/// (el dato estaba mal). Las dos exigen `canManageProducts`.
///
/// Devuelve `true` al salir si algo cambió, para que la lista recargue.
class LoteDetailPage extends StatefulWidget {
  final String empresaId;
  final Lote lote;

  const LoteDetailPage({
    super.key,
    required this.empresaId,
    required this.lote,
  });

  @override
  State<LoteDetailPage> createState() => _LoteDetailPageState();
}

class _LoteDetailPageState extends State<LoteDetailPage> {
  late Lote _lote = widget.lote;
  bool _cambio = false;
  bool _recargando = false;

  Color _estadoColor() {
    switch (_lote.estado) {
      case EstadoLote.ACTIVO:
        return Colors.green;
      case EstadoLote.AGOTADO:
        return Colors.grey;
      case EstadoLote.VENCIDO:
        return Colors.red;
      case EstadoLote.BLOQUEADO:
        return Colors.orange;
    }
  }

  /// Tras una acción el lote cambió en el servidor: se vuelve a leer para
  /// que la pantalla no muestre un dato viejo.
  Future<void> _recargar() async {
    setState(() => _recargando = true);
    try {
      final fresco = await locator<CompraRemoteDataSource>()
          .getLote(empresaId: widget.empresaId, id: _lote.id);
      if (!mounted) return;
      setState(() {
        _lote = fresco;
        _cambio = true;
        _recargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cambio = true;
        _recargando = false;
      });
    }
  }

  Future<void> _darDeBaja() async {
    final ok = await BajaLoteDialog.mostrar(
      context,
      empresaId: widget.empresaId,
      lote: _lote,
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Lote dado de baja: salió del inventario'),
      ));
      await _recargar();
    }
  }

  Future<void> _corregirVencimiento() async {
    final ok = await CorregirVencimientoDialog.mostrar(
      context,
      empresaId: widget.empresaId,
      lote: _lote,
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vencimiento corregido'),
      ));
      await _recargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final lote = _lote;
    final empresaState = context.watch<EmpresaContextCubit>().state;
    final puedeGestionar = empresaState is EmpresaContextLoaded &&
        empresaState.context.permissions.canManageProducts;
    final dias = lote.diasParaVencer;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.pop(_cambio);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(lote.codigo),
          backgroundColor: AppColors.blue1,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(_cambio),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                color: _estadoColor().withValues(alpha: 0.08),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: _estadoColor().withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        lote.estadoTexto,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _estadoColor(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (lote.nombreProducto.isNotEmpty)
                      Text(
                        lote.nombreProducto,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    if (lote.codigoProducto.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        lote.codigoProducto,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    // 🔴 Vencido por DÍA de calendario: lo que le pasa a la
                    // venta con este lote, dicho acá donde se puede resolver.
                    if (lote.fechaVencimiento != null && lote.cantidadActual > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: lote.estaVencido
                              ? Colors.red.shade50
                              : lote.proximoAVencer
                                  ? Colors.amber.shade50
                                  : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          lote.estaVencido
                              ? 'VENCIDO el ${formatearDiaEnvase(lote.fechaVencimiento, anioCompleto: true)}. '
                                  'Si el producto es de caducidad, la venta lo frena: '
                                  'dalo de baja, o corregí la fecha si se cargó mal.'
                              : dias == 0
                                  ? 'Vence HOY. Todavía se puede vender.'
                                  : lote.proximoAVencer
                                      ? 'Vence en $dias días. Sale primero que los que vencen después.'
                                      : 'Vence el ${formatearDiaEnvase(lote.fechaVencimiento, anioCompleto: true)}.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: lote.estaVencido
                                ? Colors.red.shade800
                                : lote.proximoAVencer
                                    ? Colors.amber.shade900
                                    : Colors.green.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Acciones: solo con el permiso, y solo lo que aplica.
              if (puedeGestionar)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      if (lote.cantidadActual > 0)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _recargando ? null : _darDeBaja,
                            icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                            label: const Text('Dar de baja'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade200),
                            ),
                          ),
                        ),
                      if (lote.cantidadActual > 0) const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _recargando ? null : _corregirVencimiento,
                          icon: const Icon(Icons.event_repeat_outlined, size: 18),
                          label: const Text('Corregir fecha'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.blue1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Stock
              _buildSection('Stock', [
                _buildInfoRow('Cantidad Inicial', '${lote.cantidadInicial}'),
                _buildInfoRow('Cantidad Actual', '${lote.cantidadActual}'),
                _buildInfoRow('Reservada', '${lote.cantidadReservada}'),
                _buildInfoRow('Disponible', '${lote.cantidadDisponible}'),
                _buildInfoRow('Consumido',
                    '${lote.porcentajeConsumido.toStringAsFixed(1)}%'),
              ]),

              // Barra de progreso de consumo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: lote.porcentajeConsumido / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        lote.porcentajeConsumido > 80
                            ? Colors.red
                            : lote.porcentajeConsumido > 50
                                ? Colors.orange
                                : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              _buildSection('Costo', [
                _buildInfoRow('Precio Costo',
                    '${lote.moneda} ${lote.precioCosto.toStringAsFixed(2)}'),
                _buildInfoRow('Moneda', lote.moneda),
              ]),

              _buildSection('Fechas', [
                _buildInfoRow(
                    'Fecha Ingreso', dateFormat.format(lote.fechaIngreso)),
                if (lote.fechaProduccion != null)
                  _buildInfoRow('Fecha Producción',
                      formatearDiaEnvase(lote.fechaProduccion, anioCompleto: true)),
                // Por sus campos UTC: es un DÍA, no un instante.
                _buildInfoRow(
                  'Fecha Vencimiento',
                  lote.fechaVencimiento == null
                      ? 'No vence'
                      : formatearDiaEnvase(lote.fechaVencimiento, anioCompleto: true),
                  valueColor: lote.estaVencido
                      ? Colors.red
                      : lote.proximoAVencer
                          ? Colors.orange.shade800
                          : null,
                ),
              ]),

              _buildSection('Información', [
                if (lote.numeroLote != null)
                  _buildInfoRow('N° Lote Fabricante', lote.numeroLote!),
                if (lote.nombreProveedor != null)
                  _buildInfoRow('Proveedor', lote.nombreProveedor!),
                _buildInfoRow('Creado', dateFormat.format(lote.creadoEn)),
                _buildInfoRow(
                    'Actualizado', dateFormat.format(lote.actualizadoEn)),
              ]),

              if (lote.observaciones != null && lote.observaciones!.isNotEmpty)
                _buildSection('Observaciones', [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(lote.observaciones!),
                  ),
                ]),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
