import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cliente_unificado_selector.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/date/custom_date.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../bloc/cotizacion_rapida_cubit.dart';

class CotizacionRapidaFinalizarPage extends StatelessWidget {
  const CotizacionRapidaFinalizarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: locator<CotizacionRapidaCubit>(),
      child: const _FinalizarView(),
    );
  }
}

class _FinalizarView extends StatefulWidget {
  const _FinalizarView();

  @override
  State<_FinalizarView> createState() => _FinalizarViewState();
}

class _FinalizarViewState extends State<_FinalizarView> {
  final _nombreCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  final _condCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();

  static final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    final state = context.read<CotizacionRapidaCubit>().state;
    _nombreCtrl.text = state.nombreCotizacion;
    _obsCtrl.text = state.observaciones;
    _condCtrl.text = state.condiciones;
    if (state.fechaVencimiento != null) {
      _fechaCtrl.text = _dateFmt.format(state.fechaVencimiento!);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _obsCtrl.dispose();
    _condCtrl.dispose();
    _fechaCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarCliente() async {
    final cubit = context.read<CotizacionRapidaCubit>();
    final empresaId = cubit.state.empresaId;
    if (empresaId == null) return;
    final result = await ClienteUnificadoSelector.show(
      context: context,
      empresaId: empresaId,
    );
    if (result == null || !mounted) return;

    if (result.isPersona) {
      cubit.aplicarClienteResuelto(
        clienteId: result.clienteId,
        clienteEmpresaId: null,
        tipoDocCliente: 'DNI',
        numeroDocCliente: result.dni ?? '',
        nombreResuelto: result.nombreCompleto ?? '',
      );
    } else {
      cubit.aplicarClienteResuelto(
        clienteId: null,
        clienteEmpresaId: result.clienteEmpresaId,
        tipoDocCliente: 'RUC',
        numeroDocCliente: result.ruc ?? '',
        nombreResuelto: result.razonSocial ?? '',
      );
    }
  }

  void _crear() {
    final cubit = context.read<CotizacionRapidaCubit>();
    cubit.setNombreCotizacion(_nombreCtrl.text);
    cubit.setObservaciones(_obsCtrl.text);
    cubit.setCondiciones(_condCtrl.text);
    cubit.crearCotizacion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Finalizar cotización',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        leftIcon: Icons.arrow_back_rounded,
        onLeftTap: () => context.pop(),
      ),
      // Botón fijo al final. El bottomNavigationBar respeta la barra
      // del sistema (gestos / botones nav) automáticamente en todos
      // los devices — más robusto que un Padding+SafeArea manual
      // (que en algunos celulares con gesture bar gruesa quedaba
      // tapado).
      bottomNavigationBar:
          BlocBuilder<CotizacionRapidaCubit, CotizacionRapidaState>(
        buildWhen: (a, b) =>
            a.total != b.total || a.procesando != b.procesando,
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: CustomButton(
                text:
                    'CREAR COTIZACIÓN  —  S/ ${state.total.toStringAsFixed(2)}',
                backgroundColor: AppColors.blue1,
                textColor: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                isLoading: state.procesando,
                enabled: !state.procesando,
                onPressed: state.procesando ? null : _crear,
              ),
            ),
          );
        },
      ),
      body: BlocConsumer<CotizacionRapidaCubit, CotizacionRapidaState>(
        listener: (context, state) {
          if (state.error != null) {
            SnackBarHelper.showError(context, state.error!);
            context.read<CotizacionRapidaCubit>().clearError();
          }
          if (state.cotizacionCompletadaId != null) {
            final id = state.cotizacionCompletadaId!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Cotización creada'),
                backgroundColor: Colors.green.shade600,
              ),
            );
            context.read<CotizacionRapidaCubit>().resetCompletada();
            // Stack post-creación: dashboard → cotizaciones → detalle.
            context.go('/empresa/dashboard');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              context.push('/empresa/cotizaciones');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                context.push('/empresa/cotizaciones/$id');
              });
            });
          }
        },
        builder: (context, state) {
          final tieneCliente = state.nombreClienteResuelto.isNotEmpty;
          final esGenerico = state.clienteGenerico;

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Resumen
                        _SectionCard(
                          title: 'Resumen',
                          child: Column(
                            children: [
                              _ResumenRow(
                                label: 'Items',
                                value: '${state.cantidadItems}',
                              ),
                              _ResumenRow(
                                label: 'Subtotal',
                                value:
                                    'S/ ${state.subtotal.toStringAsFixed(2)}',
                              ),
                              _ResumenRow(
                                label:
                                    'IGV (${state.impuestoPorcentaje.toStringAsFixed(0)}%)',
                                value: 'S/ ${state.igv.toStringAsFixed(2)}',
                              ),
                              const Divider(height: 16),
                              _ResumenRow(
                                label: 'Total',
                                value:
                                    'S/ ${state.total.toStringAsFixed(2)}',
                                bold: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Cliente
                        _SectionCard(
                          title: 'Cliente',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (tieneCliente) ...[
                                Row(
                                  children: [
                                    Icon(Icons.person_outline,
                                        size: 18,
                                        color: AppColors.blue1),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        state.nombreClienteResuelto,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (state.numeroDocCliente.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 24, top: 2),
                                    child: Text(
                                      '${state.tipoDocCliente}: ${state.numeroDocCliente}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                              ] else if (esGenerico)
                                Row(
                                  children: [
                                    Icon(Icons.people_outline,
                                        size: 18,
                                        color: Colors.grey.shade600),
                                    const SizedBox(width: 6),
                                    Text(
                                      'CLIENTES VARIOS',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  'Sin cliente',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomButton(
                                      text: 'Buscar cliente',
                                      height: 30,
                                      icon: const Icon(Icons.search,
                                          size: 16,
                                          color: AppColors.blue1),
                                      borderColor: AppColors.blue1,
                                      textColor: AppColors.blue1,
                                      onPressed: _seleccionarCliente,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CustomButton(
                                      text: 'Genérico',
                                      height: 30,
                                      icon: Icon(Icons.people_outline,
                                          size: 16,
                                          color: Colors.grey.shade700),
                                      borderColor: Colors.grey.shade400,
                                      textColor: Colors.grey.shade700,
                                      onPressed: () => context
                                          .read<CotizacionRapidaCubit>()
                                          .setClienteGenerico(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Vigencia
                        _SectionCard(
                          title: 'Vigencia',
                          child: CustomDate(
                            controller: _fechaCtrl,
                            label: 'Vence el',
                            hintText: 'dd/MM/yyyy',
                            borderColor: AppColors.blue1,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365)),
                            initialDate:
                                state.fechaVencimiento ?? DateTime.now(),
                            onDateSelected: (d) {
                              context
                                  .read<CotizacionRapidaCubit>()
                                  .setFechaVencimiento(d);
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Detalles — todos en mayúsculas (TextCase.upper)
                        _SectionCard(
                          title: 'Detalles',
                          child: Column(
                            children: [
                              CustomText(
                                controller: _nombreCtrl,
                                label: 'Título (opcional)',
                                hintText: 'EJ. PC GAMER PROFESIONAL',
                                borderColor: AppColors.blue1,
                                textCase: TextCase.upper,
                                fieldType: FieldType.text,
                                maxLength: 120,
                              ),
                              const SizedBox(height: 8),
                              CustomText(
                                controller: _obsCtrl,
                                label: 'Observaciones (opcional)',
                                borderColor: AppColors.blue1,
                                textCase: TextCase.upper,
                                fieldType: FieldType.text,
                                minLines: 2,
                                maxLines: 4,
                              ),
                              const SizedBox(height: 8),
                              CustomText(
                                controller: _condCtrl,
                                label: 'Condiciones (opcional)',
                                hintText:
                                    'EJ. VALIDEZ 7 DÍAS. ENTREGA 48H.',
                                borderColor: AppColors.blue1,
                                textCase: TextCase.upper,
                                fieldType: FieldType.text,
                                minLines: 2,
                                maxLines: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ResumenRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _ResumenRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 14 : 12,
      fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
      color: bold ? AppColors.blue1 : Colors.black87,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
