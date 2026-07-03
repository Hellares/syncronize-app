import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/network/dio_client.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/utils/resource.dart';
import '../../domain/usecases/get_resumen_usecase.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import 'package:syncronize/features/impresoras/domain/services/impresoras_manager.dart';

import '../../domain/entities/arqueo_caja.dart';
import '../../domain/entities/caja.dart';
import '../../domain/entities/movimiento_caja.dart';
import '../../domain/entities/resumen_caja.dart';
import '../bloc/arqueos_caja_cubit.dart';
import '../bloc/arqueos_caja_state.dart';
import '../bloc/caja_movimientos_cubit.dart';
import '../bloc/caja_movimientos_state.dart';
import '../services/arqueo_caja_esc_pos_generator.dart';
import '../services/caja_ticket_data.dart';
import '../widgets/desglose_efectivo_sheet.dart';

/// Formulario para crear un arqueo de caja (conteo sin cerrar).
/// Recibe el cubit ya provisto desde el caller.
class RealizarArqueoPage extends StatefulWidget {
  final Caja caja;

  const RealizarArqueoPage({super.key, required this.caja});

  @override
  State<RealizarArqueoPage> createState() => _RealizarArqueoPageState();
}

class _RealizarArqueoPageState extends State<RealizarArqueoPage> {
  TipoArqueoCaja _tipo = TipoArqueoCaja.rutinario;
  final _observacionesController = TextEditingController();
  final Map<MetodoPago, TextEditingController> _conteoControllers = {};
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    for (final m in MetodoPago.values) {
      _conteoControllers[m] = TextEditingController();
    }
    // Cargamos movimientos al entrar para tener resumen actualizado.
    context
        .read<CajaMovimientosCubit>()
        .loadMovimientos(widget.caja.id);
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    for (final c in _conteoControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'S/ ',
      decimalDigits: 2,
    );

