import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
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
import '../widgets/cita_estado_badge.dart';

class CitaDetailPage extends StatefulWidget {
  final String citaId;
  const CitaDetailPage({super.key, required this.citaId});

  @override
  State<CitaDetailPage> createState() => _CitaDetailPageState();
}

class _CitaDetailPageState extends State<CitaDetailPage> {
  Cita? _cita;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCita();
  }

  Future<void> _loadCita() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await locator<CitaRepository>().findOne(widget.citaId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result is Success<Cita>) {
        _cita = result.data;
      } else if (result is Error<Cita>) {
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
          _loadCita();
        } else if (state is CitaFormError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: RefreshIndicator(
        onRefresh: _loadCita,
        color: AppColors.blue1,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _buildInfoCard(),
            const SizedBox(height: 10),
            _buildClienteCard(),
            const SizedBox(height: 10),
            _buildServicioCard(),
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
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Completar cita'),
          content: Column(
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
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Volver')),
            CustomButton(
              text: 'Completar',
              backgroundColor: AppColors.green,
              onPressed: () {
                Navigator.pop(ctx);
                context.read<CitaFormCubit>().cambiarEstado(
                      id: _cita!.id,
                      nuevoEstado: 'COMPLETADA',
                      generarOrden: generarOrden,
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
