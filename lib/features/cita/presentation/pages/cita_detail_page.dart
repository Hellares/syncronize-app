import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/cita.dart';
import '../../domain/repositories/cita_repository.dart';
import '../bloc/cita_form/cita_form_cubit.dart';
import '../bloc/cita_form/cita_form_state.dart';
import '../../../servicio/domain/entities/configuracion_campo.dart';
import '../../../servicio/domain/repositories/plantilla_servicio_repository.dart';
import '../../../servicio/presentation/widgets/dynamic_form_renderer.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../widgets/cita_estado_badge.dart';
import '../widgets/add_cita_item_sheet.dart';

class CitaDetailPage extends StatefulWidget {
  final String citaId;
  const CitaDetailPage({super.key, required this.citaId});

  @override
  State<CitaDetailPage> createState() => _CitaDetailPageState();
}

class _CitaDetailPageState extends State<CitaDetailPage> {
  Cita? _cita;
  List<CitaItem> _items = [];
  double _totalItems = 0;
  List<ConfiguracionCampo> _camposPersonalizados = [];
  Map<String, dynamic> _datosPersonalizados = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  String get _empresaId {
    final state = context.read<EmpresaContextCubit>().state;
    return state is EmpresaContextLoaded ? state.context.empresa.id : '';
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future.wait([_loadCita(), _loadItems()]);
    // Cargar campos personalizados después de tener la cita (necesitamos servicioId)
    if (_cita != null) {
      await _loadCamposPersonalizados();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadCita() async {
    final result = await locator<CitaRepository>().findOne(widget.citaId);
    if (!mounted) return;
    setState(() {
      if (result is Success<Cita>) {
        _cita = result.data;
      } else if (result is Error<Cita>) {
        _error = result.message;
      }
    });
  }

  Future<void> _loadItems() async {
    try {
      final repo = locator<CitaRepository>();
      final result = await repo.getItems(widget.citaId);
      if (!mounted) return;
      if (result is Success<({List<CitaItem> items, double total})>) {
        setState(() {
          _items = result.data.items;
          _totalItems = result.data.total;
        });
      }
    } catch (e) {
      debugPrint('Error cargando items de cita: $e');
    }
  }

  Future<void> _loadCamposPersonalizados() async {
    if (_cita == null) return;
    try {
      final repo = locator<PlantillaServicioRepository>();
      final result = await repo.getCamposByServicioId(_cita!.servicioId);
      if (!mounted) return;
      if (result is Success<List<ConfiguracionCampo>>) {
        setState(() {
          _camposPersonalizados = result.data;
          _datosPersonalizados = _cita!.datosPersonalizados != null
              ? Map<String, dynamic>.from(_cita!.datosPersonalizados!)
              : {};
        });
      }
    } catch (e) {
      debugPrint('Error cargando campos personalizados: $e');
    }
  }

  Future<void> _guardarDatosPersonalizados(Map<String, dynamic> datos) async {
    try {
      final repo = locator<CitaRepository>();
      await repo.update(_cita!.id, {'datosPersonalizados': datos});
      setState(() => _datosPersonalizados = datos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: _cita?.codigo ?? 'Cita',
          backgroundColor: AppColors.blue1,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: _loadCita,
              tooltip: 'Actualizar',
            ),
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: _cita != null && !_cita!.esTerminal
            ? _buildBottomActions()
            : null,
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.blue1));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(_error!,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadCita,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blue1,
                  side: const BorderSide(color: AppColors.blue1),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_cita == null) {
      return const Center(child: Text('Cita no encontrada'));
    }

    return BlocListener<CitaFormCubit, CitaFormState>(
      listener: (context, state) {
        if (state is CitaTransitionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.mensaje), backgroundColor: Colors.green),
          );
          _loadAll();
        } else if (state is CitaFormError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: RefreshIndicator(
        onRefresh: _loadAll,
        color: AppColors.blue1,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _buildInfoCard(),
            const SizedBox(height: 10),
            _buildClienteCard(),
            const SizedBox(height: 10),
            _buildServicioCard(),
            const SizedBox(height: 10),
            _buildItemsCard(),
            const SizedBox(height: 10),
            _buildCostosCard(),
            if (_camposPersonalizados.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildCamposPersonalizadosCard(),
            ],
            if (_cita!.notas != null && _cita!.notas!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildNotasCard(),
            ],
            if (_cita!.motivoCancelacion != null) ...[
              const SizedBox(height: 10),
              _buildCancelacionCard(),
            ],
            if (_cita!.ordenServicio != null) ...[
              const SizedBox(height: 10),
              _buildOrdenServicioCard(),
            ],
            if (_cita!.citaAnterior != null) ...[
              const SizedBox(height: 10),
              _buildCitaVinculoCard(_cita!.citaAnterior!, 'Cita anterior', Icons.arrow_back),
            ],
            if (_cita!.siguienteCita != null) ...[
              const SizedBox(height: 10),
              _buildCitaVinculoCard(_cita!.siguienteCita!, 'Siguiente cita', Icons.arrow_forward),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ─── Info principal ───

  Widget _buildInfoCard() {
    final estadoColor = _estadoColor(_cita!.estado);

    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.blueborder,
      borderWidth: 0.6,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icono hora + Código + Estado
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: estadoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      _cita!.horaInicio,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: estadoColor,
                        fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                      ),
                    ),
                    Text(
                      _cita!.horaFin,
                      style: TextStyle(
                        fontSize: 11,
                        color: estadoColor.withValues(alpha: 0.7),
                        fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSubtitle(_cita!.codigo, fontSize: 14),
                    const SizedBox(height: 2),
                    if (_cita!.sede != null)
                      Row(
                        children: [
                          Icon(Icons.store_outlined, size: 11, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            _cita!.sede!.nombre,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              CitaEstadoBadge(estado: _cita!.estado),
            ],
          ),

          const SizedBox(height: 12),

          // Chips de info
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _infoChip(Icons.calendar_today, DateFormatter.formatDate(_cita!.fecha)),
              _infoChip(Icons.schedule, '${_cita!.horaInicio} - ${_cita!.horaFin}'),
              if (_cita!.servicio?.duracionMinutos != null)
                _infoChip(Icons.timer_outlined, '${_cita!.servicio!.duracionMinutos} min'),
              if (_cita!.servicio?.precio != null)
                _infoChip(Icons.monetization_on_outlined,
                    'S/ ${_cita!.servicio!.precio!.toStringAsFixed(2)}',
                    color: AppColors.green),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Cliente ───

  Widget _buildClienteCard() {
    final isEmpresa = _cita!.clienteEmpresa != null;

    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      borderWidth: 0.6,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            isEmpresa ? Icons.business : Icons.person,
            isEmpresa ? 'Cliente Empresa' : 'Cliente',
          ),
          const SizedBox(height: 10),
          _detailRow('Nombre', _cita!.clienteNombre),
          if (_cita!.cliente?.telefono != null)
            _detailRow('Teléfono', _cita!.cliente!.telefono!),
          if (_cita!.cliente?.email != null)
            _detailRow('Email', _cita!.cliente!.email!),
          if (_cita!.clienteEmpresa?.telefono != null)
            _detailRow('Teléfono', _cita!.clienteEmpresa!.telefono!),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.push(
                  '/empresa/citas/historial-cliente',
                  extra: {
                    'clienteId': isEmpresa
                        ? (_cita!.clienteEmpresaId ?? '')
                        : (_cita!.clienteId ?? ''),
                    if (isEmpresa)
                      'clienteEmpresaId': _cita!.clienteEmpresaId,
                    'clienteNombre': _cita!.clienteNombre,
                  },
                );
              },
              icon: const Icon(Icons.history, size: 14),
              label: const Text('Ver historial de citas',
                  style: TextStyle(fontSize: 10)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blue1,
                side: const BorderSide(color: AppColors.blue1, width: 0.6),
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Servicio + Técnico ───

  Widget _buildServicioCard() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      borderWidth: 0.6,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.room_service, 'Servicio y Técnico'),
          const SizedBox(height: 10),
          if (_cita!.servicio != null)
            _detailRow('Servicio', _cita!.servicio!.nombre),
          if (_cita!.tecnico != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text('Técnico',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.engineering, size: 12, color: AppColors.blue1),
                      const SizedBox(width: 4),
                      Text(
                        _cita!.tecnico!.nombreCompleto,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blue1,
                          fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Notas ───

  Widget _buildNotasCard() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      borderWidth: 0.6,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.notes, 'Notas'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.blue1.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.blue1.withValues(alpha: 0.08), width: 0.6),
            ),
            child: Text(
              _cita!.notas!,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Cancelación ───

  Widget _buildCancelacionCard() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: Colors.red.shade200,
      borderWidth: 0.6,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.cancel, size: 14, color: Colors.red),
              ),
              const SizedBox(width: 8),
              const AppSubtitle('Cancelación', fontSize: 12, color: Colors.red),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _cita!.motivoCancelacion!,
            style: TextStyle(
              fontSize: 11,
              color: Colors.red.shade700,
              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Orden de Servicio vinculada ───

  Widget _buildOrdenServicioCard() {
    return InkWell(
      onTap: () => context.push('/empresa/ordenes/${_cita!.ordenServicio!.id}'),
      borderRadius: BorderRadius.circular(8),
      child: GradientContainer(
        gradient: AppGradients.blueWhiteBlue(),
        borderColor: AppColors.green.withValues(alpha: 0.4),
        borderWidth: 0.8,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.assignment, size: 18, color: AppColors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppLabelText('Orden de servicio generada', fontSize: 9, color: AppColors.green),
                  const SizedBox(height: 2),
                  AppSubtitle(_cita!.ordenServicio!.codigo, fontSize: 12),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _cita!.ordenServicio!.estado,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.green),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.green),
          ],
        ),
      ),
    );
  }

  // ─── Campos Personalizados ───

  Widget _buildCamposPersonalizadosCard() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      borderWidth: 0.6,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.tune, 'Campos del Servicio'),
          const SizedBox(height: 10),
          DynamicFormRenderer(
            campos: _camposPersonalizados,
            values: _datosPersonalizados,
            empresaId: _empresaId,
            onChanged: (datos) {
              if (!_cita!.esTerminal) {
                _guardarDatosPersonalizados(datos);
              }
            },
          ),
        ],
      ),
    );
  }

  // ─── Resumen de Costos ───

  Widget _buildCostosCard() {
    final costoServicio = _cita!.costoServicio ?? 0;
    final costoProductos = _cita!.costoProductos ?? 0;
    final descuento = _cita!.descuento ?? 0;
    final costoTotal = _cita!.costoTotal ?? 0;
    final adelanto = _cita!.adelanto ?? 0;
    final saldo = _cita!.saldo;

    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      borderWidth: 0.6,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionHeader(Icons.monetization_on, 'Resumen de Costos'),
              const Spacer(),
              if (!_cita!.esTerminal)
                InkWell(
                  onTap: _showEditCostosDialog,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bluechip,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 12, color: AppColors.blue1),
                        SizedBox(width: 4),
                        Text('Editar',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.blue1,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          _costoRow('Mano de obra', costoServicio),
          _costoRow('Productos/Insumos', costoProductos),
          if (descuento > 0) _costoRow('Descuento', -descuento, color: Colors.red),
          const Divider(height: 16),
          _costoRow('TOTAL', costoTotal, bold: true, fontSize: 14),
          if (adelanto > 0) ...[
            const SizedBox(height: 4),
            _costoRow('Adelanto', adelanto, color: AppColors.green),
            if (_cita!.metodoPagoAdelanto != null)
              Padding(
                padding: const EdgeInsets.only(left: 80),
                child: Text(
                  _cita!.metodoPagoAdelanto!,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                ),
              ),
            _costoRow('Saldo pendiente', saldo,
                bold: true, color: saldo > 0 ? Colors.orange : AppColors.green),
          ],
        ],
      ),
    );
  }

  Widget _costoRow(String label, double value,
      {bool bold = false, double fontSize = 11, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize - 1,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: color ?? Colors.grey.shade600,
                fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
              ),
            ),
          ),
          Text(
            '${value < 0 ? '-' : ''}S/ ${value.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? (bold ? AppColors.blue1 : AppColors.blue2),
              fontFamily: AppFonts.getFontFamily(bold ? AppFont.oxygenBold : AppFont.oxygenRegular),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditCostosDialog() {
    final costoCtrl = TextEditingController(
        text: (_cita!.costoServicio ?? 0).toStringAsFixed(2));
    final descuentoCtrl = TextEditingController(
        text: (_cita!.descuento ?? 0).toStringAsFixed(2));
    final adelantoCtrl = TextEditingController(
        text: (_cita!.adelanto ?? 0).toStringAsFixed(2));
    final metodoCtrl = TextEditingController(
        text: _cita!.metodoPagoAdelanto ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar costos'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                controller: costoCtrl,
                label: 'Mano de obra (S/)',
                hintText: '0.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                borderColor: AppColors.blue1,
              ),
              const SizedBox(height: 10),
              CustomText(
                controller: descuentoCtrl,
                label: 'Descuento (S/)',
                hintText: '0.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                borderColor: AppColors.blue1,
              ),
              const SizedBox(height: 10),
              CustomText(
                controller: adelantoCtrl,
                label: 'Adelanto (S/)',
                hintText: '0.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                borderColor: AppColors.blue1,
              ),
              const SizedBox(height: 10),
              CustomText(
                controller: metodoCtrl,
                label: 'Método de pago adelanto',
                hintText: 'EFECTIVO, YAPE, PLIN...',
                borderColor: AppColors.blue1,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          CustomButton(
            text: 'Guardar',
            backgroundColor: AppColors.blue1,
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = locator<CitaRepository>();
                await repo.update(_cita!.id, {
                  'costoServicio': double.tryParse(costoCtrl.text) ?? 0,
                  'descuento': double.tryParse(descuentoCtrl.text) ?? 0,
                  'adelanto': double.tryParse(adelantoCtrl.text) ?? 0,
                  if (metodoCtrl.text.trim().isNotEmpty)
                    'metodoPagoAdelanto': metodoCtrl.text.trim(),
                });
                _loadAll();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // ─── Items / Productos ───

  Widget _buildItemsCard() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      borderWidth: 0.6,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionHeader(Icons.shopping_bag, 'Productos / Insumos'),
              const Spacer(),
              if (!_cita!.esTerminal)
                InkWell(
                  onTap: () => _showAddItemDialog(),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bluechip,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 14, color: AppColors.blue1),
                        SizedBox(width: 4),
                        Text('Agregar',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.blue1,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (_items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Sin productos agregados',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ),
            )
          else ...[
            ..._items.map((item) => _buildItemRow(item)),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const AppSubtitle('Total:', fontSize: 12, color: AppColors.blue2),
                const SizedBox(width: 8),
                Text(
                  'S/ ${_totalItems.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blue1,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(CitaItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.blue1.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                size: 12, color: AppColors.blue1),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombre,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.blue2,
                    fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                  ),
                ),
                if (item.descripcion != null && item.descripcion!.isNotEmpty)
                  Text(
                    item.descripcion!,
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          Text(
            '${item.cantidad} x S/${item.precioUnitario.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'S/${item.subtotal.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.blue1,
              fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
            ),
          ),
          if (!_cita!.esTerminal) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: () => _removeItem(item.id),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 14, color: Colors.red.shade300),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCitaItemSheet(
        onItemAdded: (item) async {
          final repo = locator<CitaRepository>();
          final result = await repo.addItem(widget.citaId, {
            'nombre': item.nombre,
            if (item.productoId != null) 'productoId': item.productoId,
            if (item.descripcion != null) 'descripcion': item.descripcion,
            'cantidad': item.cantidad,
            'precioUnitario': item.precioUnitario,
          });
          if (!mounted) return;
          if (result is Success) {
            _loadItems();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item agregado'), backgroundColor: Colors.green),
            );
          } else if (result is Error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text((result).message), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  Future<void> _removeItem(String itemId) async {
    final repo = locator<CitaRepository>();
    final result = await repo.removeItem(widget.citaId, itemId);
    if (!mounted) return;
    if (result is Success) {
      _loadItems();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item eliminado'), backgroundColor: Colors.green),
      );
    } else if (result is Error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result).message), backgroundColor: Colors.red),
      );
    }
  }

  // ─── Cita vinculada (anterior/siguiente) ───

  Widget _buildCitaVinculoCard(CitaVinculoResumen vinculo, String label, IconData icon) {
    return InkWell(
      onTap: () => context.push('/empresa/citas/${vinculo.id}'),
      borderRadius: BorderRadius.circular(8),
      child: GradientContainer(
        gradient: AppGradients.blueWhiteBlue(),
        borderColor: AppColors.blue1.withValues(alpha: 0.3),
        borderWidth: 0.8,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.blue1.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: AppColors.blue1),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppLabelText(label, fontSize: 9, color: AppColors.blue1),
                  const SizedBox(height: 2),
                  AppSubtitle(
                    '${vinculo.codigo} — ${DateFormatter.formatDate(vinculo.fecha)} ${vinculo.horaInicio}',
                    fontSize: 11,
                  ),
                ],
              ),
            ),
            CitaEstadoBadge(estado: vinculo.estado),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.blue1),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Actions ───

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: _getActionButtons(),
        ),
      ),
    );
  }

  List<Widget> _getActionButtons() {
    final cubit = context.read<CitaFormCubit>();
    final buttons = <Widget>[];

    switch (_cita!.estado) {
      case 'PENDIENTE':
        buttons.add(Expanded(
          child: CustomButton(
            text: 'Confirmar',
            onPressed: () => cubit.cambiarEstado(id: _cita!.id, nuevoEstado: 'CONFIRMADA'),
            backgroundColor: AppColors.blue1,
          ),
        ));
        buttons.add(const SizedBox(width: 8));
        buttons.add(_actionIconButton(Icons.close, Colors.red, () => _showCancelDialog()));
        break;
      case 'CONFIRMADA':
        buttons.add(Expanded(
          child: CustomButton(
            text: 'Iniciar',
            onPressed: () => cubit.cambiarEstado(id: _cita!.id, nuevoEstado: 'EN_PROCESO'),
            backgroundColor: Colors.indigo,
          ),
        ));
        buttons.add(const SizedBox(width: 8));
        buttons.add(_actionIconButton(Icons.person_off, Colors.grey, () {
          cubit.cambiarEstado(id: _cita!.id, nuevoEstado: 'NO_ASISTIO');
        }));
        buttons.add(const SizedBox(width: 8));
        buttons.add(_actionIconButton(Icons.close, Colors.red, () => _showCancelDialog()));
        break;
      case 'EN_PROCESO':
        buttons.add(Expanded(
          child: CustomButton(
            text: 'Completar',
            onPressed: () => _showCompleteDialog(),
            backgroundColor: AppColors.green,
          ),
        ));
        buttons.add(const SizedBox(width: 8));
        buttons.add(_actionIconButton(Icons.close, Colors.red, () => _showCancelDialog()));
        break;
    }

    return buttons;
  }

  Widget _actionIconButton(IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.6),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  // ─── Dialogs ───

  void _showCancelDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Motivo de cancelación',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.blue1),
            ),
          ),
          maxLines: 3,
          style: const TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Volver')),
          CustomButton(
            text: 'Cancelar cita',
            backgroundColor: Colors.red,
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CitaFormCubit>().cambiarEstado(
                    id: _cita!.id,
                    nuevoEstado: 'CANCELADA',
                    motivoCancelacion: controller.text,
                  );
            },
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog() {
    bool generarOrden = false;
    bool programarSiguiente = false;
    DateTime? siguienteFecha;
    String? siguienteHoraInicio;
    String? siguienteHoraFin;
    final siguienteNotasCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Completar cita'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GradientContainer(
                  gradient: AppGradients.blueWhiteBlue(),
                  borderColor: AppColors.blueborder,
                  borderWidth: 0.6,
                  child: CheckboxListTile(
                    title: const Text('Generar orden de servicio',
                        style: TextStyle(fontSize: 12)),
                    subtitle: const Text(
                      'Se creará una orden con los datos de esta cita',
                      style: TextStyle(fontSize: 10),
                    ),
                    value: generarOrden,
                    onChanged: (v) => setDialogState(() => generarOrden = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.blue1,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
                const SizedBox(height: 8),
                GradientContainer(
                  gradient: AppGradients.blueWhiteBlue(),
                  borderColor: programarSiguiente
                      ? AppColors.blue1.withValues(alpha: 0.4)
                      : AppColors.blueborder,
                  borderWidth: 0.6,
                  child: Column(
                    children: [
                      CheckboxListTile(
                        title: const Text('Programar siguiente cita',
                            style: TextStyle(fontSize: 12)),
                        subtitle: const Text(
                          'Agenda la próxima visita del cliente',
                          style: TextStyle(fontSize: 10),
                        ),
                        value: programarSiguiente,
                        onChanged: (v) =>
                            setDialogState(() => programarSiguiente = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.blue1,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      if (programarSiguiente) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Column(
                            children: [
                              // Fecha
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: DateTime.now().add(const Duration(days: 7)),
                                    firstDate: DateTime.now().add(const Duration(days: 1)),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    setDialogState(() => siguienteFecha = picked);
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: AppColors.blue1.withValues(alpha: 0.3)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 14, color: AppColors.blue1),
                                      const SizedBox(width: 8),
                                      Text(
                                        siguienteFecha != null
                                            ? DateFormatter.formatDate(siguienteFecha!)
                                            : 'Seleccionar fecha',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: siguienteFecha != null
                                              ? AppColors.blue2
                                              : Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Horas
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final picked = await showTimePicker(
                                          context: ctx,
                                          initialTime: const TimeOfDay(hour: 9, minute: 0),
                                          builder: (c, child) => MediaQuery(
                                            data: MediaQuery.of(c)
                                                .copyWith(alwaysUse24HourFormat: true),
                                            child: child!,
                                          ),
                                        );
                                        if (picked != null) {
                                          setDialogState(() {
                                            siguienteHoraInicio =
                                                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: AppColors.blue1.withValues(alpha: 0.3)),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          siguienteHoraInicio ?? 'Inicio',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: siguienteHoraInicio != null
                                                ? AppColors.blue2
                                                : Colors.grey.shade500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6),
                                    child: Text('—'),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final picked = await showTimePicker(
                                          context: ctx,
                                          initialTime: const TimeOfDay(hour: 10, minute: 0),
                                          builder: (c, child) => MediaQuery(
                                            data: MediaQuery.of(c)
                                                .copyWith(alwaysUse24HourFormat: true),
                                            child: child!,
                                          ),
                                        );
                                        if (picked != null) {
                                          setDialogState(() {
                                            siguienteHoraFin =
                                                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: AppColors.blue1.withValues(alpha: 0.3)),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          siguienteHoraFin ?? 'Fin',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: siguienteHoraFin != null
                                                ? AppColors.blue2
                                                : Colors.grey.shade500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              CustomText(
                                controller: siguienteNotasCtrl,
                                label: 'Notas (opcional)',
                                borderColor: AppColors.blue1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Volver')),
            CustomButton(
              text: 'Completar',
              backgroundColor: AppColors.green,
              onPressed: () {
                // Validar siguiente cita si se marca
                if (programarSiguiente) {
                  if (siguienteFecha == null ||
                      siguienteHoraInicio == null ||
                      siguienteHoraFin == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                          content: Text('Complete fecha y hora de la siguiente cita')),
                    );
                    return;
                  }
                }

                Navigator.pop(ctx);

                Map<String, dynamic>? siguienteCitaData;
                if (programarSiguiente && siguienteFecha != null) {
                  siguienteCitaData = {
                    'fecha': DateFormat('yyyy-MM-dd').format(siguienteFecha!),
                    'horaInicio': siguienteHoraInicio,
                    'horaFin': siguienteHoraFin,
                    if (siguienteNotasCtrl.text.trim().isNotEmpty)
                      'notas': siguienteNotasCtrl.text.trim(),
                  };
                }

                context.read<CitaFormCubit>().cambiarEstado(
                  id: _cita!.id,
                  nuevoEstado: 'COMPLETADA',
                  generarOrden: generarOrden,
                  siguienteCita: siguienteCitaData,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ───

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.blue1.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: AppColors.blue1),
        ),
        const SizedBox(width: 8),
        AppSubtitle(title, fontSize: 12, color: AppColors.blue1),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.blue2,
                fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, {Color? color}) {
    final chipColor = color ?? AppColors.blue1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: chipColor.withValues(alpha: 0.2), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: chipColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: chipColor,
              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
            ),
          ),
        ],
      ),
    );
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'CONFIRMADA':
        return AppColors.blue1;
      case 'EN_PROCESO':
        return Colors.indigo;
      case 'COMPLETADA':
        return AppColors.green;
      case 'CANCELADA':
        return Colors.red;
      case 'NO_ASISTIO':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