    return BlocListener<ArqueosCajaCubit, ArqueosCajaState>(
      listener: (context, state) {
        if (state is ArqueosCajaLoaded && state.recienCreado != null) {
          _imprimirComprobante(state.recienCreado!);
          SnackBarHelper.showSuccess(context, 'Arqueo registrado');
          Navigator.of(context).pop(state.recienCreado);
        }
        if (state is ArqueosCajaError) {
          setState(() => _isCreating = false);
          SnackBarHelper.showError(context, state.message);
        }
      },
      child: Scaffold(
        appBar: SmartAppBar(
          title: 'Arqueo de Caja',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
        ),
        body: GradientContainer(
          child: BlocBuilder<CajaMovimientosCubit, CajaMovimientosState>(
            builder: (context, movState) {
              if (movState is CajaMovimientosLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (movState is CajaMovimientosLoaded &&
                  movState.resumen != null) {
                return _buildForm(movState.resumen!, currencyFormat);
              }
              return const Center(
                child: Text(
                  'No se pudo cargar el resumen',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ResumenCaja resumen, NumberFormat currencyFormat) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Selector de tipo ──
          const AppSubtitle(
            'Tipo de Arqueo',
            fontSize: 14,
            color: AppColors.blue3,
          ),
          const SizedBox(height: 8),
          RadioGroup<TipoArqueoCaja>(
            groupValue: _tipo,
            onChanged: (v) => setState(() => _tipo = v!),
            child: Column(
              children: TipoArqueoCaja.values.map((tipo) {
                final selected = tipo == _tipo;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _tipo = tipo),
                    borderRadius: BorderRadius.circular(10),
                    child: GradientContainer(
                      padding: const EdgeInsets.all(12),
                      borderColor: selected ? tipo.color : null,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: tipo.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(tipo.icon, color: tipo.color, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tipo.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? tipo.color
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tipo.descripcion,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Radio<TipoArqueoCaja>(
                            value: tipo,
                            activeColor: tipo.color,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          if (_tipo == TipoArqueoCaja.relevo) ...[
            const SizedBox(height: 12),
            _buildSucesorPicker(),
          ],

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // ── Resumen del sistema ──
          GradientContainer(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSubtitle(
                  'Resumen del Sistema',
                  fontSize: 14,
                  color: AppColors.blue3,
                ),
                const SizedBox(height: 10),
                _row('Total Ingresos', currencyFormat.format(resumen.totalIngresos),
                    AppColors.green),
                if (resumen.egresoAnulacionVenta > 0) ...[
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Text(
                      '(− ${currencyFormat.format(resumen.egresoAnulacionVenta)} anulados)',
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                _row('Total Egresos', currencyFormat.format(resumen.totalEgresos),
                    AppColors.red),
                ...resumen.egresosPorCategoria.map((e) => Padding(
                      padding: const EdgeInsets.only(left: 14, top: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '· ${e.label}'
                            '${e.cantidad > 0 ? " (${e.cantidad})" : ""}',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            currencyFormat.format(e.total),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.red.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    )),
                if (resumen.egresoAnulacionVenta > 0) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 11, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Anulación de Venta'
                                  '${resumen.cantidadAnulaciones > 0 ? " (${resumen.cantidadAnulaciones})" : ""}'
                                  ' — ya descontado',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currencyFormat.format(resumen.egresoAnulacionVenta),
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 16),
                _row('Saldo en Caja',
                    currencyFormat.format(resumen.saldoEfectivo), AppColors.green,
                    bold: true),
                if ((resumen.saldo - resumen.saldoEfectivo).abs() > 0.01) ...[
                  const SizedBox(height: 4),
                  _row(
                      'Total Operado',
                      currencyFormat.format(resumen.saldo),
                      AppColors.blue1,
                      bold: true),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),
          const AppSubtitle(
            'Conteo Fisico por Metodo',
            fontSize: 14,
            color: AppColors.blue3,
          ),
          const SizedBox(height: 8),
          ...MetodoPago.values.map((metodo) {
            final detalle = resumen.detalles
                .where((d) => d.metodoPago == metodo)
                .toList();
            final esperado =
                detalle.isNotEmpty ? detalle.first.saldo : 0.0;
            // Mostramos EFECTIVO siempre + otros con saldo > 0
            if (esperado == 0 && metodo != MetodoPago.efectivo) {
              return const SizedBox.shrink();
            }
            return _buildConteoCard(metodo, esperado, currencyFormat);
          }),

          const SizedBox(height: 16),
          CustomText(
            label: 'Observaciones (opcional)',
            controller: _observacionesController,
            maxLines: 3,
            height: null, // multiline: deja crecer
            prefixIcon: const Icon(Icons.note_rounded),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Registrar Arqueo',
              backgroundColor: _tipo.color,
              height: 48,
              isLoading: _isCreating,
              onPressed: _isCreating ? null : _submit,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String? _sucesorId;
  String? _sucesorNombre;
  Map<double, int>? _desgloseEfectivo;

  Widget _buildSucesorPicker() {
    return InkWell(
      onTap: _showSucesorPicker,
      borderRadius: BorderRadius.circular(10),
      child: GradientContainer(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.swap_horiz_rounded, color: AppColors.blue1),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recibe el turno',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _sucesorNombre ?? 'Seleccionar usuario...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _sucesorNombre != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _showSucesorPicker() async {
    // Cargamos usuarios de la empresa via DioClient (no hay un cache
    // global de "usuarios de la empresa" en EmpresaContext, asi que lo
    // pedimos puntualmente).
    List<Map<String, dynamic>> usuarios = [];
    try {
      final dio = locator<DioClient>();
      final response = await dio.get('/usuarios');
      final raw = response.data;
      if (raw is Map && raw['data'] is List) {
        usuarios = (raw['data'] as List).cast<Map<String, dynamic>>();
      } else if (raw is List) {
        usuarios = raw.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'No se pudieron cargar usuarios: $e');
      return;
    }
    if (!mounted) return;
    if (usuarios.isEmpty) {
      SnackBarHelper.showError(context, 'No hay otros usuarios disponibles.');
      return;
    }

    await showModalBottomSheet(
      context: context,
      builder: (sheet) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: usuarios.length,
            itemBuilder: (_, idx) {
              final u = usuarios[idx];
              final id = u['id'] as String? ?? '';
              if (id == widget.caja.usuarioId) {
                return const SizedBox.shrink();
              }
              final persona = u['persona'] as Map<String, dynamic>?;
              final nombre = persona != null
                  ? '${persona['nombres'] ?? ''} ${persona['apellidos'] ?? ''}'
                      .trim()
                  : (u['email'] as String? ?? id);
              return ListTile(
                leading: const Icon(Icons.person_rounded),
                title: Text(nombre.isEmpty ? id : nombre),
                onTap: () {
                  setState(() {
                    _sucesorId = id;
                    _sucesorNombre = nombre.isEmpty ? id : nombre;
                  });
                  Navigator.pop(sheet);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _row(String label, String value, Color color, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 14 : 12,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 15 : 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildConteoCard(
    MetodoPago metodo,
    double esperado,
    NumberFormat currencyFormat,
  ) {
    final controller = _conteoControllers[metodo]!;
    final conteoValue =
        double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
    final diferencia = conteoValue - esperado;
    final hasDif = controller.text.isNotEmpty && diferencia != 0;
    final esEfectivo = metodo == MetodoPago.efectivo;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GradientContainer(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(metodo.icon, size: 18, color: AppColors.blue3),
                const SizedBox(width: 6),
                AppSubtitle(
                  metodo.label,
                  fontSize: 13,
                  color: AppColors.blue3,
                ),
                if (esEfectivo) ...[
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _abrirDesgloseSheet(controller, esperado),
                    icon: const Icon(Icons.payments_rounded, size: 14),
                    label: Text(
                      _desgloseEfectivo == null
                          ? 'Contar billetes'
                          : 'Editar desglose',
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.blue1,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 0),
                      minimumSize: const Size(0, 28),
                    ),
                  ),
                ],
              ],
            ),
            if (esEfectivo && _desgloseEfectivo != null) ...[
              const SizedBox(height: 4),
              _buildResumenDesglose(currencyFormat),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Esperado',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        currencyFormat.format(esperado),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue3,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CustomText(
                    label: 'Conteo',
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    prefixText: 'S/ ',
                    height: 38,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            if (hasDif) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (diferencia > 0 ? AppColors.green : AppColors.red)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      diferencia > 0
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 12,
                      color:
                          diferencia > 0 ? AppColors.green : AppColors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${diferencia > 0 ? 'Sobrante' : 'Faltante'}: ${currencyFormat.format(diferencia.abs())}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            diferencia > 0 ? AppColors.green : AppColors.red,
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

  Future<void> _abrirDesgloseSheet(
      TextEditingController conteoEfectivo, double esperado) async {
    final result = await showDesgloseEfectivoSheet(
      context,
      initial: _desgloseEfectivo,
      esperado: esperado,
    );
    if (result == null) return;
    setState(() {
      if (result.cantidades.isEmpty) {
        _desgloseEfectivo = null;
        return;
      }
      _desgloseEfectivo = result.cantidades;
      // Auto-completar el conteo del EFECTIVO con el total del desglose.
      conteoEfectivo.text = result.total.toStringAsFixed(2);
    });
  }

  Widget _buildResumenDesglose(NumberFormat currency) {
    if (_desgloseEfectivo == null || _desgloseEfectivo!.isEmpty) {
      return const SizedBox.shrink();
    }
    // Ordenamos denominaciones de mayor a menor.
    final entries = _desgloseEfectivo!.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: entries.map((e) {
        final label = e.key >= 1
            ? 'S/${e.key.toInt()} x${e.value}'
            : 'S/${e.key.toStringAsFixed(2)} x${e.value}';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.bluechip,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.blue3,
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _submit() async {
    if (_tipo == TipoArqueoCaja.relevo && _sucesorId == null) {
      SnackBarHelper.showError(
          context, 'Selecciona el usuario que recibe el turno.');
      return;
    }

    final conteos = MetodoPago.values.map((metodo) {
      final value = double.tryParse(
              _conteoControllers[metodo]!.text.replaceAll(',', '.')) ??
          0.0;
      return {
        'metodoPago': metodo.apiValue,
        'conteoFisico': value,
      };
    }).toList();

    // Convertimos Map<double, int> a Map<String, int> para serializar
    // (las keys JSON son strings).
    final desgloseSerializado = _desgloseEfectivo?.map(
      (k, v) => MapEntry(
        k >= 1 ? k.toInt().toString() : k.toStringAsFixed(2),
        v,
      ),
    );

    setState(() => _isCreating = true);
    await context.read<ArqueosCajaCubit>().crearArqueo(
          cajaId: widget.caja.id,
          tipo: _tipo,
          conteos: conteos,
          observaciones: _observacionesController.text.isNotEmpty
              ? _observacionesController.text
              : null,
          turnoEntregadoAId: _sucesorId,
          desgloseEfectivo: desgloseSerializado,
        );
  }

  Future<void> _imprimirComprobante(ArqueoCaja arqueo) async {
    try {
      final ticketData = await resolverCajaTicketData(context, widget.caja);

      final manager = locator<ImpresorasManager>();
      final principal = await manager.getPrincipal();
      if (principal == null) return;

      // Fetch FRESCO del resumen — no leer del state del cubit, porque
      // entre la apertura de la page y el momento del arqueo pudo haber
      // anulaciones u otros movimientos que invalidan el cache local.
      // El endpoint es liviano (un par de aggregates).
      final resumenResult =
          await locator<GetResumenUseCase>()(cajaId: widget.caja.id);
      final resumen = resumenResult is Success<ResumenCaja>
          ? resumenResult.data
          : null;

      final bytes = await ArqueoCajaEscPosGenerator.generate(
        caja: widget.caja,
        arqueo: arqueo,
        empresaNombre: ticketData.empresaNombre,
        empresaRazonSocial: ticketData.razonSocial,
        empresaRuc: ticketData.ruc,
        empresaDireccion: ticketData.direccion,
        empresaTelefono: ticketData.telefono,
        sedeNombre: widget.caja.sedeNombre,
        logoEmpresa: ticketData.logoBytes,
        paperWidth: principal.anchoPapel.mm,
        egresoAnulacionVenta: resumen?.egresoAnulacionVenta ?? 0,
        cantidadAnulaciones: resumen?.cantidadAnulaciones ?? 0,
        egresosPorCategoria: resumen?.egresosPorCategoria ?? const [],
      );

      await manager.imprimirEnPrincipal(bytes);
    } catch (_) {
      // Silencioso.
    }
  }
}
