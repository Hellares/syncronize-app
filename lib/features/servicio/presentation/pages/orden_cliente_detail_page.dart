import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../widgets/mensajes_orden_widget.dart';

class OrdenClienteDetailPage extends StatefulWidget {
  final String ordenId;

  const OrdenClienteDetailPage({super.key, required this.ordenId});

  @override
  State<OrdenClienteDetailPage> createState() => _OrdenClienteDetailPageState();
}

class _OrdenClienteDetailPageState extends State<OrdenClienteDetailPage> {
  final _dio = locator<DioClient>();

  Map<String, dynamic>? _orden;
  List<dynamic> _historial = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _dio.get('${ApiConstants.ordenesServicio}/mis-ordenes/${widget.ordenId}'),
        _dio.get('${ApiConstants.ordenesServicio}/mis-ordenes/${widget.ordenId}/historial'),
      ]);

      setState(() {
        _orden = results[0].data as Map<String, dynamic>;
        _historial = results[1].data as List;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar la orden';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar.withBackButton(
        title: 'Mi Orden de Servicio',
        onBack: () => context.pop(),
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(_error!),
                        const SizedBox(height: 8),
                        TextButton(onPressed: _loadAll, child: const Text('Reintentar')),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAll,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildEstadoCard(),
                        const SizedBox(height: 16),
                        _buildInfoCard(),
                        const SizedBox(height: 16),
                        if (_orden?['descripcionProblema'] != null ||
                            _orden?['diagnostico'] != null)
                          ...[_buildDescripcionCard(), const SizedBox(height: 16)],
                        if (_orden?['costoTotal'] != null)
                          ...[_buildCostosCard(), const SizedBox(height: 16)],
                        if ((_orden?['componentes'] as List?)?.isNotEmpty ?? false)
                          ...[_buildComponentesCard(), const SizedBox(height: 16)],
                        _buildTimelineCard(),
                        const SizedBox(height: 16),
                        MensajesOrdenWidget(
                          ordenId: widget.ordenId,
                          esCliente: true,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildEstadoCard() {
    final estado = _orden?['estado'] as String? ?? '';
    final prioridad = _orden?['prioridad'] as String? ?? '';
    final codigo = _orden?['codigo'] as String? ?? '';

    final estadoColor = _getEstadoColor(estado);

    return GradientContainer(
      borderColor: estadoColor,
      borderWidth: 1.0,
      shadowStyle: ShadowStyle.colorful,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(codigo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: estadoColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: estadoColor),
            ),
            child: Text(
              _formatEstado(estado),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: estadoColor,
              ),
            ),
          ),
          if (prioridad.isNotEmpty && prioridad != 'NORMAL') ...[
            const SizedBox(height: 8),
            Text(
              'Prioridad: ${_formatEstado(prioridad)}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: AppColors.blue1),
              const SizedBox(width: 6),
              const Text('Información', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(),
            if (_orden?['servicio'] != null)
              _infoRow(Icons.build, 'Servicio', _orden!['servicio']['nombre']),
            if (_orden?['tipoServicio'] != null)
              _infoRow(Icons.category, 'Tipo', _formatEstado(_orden!['tipoServicio'])),
            if (_orden?['tipoEquipo'] != null)
              _infoRow(Icons.devices, 'Equipo', _orden!['tipoEquipo']),
            if (_orden?['marcaEquipo'] != null)
              _infoRow(Icons.label, 'Marca', _orden!['marcaEquipo']),
            if (_orden?['modeloEquipo'] != null)
              _infoRow(Icons.phone_android, 'Modelo', _orden!['modeloEquipo']),
            if (_orden?['numeroSerie'] != null)
              _infoRow(Icons.numbers, 'N° Serie', _orden!['numeroSerie']),
            if (_orden?['fechaEntrega'] != null)
              _infoRow(Icons.event, 'Fecha entrega',
                  _formatDate(_orden!['fechaEntrega'])),
            _infoRow(Icons.calendar_today, 'Fecha ingreso',
                _formatDate(_orden!['creadoEn'])),
          ],
        ),
      );
  }

  Widget _buildDescripcionCard() {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, size: 18, color: AppColors.blue1),
              const SizedBox(width: 6),
              const Text('Detalles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(),
            if (_orden?['descripcionProblema'] != null) ...[
              const Text('Problema reportado',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(_orden!['descripcionProblema'], style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
            ],
            if (_orden?['diagnostico'] != null) ...[
              const Text('Diagnóstico',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                _orden!['diagnostico'] is Map
                    ? (_orden!['diagnostico']['descripcion'] ?? 'En proceso')
                    : _orden!['diagnostico'].toString(),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      );
  }

  Widget _buildCostosCard() {
    return GradientContainer(
      gradient: AppGradients.green(),
      borderColor: Colors.green.shade200,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, size: 18, color: Colors.green[700]),
              const SizedBox(width: 6),
              const Text('Costos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(),
            if (_orden?['costoTotal'] != null)
              _costoRow('Costo total', _orden!['costoTotal']),
            if (_orden?['descuento'] != null && _orden!['descuento'] > 0)
              _costoRow('Descuento', -_orden!['descuento']),
            if (_orden?['adelanto'] != null && _orden!['adelanto'] > 0)
              _costoRow('Adelanto', _orden!['adelanto'], color: Colors.green),
          ],
        ),
      );
  }

  Widget _buildComponentesCard() {
    final componentes = _orden?['componentes'] as List? ?? [];
    return GradientContainer(
      borderColor: AppColors.blueborder,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.memory, size: 18, color: AppColors.blue1),
              const SizedBox(width: 6),
              const Text('Componentes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(),
            ...componentes.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.memory, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${c['nombre']}${c['tipo'] != null ? ' (${c['tipo']})' : ''}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      if (c['costoAccion'] != null)
                        Text(
                          'S/ ${(c['costoAccion'] as num).toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                )),
          ],
        ),
      );
  }

  Widget _buildTimelineCard() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      shadowStyle: ShadowStyle.colorful,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, size: 18, color: AppColors.blue1),
              const SizedBox(width: 6),
              const Text('Timeline de Estado',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(),
            if (_historial.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('Sin cambios registrados',
                      style: TextStyle(color: Colors.grey[500])),
                ),
              )
            else
              ...List.generate(_historial.length, (index) {
                final item = _historial[index];
                final isLast = index == _historial.length - 1;
                return _TimelineItem(
                  estadoNuevo: item['estadoNuevo'] as String? ?? '',
                  estadoAnterior: item['estadoAnterior'] as String?,
                  notas: item['notas'] as String?,
                  fecha: item['creadoEn'] as String?,
                  isFirst: index == 0,
                  isLast: isLast,
                );
              }),
          ],
        ),
      );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.blue1),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _costoRow(String label, num value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            'S/ ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color ?? (value < 0 ? Colors.red : null),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatEstado(String estado) {
    return estado.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'RECIBIDO':
        return Colors.blue;
      case 'EN_DIAGNOSTICO':
        return Colors.orange;
      case 'ESPERANDO_APROBACION':
        return Colors.amber[700]!;
      case 'APROBADO':
        return Colors.teal;
      case 'EN_REPARACION':
      case 'EN_PROCESO':
        return Colors.indigo;
      case 'REPARADO':
      case 'COMPLETADO':
        return Colors.green;
      case 'ENTREGADO':
        return Colors.green[800]!;
      case 'CANCELADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _TimelineItem extends StatelessWidget {
  final String estadoNuevo;
  final String? estadoAnterior;
  final String? notas;
  final String? fecha;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.estadoNuevo,
    this.estadoAnterior,
    this.notas,
    this.fecha,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    String fechaFormateada = '';
    if (fecha != null) {
      try {
        final date = DateTime.parse(fecha!).toLocal();
        fechaFormateada = DateFormat('dd/MM/yyyy HH:mm').format(date);
      } catch (_) {}
    }

    final color = _getColor(estadoNuevo);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(child: Container(width: 2, color: Colors.grey[300])),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isLast ? color : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: Colors.grey[300])),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatEstado(estadoNuevo),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  if (notas != null && notas!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(notas!, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                  const SizedBox(height: 2),
                  Text(fechaFormateada,
                      style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatEstado(String estado) {
    return estado.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  Color _getColor(String estado) {
    switch (estado) {
      case 'RECIBIDO':
        return Colors.blue;
      case 'EN_DIAGNOSTICO':
        return Colors.orange;
      case 'ESPERANDO_APROBACION':
        return Colors.amber[700]!;
      case 'APROBADO':
        return Colors.teal;
      case 'EN_REPARACION':
      case 'EN_PROCESO':
        return Colors.indigo;
      case 'REPARADO':
      case 'COMPLETADO':
        return Colors.green;
      case 'ENTREGADO':
        return Colors.green[800]!;
      case 'CANCELADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
