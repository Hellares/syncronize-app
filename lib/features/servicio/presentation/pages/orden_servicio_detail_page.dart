import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncronize/core/widgets/info_chip.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/orden_servicio.dart';
import '../../domain/repositories/orden_servicio_repository.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../../usuario/domain/entities/usuario.dart';
import '../widgets/estado_badge_widget.dart';
import '../widgets/add_componente_sheet.dart';
import '../widgets/asignar_tecnico_sheet.dart';
import '../widgets/cronometro_servicio_widget.dart';
import '../widgets/firma_digital_sheet.dart';
import '../widgets/patron_animado_dialog.dart';
import '../widgets/inspeccion_visual_dialog.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_cubit.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_state.dart';
import '../../../empresa/domain/entities/configuracion_empresa.dart';
import '../services/whatsapp_notification_service.dart';
import 'documento_orden_servicio_preview_page.dart';
import 'package:go_router/go_router.dart';
import '../../../tercerizacion/domain/entities/directorio_empresa.dart';
import '../../../tercerizacion/domain/usecases/crear_tercerizacion_usecase.dart';
import '../../../tercerizacion/domain/entities/tercerizacion.dart';

class OrdenServicioDetailPage extends StatefulWidget {
  final String ordenId;
  const OrdenServicioDetailPage({super.key, required this.ordenId});

  @override
  State<OrdenServicioDetailPage> createState() =>
      _OrdenServicioDetailPageState();
}

class _OrdenServicioDetailPageState extends State<OrdenServicioDetailPage> {
  OrdenServicio? _orden;
  List<HistorialOrdenServicio> _historial = [];
  List<ArchivoResponse> _archivos = [];
  List<ArchivoResponse> _firmaArchivos = [];
  bool _isLoading = true;
  bool _isUploadingImage = false;
  double _uploadProgress = 0.0;
  String? _error;

