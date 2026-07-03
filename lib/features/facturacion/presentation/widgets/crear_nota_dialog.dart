import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
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

class _CrearNotaContent extends StatefulWidget {
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

  @override
  State<_CrearNotaContent> createState() => _CrearNotaContentState();
}

class _CrearNotaContentState extends State<_CrearNotaContent> {
  // CustomText dispara onChanged a través del listener del controller, por eso
  // necesita uno propio (a diferencia del TextField anterior).
  final _motivoController = TextEditingController();

  Color get _color =>
      widget.tipoNota == TipoNota.notaCredito ? Colors.orange : Colors.purple;
  String get _simboloMoneda => widget.moneda == 'USD' ? '\$' : 'S/';
  IconData get _icon => widget.tipoNota == TipoNota.notaCredito
      ? Icons.note_add_outlined
      : Icons.add_circle_outline;

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CrearNotaCubit, CrearNotaState>(
      listener: (ctx, state) {
        if (state.status == CrearNotaStatus.success && state.resultado != null) {
          Navigator.of(ctx).pop(state.resultado);
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(
                  '${widget.tipoNota.label} ${state.resultado!.codigoGenerado} emitida'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      builder: (ctx, state) {
        final submitting = state.status == CrearNotaStatus.submitting;
        return StyledDialog(
          accentColor: _color,
          icon: _icon,
          titulo: widget.tipoNota.label,
          barrierDismissible: false,
          backgroundColor: Colors.white,
          content: [
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
              CustomText(
                controller: _motivoController,
                maxLines: 2,
                maxLength: 250,
                borderColor: _color.withValues(alpha: 0.4),
                label: 'Motivo (descripción libre)',
                hintText: 'Mín. 3 caracteres',
                onChanged: (v) =>
                    ctx.read<CrearNotaCubit>().cambiarMotivoTexto(v),
              ),
              const SizedBox(height: 8),
              _buildItemsSection(ctx, state),
            ],
            if (state.errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  state.errorMessage!,
                  style: TextStyle(fontSize: 11, color: Colors.red.shade800),
                ),
              ),
            ],
          ],
          actions: [
            Expanded(
              child: CustomButton(
                text: 'Cancelar',
                isOutlined: true,
                borderColor: Colors.grey.shade400,
                textColor: Colors.grey.shade700,
                enabled: !submitting,
                onPressed: submitting ? null : () => Navigator.of(ctx).pop(),
              ),
            ),
            Expanded(
              child: CustomButton(
                text: 'Emitir ${widget.tipoNota.label}',
                backgroundColor: _color,
                borderColor: _color,
                textColor: Colors.white,
                isLoading: submitting,
                enabled: submitting || state.formValido,
                onPressed: (submitting || !state.formValido)
                    ? null
                    : () => ctx.read<CrearNotaCubit>().emitir(
                          comprobanteOrigenId: widget.comprobanteOrigenId,
                          sedeId: widget.sedeId,
                        ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Comprobante origen: ${widget.comprobanteCodigo}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
              'Total: $_simboloMoneda ${widget.comprobanteTotal.toStringAsFixed(2)}',
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
            moneda: widget.moneda,
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
