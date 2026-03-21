import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../domain/entities/devolucion_venta.dart';
import '../../domain/usecases/get_devolucion_usecase.dart';
import '../bloc/devolucion_form/devolucion_form_cubit.dart';
import '../bloc/devolucion_form/devolucion_form_state.dart';
import '../widgets/devolucion_estado_chip.dart';

class DevolucionVentaDetailPage extends StatefulWidget {
  final String devolucionId;
  const DevolucionVentaDetailPage({super.key, required this.devolucionId});

  @override
  State<DevolucionVentaDetailPage> createState() => _DevolucionVentaDetailPageState();
}

class _DevolucionVentaDetailPageState extends State<DevolucionVentaDetailPage> {
  DevolucionVenta? _devolucion;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final result = await locator<GetDevolucionUseCase>()(id: widget.devolucionId);
    if (result is Success<DevolucionVenta>) {
      setState(() { _devolucion = result.data; _loading = false; });
    } else if (result is Error<DevolucionVenta>) {
      setState(() { _error = result.message; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<DevolucionFormCubit>(),
      child: BlocListener<DevolucionFormCubit, DevolucionFormState>(
        listener: (context, state) {
          if (state is DevolucionEstadoUpdated) {
            setState(() => _devolucion = state.devolucion);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
            _load();
          }
          if (state is DevolucionFormError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        child: GradientBackground(
          child: Builder(
            builder: (context) => Scaffold(
              backgroundColor: Colors.transparent,
              appBar: SmartAppBar(
                title: _devolucion?.codigo ?? 'Devolucion',
                backgroundColor: AppColors.blue1,
                foregroundColor: Colors.white,
              ),
              body: _buildBody(),
              bottomNavigationBar: _buildActions(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final d = _devolucion!;
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          GradientContainer(
            borderColor: AppColors.blueborder,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.bluechip, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.assignment_return, color: AppColors.blue1, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: AppSubtitle(d.codigo, fontSize: 15)),
                  DevolucionEstadoChip(estado: d.estado),
                ]),
                const SizedBox(height: 14),
                _row(Icons.calendar_today, 'Creada', fmt.format(d.creadoEn)),
                if (d.aprobadoEn != null) _row(Icons.check_circle, 'Aprobada', fmt.format(d.aprobadoEn!)),
                if (d.procesadoEn != null) _row(Icons.inventory, 'Procesada', fmt.format(d.procesadoEn!)),
                _row(Icons.swap_horiz, 'Reembolso', d.tipoReembolso.label),
                if (d.ventaCodigo != null) _row(Icons.receipt, 'Venta', d.ventaCodigo!),
                if (d.sedeNombre != null) _row(Icons.store, 'Sede', d.sedeNombre!),
              ]),
            ),
          ),
          if (d.motivo != null) ...[
            const SizedBox(height: 12),
            GradientContainer(
              borderColor: AppColors.blueborder,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.notes, size: 16, color: AppColors.blue1),
                    const SizedBox(width: 8),
                    const AppSubtitle('MOTIVO', fontSize: 12),
                  ]),
                  const SizedBox(height: 8),
                  Text(d.motivo!, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                ]),
              ),
            ),
          ],
          // Items
          if (d.items != null && d.items!.isNotEmpty) ...[
            const SizedBox(height: 12),
            GradientContainer(
              borderColor: AppColors.blueborder,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.inventory_2, size: 16, color: AppColors.blue1),
                    const SizedBox(width: 8),
                    AppSubtitle('ITEMS (${d.items!.length})', fontSize: 12),
                  ]),
                  const SizedBox(height: 12),
                  ...d.items!.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.productoNombre ?? item.varianteNombre ?? 'Producto',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Wrap(spacing: 8, children: [
                        _chip('Cant: ${item.cantidad}', Colors.blue),
                        _chip(item.motivo.label, Colors.orange),
                        _chip(item.estadoProducto.label, Colors.purple),
                        _chip(item.accion.label, Colors.teal),
                      ]),
                      if (item.productoReemplazoNombre != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(children: [
                            Icon(Icons.swap_horiz, size: 14, color: Colors.orange.shade700),
                            const SizedBox(width: 4),
                            Expanded(child: Text(
                              'Cambio por: ${item.productoReemplazoNombre}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange.shade800),
                            )),
                          ]),
                        ),
                        if (item.diferenciaPrecio != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Diferencia: S/ ${item.diferenciaPrecio!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: item.diferenciaPrecio! > 0 ? Colors.red.shade700 : Colors.green.shade700,
                              ),
                            ),
                          ),
                      ],
                      if (item.observaciones != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(item.observaciones!, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                        ),
                    ]),
                  )),
                ]),
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget? _buildActions(BuildContext context) {
    if (_devolucion == null) return null;
    final d = _devolucion!;
    final actions = <Widget>[];

    if (d.puedeAprobar) {
      actions.add(Expanded(child: ElevatedButton.icon(
        onPressed: () => context.read<DevolucionFormCubit>().aprobar(d.id),
        icon: const Icon(Icons.check, size: 18),
        label: const Text('Aprobar'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue1, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      )));
    }
    if (d.puedeProcesar) {
      actions.add(Expanded(child: ElevatedButton.icon(
        onPressed: () => _showProcessConfirm(context),
        icon: const Icon(Icons.inventory, size: 18),
        label: const Text('Procesar Stock'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      )));
    }

    if (actions.isEmpty) return null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(children: actions),
    );
  }

  void _showProcessConfirm(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Procesar devolucion', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      content: const Text('Se actualizara el stock segun las acciones definidas para cada item. ¿Continuar?', style: TextStyle(fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () { Navigator.pop(ctx); context.read<DevolucionFormCubit>().procesar(_devolucion!.id); },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
          child: const Text('Procesar'),
        ),
      ],
    ));
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        SizedBox(width: 85, child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 9, color: color.shade700, fontWeight: FontWeight.w600)),
    );
  }
}

extension on Color {
  Color get shade700 => this;
}