  String get _empresaId {
    final state = context.read<EmpresaContextCubit>().state;
    return state is EmpresaContextLoaded ? state.context.empresa.id : '';
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadOrden(), _loadHistorial(), _loadArchivos()]);
    _filterFirmaFromArchivos();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadOrden() async {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    final repo = locator<OrdenServicioRepository>();
    final result = await repo.getOrden(
      id: widget.ordenId,
      empresaId: empresaState.context.empresa.id,
    );

    if (!mounted) return;

    if (result is Success<OrdenServicio>) {
      _orden = result.data;
      _error = null;
    } else if (result is Error<OrdenServicio>) {
      _error = result.message;
    }
  }

  Future<void> _loadHistorial() async {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    final repo = locator<OrdenServicioRepository>();
    final result = await repo.getHistorial(
      ordenId: widget.ordenId,
      empresaId: empresaState.context.empresa.id,
    );

    if (!mounted) return;

    if (result is Success<List<HistorialOrdenServicio>>) {
      _historial = result.data;
    }
  }

  Future<void> _loadArchivos() async {
    try {
      final storageService = locator<StorageService>();
      final archivos = await storageService.getFilesByEntity(
        entidadTipo: 'ORDEN_SERVICIO',
        entidadId: widget.ordenId,
        empresaId: _empresaId,
      );
      if (mounted) {
        _archivos = archivos;
      }
    } catch (e) {
      debugPrint('Error cargando archivos: $e');
    }
  }

  void _filterFirmaFromArchivos() {
    _firmaArchivos = _archivos.where((a) => a.categoria == 'FIRMA').toList();
    _archivos = _archivos.where((a) => a.categoria != 'FIRMA').toList();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: _orden?.codigo ?? 'Orden de Servicio',
          backgroundColor: AppColors.blue1,
          foregroundColor: Colors.white,
          actions: [
            if (_orden != null)
              IconButton(
                icon: const Icon(Icons.receipt_long, color: Colors.white, size: 19,),
                onPressed: _generarTicket,
                tooltip: 'Generar ticket',
              ),
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomActions(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
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
                onPressed: _loadAll,
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

    if (_orden == null) {
      return const Center(child: Text('Orden no encontrada'));
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: AppColors.blue1,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // ─── Card principal: Info general ───
          _buildInfoCard(),
          if (!_orden!.isClienteFinal) ...[
            const SizedBox(height: 10),
            _buildTercerizacionBanner(),
          ],
          const SizedBox(height: 10),
          // ─── Card interactiva: Componentes ───
          _buildComponentesSection(),
          const SizedBox(height: 10),
          // ─── Card interactiva: Costos ───
          _buildResumenCostosSection(),
          const SizedBox(height: 10),
          // ─── Card interactiva: Imagenes ───
          if (_shouldShowImagenes()) ...[
            _buildImagenesSection(),
            const SizedBox(height: 10),
          ],
          // ─── Card: Cronometro ───
          _buildCronometroSection(),
          const SizedBox(height: 10),
          // ─── Card: Aviso de mantenimiento ───
          _buildAvisoMantenimientoSection(),
          const SizedBox(height: 10),
          // ─── Card: Historial ───
          _buildHistorialSection(),
          const SizedBox(height: 10),
          // ─── Card interactiva: Firma ───
          _buildFirmaSection(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ─── Info Card consolidada ───

  Widget _buildInfoCard() {
    final prioridadColor = _prioridadColorHelper(_orden!.prioridad);

    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.blueborder,
      borderWidth: 0.6,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Código + Estado ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: prioridadColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.build_outlined,
                    color: prioridadColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSubtitle(_orden!.codigo, fontSize: 12),
                    Text(
                      _tipoServicioLabel(_orden!.tipoServicio),
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              EstadoBadgeWidget(estado: _orden!.estado),
              if (_orden!.cantidadReingresos > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.4), width: 0.6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.replay, size: 10, color: Colors.orange),
                      const SizedBox(width: 3),
                      Text(
                        'x${_orden!.cantidadReingresos}',
                        style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w600, color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          // Reingreso motivo
          if (_orden!.motivoReingreso != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.15), width: 0.6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 13, color: Colors.orange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _orden!.motivoReingreso!,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // ── Chips: Prioridad, Fecha, Diagnóstico ──
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _infoChip(Icons.flag_outlined, _orden!.prioridad, color: prioridadColor),
              _infoChip(Icons.calendar_today, DateFormatter.formatDate(_orden!.creadoEn)),
              _infoChip(Icons.access_time, DateFormatter.formatTime(_orden!.creadoEn)),
              _infoChip(Icons.medical_information_outlined,
                  _estadoDiagnosticoLabel(_orden!.estadoDiagnostico)),
              if (_orden!.costoFinal != null)
                _infoChip(Icons.monetization_on_outlined,
                    'S/ ${_orden!.costoFinal!.toStringAsFixed(2)}',
                    color: AppColors.blue1),
              if (_orden!.fechaEntrega != null)
                _infoChip(Icons.event_available,
                    DateFormatter.formatDate(_orden!.fechaEntrega!),
                    color: AppColors.green),
            ],
          ),

          _sectionDivider(),

          // ── Técnico ──
          Row(
            children: [
              Icon(Icons.engineering_outlined, size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _orden!.tecnico != null
                      ? _orden!.tecnico!.nombreCompleto
                      : 'Sin tecnico asignado',
                  style: TextStyle(
                    fontSize: 11,
                    color: _orden!.tecnico != null ? Colors.grey.shade700 : Colors.grey.shade500,
                    fontStyle: _orden!.tecnico != null ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ),
              InkWell(
                onTap: _showAsignarTecnicoSheet,
                child: InfoChip(
                  height: 25,
                  borderColor: AppColors.blue1,
                  borderRadius: 4,
                  icon: _orden!.tecnico != null ? Icons.swap_horiz : Icons.person_add,
                  text: _orden!.tecnico != null ? 'Cambiar' : 'Asignar',
                  textColor: AppColors.blue1,

                ),
              ),
            ],
          ),

          // ── Cliente (persona o empresa) ──
          if (_orden!.cliente != null || _orden!.clienteEmpresa != null) ...[
            _sectionDivider(),
            if (_orden!.clienteEmpresa != null)
              _inlineSection(Icons.business_outlined, 'CLIENTE EMPRESA', [
                _buildDetailRow(Icons.business, 'Razón Social', _orden!.clienteEmpresa!.razonSocial),
                if (_orden!.clienteEmpresa!.nombreComercial != null)
                  _buildDetailRow(Icons.store, 'Nombre Comercial', _orden!.clienteEmpresa!.nombreComercial!),
                _buildDetailRow(Icons.badge_outlined, 'RUC', _orden!.clienteEmpresa!.numeroDocumento),
                if (_orden!.clienteEmpresa!.email != null)
                  _buildDetailRow(Icons.email_outlined, 'Email', _orden!.clienteEmpresa!.email!),
                if (_orden!.clienteEmpresa!.telefono != null)
                  _buildDetailRow(Icons.phone_outlined, 'Teléfono', _orden!.clienteEmpresa!.telefono!),
                if (_orden!.contactoClienteEmpresa != null) ...[
                  _buildDetailRow(Icons.person, 'Contacto', _orden!.contactoClienteEmpresa!.nombre),
                  if (_orden!.contactoClienteEmpresa!.cargo != null)
                    _buildDetailRow(Icons.work_outline, 'Cargo', _orden!.contactoClienteEmpresa!.cargo!),
                  if (_orden!.contactoClienteEmpresa!.dni != null)
                    _buildDetailRow(Icons.badge_outlined, 'DNI Contacto', _orden!.contactoClienteEmpresa!.dni!),
                  if (_orden!.contactoClienteEmpresa!.telefono != null)
                    _buildDetailRow(Icons.phone_outlined, 'Tel. Contacto', _orden!.contactoClienteEmpresa!.telefono!),
                  if (_orden!.contactoClienteEmpresa!.email != null)
                    _buildDetailRow(Icons.email_outlined, 'Email Contacto', _orden!.contactoClienteEmpresa!.email!),
                ],
              ])
            else if (_orden!.cliente != null)
              _inlineSection(Icons.person_outline, 'CLIENTE', [
                _buildDetailRow(Icons.person, 'Nombre', _orden!.cliente!.nombreCompleto),
                if (_orden!.cliente!.documentoNumero != null)
                  _buildDetailRow(Icons.badge_outlined, 'Documento', _orden!.cliente!.documentoNumero!),
                if (_orden!.cliente!.email != null)
                  _buildDetailRow(Icons.email_outlined, 'Email', _orden!.cliente!.email!),
                if (_orden!.cliente!.telefono != null)
                  _buildDetailRow(Icons.phone_outlined, 'Teléfono', _orden!.cliente!.telefono!),
              ]),
          ],

          // ── Equipo ──
          if (_orden!.tipoEquipo != null || _orden!.marcaEquipo != null || _orden!.modeloEquipo != null) ...[
            () {
              final configState = context.read<ConfiguracionEmpresaCubit>().state;
              final config = configState is ConfiguracionEmpresaLoaded ? configState.configuracion : null;
              return Column(
                children: [
                  _sectionDivider(),
                  _inlineSection(Icons.devices_outlined, config?.labelSeccionEquipo ?? 'EQUIPO', [
                    if (_orden!.modeloEquipo != null)
                      _buildDetailRow(Icons.devices, 'Modelo', _orden!.modeloEquipo!.nombreCompleto),
                    if (_orden!.modeloEquipo == null && _orden!.marcaEquipo != null)
                      _buildDetailRow(Icons.branding_watermark_outlined, config?.labelMarcaEquipo ?? 'Marca', _orden!.marcaEquipo!),
                    if (_orden!.tipoEquipo != null)
                      _buildDetailRow(Icons.category_outlined, config?.labelTipoEquipo ?? 'Tipo', _orden!.tipoEquipo!),
                    if (_orden!.numeroSerie != null)
                      _buildDetailRow(Icons.qr_code_outlined, config?.labelNumeroSerie ?? 'Serie', _orden!.numeroSerie!),
                    if (_orden!.condicionEquipo != null)
                      _buildDetailRow(Icons.info_outline, config?.labelCondicionEquipo ?? 'Condicion', _orden!.condicionEquipo!),
                  ]),
                ],
              );
            }(),
          ],

          // ── Problema / Diagnóstico ──
          if (_orden!.descripcionProblema != null ||
              _orden!.sintomas != null ||
              _orden!.diagnostico != null) ...[
            _sectionDivider(),
            _inlineSection(Icons.report_problem_outlined, 'PROBLEMA', [
              if (_orden!.descripcionProblema != null)
                _buildDetailRow(Icons.description_outlined, 'Descripcion', _orden!.descripcionProblema!),
              if (_orden!.sintomas != null)
                _buildDetailRow(Icons.healing_outlined, 'Sintomas', _formatDynamicField(_orden!.sintomas)),
              if (_orden!.diagnostico != null)
                _buildDetailRow(Icons.biotech_outlined, 'Diagnostico', _formatDynamicField(_orden!.diagnostico)),
            ]),
          ],

          // ── Accesorios ──
          if (_orden!.accesorios != null) ...[
            _sectionDivider(),
            _inlineSection(Icons.inventory_2_outlined, 'ACCESORIOS', [
              if (_orden!.accesorios is List)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: (_orden!.accesorios as List).map<Widget>((item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.green.withValues(alpha: 0.2), width: 0.6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, size: 10, color: AppColors.green),
                        const SizedBox(width: 4),
                        Text(item.toString(), style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                      ],
                    ),
                  )).toList(),
                )
              else
                Text(
                  _orden!.accesorios.toString(),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
            ]),
          ],

          // ── Datos Personalizados ──
          if (_orden!.datosPersonalizados != null &&
              _orden!.datosPersonalizados!.isNotEmpty) ...[
            () {
              final displayEntries = _orden!.datosPersonalizados!.entries.where((e) {
                if (e.value == null) return false;
                if (e.value is String && (e.value as String).isEmpty) return false;
                if (e.value is List && (e.value as List).isEmpty) return false;
                return true;
              }).toList();
              if (displayEntries.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionDivider(),
                  _inlineSection(Icons.tune_outlined, 'DATOS ADICIONALES',
                    displayEntries.map((e) => _buildDatoPersonalizado(e.key, e.value)).toList(),
                  ),
                ],
              );
            }(),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, {Color? color}) {
    final chipColor = color ?? AppColors.blue1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: chipColor),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: chipColor),
          ),
        ],
      ),
    );
  }

  Widget _sectionDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(height: 1, color: Colors.grey.shade200),
    );
  }

  Widget _inlineSection(IconData icon, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: AppColors.blue1),
            const SizedBox(width: 6),
            AppSubtitle(title, fontSize: 10, color: AppColors.blue1),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Color _prioridadColorHelper(String prioridad) {
    switch (prioridad) {
      case 'URGENTE':
      case 'EMERGENCIA':
        return Colors.red;
      case 'ALTA':
        return Colors.orange;
      case 'NORMAL':
        return AppColors.blue1;
      case 'BAJA':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDatoPersonalizado(String key, dynamic value) {
    // Boolean → Sí / No
    if (value is bool) {
      return _buildDetailRow(
        value ? Icons.check_circle_outline : Icons.cancel_outlined,
        key,
        value ? 'Sí' : 'No',
      );
    }

    // List → chips
    if (value is List) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.label_outline, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            SizedBox(
              width: 85,
              child: Text(
                key,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: value.map<Widget>((v) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    v.toString(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      );
    }

    // Map/Object → sub-fields
    if (value is Map) {
      final entries = value.entries
          .where((e) => e.value != null && e.value.toString().isNotEmpty)
          .toList();
      if (entries.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.blue1.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_tree_outlined, size: 14, color: AppColors.blue1),
                  const SizedBox(width: 6),
                  Text(
                    key,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...entries.map((sub) {
                final subVal = sub.value;
                if (subVal is bool) {
                  return _buildDetailRow(
                    subVal ? Icons.check_circle_outline : Icons.cancel_outlined,
                    sub.key.toString(),
                    subVal ? 'Sí' : 'No',
                  );
                }
                return _buildDetailRow(
                  Icons.subdirectory_arrow_right,
                  sub.key.toString(),
                  subVal.toString(),
                );
              }),
            ],
          ),
        ),
      );
    }

    // Inspección visual → preview con imagen
    if (value is String && _isInspeccionVisual(value)) {
      return _buildInspeccionPreview(key, value);
    }

    // Patrón de desbloqueo → preview visual
    if (value is String && _isPatronDesbloqueo(value)) {
      return _buildPatronPreview(key, value);
    }

    // Default: number, string, etc.
    return _buildDetailRow(
      Icons.label_outline,
      key,
      value.toString(),
    );
  }

  bool _isInspeccionVisual(String value) {
    try {
      final data = jsonDecode(value);
      return data is Map && data.containsKey('silueta') && data.containsKey('puntos');
    } catch (_) {
      return false;
    }
  }

  Widget _buildInspeccionPreview(String key, String jsonStr) {
    int puntosCount = 0;
    try {
      final data = jsonDecode(jsonStr);
      if (data is Map && data['puntos'] is List) {
        puntosCount = (data['puntos'] as List).length;
      }
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => InspeccionVisualDialog.show(context, jsonStr),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.blue1.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.blue1.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.car_crash_outlined, size: 20, color: AppColors.blue1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      key,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$puntosCount punto${puntosCount != 1 ? 's' : ''} de dano registrado${puntosCount != 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Toque para ver inspeccion',
                      style: TextStyle(fontSize: 9, color: AppColors.blue1.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.visibility_outlined, size: 16, color: AppColors.blue1.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }

  bool _isPatronDesbloqueo(String value) {
    if (value.isEmpty) return false;
    final parts = value.split('-');
    if (parts.length < 2 || parts.length > 9) return false;
    return parts.every((p) {
      final n = int.tryParse(p);
      return n != null && n >= 0 && n <= 8;
    });
  }

  Widget _buildPatronPreview(String key, String patronStr) {
    final nodos = patronStr
        .split('-')
        .map((s) => int.tryParse(s))
        .where((n) => n != null && n >= 0 && n <= 8)
        .cast<int>()
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => PatronAnimadoDialog.show(context, patronStr),
        borderRadius: BorderRadius.circular(8),
        child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.blue1.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.blue1.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            // Mini grilla del patrón
            SizedBox(
              width: 60,
              height: 60,
              child: CustomPaint(
                painter: _PatronMiniPainter(patron: nodos, color: AppColors.blue1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pattern, size: 14, color: AppColors.blue1),
                      const SizedBox(width: 6),
                      Text(
                        key,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blue1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Patron de ${nodos.length} puntos',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// Show images section if: ARCHIVO field is enabled (true) in datosPersonalizados, or images already exist
  bool _shouldShowImagenes() {
    if (_archivos.isNotEmpty) return true;
    final datos = _orden?.datosPersonalizados;
    if (datos == null) return false;
    return datos.values.any((v) => v == true);
  }

  // ─── Imagenes / Archivos ───

  Widget _buildImagenesSection() {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_camera_outlined, size: 16, color: AppColors.blue1),
                const SizedBox(width: 8),
                Expanded(
                  child: AppSubtitle('IMAGENES (${_archivos.length})', fontSize: 12),
                ),
                InkWell(
                  onTap: _isUploadingImage ? null : () => _pickAndUploadImage(ImageSource.camera),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bluechip,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt, size: 14, color: AppColors.blue1),
                        SizedBox(width: 4),
                        Text('Camara',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.blue1,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: _isUploadingImage ? null : () => _pickAndUploadImage(ImageSource.gallery),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bluechip,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_library, size: 14, color: AppColors.blue1),
                        SizedBox(width: 4),
                        Text('Galeria',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.blue1,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Upload progress
            if (_isUploadingImage) ...[
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[200],
                color: AppColors.blue1,
              ),
              const SizedBox(height: 4),
              Text(
                'Subiendo imagen... ${(_uploadProgress * 100).toInt()}%',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
            ],

            // Image grid
            if (_archivos.isEmpty && !_isUploadingImage)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 8),
                    Text('Sin imagenes adjuntas',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              )
            else if (_archivos.isNotEmpty)
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _archivos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final archivo = _archivos[index];
                    return _buildArchivoThumb(archivo);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivoThumb(ArchivoResponse archivo) {
    final url = archivo.urlThumbnail ?? archivo.url;
    return GestureDetector(
      onTap: () => _showImageDialog(archivo.url, archivo.nombreOriginal),
      child: Stack(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder(),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _confirmDeleteArchivo(archivo),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: Icon(Icons.image, color: Colors.grey[400], size: 28),
    );
  }

  void _showImageDialog(String? url, String? nombre) {
    if (url == null) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.blue1,
              child: Row(
                children: [
                  const Icon(Icons.image, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nombre ?? 'Imagen',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              color: Colors.black,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator(color: Colors.white)),
                    );
                  },
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 200,
                    child: Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 48)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final picker = ImagePicker();

    try {
      List<XFile> files = [];
      if (source == ImageSource.gallery) {
        files = await picker.pickMultiImage(imageQuality: 85);
      } else {
        final photo = await picker.pickImage(source: source, imageQuality: 85);
        if (photo != null) files = [photo];
      }

      if (files.isEmpty) return;

      setState(() {
        _isUploadingImage = true;
        _uploadProgress = 0.0;
      });

      final storageService = locator<StorageService>();

      for (int i = 0; i < files.length; i++) {
        await storageService.uploadFile(
          file: File(files[i].path),
          empresaId: _empresaId,
          entidadTipo: 'ORDEN_SERVICIO',
          entidadId: widget.ordenId,
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _uploadProgress = (i + progress) / files.length;
              });
            }
          },
        );
      }

      // Reload archivos
      await _loadArchivos();
      _filterFirmaFromArchivos();

      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          _uploadProgress = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${files.length} imagen${files.length > 1 ? 'es subidas' : ' subida'}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          _uploadProgress = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDeleteArchivo(ArchivoResponse archivo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar imagen', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: const Text('Se eliminara esta imagen del servicio.', style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final storageService = locator<StorageService>();
      await storageService.deleteFile(archivoId: archivo.id, empresaId: _empresaId);
      await _loadArchivos();
      _filterFirmaFromArchivos();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen eliminada'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── Componentes ───

  Widget _buildComponentesSection() {
    final componentes = _orden!.componentes ?? [];

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.memory_outlined, size: 16, color: AppColors.blue1),
                const SizedBox(width: 8),
                Expanded(
                  child: AppSubtitle(
                      'COMPONENTES (${componentes.length})',
                      fontSize: 12),
                ),
                InkWell(
                  onTap: _showAddComponenteSheet,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bluechip,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 14, color: AppColors.blue1),
                        SizedBox(width: 4),
                        Text('Agregar',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.blue1,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (componentes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 8),
                    Text('Sin componentes asociados',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              )
            else
              ...componentes.asMap().entries.map((entry) {
                final i = entry.key;
                final comp = entry.value;
                return Column(
                  children: [
                    if (i > 0)
                      Divider(
                          height: 16,
                          color: AppColors.blueborder.withValues(alpha: 0.4)),
                    InkWell(
                      onTap: () => _showComponenteDetail(comp),
                      borderRadius: BorderRadius.circular(8),
                      child: _buildComponenteTile(comp, i + 1),
                    ),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  // ─── Resumen de Costos ───

  Widget _buildResumenCostosSection() {
    final componentes = _orden!.componentes ?? [];

    double totalMO = 0;
    double totalRep = 0;
    for (final comp in componentes) {
      totalMO += comp.costoAccion ?? 0;
      totalRep += comp.costoRepuestos ?? 0;
    }
    final subtotalComponentes = totalMO + totalRep;
    final costoTotal = _orden!.costoTotal;
    final adelanto = _orden!.adelanto;
    final descuento = _orden!.descuento;
    final subtotal = _orden!.subtotal;
    final costoFinal = _orden!.costoFinal;
    final saldoPendiente = _orden!.saldoPendiente;

    final isTerminal = _orden!.estado == 'CANCELADO' || _orden!.estado == 'FINALIZADO';
    final hasCosts = subtotalComponentes > 0 || costoTotal != null;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 16, color: AppColors.blue1),
                const SizedBox(width: 8),
                AppSubtitle('RESUMEN DE COSTOS', fontSize: 12),
                const Spacer(),
                if (!isTerminal)
                  InkWell(
                    onTap: _showEditarCostosSheet,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bluechip,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined, size: 13, color: AppColors.blue1),
                          const SizedBox(width: 4),
                          Text(
                            hasCosts ? 'Editar' : 'Agregar',
                            style: const TextStyle(fontSize: 11, color: AppColors.blue1, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Detalle por componente
            if (componentes.isNotEmpty && subtotalComponentes > 0) ...[
              ...componentes.where((c) =>
                  (c.costoAccion ?? 0) > 0 || (c.costoRepuestos ?? 0) > 0
              ).map((comp) {
                final nombre = comp.componente?.displayName ?? 'Componente';
                final costoComp = (comp.costoAccion ?? 0) + (comp.costoRepuestos ?? 0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.build_outlined,
                          size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(nombre,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text('S/ ${costoComp.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }),
              Divider(height: 16, color: AppColors.blueborder.withValues(alpha: 0.5)),
              if (totalMO > 0)
                _buildCostoRow('Mano de obra', totalMO),
              if (totalRep > 0)
                _buildCostoRow('Repuestos', totalRep),
              if (totalMO > 0 && totalRep > 0)
                _buildCostoRow('Subtotal componentes', subtotalComponentes, bold: true),
            ],

            // Costo total acordado + desglose
            if (costoTotal != null) ...[
              if (subtotalComponentes > 0)
                Divider(height: 16, color: AppColors.blueborder.withValues(alpha: 0.5)),
              _buildCostoRow('Costo del servicio', costoTotal),
              if (subtotalComponentes > 0 && subtotal != null)
                _buildCostoRow('Subtotal', subtotal, bold: true),
              if (descuento != null && descuento > 0)
                _buildCostoRow('Descuento', -descuento, color: Colors.green.shade700, showSign: true),
              if (costoFinal != null)
                _buildCostoRow('Costo final', costoFinal, bold: true,
                    color: AppColors.blue1, fontSize: 13),
            ],

            // Sección de pagos
            if (costoFinal != null && (adelanto != null || saldoPendiente != null)) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bluechip,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    if (adelanto != null && adelanto > 0) ...[
                      _buildCostoRow('Adelanto', adelanto,
                          color: Colors.green.shade700),
                      if (_orden!.metodoPagoAdelanto != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(_metodoPagoIcon(_orden!.metodoPagoAdelanto!),
                                  size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 6),
                              Text(
                                _metodoPagoLabel(_orden!.metodoPagoAdelanto!),
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                    ],
                    if (saldoPendiente != null)
                      _buildCostoRow(
                        saldoPendiente <= 0 ? 'PAGADO' : 'SALDO PENDIENTE',
                        saldoPendiente <= 0 ? 0 : saldoPendiente,
                        bold: true,
                        fontSize: 13,
                        color: saldoPendiente <= 0
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                  ],
                ),
              ),
            ] else if (costoTotal == null && subtotalComponentes > 0) ...[
              // Solo componentes, sin costo de servicio
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bluechip,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildCostoRow('TOTAL COMPONENTES', subtotalComponentes, bold: true,
                    color: AppColors.blue1, fontSize: 13),
              ),
            ],

            // Empty state
            if (!hasCosts) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Sin costos registrados',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditarCostosSheet() {
    final costoTotalCtrl = TextEditingController(
      text: _orden?.costoTotal?.toStringAsFixed(2) ?? '',
    );
    final adelantoCtrl = TextEditingController(
      text: _orden?.adelanto?.toStringAsFixed(2) ?? '',
    );
    final descuentoCtrl = TextEditingController(
      text: _orden?.descuento?.toStringAsFixed(2) ?? '',
    );
    String? metodoPago = _orden?.metodoPagoAdelanto;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final costo = double.tryParse(costoTotalCtrl.text) ?? 0;
          final desc = double.tryParse(descuentoCtrl.text) ?? 0;
          final adel = double.tryParse(adelantoCtrl.text) ?? 0;
          final compCost = _orden?.subtotalComponentes ?? 0;
          final subtotalCalc = costo + compCost;
          final costoFinalCalc = subtotalCalc - desc;
          final saldoCalc = costoFinalCalc - adel;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.blue1.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.payments_outlined, color: AppColors.blue1, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppTitle('Costos del servicio', fontSize: 15, color: AppColors.blue1),
                            AppLabelText(
                              'Editar precios y pagos',
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(ctx),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.close, size: 20, color: Colors.grey.shade400),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Costo total
                  CustomText(
                    controller: costoTotalCtrl,
                    label: 'Costo del servicio',
                    hintText: '0.00',
                    prefixText: 'S/ ',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    borderColor: AppColors.blue1,
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 10),

                  // Descuento
                  CustomText(
                    controller: descuentoCtrl,
                    label: 'Descuento',
                    hintText: '0.00',
                    prefixText: 'S/ ',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    borderColor: AppColors.blue1,
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 10),

                  // Adelanto + método de pago
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: CustomText(
                          controller: adelantoCtrl,
                          label: 'Adelanto',
                          hintText: '0.00',
                          prefixText: 'S/ ',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          borderColor: AppColors.blue1,
                          onChanged: (_) => setSheetState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: CustomDropdown<String>(
                          label: 'Medio pago',
                          hintText: 'Seleccionar',
                          value: metodoPago,
                          borderColor: AppColors.blue1,
                          items: const [
                            DropdownItem<String>(value: 'EFECTIVO', label: 'Efectivo'),
                            DropdownItem<String>(value: 'YAPE', label: 'Yape'),
                            DropdownItem<String>(value: 'PLIN', label: 'Plin'),
                            DropdownItem<String>(value: 'TARJETA', label: 'Tarjeta'),
                            DropdownItem<String>(value: 'TRANSFERENCIA', label: 'Transf.'),
                            DropdownItem<String>(value: 'MIXTO', label: 'Mixto'),
                          ],
                          onChanged: (v) => setSheetState(() => metodoPago = v),
                        ),
                      ),
                    ],
                  ),

                  // Resumen en vivo
                  if (costo > 0 || compCost > 0) ...[
                    const SizedBox(height: 16),
                    GradientContainer(
                      gradient: AppGradients.blueWhiteBlue(),
                      shadowStyle: ShadowStyle.none,
                      borderColor: AppColors.blue1,
                      borderWidth: 0.6,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            if (compCost > 0 && costo > 0) ...[
                              _buildCostoRow('Componentes', compCost),
                              _buildCostoRow('Servicio', costo),
                              Divider(height: 12, color: Colors.grey.shade200),
                              _buildCostoRow('Subtotal', subtotalCalc, bold: true),
                            ],
                            if (desc > 0)
                              _buildCostoRow('Descuento', -desc, color: Colors.green.shade700, showSign: true),
                            _buildCostoRow('Costo final', costoFinalCalc, bold: true,
                                color: AppColors.blue1),
                            if (adel > 0)
                              _buildCostoRow('Adelanto', adel, color: Colors.green.shade700),
                            Divider(height: 12, color: Colors.grey.shade200),
                            _buildCostoRow(
                              saldoCalc <= 0 ? 'PAGADO' : 'Saldo pendiente',
                              saldoCalc <= 0 ? 0 : saldoCalc,
                              bold: true,
                              fontSize: 13,
                              color: saldoCalc <= 0 ? Colors.green.shade700 : Colors.orange.shade700,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  CustomButton(
                    backgroundColor: AppColors.blue1,
                    text: 'Guardar costos',
                    icon: const Icon(Icons.save_outlined, size: 16),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _guardarCostos(
                        costoTotal: costoTotalCtrl.text.isNotEmpty
                            ? double.tryParse(costoTotalCtrl.text)
                            : null,
                        adelanto: adelantoCtrl.text.isNotEmpty
                            ? double.tryParse(adelantoCtrl.text)
                            : null,
                        descuento: descuentoCtrl.text.isNotEmpty
                            ? double.tryParse(descuentoCtrl.text)
                            : null,
                        metodoPagoAdelanto: metodoPago,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _guardarCostos({
    double? costoTotal,
    double? adelanto,
    double? descuento,
    String? metodoPagoAdelanto,
  }) async {
    final repo = locator<OrdenServicioRepository>();
    setState(() => _isLoading = true);

    final result = await repo.actualizar(
      id: widget.ordenId,
      empresaId: _empresaId,
      costoTotal: costoTotal,
      adelanto: adelanto,
      descuento: descuento,
      metodoPagoAdelanto: metodoPagoAdelanto,
    );

    if (!mounted) return;

    if (result is Success<OrdenServicio>) {
      await _loadOrden();
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Costos actualizados')),
        );
      }
    } else if (result is Error<OrdenServicio>) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildCostoRow(String label, double valor,
      {bool bold = false, Color? color, bool showSign = false, double fontSize = 12}) {
    final prefix = showSign && valor >= 0 ? '+' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: color ?? Colors.grey.shade700,
              )),
          Text('$prefix S/ ${valor.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: color,
              )),
        ],
      ),
    );
  }

  String _metodoPagoLabel(String metodo) {
    const labels = {
      'EFECTIVO': 'Efectivo',
      'YAPE': 'Yape',
      'PLIN': 'Plin',
      'TARJETA': 'Tarjeta',
      'TRANSFERENCIA': 'Transferencia',
      'MIXTO': 'Mixto',
    };
    return labels[metodo] ?? metodo;
  }

  IconData _metodoPagoIcon(String metodo) {
    switch (metodo) {
      case 'EFECTIVO':
        return Icons.payments_outlined;
      case 'YAPE':
      case 'PLIN':
        return Icons.phone_android_outlined;
      case 'TARJETA':
        return Icons.credit_card_outlined;
      case 'TRANSFERENCIA':
        return Icons.account_balance_outlined;
      case 'MIXTO':
        return Icons.swap_horiz_outlined;
      default:
        return Icons.payment_outlined;
    }
  }

  Widget _dialogCostRow(String label, String valor,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                  color: color ?? Colors.grey.shade700)),
          Text(valor,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                  color: color)),
        ],
      ),
    );
  }

  Widget _buildComponenteTile(OrdenComponente comp, int index) {
    final nombre = comp.componente?.displayName ?? comp.componenteId;
    final categoria = comp.componente?.tipoComponente?.categoria;
    final hasDetails = comp.costoAccion != null ||
        comp.costoRepuestos != null ||
        comp.tiempoAccion != null ||
        comp.garantiaMeses != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.bluechip,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Icon(_categoriaIcon(categoria),
                size: 14, color: AppColors.blue1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nombre,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              if (comp.descripcionAccion != null &&
                  comp.descripcionAccion!.isNotEmpty)
                Text(comp.descripcionAccion!,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600)),
              if (hasDetails)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('Toca para ver detalle',
                      style: TextStyle(fontSize: 10, color: AppColors.blue1)),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _accionColor(comp.tipoAccion).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            comp.tipoAccion,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _accionColor(comp.tipoAccion),
            ),
          ),
        ),
        InkWell(
          onTap: () => _removeComponente(comp),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
          ),
        ),
      ],
    );
  }

  void _showComponenteDetail(OrdenComponente comp) {
    final nombre = comp.componente?.displayName ?? comp.componenteId;
    final tipo = comp.componente?.tipoComponente;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _accionColor(comp.tipoAccion).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _categoriaIcon(tipo?.categoria),
                      color: _accionColor(comp.tipoAccion),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nombre,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _accionColor(comp.tipoAccion)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            comp.tipoAccion,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _accionColor(comp.tipoAccion),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Componente info
              if (tipo != null || comp.componente?.marca != null ||
                  comp.componente?.modelo != null ||
                  comp.componente?.numeroSerie != null) ...[
                _detailSectionTitle('COMPONENTE'),
                if (tipo != null)
                  _detailRow(Icons.category_outlined, 'Tipo', '${tipo.nombre} (${tipo.categoria})'),
                if (comp.componente?.codigo != null)
                  _detailRow(Icons.tag, 'Codigo', comp.componente!.codigo),
                if (comp.componente?.marca != null)
                  _detailRow(Icons.branding_watermark_outlined, 'Marca', comp.componente!.marca!),
                if (comp.componente?.modelo != null)
                  _detailRow(Icons.devices, 'Modelo', comp.componente!.modelo!),
                if (comp.componente?.numeroSerie != null)
                  _detailRow(Icons.qr_code_outlined, 'Serie', comp.componente!.numeroSerie!),
                _detailRow(Icons.circle, 'Estado', comp.estadoComponente),
                const SizedBox(height: 12),
              ],

              // Accion details
              if (comp.descripcionAccion != null ||
                  comp.resultadoAccion != null) ...[
                _detailSectionTitle('ACCION'),
                if (comp.descripcionAccion != null)
                  _detailRow(Icons.description_outlined, 'Descripcion', comp.descripcionAccion!),
                if (comp.resultadoAccion != null)
                  _detailRow(Icons.check_circle_outline, 'Resultado', comp.resultadoAccion!),
                if (comp.observaciones != null)
                  _detailRow(Icons.notes, 'Observaciones', comp.observaciones!),
                const SizedBox(height: 12),
              ],

              // Costos y tiempos
              if (comp.costoAccion != null || comp.costoRepuestos != null ||
                  comp.tiempoAccion != null) ...[
                _detailSectionTitle('COSTOS Y TIEMPOS'),
                if (comp.costoAccion != null)
                  _detailRow(Icons.monetization_on_outlined, 'Costo accion',
                      'S/ ${comp.costoAccion!.toStringAsFixed(2)}'),
                if (comp.costoRepuestos != null)
                  _detailRow(Icons.build_outlined, 'Costo repuestos',
                      'S/ ${comp.costoRepuestos!.toStringAsFixed(2)}'),
                if (comp.costoAccion != null || comp.costoRepuestos != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.attach_money, size: 14, color: AppColors.green),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: Text('Total',
                              style: TextStyle(fontSize: 11,
                                  color: AppColors.green,
                                  fontWeight: FontWeight.w700)),
                        ),
                        Expanded(
                          child: Text(
                            'S/ ${((comp.costoAccion ?? 0) + (comp.costoRepuestos ?? 0)).toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (comp.tiempoAccion != null)
                  _detailRow(Icons.timer_outlined, 'Tiempo', '${comp.tiempoAccion} minutos'),
                const SizedBox(height: 12),
              ],

              // Garantia y prueba
              if (comp.garantiaMeses != null || comp.pruebaRealizada) ...[
                _detailSectionTitle('GARANTIA Y PRUEBAS'),
                if (comp.garantiaMeses != null)
                  _detailRow(Icons.shield_outlined, 'Garantia', '${comp.garantiaMeses} meses'),
                if (comp.pruebaRealizada)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.verified, size: 14, color: AppColors.blue1),
                        const SizedBox(width: 8),
                        Text('Prueba realizada',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.blue1,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],

              const SizedBox(height: 16),

              // Delete button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _removeComponente(comp);
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Eliminar componente'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.blue1,
              letterSpacing: 0.5)),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ─── Historial / Timeline ───

  // ─── Aviso de Mantenimiento ───

  Widget _buildAvisoMantenimientoSection() {
    final orden = _orden!;
    final incluidoEnAvisos = orden.incluirAvisoMantenimiento;
    final fechaPersonalizada = orden.fechaAvisoPersonalizado;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.notifications_outlined, 'AVISO DE MANTENIMIENTO'),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  incluidoEnAvisos ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: incluidoEnAvisos ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  incluidoEnAvisos ? 'Incluido en avisos' : 'No incluido en avisos',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: incluidoEnAvisos ? Colors.green.shade700 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            if (incluidoEnAvisos) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    fechaPersonalizada != null ? Icons.event : Icons.schedule,
                    size: 16,
                    color: AppColors.blue1,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fechaPersonalizada != null
                          ? 'Fecha personalizada: ${DateFormatter.formatDate(fechaPersonalizada)}'
                          : 'Fecha calculada automáticamente según intervalos',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              if (fechaPersonalizada != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    'El cliente solicitó aviso para esta fecha específica',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistorialSection() {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.timeline, 'HISTORIAL'),
            const SizedBox(height: 14),

            // Entry for creation
            _buildTimelineEntry(
              isFirst: true,
              isLast: _historial.isEmpty,
              color: _estadoTimelineColor('RECIBIDO'),
              fecha: DateFormatter.formatSmart(_orden!.creadoEn),
              titulo: 'Orden creada',
              subtitulo: 'Estado inicial: Recibido',
            ),

            // Entries from historial
            for (var i = 0; i < _historial.length; i++)
              _buildTimelineEntry(
                isFirst: false,
                isLast: i == _historial.length - 1,
                color: _estadoTimelineColor(_historial[i].estadoNuevo),
                fecha: DateFormatter.formatSmart(_historial[i].creadoEn),
                titulo: _estadoTimelineLabel(_historial[i].estadoNuevo),
                subtitulo: _historial[i].notas,
                comunicarCliente: _historial[i].comunicarCliente,
              ),

            if (_historial.isEmpty && _orden!.estado != 'RECIBIDO')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Historial anterior no disponible',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineEntry({
    required bool isFirst,
    required bool isLast,
    required Color color,
    required String fecha,
    required String titulo,
    String? subtitulo,
    bool comunicarCliente = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                      flex: 1,
                      child:
                          Container(width: 2, color: color.withAlpha(80))),
                Container(
                  width: isLast ? 14 : 10,
                  height: isLast ? 14 : 10,
                  decoration: BoxDecoration(
                    color: isLast ? Colors.white : color,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: isLast ? 3 : 0),
                  ),
                ),
                if (!isLast)
                  Expanded(
                      flex: 2,
                      child: Container(
                          width: 2,
                          color: AppColors.blueborder.withValues(alpha: 0.4))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(titulo,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(fecha,
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade500)),
                    ],
                  ),
                  if (subtitulo != null && subtitulo.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(subtitulo,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                  ],
                  if (comunicarCliente) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.send,
                            size: 12, color: AppColors.blue1),
                        const SizedBox(width: 4),
                        const Text('Comunicado al cliente',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.blue1)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Cronometro ───

  Widget _buildCronometroSection() {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CronometroServicioWidget(
          orden: _orden!,
          historial: _historial,
        ),
      ),
    );
  }

  // ─── Firma Digital ───

  Widget _buildFirmaSection() {
    final hasFirma = _firmaArchivos.isNotEmpty;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.draw_outlined, size: 16, color: AppColors.blue1),
                const SizedBox(width: 8),
                const Expanded(
                  child: AppSubtitle('FIRMA DEL CLIENTE', fontSize: 12),
                ),
                if (!hasFirma)
                  InkWell(
                    onTap: _capturarFirma,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bluechip,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 14, color: AppColors.blue1),
                          SizedBox(width: 4),
                          Text('Capturar',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.blue1,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasFirma)
              Center(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.network(
                      _firmaArchivos.first.url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 8),
                    Text('Sin firma capturada',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _capturarFirma() async {
    final firmaBytes = await showModalBottomSheet<Uint8List>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const FirmaDigitalSheet(),
    );

    if (firmaBytes == null || !mounted) return;

    try {
      // Save to temp file and upload
      final tempDir = await Directory.systemTemp.createTemp('firma_');
      final tempFile = File('${tempDir.path}/firma.png');
      await tempFile.writeAsBytes(firmaBytes);

      final storageService = locator<StorageService>();
      await storageService.uploadFile(
        file: tempFile,
        empresaId: _empresaId,
        entidadTipo: 'ORDEN_SERVICIO',
        entidadId: widget.ordenId,
        categoria: 'FIRMA',
      );

      await _loadArchivos();
      _filterFirmaFromArchivos();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Firma guardada'), backgroundColor: Colors.green),
        );
      }

      // Cleanup
      try { await tempFile.delete(); await tempDir.delete(); } catch (_) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al guardar firma: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── Asignar Tecnico ───

  void _showAsignarTecnicoSheet() async {
    final tecnico = await showModalBottomSheet<Usuario>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AsignarTecnicoSheet(
        empresaId: _empresaId,
        tecnicoActualId: _orden?.tecnicoId,
      ),
    );

    if (tecnico == null || !mounted) return;

    final repo = locator<OrdenServicioRepository>();
    setState(() => _isLoading = true);

    final result = await repo.assignTecnico(
      id: widget.ordenId,
      empresaId: _empresaId,
      tecnicoId: tecnico.id,
    );

    if (!mounted) return;

    if (result is Success<OrdenServicio>) {
      _orden = result.data;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Tecnico asignado: ${tecnico.nombreCompleto}')),
      );
    } else if (result is Error) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as Error).message)),
      );
    }
  }

  // ─── Bottom Actions ───

  Widget? _buildBottomActions() {
    if (_orden == null) return null;

    final validTransitions = _getValidTransitions(_orden!.estado);
    if (validTransitions.isEmpty) return null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        children: [
          // Cancelar
          if (validTransitions.contains('CANCELADO')) ...[
            CustomButton(
              text: 'Cancelar',
              icon: const Icon(Icons.close, size: 14, color: Colors.red),
              isOutlined: true,
              borderColor: Colors.red,
              textColor: Colors.red,
              enableShadows: false,
              height: 35,
              borderRadius: 8,
              onPressed: () => _showTransitionDialog('CANCELADO'),
            ),
            const SizedBox(width: 10),
          ],
          // Transiciones principales
          ...validTransitions
              .where((e) => e != 'CANCELADO' && e != 'TERCERIZADO')
              .map((estado) {
            final isReingresoBtn = estado == 'EN_DIAGNOSTICO' &&
                (_orden!.estado == 'ENTREGADO' || _orden!.estado == 'FINALIZADO');
            return Expanded(
              child: CustomButton(
                text: isReingresoBtn ? 'Reingreso' : _estadoTimelineLabel(estado),
                icon: Icon(
                  isReingresoBtn ? Icons.replay : _transitionIcon(estado),
                  size: 14,
                  color: Colors.white,
                ),
                backgroundColor: isReingresoBtn ? Colors.orange : AppColors.blue1,
                height: 35,
                borderRadius: 8,
                onPressed: () => _showTransitionDialog(estado),
              ),
            );
          }),
          // Tercerizar B2B
          if (validTransitions.contains('TERCERIZADO') && _orden!.isClienteFinal) ...[
            const SizedBox(width: 10),
            CustomButton(
              text: 'B2B',
              icon: const Icon(Icons.swap_horiz, size: 14, color: Colors.deepPurple),
              isOutlined: true,
              borderColor: Colors.deepPurple,
              textColor: Colors.deepPurple,
              enableShadows: false,
              height: 35,
              borderRadius: 8,
              onPressed: () => _iniciarTercerizacion(),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Transition Dialog ───

  void _showTransitionDialog(String nuevoEstado) {
    final notasController = TextEditingController();
    final costoTotalController = TextEditingController();
    final adelantoController = TextEditingController();
    final descuentoController = TextEditingController();
    final motivoReingresoController = TextEditingController();
    bool comunicarCliente = false;
    String? metodoPagoAdelanto;
    final showCostos = nuevoEstado == 'ESPERANDO_APROBACION' ||
        nuevoEstado == 'EN_REPARACION' ||
        nuevoEstado == 'LISTO_ENTREGA' ||
        nuevoEstado == 'ENTREGADO' ||
        nuevoEstado == 'REPARADO';
    final isCancelado = nuevoEstado == 'CANCELADO';
    final isReingreso = nuevoEstado == 'EN_DIAGNOSTICO' &&
        (_orden?.estado == 'ENTREGADO' || _orden?.estado == 'FINALIZADO');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isCancelado
                        ? Colors.red.withValues(alpha: 0.1)
                        : AppColors.bluechip,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isReingreso
                        ? Icons.replay_outlined
                        : isCancelado
                            ? Icons.cancel_outlined
                            : _transitionIcon(nuevoEstado),
                    color: isReingreso
                        ? Colors.orange
                        : isCancelado
                            ? Colors.red
                            : AppColors.blue1,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isReingreso
                        ? 'Reingreso de orden'
                        : isCancelado
                            ? 'Cancelar orden'
                            : _estadoTimelineLabel(nuevoEstado),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isReingreso) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Se reabrira la orden para revision. '
                              'Reingreso #${(_orden?.cantidadReingresos ?? 0) + 1}',
                              style: const TextStyle(fontSize: 12, color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: motivoReingresoController,
                      decoration: InputDecoration(
                        labelText: 'Motivo del reingreso *',
                        hintText: 'Ej: El equipo volvio a fallar despues de 2 horas...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.orange),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: notasController,
                    decoration: InputDecoration(
                      labelText: isCancelado
                          ? 'Motivo de cancelacion *'
                          : isReingreso
                              ? 'Notas adicionales'
                              : 'Notas / Observaciones',
                      hintText: isCancelado
                          ? 'Indica el motivo...'
                          : 'Agrega notas sobre este cambio...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.blue1),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  if (showCostos) ...[
                    const SizedBox(height: 12),
                    // Resumen de costos actuales como referencia
                    if (_orden != null) ...[
                      Builder(builder: (_) {
                        final comps = _orden!.componentes ?? [];
                        double totalMO = 0;
                        double totalRep = 0;
                        for (final c in comps) {
                          totalMO += c.costoAccion ?? 0;
                          totalRep += c.costoRepuestos ?? 0;
                        }
                        final subtotal = totalMO + totalRep;
                        final hasCostData = subtotal > 0 ||
                            _orden!.costoTotal != null ||
                            _orden!.adelanto != null;
                        if (hasCostData) {
                          return Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.bluechip.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Costos actuales',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.blue1)),
                                const SizedBox(height: 6),
                                if (subtotal > 0)
                                  _dialogCostRow('Componentes',
                                      'S/ ${subtotal.toStringAsFixed(2)}'),
                                if (_orden!.costoTotal != null)
                                  _dialogCostRow('Costo total',
                                      'S/ ${_orden!.costoTotal!.toStringAsFixed(2)}',
                                      bold: true, color: AppColors.blue1),
                                if (_orden!.adelanto != null)
                                  _dialogCostRow('Adelanto',
                                      'S/ ${_orden!.adelanto!.toStringAsFixed(2)}',
                                      color: Colors.green.shade700),
                                if (_orden!.saldoPendiente != null)
                                  _dialogCostRow('Saldo pendiente',
                                      'S/ ${_orden!.saldoPendiente!.toStringAsFixed(2)}',
                                      bold: true,
                                      color: _orden!.saldoPendiente! > 0
                                          ? Colors.orange.shade700
                                          : Colors.green.shade700),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ],
                    // Costo total
                    TextFormField(
                      controller: costoTotalController,
                      decoration: InputDecoration(
                        labelText: 'Costo total del servicio (S/)',
                        hintText: 'Precio final acordado',
                        prefixText: 'S/ ',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.blue1),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                    ),
                    const SizedBox(height: 10),
                    // Descuento
                    TextFormField(
                      controller: descuentoController,
                      decoration: InputDecoration(
                        labelText: 'Descuento (S/)',
                        hintText: 'Opcional',
                        prefixText: 'S/ ',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.blue1),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                    ),
                    const SizedBox(height: 10),
                    // Adelanto + método de pago
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: adelantoController,
                            decoration: InputDecoration(
                              labelText: 'Adelanto (S/)',
                              hintText: 'Monto',
                              prefixText: 'S/ ',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: AppColors.blue1),
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          // F1 FIX: DropdownButtonFormField usa 'value' no 'initialValue'
                          child: DropdownButtonFormField<String>(
                            value: metodoPagoAdelanto,
                            decoration: InputDecoration(
                              labelText: 'Medio',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: AppColors.blue1),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 14),
                            ),
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'EFECTIVO', child: Text('Efectivo', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'YAPE', child: Text('Yape', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'PLIN', child: Text('Plin', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'TARJETA', child: Text('Tarjeta', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'TRANSFERENCIA', child: Text('Transf.', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'MIXTO', child: Text('Mixto', style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (v) =>
                                setDialogState(() => metodoPagoAdelanto = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bluechip.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SwitchListTile(
                      title: const Text('Comunicar al cliente',
                          style: TextStyle(fontSize: 13)),
                      subtitle: const Text(
                          'Registrar que este cambio fue notificado',
                          style: TextStyle(fontSize: 11)),
                      value: comunicarCliente,
                      activeThumbColor: AppColors.blue1,
                      onChanged: (v) =>
                          setDialogState(() => comunicarCliente = v),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      dense: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar',
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (isCancelado && notasController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Debes indicar el motivo de cancelacion')),
                    );
                    return;
                  }
                  if (isReingreso && motivoReingresoController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Debes indicar el motivo del reingreso')),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  _executeTransition(
                    nuevoEstado,
                    notas: notasController.text.trim().isNotEmpty
                        ? notasController.text.trim()
                        : null,
                    comunicarCliente: comunicarCliente,
                    motivoReingreso: isReingreso
                        ? motivoReingresoController.text.trim()
                        : null,
                    costoTotal: costoTotalController.text.isNotEmpty
                        ? double.tryParse(costoTotalController.text)
                        : null,
                    adelanto: adelantoController.text.isNotEmpty
                        ? double.tryParse(adelantoController.text)
                        : null,
                    descuento: descuentoController.text.isNotEmpty
                        ? double.tryParse(descuentoController.text)
                        : null,
                    metodoPagoAdelanto: metodoPagoAdelanto,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReingreso
                      ? Colors.orange
                      : isCancelado
                          ? Colors.red
                          : AppColors.blue1,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                    isReingreso
                        ? 'Confirmar reingreso'
                        : isCancelado
                            ? 'Confirmar cancelacion'
                            : 'Confirmar'),
              ),
            ],
          );
        });
      },
    );
  }

  void _executeTransition(
    String nuevoEstado, {
    String? notas,
    bool comunicarCliente = false,
    String? motivoReingreso,
    double? costoTotal,
    double? adelanto,
    double? descuento,
    String? metodoPagoAdelanto,
  }) async {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    final repo = locator<OrdenServicioRepository>();

    setState(() => _isLoading = true);

    final result = await repo.transitionEstado(
      id: widget.ordenId,
      empresaId: empresaState.context.empresa.id,
      nuevoEstado: nuevoEstado,
      notas: notas,
      comunicarCliente: comunicarCliente,
      motivoReingreso: motivoReingreso,
      costoTotal: costoTotal,
      adelanto: adelanto,
      descuento: descuento,
      metodoPagoAdelanto: metodoPagoAdelanto,
    );

    if (!mounted) return;

    if (result is Success<OrdenServicio>) {
      _orden = result.data;
      await _loadHistorial();
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Estado cambiado a ${_estadoTimelineLabel(nuevoEstado)}')),
        );
        // Offer WhatsApp notification
        _ofrecerNotificacionWhatsApp(nuevoEstado);
      }
    } else if (result is Error) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as Error).message)),
      );
    }
  }

  void _ofrecerNotificacionWhatsApp(String nuevoEstado) {
    if (_orden?.cliente?.telefono == null) return;

    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Notificar al cliente',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: const Text(
          'Enviar notificacion por WhatsApp al cliente sobre el cambio de estado?',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('No', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              WhatsAppNotificationService.notificarCambioEstado(
                orden: _orden!,
                nuevoEstado: nuevoEstado,
                empresaNombre: (empresaState).context.empresa.nombre,
              );
            },
            icon: const Icon(Icons.chat, size: 16),
            label: const Text('Enviar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Component Actions ───

  void _showAddComponenteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddComponenteSheet(
        ordenId: widget.ordenId,
        onAdded: (componente) => _loadAll(),
      ),
    );
  }

  void _removeComponente(OrdenComponente comp) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar componente',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: const Text(
          'Se eliminara este componente de la orden.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final repo = locator<OrdenServicioRepository>();
    final result = await repo.removeComponente(
      ordenId: widget.ordenId,
      componenteId: comp.id,
    );

    if (!mounted) return;

    if (result is Success) {
      _loadAll();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Componente eliminado')),
      );
    } else if (result is Error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result).message)),
      );
    }
  }

  // ─── Generar Ticket PDF ───

  Future<void> _generarTicket() async {
    if (_orden == null) return;

    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    final empresa = empresaState.context.empresa;
    final empresaContext = empresaState.context;

    // Resolve sede name: match by orden.sedeId or fallback to sedePrincipal
    String? sedeNombre;
    if (_orden!.sedeId != null) {
      final matched = empresaContext.sedes
          .where((s) => s.id == _orden!.sedeId)
          .firstOrNull;
      sedeNombre = matched?.nombre;
    }
    sedeNombre ??= empresaContext.sedePrincipal?.nombre;

    // Try to load logo
    Uint8List? logoBytes;
    final logoUrl = empresa.logo;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(logoUrl));
        if (response.statusCode == 200) {
          logoBytes = response.bodyBytes;
        }
      } catch (_) {}
    }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentoOrdenServicioPreviewPage(
          orden: _orden!,
          empresaNombre: empresa.nombre,
          empresaRuc: empresa.ruc,
          empresaDireccion: empresa.direccionFiscal,
          empresaTelefono: empresa.telefono,
          sedeNombre: sedeNombre,
          logoEmpresa: logoBytes,
        ),
      ),
    );
  }

  // ─── UI Helpers (same pattern as cotizacion_detail) ───

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.blue1),
        const SizedBox(width: 8),
        AppSubtitle(title, fontSize: 12),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDynamicField(dynamic value) {
    if (value == null) return '-';
    if (value is List) return value.join(', ');
    if (value is Map) {
      return value.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
    }
    return value.toString();
  }

  // ─── State/Label Helpers ───

  // ─── Tercerización B2B ───

  Widget _buildTercerizacionBanner() {
    final isEnviada = _orden!.isB2BEnviado || _orden!.isTercerizado;

    final terc = isEnviada
        ? _orden!.tercerizacionOrigen
        : _orden!.tercerizacionDestino;

    final empresaNombre = isEnviada
        ? (terc?.empresaDestino?.nombre ?? 'Empresa destino')
        : (terc?.empresaOrigen?.nombre ?? 'Empresa origen');

    final empresaLogo = isEnviada
        ? terc?.empresaDestino?.logo
        : terc?.empresaOrigen?.logo;

    final estadoTerc = terc?.estado ?? '';

    final color = isEnviada ? Colors.deepPurple : AppColors.blue1;
    final bgColor = isEnviada
        ? Colors.deepPurple.withValues(alpha: 0.06)
        : AppColors.blue1.withValues(alpha: 0.06);
    final borderColor = isEnviada
        ? Colors.deepPurple.withValues(alpha: 0.2)
        : AppColors.blue1.withValues(alpha: 0.2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                isEnviada ? Icons.call_made : Icons.call_received,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                isEnviada ? 'Tercerización enviada' : 'Tercerización recibida',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const Spacer(),
              if (estadoTerc.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _tercEstadoColor(estadoTerc).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    estadoTerc.replaceAll('_', ' '),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _tercEstadoColor(estadoTerc),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Empresa info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withValues(alpha: 0.1),
                backgroundImage:
                    empresaLogo != null ? NetworkImage(empresaLogo) : null,
                child: empresaLogo == null
                    ? Text(
                        empresaNombre.isNotEmpty
                            ? empresaNombre[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      empresaNombre,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      isEnviada
                          ? 'Servicio enviado a esta empresa'
                          : 'Servicio recibido de esta empresa',
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Precio B2B
          if (terc?.precioB2B != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.payments_outlined,
                    size: 14, color: Colors.green.shade600),
                const SizedBox(width: 6),
                Text(
                  'Precio B2B: S/ ${terc!.precioB2B!.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],

          // Botón ver detalle
          if (terc != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.push('/empresa/tercerizacion/${terc.id}'),
                icon: Icon(Icons.open_in_new, size: 14, color: color),
                label: Text(
                  'Ver detalle de tercerización',
                  style: TextStyle(fontSize: 11, color: color),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: color.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _tercEstadoColor(String estado) {
    switch (estado) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'ACEPTADO':
        return Colors.blue;
      case 'EN_PROCESO':
        return Colors.indigo;
      case 'COMPLETADO':
        return Colors.green;
      case 'RECHAZADO':
        return Colors.red;
      case 'CANCELADO':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _iniciarTercerizacion() async {
    if (_orden == null) return;

    final empresaSeleccionada = await context.push<DirectorioEmpresa>(
      '/empresa/tercerizacion/directorio',
      extra: {
        'empresaId': _empresaId,
        'ordenOrigenId': _orden!.id,
        'tipoServicioFiltro': _orden!.tipoServicio,
      },
    );

    if (empresaSeleccionada == null || !mounted) return;

    // Pre-fill with existing order data
    final notasController = TextEditingController();
    final descripcionController = TextEditingController(
      text: _orden!.descripcionProblema ?? '',
    );
    // Extract existing sintomas
    final sintomasActuales = <String>[];
    if (_orden!.sintomas is List) {
      for (final s in _orden!.sintomas as List) {
        sintomasActuales.add(s.toString());
      }
    } else if (_orden!.sintomas is String && (_orden!.sintomas as String).isNotEmpty) {
      sintomasActuales.add(_orden!.sintomas as String);
    }
    final sintomasController = TextEditingController(
      text: sintomasActuales.join(', '),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tercerizar servicio', style: TextStyle(fontSize: 15)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Se enviará la solicitud a:',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Text(
                  empresaSeleccionada.nombre,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                // Descripción técnica del problema
                Text(
                  'Descripción técnica del problema',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: descripcionController,
                  decoration: InputDecoration(
                    hintText: 'Ej: Equipo no enciende. Descartado cargador y batería...',
                    hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                  maxLines: 4,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                // Síntomas
                Text(
                  'Síntomas identificados',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: sintomasController,
                  decoration: InputDecoration(
                    hintText: 'Separados por coma: No enciende, Pantalla negra...',
                    hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                // Notas
                Text(
                  'Notas adicionales (opcional)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: notasController,
                  decoration: InputDecoration(
                    hintText: 'Instrucciones o contexto para la empresa destino',
                    hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue1),
            child: const Text('Enviar solicitud',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Parse sintomas from comma-separated text
    final sintomasList = sintomasController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    setState(() => _isLoading = true);

    final useCase = locator<CrearTercerizacionUseCase>();
    final result = await useCase(
      empresaDestinoId: empresaSeleccionada.id,
      ordenOrigenId: _orden!.id,
      notasOrigen: notasController.text.trim().isNotEmpty
          ? notasController.text.trim()
          : null,
      descripcionProblema: descripcionController.text.trim().isNotEmpty
          ? descripcionController.text.trim()
          : null,
      sintomas: sintomasList.isNotEmpty ? sintomasList : null,
    );

    if (!mounted) return;

    if (result is Success<TercerizacionServicio>) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud de tercerización enviada',
              style: TextStyle(fontSize: 12)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadAll();
    } else if (result is Error<TercerizacionServicio>) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message, style: const TextStyle(fontSize: 12)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<String> _getValidTransitions(String estado) {
    const transitions = {
      'RECIBIDO': ['EN_DIAGNOSTICO', 'TERCERIZADO', 'CANCELADO'],
      'EN_DIAGNOSTICO': ['ESPERANDO_APROBACION', 'EN_REPARACION', 'TERCERIZADO', 'CANCELADO'],
      'ESPERANDO_APROBACION': ['EN_REPARACION', 'TERCERIZADO', 'CANCELADO'],
      'EN_REPARACION': ['PENDIENTE_PIEZAS', 'REPARADO', 'CANCELADO'],
      'PENDIENTE_PIEZAS': ['EN_REPARACION', 'CANCELADO'],
      'REPARADO': ['LISTO_ENTREGA'],
      'LISTO_ENTREGA': ['ENTREGADO'],
      'ENTREGADO': ['FINALIZADO', 'EN_DIAGNOSTICO'],
      'FINALIZADO': ['EN_DIAGNOSTICO'],
    };
    return transitions[estado] ?? [];
  }

  String _estadoTimelineLabel(String estado) {
    const labels = {
      'RECIBIDO': 'Recibido',
      'EN_DIAGNOSTICO': 'En Diagnostico',
      'ESPERANDO_APROBACION': 'Esperando Aprobacion',
      'EN_REPARACION': 'En Reparacion',
      'PENDIENTE_PIEZAS': 'Pendiente Piezas',
      'REPARADO': 'Reparado',
      'LISTO_ENTREGA': 'Listo para Entrega',
      'ENTREGADO': 'Entregado',
      'FINALIZADO': 'Finalizado',
      'TERCERIZADO': 'Tercerizar',
      'CANCELADO': 'Cancelado',
    };
    return labels[estado] ?? estado;
  }

  String _tipoServicioLabel(String tipo) {
    const labels = {
      'REPARACION': 'Reparacion',
      'MANTENIMIENTO': 'Mantenimiento',
      'INSTALACION': 'Instalacion',
      'DIAGNOSTICO': 'Diagnostico',
      'ACTUALIZACION': 'Actualizacion',
      'LIMPIEZA': 'Limpieza',
      'RECUPERACION_DATOS': 'Recuperacion de datos',
      'CONFIGURACION': 'Configuracion',
      'CONSULTORIA': 'Consultoria',
      'FORMACION': 'Formacion',
      'SOPORTE': 'Soporte',
    };
    return labels[tipo] ?? tipo;
  }

  String _estadoDiagnosticoLabel(String estado) {
    const labels = {
      'PENDIENTE': 'Pendiente',
      'EN_PROGRESO': 'En progreso',
      'COMPLETADO': 'Completado',
      'REQUIERE_VISITA': 'Requiere visita',
      'REQUIERE_PIEZAS': 'Requiere piezas',
      'EQUIPO_NO_REPARABLE': 'No reparable',
    };
    return labels[estado] ?? estado;
  }

  Color _estadoTimelineColor(String estado) {
    switch (estado) {
      case 'RECIBIDO':
        return AppColors.blue1;
      case 'EN_DIAGNOSTICO':
        return Colors.indigo;
      case 'ESPERANDO_APROBACION':
        return AppColors.orange;
      case 'EN_REPARACION':
        return Colors.orange;
      case 'PENDIENTE_PIEZAS':
        return Colors.purple;
      case 'REPARADO':
        return Colors.teal;
      case 'LISTO_ENTREGA':
        return Colors.cyan;
      case 'ENTREGADO':
        return AppColors.green;
      case 'FINALIZADO':
        return AppColors.greendark;
      case 'CANCELADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _transitionIcon(String estado) {
    switch (estado) {
      case 'EN_DIAGNOSTICO':
        return Icons.search;
      case 'ESPERANDO_APROBACION':
        return Icons.hourglass_bottom;
      case 'EN_REPARACION':
        return Icons.build;
      case 'PENDIENTE_PIEZAS':
        return Icons.inventory;
      case 'REPARADO':
        return Icons.check_circle_outline;
      case 'LISTO_ENTREGA':
        return Icons.local_shipping;
      case 'ENTREGADO':
        return Icons.handshake;
      case 'FINALIZADO':
        return Icons.verified;
      case 'TERCERIZADO':
        return Icons.swap_horiz;
      case 'CANCELADO':
        return Icons.cancel;
      default:
        return Icons.arrow_forward;
    }
  }

  IconData _categoriaIcon(String? categoria) {
    switch (categoria) {
      case 'HARDWARE':
        return Icons.memory;
      case 'SOFTWARE':
        return Icons.code;
      case 'PERIFERICO':
        return Icons.keyboard;
      case 'ACCESORIOS':
        return Icons.cable;
      case 'CONSUMIBLES':
        return Icons.inventory_2;
      default:
        return Icons.extension;
    }
  }

  Color _accionColor(String accion) {
    switch (accion) {
      case 'REPARAR':
        return Colors.orange;
      case 'REEMPLAZAR':
        return AppColors.red;
      case 'DIAGNOSTICAR':
        return AppColors.blue1;
      case 'LIMPIAR':
        return Colors.teal;
      case 'INSTALAR':
        return AppColors.green;
      case 'ACTUALIZAR':
        return Colors.indigo;
      case 'DESMONTAR':
        return Colors.brown;
      case 'PROBAR':
        return Colors.cyan;
      case 'CALIBRAR':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class _PatronMiniPainter extends CustomPainter {
  final List<int> patron;
  final Color color;

  _PatronMiniPainter({required this.patron, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final spacing = size.width / 3;

    Offset center(int index) {
      final row = index ~/ 3;
      final col = index % 3;
      return Offset(spacing * col + spacing / 2, spacing * row + spacing / 2);
    }

    // Líneas
    if (patron.length >= 2) {
      final paint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < patron.length - 1; i++) {
        canvas.drawLine(center(patron[i]), center(patron[i + 1]), paint);
      }
    }

    // Nodos
    for (int i = 0; i < 9; i++) {
      final c = center(i);
      final selected = patron.contains(i);
      if (selected) {
        canvas.drawCircle(c, 6, Paint()..color = color.withValues(alpha: 0.2));
        canvas.drawCircle(
          c, 6,
          Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke,
        );
        final tp = TextPainter(
          text: TextSpan(
            text: '${patron.indexOf(i) + 1}',
            style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: color),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
      } else {
        canvas.drawCircle(c, 2.5, Paint()..color = Colors.grey.shade400);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatronMiniPainter oldDelegate) =>
      oldDelegate.patron != patron;
}
