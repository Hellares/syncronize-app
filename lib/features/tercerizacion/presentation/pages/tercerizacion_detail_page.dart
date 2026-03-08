import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
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
        padding: const EdgeInsets.all(16),
        children: [
          _buildEstadoHeader(item),
          const SizedBox(height: 12),
          _buildEmpresasSection(item),
          const SizedBox(height: 12),
          _buildEquipoSection(item),
          if (item.componentesData != null && item.componentesData is List && (item.componentesData as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildComponentesSection(item),
          ],
          if (item.descripcionProblema != null) ...[
            const SizedBox(height: 12),
            _buildProblemaSection(item),
          ],
          if (item.ordenOrigen != null || item.ordenDestino != null) ...[
            const SizedBox(height: 12),
            _buildOrdenesSection(item),
          ],
          if (item.precioB2B != null) ...[
            const SizedBox(height: 12),
            _buildPrecioSection(item),
          ],
          if (item.notasOrigen != null || item.notasDestino != null) ...[
            const SizedBox(height: 12),
            _buildNotasSection(item),
          ],
          if (item.motivoRechazo != null) ...[
            const SizedBox(height: 12),
            _buildRechazoSection(item),
          ],
          const SizedBox(height: 12),
          _buildFechasSection(item),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ─── Estado Header ───

  Widget _buildEstadoHeader(TercerizacionServicio item) {
    final config = _estadoConfig[item.estado] ??
        {'color': Colors.grey, 'label': item.estado, 'icon': Icons.help};

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (config['color'] as Color).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(config['icon'] as IconData,
                  color: config['color'] as Color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config['label'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: config['color'] as Color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        _isEnviada ? Icons.call_made : Icons.call_received,
                        size: 14,
                        color: _isEnviada ? Colors.orange : AppColors.blue1,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isEnviada ? 'Enviada por ti' : 'Recibida',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isEnviada ? Colors.orange : AppColors.blue1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empresas ───

  Widget _buildEmpresasSection(TercerizacionServicio item) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Empresas',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _buildEmpresaRow(
              label: 'Origen',
              empresa: item.empresaOrigen,
              icon: Icons.call_made,
              color: Colors.orange,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(width: 16),
                  Icon(Icons.arrow_downward, size: 16, color: Colors.grey),
                ],
              ),
            ),
            _buildEmpresaRow(
              label: 'Destino',
              empresa: item.empresaDestino,
              icon: Icons.call_received,
              color: AppColors.blue1,
            ),
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
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: 0.1),
          backgroundImage:
              empresa?.logo != null ? NetworkImage(empresa!.logo!) : null,
          child: empresa?.logo == null
              ? Icon(icon, size: 16, color: color)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                empresa?.nombre ?? 'Empresa $label',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              if (empresa?.rubro != null)
                Text(empresa!.rubro!,
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Equipo ───

  Widget _buildEquipoSection(TercerizacionServicio item) {
    final datos = item.datosEquipo;
    final tipoEquipo = datos['tipoEquipo'] as String? ?? '';
    final marcaEquipo = datos['marcaEquipo'] as String? ?? '';
    final modeloEquipo = datos['modeloEquipo'] as String? ?? '';
    final serieEquipo = datos['serieEquipo'] as String? ?? '';

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.devices, size: 16, color: AppColors.blue1),
                const SizedBox(width: 6),
                const Text('Datos del Equipo',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
            if (tipoEquipo.isNotEmpty)
              _infoRow('Tipo', tipoEquipo),
            if (marcaEquipo.isNotEmpty)
              _infoRow('Marca', marcaEquipo),
            if (modeloEquipo.isNotEmpty)
              _infoRow('Modelo', modeloEquipo),
            if (serieEquipo.isNotEmpty)
              _infoRow('Serie', serieEquipo),
          ],
        ),
      ),
    );
  }

  // ─── Componentes ───

  Widget _buildComponentesSection(TercerizacionServicio item) {
    final componentes = item.componentesData as List;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.memory, size: 16, color: AppColors.blue1),
                const SizedBox(width: 6),
                Text('Componentes (${componentes.length})',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
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

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            nombre.isNotEmpty ? nombre : codigo,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (tipoAccion.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _accionColor(tipoAccion).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tipoAccion.replaceAll('_', ' '),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: _accionColor(tipoAccion),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (codigo.isNotEmpty && nombre.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('Código: $codigo',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade500)),
                    ],
                    if (descripcionAccion.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(descripcionAccion,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade700)),
                    ],
                    if (observaciones.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('Obs: $observaciones',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic)),
                    ],
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

  // ─── Problema ───

  Widget _buildProblemaSection(TercerizacionServicio item) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.report_problem_outlined,
                    size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                const Text('Problema',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.descripcionProblema!,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            if (item.sintomas != null && item.sintomas is List) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: (item.sintomas as List)
                    .map((s) => Chip(
                          label: Text(s.toString(),
                              style: const TextStyle(fontSize: 10)),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Órdenes vinculadas ───

  Widget _buildOrdenesSection(TercerizacionServicio item) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, size: 16, color: AppColors.blue1),
                const SizedBox(width: 6),
                const Text('Órdenes vinculadas',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
            if (item.ordenOrigen != null)
              _ordenRow('Orden origen', item.ordenOrigen!),
            if (item.ordenOrigen != null && item.ordenDestino != null)
              const SizedBox(height: 8),
            if (item.ordenDestino != null)
              _ordenRow('Orden destino', item.ordenDestino!),
          ],
        ),
      ),
    );
  }

  Widget _ordenRow(String label, OrdenResumen orden) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          const SizedBox(height: 2),
          Text(orden.codigo,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          if (orden.estado != null) ...[
            const SizedBox(height: 2),
            Text('Estado: ${orden.estado}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ],
      ),
    );
  }

  // ─── Precio ───

  Widget _buildPrecioSection(TercerizacionServicio item) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments_outlined, size: 16, color: Colors.green),
                const SizedBox(width: 6),
                const Text('Precio B2B',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'S/ ${item.precioB2B!.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
            ),
            if (item.metodoPagoB2B != null)
              Text('Método: ${item.metodoPagoB2B}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  // ─── Notas ───

  Widget _buildNotasSection(TercerizacionServicio item) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notas',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (item.notasOrigen != null) ...[
              _infoRow('Origen', item.notasOrigen!),
            ],
            if (item.notasDestino != null) ...[
              _infoRow('Destino', item.notasDestino!),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Rechazo ───

  Widget _buildRechazoSection(TercerizacionServicio item) {
    return GradientContainer(
      borderColor: Colors.red.shade200,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.block, size: 16, color: Colors.red),
                const SizedBox(width: 6),
                const Text('Motivo de rechazo',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.motivoRechazo!,
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Fechas ───

  Widget _buildFechasSection(TercerizacionServicio item) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fechas',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _infoRow('Solicitud', DateFormatter.formatDate(item.fechaSolicitud)),
            if (item.fechaRespuesta != null)
              _infoRow(
                  'Respuesta', DateFormatter.formatDate(item.fechaRespuesta!)),
            if (item.fechaCompletado != null)
              _infoRow(
                  'Completado', DateFormatter.formatDate(item.fechaCompletado!)),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ───

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12)),
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
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isActioning ? null : () => _showRechazarDialog(),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Rechazar', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isActioning ? null : () => _aceptar(),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Aceptar', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ]);
    }

    // Empresa destino puede completar si ACEPTADO o EN_PROCESO
    if (_isRecibida && (item.isAceptado || item.estado == 'EN_PROCESO')) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isActioning ? null : () => _showCompletarDialog(),
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: const Text('Completar', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      );
    }

    // Empresa origen puede cancelar si PENDIENTE
    if (_isEnviada && item.isPendiente) {
      buttons.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isActioning ? null : () => _cancelar(),
            icon: const Icon(Icons.cancel_outlined, size: 16),
            label: const Text('Cancelar solicitud',
                style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      );
    }

    if (buttons.isEmpty) return null;

    return Container(
      padding: const EdgeInsets.all(16),
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
              child: CircularProgressIndicator(),
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
