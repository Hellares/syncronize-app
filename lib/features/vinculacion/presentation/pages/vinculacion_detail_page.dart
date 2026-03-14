import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/vinculacion.dart';
import '../../domain/repositories/vinculacion_repository.dart';
import '../../../../core/utils/resource.dart';
import '../bloc/vinculacion_action/vinculacion_action_cubit.dart';
import '../bloc/vinculacion_action/vinculacion_action_state.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';

class VinculacionDetailPage extends StatefulWidget {
  final String vinculacionId;

  const VinculacionDetailPage({super.key, required this.vinculacionId});

  @override
  State<VinculacionDetailPage> createState() => _VinculacionDetailPageState();
}

class _VinculacionDetailPageState extends State<VinculacionDetailPage> {
  VinculacionEmpresa? _vinculacion;
  bool _isLoading = true;
  String? _error;
  String _empresaId = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });

    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _empresaId = empresaState.context.empresa.id;
    }

    final repo = locator<VinculacionRepository>();
    final result = await repo.getById(id: widget.vinculacionId);

    if (!mounted) return;

    if (result is Success<VinculacionEmpresa>) {
      setState(() { _vinculacion = result.data; _isLoading = false; });
    } else if (result is Error<VinculacionEmpresa>) {
      setState(() { _error = result.message; _isLoading = false; });
    }
  }

  bool get _isRecibida => _vinculacion?.empresaVinculadaId == _empresaId;
  bool get _isEnviada => _vinculacion?.empresaSolicitanteId == _empresaId;

  @override
  Widget build(BuildContext context) {
    return BlocListener<VinculacionActionCubit, VinculacionActionState>(
      listener: (context, state) {
        if (state is VinculacionActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.mensaje), backgroundColor: Colors.green),
          );
          _loadData();
        } else if (state is VinculacionActionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: SmartAppBar(
            backgroundColor: AppColors.blue1,
            foregroundColor: AppColors.white,
            title: 'Detalle Vinculacion',
          ),
          body: SafeArea(child: _buildBody()),
          bottomNavigationBar: _buildActions(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CustomLoading());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            TextButton(onPressed: _loadData, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    final item = _vinculacion!;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEstadoCard(item),
            const SizedBox(height: 12),
            _buildEmpresasCard(item),
            const SizedBox(height: 12),
            _buildClienteCard(item),
            if (item.mensaje != null && item.mensaje!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildMensajeCard(item),
            ],
            if (item.isRechazada && item.motivoRechazo != null) ...[
              const SizedBox(height: 12),
              _buildRechazoCard(item),
            ],
            const SizedBox(height: 12),
            _buildTimelineCard(item),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoCard(VinculacionEmpresa item) {
    final config = _estadoConfig[item.estado] ??
        {'color': Colors.grey, 'label': item.estado, 'icon': Icons.help_outline};
    final color = config['color'] as Color;

    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.blueborder,
      borderWidth: 0.6,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(config['icon'] as IconData, size: 24, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config['label'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isEnviada ? 'Solicitud enviada' : 'Solicitud recibida',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (_isEnviada ? Colors.orange : AppColors.blue1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _isEnviada ? Icons.call_made : Icons.call_received,
                size: 16,
                color: _isEnviada ? Colors.orange : AppColors.blue1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpresasCard(VinculacionEmpresa item) {
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
            Text(
              'Empresas',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.blue2,
                fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
              ),
            ),
            const SizedBox(height: 10),
            _empresaRow(
              'Solicitante',
              item.empresaSolicitante?.nombre ?? 'N/A',
              item.empresaSolicitante?.rubro,
              Icons.business,
              Colors.orange,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(Icons.arrow_downward, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Expanded(child: Divider(color: Colors.grey.shade200)),
                ],
              ),
            ),
            _empresaRow(
              'Vinculada',
              item.empresaVinculada?.nombre ?? 'N/A',
              item.empresaVinculada?.rubro,
              Icons.business,
              AppColors.blue1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _empresaRow(String label, String nombre, String? rubro, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade500,
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                ),
              ),
              Text(
                nombre,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue2,
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (rubro != null)
                Text(
                  rubro,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClienteCard(VinculacionEmpresa item) {
    final cliente = item.clienteEmpresa;
    if (cliente == null) return const SizedBox.shrink();

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
            Text(
              'Cliente Empresa',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.blue2,
                fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
              ),
            ),
            const SizedBox(height: 10),
            _detailRow(Icons.business_outlined, 'Razon Social', cliente.razonSocial),
            if (cliente.nombreComercial != null)
              _detailRow(Icons.storefront_outlined, 'Nombre Comercial', cliente.nombreComercial!),
            _detailRow(Icons.badge_outlined, 'RUC', cliente.numeroDocumento),
            if (cliente.email != null)
              _detailRow(Icons.email_outlined, 'Email', cliente.email!),
            if (cliente.telefono != null)
              _detailRow(Icons.phone_outlined, 'Telefono', cliente.telefono!),
          ],
        ),
      ),
    );
  }

  Widget _buildMensajeCard(VinculacionEmpresa item) {
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
            Text(
              'Mensaje',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.blue2,
                fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.mensaje!,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                height: 1.4,
                fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRechazoCard(VinculacionEmpresa item) {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      shadowStyle: ShadowStyle.glow,
      borderColor: Colors.red.shade200,
      borderWidth: 0.6,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cancel_outlined, size: 16, color: Colors.red.shade400),
                const SizedBox(width: 6),
                Text(
                  'Motivo de Rechazo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade700,
                    fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.motivoRechazo!,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                height: 1.4,
                fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(VinculacionEmpresa item) {
    final events = <_TimelineEvent>[
      _TimelineEvent(
        'Solicitud enviada',
        DateFormatter.formatDateTime(item.fechaSolicitud),
        Icons.send,
        AppColors.blue1,
        true,
      ),
    ];

    if (item.fechaRespuesta != null) {
      final isAccepted = item.isAceptada || item.isDesvinculada;
      events.add(_TimelineEvent(
        isAccepted ? 'Solicitud aceptada' : (item.isRechazada ? 'Solicitud rechazada' : 'Respondida'),
        DateFormatter.formatDateTime(item.fechaRespuesta!),
        isAccepted ? Icons.check_circle : Icons.cancel,
        isAccepted ? Colors.green : Colors.red,
        true,
      ));
    }

    if (item.isDesvinculada) {
      events.add(_TimelineEvent(
        'Desvinculada',
        '',
        Icons.link_off,
        Colors.blueGrey,
        true,
      ));
    }

    if (item.isCancelada) {
      events.add(_TimelineEvent(
        'Cancelada',
        '',
        Icons.block,
        Colors.grey,
        true,
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
            Text(
              'Timeline',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.blue2,
                fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
              ),
            ),
            const SizedBox(height: 10),
            ...events.asMap().entries.map((entry) {
              final i = entry.key;
              final event = entry.value;
              final isLast = i == events.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Icon(event.icon, size: 18, color: event.color),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 24,
                          color: Colors.grey.shade300,
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blue2,
                              fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                            ),
                          ),
                          if (event.subtitle.isNotEmpty)
                            Text(
                              event.subtitle,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                                fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade500,
                    fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.blue2,
                    fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildActions() {
    final item = _vinculacion;
    if (item == null) return null;

    final buttons = <Widget>[];

    // Recibida + PENDIENTE → Aceptar / Rechazar
    if (_isRecibida && item.isPendiente) {
      buttons.addAll([
        Expanded(
          child: CustomButton(
            text: 'Rechazar',
            onPressed: () => _showRechazarDialog(),
            isOutlined: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CustomButton(
            text: 'Aceptar',
            onPressed: () => _aceptar(),
          ),
        ),
      ]);
    }

    // Enviada + PENDIENTE → Cancelar
    if (_isEnviada && item.isPendiente) {
      buttons.add(
        Expanded(
          child: CustomButton(
            text: 'Cancelar Solicitud',
            onPressed: () => _showCancelarDialog(),
            isOutlined: true,
          ),
        ),
      );
    }

    // ACEPTADA → Desvincular (cualquier parte)
    if (item.isAceptada) {
      buttons.add(
        Expanded(
          child: CustomButton(
            text: 'Desvincular',
            onPressed: () => _showDesvincularDialog(),
            isOutlined: true,
          ),
        ),
      );
    }

    if (buttons.isEmpty) return null;

    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 14, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(children: buttons),
    );
  }

  void _aceptar() {
    context.read<VinculacionActionCubit>().aceptar(widget.vinculacionId);
  }

  void _showRechazarDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rechazar vinculacion', style: TextStyle(fontSize: 14)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Motivo de rechazo',
            hintText: 'Indica por que rechazas...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(dialogContext);
              context.read<VinculacionActionCubit>().rechazar(
                widget.vinculacionId,
                controller.text.trim(),
              );
            },
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  void _showCancelarDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar solicitud', style: TextStyle(fontSize: 14)),
        content: const Text('¿Estas seguro de cancelar esta solicitud de vinculacion?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<VinculacionActionCubit>().cancelar(widget.vinculacionId);
            },
            child: const Text('Si, cancelar'),
          ),
        ],
      ),
    );
  }

  void _showDesvincularDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desvincular empresas', style: TextStyle(fontSize: 14)),
        content: const Text('¿Estas seguro de desvincular estas empresas? Se eliminara la referencia de vinculacion.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<VinculacionActionCubit>().desvincular(widget.vinculacionId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );
  }

  static const _estadoConfig = {
    'PENDIENTE': {'color': Colors.orange, 'label': 'Pendiente de respuesta', 'icon': Icons.hourglass_empty},
    'ACEPTADA': {'color': Colors.green, 'label': 'Vinculacion aceptada', 'icon': Icons.check_circle_outline},
    'RECHAZADA': {'color': Colors.red, 'label': 'Vinculacion rechazada', 'icon': Icons.cancel_outlined},
    'CANCELADA': {'color': Colors.grey, 'label': 'Solicitud cancelada', 'icon': Icons.block},
    'DESVINCULADA': {'color': Colors.blueGrey, 'label': 'Empresas desvinculadas', 'icon': Icons.link_off},
  };
}

class _TimelineEvent {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool completed;

  _TimelineEvent(this.title, this.subtitle, this.icon, this.color, this.completed);
}
