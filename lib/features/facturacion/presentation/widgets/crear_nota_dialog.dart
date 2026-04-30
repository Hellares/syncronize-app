import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/crear_nota_item.dart';
import '../../domain/entities/nota_emitida.dart';
import '../../domain/entities/tipo_nota.dart';
import '../bloc/crear_nota_cubit.dart';
import '../bloc/crear_nota_state.dart';
import 'items_adicionales_widget.dart';
import 'items_selector_widget.dart';
import 'motivo_selector_widget.dart';

class CrearNotaDialog extends StatelessWidget {
  final String comprobanteOrigenId;
  final String sedeId;
  final TipoNota tipoNota;
  final String comprobanteCodigo;
  final double comprobanteTotal;
  final String moneda;
  final List<CrearNotaItem> itemsOrigen;

  const CrearNotaDialog({
    super.key,
    required this.comprobanteOrigenId,
    required this.sedeId,
    required this.tipoNota,
    required this.comprobanteCodigo,
    required this.comprobanteTotal,
    this.moneda = 'PEN',
    this.itemsOrigen = const [],
  });

  /// Muestra el dialog. Devuelve la nota emitida si fue exitoso, null si se canceló.
  static Future<NotaEmitida?> show(
    BuildContext context, {
    required String comprobanteOrigenId,
    required String sedeId,
    required TipoNota tipoNota,
    required String comprobanteCodigo,
    required double comprobanteTotal,
    String moneda = 'PEN',
    List<CrearNotaItem> itemsOrigen = const [],
  }) {
    return showDialog<NotaEmitida>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CrearNotaDialog(
        comprobanteOrigenId: comprobanteOrigenId,
        sedeId: sedeId,
        tipoNota: tipoNota,
        comprobanteCodigo: comprobanteCodigo,
        comprobanteTotal: comprobanteTotal,
        moneda: moneda,
        itemsOrigen: itemsOrigen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<CrearNotaCubit>()..inicializar(tipoNota: tipoNota, itemsOrigen: itemsOrigen),
      child: _CrearNotaContent(
        tipoNota: tipoNota,
        comprobanteOrigenId: comprobanteOrigenId,
        sedeId: sedeId,
        comprobanteCodigo: comprobanteCodigo,
        comprobanteTotal: comprobanteTotal,
        moneda: moneda,
      ),
    );
  }
}

class _CrearNotaContent extends StatelessWidget {
  final TipoNota tipoNota;
  final String comprobanteOrigenId;
  final String sedeId;
  final String comprobanteCodigo;
  final double comprobanteTotal;
  final String moneda;

  const _CrearNotaContent({
    required this.tipoNota,
    required this.comprobanteOrigenId,
    required this.sedeId,
    required this.comprobanteCodigo,
    required this.comprobanteTotal,
    required this.moneda,
  });

  Color get _color => tipoNota == TipoNota.notaCredito ? Colors.orange : Colors.purple;
  String get _simboloMoneda => moneda == 'USD' ? '\$' : 'S/';

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CrearNotaCubit, CrearNotaState>(
      listener: (ctx, state) {
        if (state.status == CrearNotaStatus.success && state.resultado != null) {
          Navigator.of(ctx).pop(state.resultado);
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text('${tipoNota.label} ${state.resultado!.codigoGenerado} emitida'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      builder: (ctx, state) {
        return AlertDialog(
          title: Text(tipoNota.label, style: const TextStyle(fontSize: 16)),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 480,
              maxHeight: MediaQuery.of(ctx).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  if (state.status == CrearNotaStatus.loadingMotivos)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.motivos.isNotEmpty) ...[
                    MotivoSelectorWidget(
                      motivos: state.motivos,
                      seleccionado: state.motivoSeleccionado,
                      onChanged: (codigo) =>
                          ctx.read<CrearNotaCubit>().seleccionarMotivo(codigo),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      maxLines: 2,
                      maxLength: 250,
                      decoration: const InputDecoration(
                        labelText: 'Motivo (descripción libre)',
                        hintText: 'Mín. 3 caracteres',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 12),
                      onChanged: (v) =>
                          ctx.read<CrearNotaCubit>().cambiarMotivoTexto(v),
                    ),
                    const SizedBox(height: 8),
                    _buildItemsSection(ctx, state),
                  ],
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        state.errorMessage!,
                        style: TextStyle(fontSize: 11, color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: state.status == CrearNotaStatus.submitting
                  ? null
                  : () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _color),
              onPressed: (state.status == CrearNotaStatus.submitting || !state.formValido)
                  ? null
                  : () => ctx.read<CrearNotaCubit>().emitir(
                        comprobanteOrigenId: comprobanteOrigenId,
                        sedeId: sedeId,
                      ),
              child: state.status == CrearNotaStatus.submitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Emitir ${tipoNota.label}',
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Comprobante origen: $comprobanteCodigo',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Text('Total: $_simboloMoneda ${comprobanteTotal.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildItemsSection(BuildContext ctx, CrearNotaState state) {
    // ND → editor de items adicionales (cargos extra: intereses, aumento valor).
    if (state.esNotaDebito) {
      final requiereItems = state.motivoNDRequiereItems;
      final faltanItems = requiereItems && state.itemsAdicionales.isEmpty;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Items adicionales',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  if (requiereItems)
                    const Text(' *',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w700)),
                ],
              ),
              Text(
                '${state.itemsAdicionales.length} item${state.itemsAdicionales.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
            ],
          ),
          if (faltanItems) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                'Este motivo requiere al menos 1 ítem con el monto a cargar (ej. intereses, recargo, penalidad).',
                style: TextStyle(fontSize: 11, color: Colors.red.shade800),
              ),
            ),
          ],
          const SizedBox(height: 6),
          ItemsAdicionalesWidget(
            items: state.itemsAdicionales,
            moneda: moneda,
            onAgregar: () =>
                ctx.read<CrearNotaCubit>().agregarItemAdicional(),
            onEditar: (i, it) =>
                ctx.read<CrearNotaCubit>().editarItemAdicional(i, it),
            onEliminar: (i) =>
                ctx.read<CrearNotaCubit>().eliminarItemAdicional(i),
          ),
        ],
      );
    }

    // NC → comportamiento existente (parciales / copia completa).
    if (state.itemsOrigen.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Items',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Row(
              children: [
                Text(
                  state.itemsParciales ? 'Parciales' : 'Copia completa',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
                Switch(
                  value: state.itemsParciales,
                  onChanged: (v) => ctx.read<CrearNotaCubit>().cambiarModoItems(v),
                ),
              ],
            ),
          ],
        ),
        if (state.itemsParciales)
          ItemsSelectorWidget(
            items: state.itemsOrigen,
            incluidos: state.itemsIncluidos,
            cantidadesEditadas: state.cantidadesEditadas,
            onToggle: (i, v) => ctx.read<CrearNotaCubit>().toggleItem(i, v),
            onCantidadChanged: (i, c) =>
                ctx.read<CrearNotaCubit>().editarCantidad(i, c),
          )
        else
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Se copiarán los ${state.itemsOrigen.length} items del comprobante origen tal cual.',
              style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700),
            ),
          ),
      ],
    );
  }
}
