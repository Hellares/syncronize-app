import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_fonts.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/tercerizacion.dart';
import '../../domain/usecases/get_tercerizacion_usecase.dart';
import '../../domain/usecases/responder_tercerizacion_usecase.dart';
import '../../domain/usecases/completar_tercerizacion_usecase.dart';
import '../../domain/usecases/cancelar_tercerizacion_usecase.dart';

class TercerizacionDetailPage extends StatefulWidget {
  final String tercerizacionId;
  const TercerizacionDetailPage({super.key, required this.tercerizacionId});

  @override
  State<TercerizacionDetailPage> createState() =>
      _TercerizacionDetailPageState();
}

class _TercerizacionDetailPageState extends State<TercerizacionDetailPage> {
  TercerizacionServicio? _item;
  bool _isLoading = true;
  bool _isActioning = false;
  String? _error;

  String get _empresaId {
    final state = context.read<EmpresaContextCubit>().state;
    return state is EmpresaContextLoaded ? state.context.empresa.id : '';
  }

  bool get _isEnviada => _item?.empresaOrigenId == _empresaId;
  bool get _isRecibida => _item?.empresaDestinoId == _empresaId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final useCase = locator<GetTercerizacionUseCase>();
    final result = await useCase(id: widget.tercerizacionId);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result is Success<TercerizacionServicio>) {
        _item = result.data;
      } else if (result is Error<TercerizacionServicio>) {
        _error = result.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Tercerización',
          backgroundColor: AppColors.blue1,
          foregroundColor: Colors.white,
        ),
        body: _buildBody(),
        bottomNavigationBar: _buildActions(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CustomLoading());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            TextButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    if (_item == null) {
      return const Center(child: Text('No encontrado'));
    }

    final item = _item!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _buildInfoCard(item),
          const SizedBox(height: 12),
          if (item.componentesData != null && item.componentesData is List && (item.componentesData as List).isNotEmpty) ...[
            _buildComponentesSection(item),
            const SizedBox(height: 12),
          ],
          if (item.ordenOrigen != null || item.ordenDestino != null) ...[
            _buildOrdenesSection(item),
            const SizedBox(height: 12),
          ],
          if (item.motivoRechazo != null) ...[
            _buildRechazoSection(item),
            const SizedBox(height: 12),
          ],
          _buildTimelineSection(item),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ─── Info Card Unificada ───

  Widget _buildInfoCard(TercerizacionServicio item) {
    final config = _estadoConfig[item.estado] ??
        {'color': Colors.grey, 'label': item.estado, 'icon': Icons.help};
    final estadoColor = config['color'] as Color;
    final dirColor = _isEnviada ? Colors.orange : AppColors.blue1;

    final datos = item.datosEquipo;
    final tipoEquipo = datos['tipoEquipo'] as String? ?? '';
    final marcaEquipo = datos['marcaEquipo'] as String? ?? '';
    final modeloEquipo = datos['modeloEquipo'] as String? ?? '';
    final serieEquipo = datos['serieEquipo'] as String? ?? '';
    final condicionEquipo = datos['condicionEquipo'] as String? ?? '';

    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.blueborder,
      borderWidth: 0.6,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Estado + Dirección ───
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(config['icon'] as IconData,
                      color: estadoColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: estadoColor,
                          fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            _isEnviada ? Icons.call_made : Icons.call_received,
                            size: 12, color: dirColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isEnviada ? 'Enviada por ti' : 'Recibida',
                            style: TextStyle(
                              fontSize: 10,
                              color: dirColor,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _infoChip(
                  Icons.calendar_today_outlined,
                  DateFormatter.formatDate(item.fechaSolicitud),
                ),
              ],
            ),

            _sectionDivider(),

            // ─── Empresas ───
            _buildEmpresaRow(
              label: 'Origen',
              empresa: item.empresaOrigen,
              icon: Icons.call_made,
              color: Colors.orange,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Icon(Icons.arrow_downward, size: 16, color: Colors.green),
            ),
            _buildEmpresaRow(
              label: 'Destino',
              empresa: item.empresaDestino,
              icon: Icons.call_received,
              color: AppColors.blue1,
            ),

            _sectionDivider(),

            // ─── Equipo ───
            _inlineSection('Equipo', Icons.devices_outlined),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (tipoEquipo.isNotEmpty)
                  _infoChip(Icons.category_outlined, tipoEquipo),
                if (marcaEquipo.isNotEmpty)
                  _infoChip(Icons.branding_watermark_outlined, marcaEquipo),
                if (modeloEquipo.isNotEmpty)
                  _infoChip(Icons.phone_android_outlined, modeloEquipo),
                if (serieEquipo.isNotEmpty)
                  _infoChip(Icons.tag, serieEquipo),
                if (condicionEquipo.isNotEmpty)
                  _infoChip(Icons.info_outline, condicionEquipo),
              ],
            ),

            // ─── Problema ───
            if (item.descripcionProblema != null) ...[
              _sectionDivider(),
              _inlineSection('Problema', Icons.report_problem_outlined),
              const SizedBox(height: 6),
              Text(
                item.descripcionProblema!,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                  height: 1.4,
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                ),
              ),
              if (item.sintomas != null && item.sintomas is List) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: (item.sintomas as List).map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      s.toString(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                        fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ],

            // ─── Precio B2B ───
            if (item.precioB2B != null) ...[
              _sectionDivider(),
              Row(
                children: [
                  Icon(Icons.payments_outlined, size: 14, color: Colors.green.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Precio B2B',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'S/ ${item.precioB2B!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade700,
                      fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                    ),
                  ),
                ],
              ),
              if (item.metodoPagoB2B != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _infoChip(Icons.account_balance_wallet_outlined, item.metodoPagoB2B!),
                  ),
                ),
            ],

            // ─── Notas ───
            if (item.notasOrigen != null || item.notasDestino != null) ...[
              _sectionDivider(),
              _inlineSection('Notas', Icons.notes_outlined),
              const SizedBox(height: 6),
              if (item.notasOrigen != null)
                _notaRow('Origen', item.notasOrigen!),
              if (item.notasDestino != null)
                _notaRow('Destino', item.notasDestino!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmpresaRow({
    required String label,
    required EmpresaResumen? empresa,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.1),
            backgroundImage:
                empresa?.logo != null ? NetworkImage(empresa!.logo!) : null,
            child: empresa?.logo == null
                ? Icon(icon, size: 14, color: color)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  empresa?.nombre ?? 'Empresa $label',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                  ),
                ),
                if (empresa?.rubro != null)
                  Text(
                    empresa!.rubro!,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade500,
                      fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                    ),
                  ),
              ],
            ),
          ),
          if (empresa?.telefono != null)
            _infoChip(Icons.phone_outlined, empresa!.telefono!),
        ],
      ),
    );
  }

  // ─── Componentes (card separada - interactiva) ───

  Widget _buildComponentesSection(TercerizacionServicio item) {
    final componentes = item.componentesData as List;

    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.blueborder,
      borderWidth: 0.6,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.memory, size: 14, color: AppColors.blue1),
                const SizedBox(width: 6),
                AppTitle('Componentes (${componentes.length})',
                    fontSize: 12, color: AppColors.blue2),
              ],
            ),
            const SizedBox(height: 10),
            ...componentes.map((c) {
              final comp = c is Map<String, dynamic> ? c : <String, dynamic>{};
              final componente = comp['componente'] as Map<String, dynamic>? ?? {};
              final nombre = componente['nombre'] as String? ?? '';
              final codigo = componente['codigo'] as String? ?? '';
              final tipoAccion = comp['tipoAccion'] as String? ?? '';
              final descripcionAccion = comp['descripcionAccion'] as String? ?? '';
              final observaciones = comp['observaciones'] as String? ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _accionColor(tipoAccion).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.settings, size: 12,
                          color: _accionColor(tipoAccion)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  nombre.isNotEmpty ? nombre : codigo,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                                  ),
                                ),
                              ),
                              if (tipoAccion.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _accionColor(tipoAccion).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    tipoAccion.replaceAll('_', ' '),
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: _accionColor(tipoAccion),
                                      fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (descripcionAccion.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                descripcionAccion,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                                ),
                              ),
                            ),
                          if (observaciones.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Obs: $observaciones',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _accionColor(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'REPARAR':
        return Colors.orange;
      case 'REEMPLAZAR':
        return Colors.red;
      case 'REVISAR':
        return Colors.blue;
      case 'LIMPIAR':
        return Colors.teal;
      case 'ACTUALIZAR':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  // ─── Órdenes vinculadas ───

  Widget _buildOrdenesSection(TercerizacionServicio item) {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.blueborder,
      borderWidth: 0.6,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, size: 14, color: AppColors.blue1),
                const SizedBox(width: 6),
                const AppTitle('Ordenes vinculadas', fontSize: 12, color: AppColors.blue2),
              ],
            ),
            const SizedBox(height: 10),
            if (item.ordenOrigen != null)
              _ordenRow('Orden origen', item.ordenOrigen!, Colors.orange),
            if (item.ordenOrigen != null && item.ordenDestino != null)
              const SizedBox(height: 6),
            if (item.ordenDestino != null)
              _ordenRow('Orden destino', item.ordenDestino!, AppColors.blue1),
          ],
        ),
      ),
    );
  }

  Widget _ordenRow(String label, OrdenResumen orden, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.description_outlined, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orden.codigo,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade500,
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                ),
              ),
            ],
          ),
        ),
        if (orden.estado != null)
          _infoChip(Icons.circle, orden.estado!, bgColor: color.withValues(alpha: 0.08), textColor: color, iconSize: 6),
      ],
    );
  }

  // ─── Rechazo ───

  Widget _buildRechazoSection(TercerizacionServicio item) {
    return GradientContainer(
      borderColor: Colors.red.shade200,
      borderWidth: 0.8,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.block, size: 14, color: Colors.red.shade400),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Motivo de rechazo',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                      fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.motivoRechazo!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade600,
                      height: 1.4,
                      fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Timeline / Historial ───

  Widget _buildTimelineSection(TercerizacionServicio item) {
    final events = <_TimelineEvent>[];

    // Solicitud
    events.add(_TimelineEvent(
      icon: Icons.send_outlined,
      color: Colors.blue,
      title: 'Solicitud enviada',
      subtitle: item.empresaOrigen?.nombre ?? 'Empresa origen',
      date: item.fechaSolicitud,
      isCompleted: true,
    ));

    // Respuesta
    if (item.fechaRespuesta != null) {
      final isAceptado = item.isAceptado || item.estado == 'EN_PROCESO' || item.isCompletado;
      events.add(_TimelineEvent(
        icon: isAceptado ? Icons.check_circle_outline : Icons.cancel_outlined,
        color: isAceptado ? Colors.green : (item.isRechazado ? Colors.red : Colors.orange),
        title: item.isRechazado ? 'Solicitud rechazada' : 'Solicitud aceptada',
        subtitle: item.empresaDestino?.nombre ?? 'Empresa destino',
        date: item.fechaRespuesta!,
        isCompleted: true,
      ));
    } else if (!item.isCancelado) {
      events.add(_TimelineEvent(
        icon: Icons.hourglass_empty,
        color: Colors.orange,
        title: 'Esperando respuesta',
        subtitle: item.empresaDestino?.nombre ?? 'Empresa destino',
        date: null,
        isCompleted: false,
      ));
    }

    // En proceso (si aplica)
    if (item.estado == 'EN_PROCESO' || item.isCompletado) {
      events.add(_TimelineEvent(
        icon: Icons.engineering,
        color: Colors.indigo,
        title: 'En proceso de reparacion',
        subtitle: 'Equipo en taller destino',
        date: item.fechaRespuesta,
        isCompleted: true,
      ));
    }

    // Completado
    if (item.isCompletado) {
      events.add(_TimelineEvent(
        icon: Icons.task_alt,
        color: Colors.green,
        title: 'Servicio completado',
        subtitle: item.precioB2B != null
            ? 'Precio: S/ ${item.precioB2B!.toStringAsFixed(2)}'
            : 'Trabajo finalizado',
        date: item.fechaCompletado,
        isCompleted: true,
      ));
    } else if (!item.isRechazado && !item.isCancelado && item.fechaRespuesta != null) {
      events.add(_TimelineEvent(
        icon: Icons.task_alt,
        color: Colors.grey,
        title: 'Pendiente de completar',
        subtitle: 'Esperando finalizacion',
        date: null,
        isCompleted: false,
      ));
    }

    // Cancelado
    if (item.isCancelado) {
      events.add(_TimelineEvent(
        icon: Icons.block,
        color: Colors.grey,
        title: 'Solicitud cancelada',
        subtitle: 'Cancelada por empresa origen',
        date: item.fechaRespuesta,
        isCompleted: true,
      ));
    }

    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.blueborder,
      borderWidth: 0.6,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, size: 14, color: AppColors.blue1),
                const SizedBox(width: 6),
                const AppTitle('Historial', fontSize: 12, color: AppColors.blue2),
              ],
            ),
            const SizedBox(height: 12),
            ...events.asMap().entries.map((entry) {
              final i = entry.key;
              final event = entry.value;
              final isLast = i == events.length - 1;
              return _buildTimelineItem(event, isLast);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(_TimelineEvent event, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Línea + círculo
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: event.isCompleted
                        ? event.color.withValues(alpha: 0.15)
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: event.isCompleted ? event.color : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    event.icon,
                    size: 11,
                    color: event.isCompleted ? event.color : Colors.grey.shade400,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: event.isCompleted
                          ? event.color.withValues(alpha: 0.3)
                          : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Contenido
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: event.isCompleted ? Colors.grey.shade800 : Colors.grey.shade400,
                      fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                    ),
                  ),
                  if (event.date != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        DateFormatter.formatDateTime(event.date!),
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade400,
                          fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───

  Widget _sectionDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: Colors.grey.shade200),
    );
  }

  Widget _inlineSection(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.blue1),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
          ),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String text, {
    Color? bgColor,
    Color? textColor,
    double iconSize = 11,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: textColor ?? Colors.grey.shade500),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: textColor ?? Colors.grey.shade600,
              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notaRow(String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.bluechip,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.blue1,
                fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Actions ───

  Widget? _buildActions() {
    if (_item == null) return null;
    final item = _item!;

    final List<Widget> buttons = [];

    // Empresa destino puede aceptar/rechazar si PENDIENTE
    if (_isRecibida && item.isPendiente) {
      buttons.addAll([
        CustomButton(
          text: 'Rechazar',
          icon: const Icon(Icons.close, size: 14, color: Colors.red),
          isOutlined: true,
          borderColor: Colors.red,
          textColor: Colors.red,
          enableShadows: false,
          height: 38,
          borderRadius: 8,
          onPressed: _isActioning ? null : () => _showRechazarDialog(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CustomButton(
            text: 'Aceptar',
            icon: const Icon(Icons.check, size: 14, color: Colors.white),
            backgroundColor: Colors.green,
            height: 38,
            borderRadius: 8,
            onPressed: _isActioning ? null : () => _aceptar(),
          ),
        ),
      ]);
    }

    // Empresa destino puede completar si ACEPTADO o EN_PROCESO
    if (_isRecibida && (item.isAceptado || item.estado == 'EN_PROCESO')) {
      buttons.add(
        Expanded(
          child: CustomButton(
            text: 'Completar servicio',
            icon: const Icon(Icons.check_circle_outline, size: 14, color: Colors.white),
            backgroundColor: Colors.green,
            height: 38,
            borderRadius: 8,
            onPressed: _isActioning ? null : () => _showCompletarDialog(),
          ),
        ),
      );
    }

    // Empresa origen puede cancelar si PENDIENTE
    if (_isEnviada && item.isPendiente) {
      buttons.add(
        Expanded(
          child: CustomButton(
            text: 'Cancelar solicitud',
            icon: const Icon(Icons.cancel_outlined, size: 14, color: Colors.red),
            isOutlined: true,
            borderColor: Colors.red,
            textColor: Colors.red,
            enableShadows: false,
            height: 38,
            borderRadius: 8,
            onPressed: _isActioning ? null : () => _cancelar(),
          ),
        ),
      );
    }

    if (buttons.isEmpty) return null;

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
      child: _isActioning
          ? const Center(
              child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(color: AppColors.blue1),
            ))
          : Row(children: buttons),
    );
  }

  // ─── Action handlers ───

  Future<void> _aceptar() async {
    setState(() => _isActioning = true);
    final useCase = locator<ResponderTercerizacionUseCase>();
    final result = await useCase(id: widget.tercerizacionId, aceptar: true);

    if (!mounted) return;
    setState(() => _isActioning = false);

    if (result is Success<TercerizacionServicio>) {
      _showSnackBar('Tercerización aceptada', Colors.green);
      _load();
    } else if (result is Error<TercerizacionServicio>) {
      _showSnackBar(result.message, Colors.red);
    }
  }

  void _showRechazarDialog() {
    final motivoController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar tercerización',
            style: TextStyle(fontSize: 15)),
        content: TextField(
          controller: motivoController,
          decoration: const InputDecoration(
            hintText: 'Motivo del rechazo (opcional)',
            hintStyle: TextStyle(fontSize: 13),
          ),
          maxLines: 3,
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _rechazar(motivoController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Rechazar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _rechazar(String motivo) async {
    setState(() => _isActioning = true);
    final useCase = locator<ResponderTercerizacionUseCase>();
    final result = await useCase(
      id: widget.tercerizacionId,
      aceptar: false,
      motivoRechazo: motivo.isNotEmpty ? motivo : null,
    );

    if (!mounted) return;
    setState(() => _isActioning = false);

    if (result is Success<TercerizacionServicio>) {
      _showSnackBar('Tercerización rechazada', Colors.orange);
      _load();
    } else if (result is Error<TercerizacionServicio>) {
      _showSnackBar(result.message, Colors.red);
    }
  }

  void _showCompletarDialog() {
    final precioController = TextEditingController();
    final metodoController = TextEditingController();
    final notasController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Completar tercerización',
            style: TextStyle(fontSize: 15)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio B2B (S/)',
                  labelStyle: TextStyle(fontSize: 13),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: metodoController,
                decoration: const InputDecoration(
                  labelText: 'Método de pago (opcional)',
                  labelStyle: TextStyle(fontSize: 13),
                ),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notasController,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  labelStyle: TextStyle(fontSize: 13),
                ),
                maxLines: 2,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final precio = double.tryParse(precioController.text.trim());
              if (precio == null || precio <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Ingrese un precio válido')),
                );
                return;
              }
              Navigator.pop(ctx);
              _completar(
                precio,
                metodoController.text.trim().isNotEmpty
                    ? metodoController.text.trim()
                    : null,
                notasController.text.trim().isNotEmpty
                    ? notasController.text.trim()
                    : null,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child:
                const Text('Completar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _completar(
      double precio, String? metodo, String? notas) async {
    setState(() => _isActioning = true);
    final useCase = locator<CompletarTercerizacionUseCase>();
    final result = await useCase(
      id: widget.tercerizacionId,
      precioB2B: precio,
      metodoPagoB2B: metodo,
      notasDestino: notas,
    );

    if (!mounted) return;
    setState(() => _isActioning = false);

    if (result is Success<TercerizacionServicio>) {
      _showSnackBar('Tercerización completada', Colors.green);
      _load();
    } else if (result is Error<TercerizacionServicio>) {
      _showSnackBar(result.message, Colors.red);
    }
  }

  Future<void> _cancelar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar solicitud?',
            style: TextStyle(fontSize: 15)),
        content: const Text(
            'Se cancelará la solicitud de tercerización.',
            style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, cancelar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActioning = true);
    final useCase = locator<CancelarTercerizacionUseCase>();
    final result = await useCase(id: widget.tercerizacionId);

    if (!mounted) return;
    setState(() => _isActioning = false);

    if (result is Success<TercerizacionServicio>) {
      _showSnackBar('Solicitud cancelada', Colors.orange);
      _load();
    } else if (result is Error<TercerizacionServicio>) {
      _showSnackBar(result.message, Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 12)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static const _estadoConfig = {
    'PENDIENTE': {
      'color': Colors.orange,
      'label': 'Pendiente de respuesta',
      'icon': Icons.hourglass_empty,
    },
    'ACEPTADO': {
      'color': Colors.blue,
      'label': 'Aceptado',
      'icon': Icons.check_circle_outline,
    },
    'RECHAZADO': {
      'color': Colors.red,
      'label': 'Rechazado',
      'icon': Icons.cancel_outlined,
    },
    'EN_PROCESO': {
      'color': Colors.indigo,
      'label': 'En proceso',
      'icon': Icons.engineering,
    },
    'COMPLETADO': {
      'color': Colors.green,
      'label': 'Completado',
      'icon': Icons.task_alt,
    },
    'CANCELADO': {
      'color': Colors.grey,
      'label': 'Cancelado',
      'icon': Icons.block,
    },
  };
}

class _TimelineEvent {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final DateTime? date;
  final bool isCompleted;

  const _TimelineEvent({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.isCompleted,
  });
}
