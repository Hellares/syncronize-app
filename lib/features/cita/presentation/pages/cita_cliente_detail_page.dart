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
import '../../../servicio/presentation/widgets/mensajes_orden_widget.dart';

class CitaClienteDetailPage extends StatefulWidget {
  final String citaId;

  const CitaClienteDetailPage({super.key, required this.citaId});

  @override
  State<CitaClienteDetailPage> createState() => _CitaClienteDetailPageState();
}

class _CitaClienteDetailPageState extends State<CitaClienteDetailPage> {
  final _dio = locator<DioClient>();

  Map<String, dynamic>? _cita;
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
        _dio.get('${ApiConstants.citas}/mis-citas/${widget.citaId}'),
        _dio.get('${ApiConstants.citas}/mis-citas/${widget.citaId}/historial'),
      ]);

      setState(() {
        _cita = results[0].data as Map<String, dynamic>;
        _historial = results[1].data as List;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar la cita';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar.withBackButton(
        title: 'Mi Cita',
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
                        if (_cita?['costoTotal'] != null)
                          ...[_buildCostosCard(), const SizedBox(height: 16)],
                        if (_cita?['ordenServicio'] != null)
                          ...[_buildOrdenVinculadaCard(), const SizedBox(height: 16)],
                        _buildTimelineCard(),
                        const SizedBox(height: 16),
                        MensajesOrdenWidget(
                          citaId: widget.citaId,
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
    final estado = _cita?['estado'] as String? ?? '';
    final codigo = _cita?['codigo'] as String? ?? '';
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: estadoColor),
            ),
          ),
          if (_cita?['motivoCancelacion'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Motivo: ${_cita!['motivoCancelacion']}',
              style: TextStyle(fontSize: 13, color: Colors.red[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final fecha = _cita?['fecha'] as String?;
    String fechaFormateada = '';
    if (fecha != null) {
      try {
        final date = DateTime.parse(fecha).toLocal();
        fechaFormateada = DateFormat('EEEE dd/MM/yyyy', 'es').format(date);
      } catch (_) {
        fechaFormateada = fecha;
      }
    }

    return GradientContainer(
      borderColor: AppColors.blueborder,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, size: 18, color: AppColors.blue1),
              const SizedBox(width: 6),
              const Text('Información de la Cita',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(),
          if (fechaFormateada.isNotEmpty)
            _infoRow(Icons.event, 'Fecha', fechaFormateada),
          if (_cita?['horaInicio'] != null && _cita?['horaFin'] != null)
            _infoRow(Icons.access_time, 'Horario',
                '${_cita!['horaInicio']} - ${_cita!['horaFin']}'),
          if (_cita?['servicio'] != null)
            _infoRow(Icons.build, 'Servicio', _cita!['servicio']['nombre']),
          if (_cita?['sede'] != null)
            _infoRow(Icons.store, 'Sede', _cita!['sede']['nombre']),
          if (_cita?['notas'] != null && (_cita!['notas'] as String).isNotEmpty)
            _infoRow(Icons.notes, 'Notas', _cita!['notas']),
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
          if (_cita?['costoServicio'] != null)
            _costoRow('Servicio', _cita!['costoServicio']),
          if (_cita?['costoProductos'] != null && _cita!['costoProductos'] > 0)
            _costoRow('Productos', _cita!['costoProductos']),
          if (_cita?['descuento'] != null && _cita!['descuento'] > 0)
            _costoRow('Descuento', -_cita!['descuento']),
          if (_cita?['costoTotal'] != null) ...[
            const Divider(),
            _costoRow('Total', _cita!['costoTotal'], bold: true),
          ],
          if (_cita?['adelanto'] != null && _cita!['adelanto'] > 0)
            _costoRow('Adelanto', _cita!['adelanto'], color: Colors.green),
        ],
      ),
    );
  }

  Widget _buildOrdenVinculadaCard() {
    final orden = _cita!['ordenServicio'] as Map<String, dynamic>;
    return GradientContainer(
      borderColor: Colors.purple.shade200,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.link, size: 18, color: Colors.purple[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Orden de servicio vinculada',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                Text(
                  '${orden['codigo']} - ${_formatEstado(orden['estado'])}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _costoRow(String label, num value, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.w600 : null)),
          Text(
            'S/ ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: color ?? (value < 0 ? Colors.red : null),
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

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'CONFIRMADA':
        return Colors.blue;
      case 'EN_PROCESO':
        return Colors.indigo;
      case 'COMPLETADA':
        return Colors.green;
      case 'CANCELADA':
        return Colors.red;
      case 'NO_ASISTIO':
        return Colors.grey[700]!;
      default:
        return Colors.grey;
    }
  }
}

class _TimelineItem extends StatelessWidget {
  final String estadoNuevo;
  final String? notas;
  final String? fecha;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.estadoNuevo,
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatEstado(estadoNuevo),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
                  ),
                  if (notas != null && notas!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(notas!, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                  const SizedBox(height: 2),
                  Text(fechaFormateada, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
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
      case 'PENDIENTE': return Colors.orange;
      case 'CONFIRMADA': return Colors.blue;
      case 'EN_PROCESO': return Colors.indigo;
      case 'COMPLETADA': return Colors.green;
      case 'CANCELADA': return Colors.red;
      case 'NO_ASISTIO': return Colors.grey[700]!;
      default: return Colors.grey;
    }
  }
}
