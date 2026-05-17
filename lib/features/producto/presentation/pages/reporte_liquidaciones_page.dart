import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/domain/entities/sede.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/producto_stock.dart' show MotivoLiquidacion, MotivoLiquidacionX;

/// Reporte de liquidaciones y pérdidas comerciales.
/// Llama `GET /reportes-financieros/liquidaciones` y muestra resumen,
/// desglose por motivo y por producto. Permite exportar a Excel.
class ReporteLiquidacionesPage extends StatefulWidget {
  const ReporteLiquidacionesPage({super.key});

  @override
  State<ReporteLiquidacionesPage> createState() =>
      _ReporteLiquidacionesPageState();
}

class _ReporteLiquidacionesPageState extends State<ReporteLiquidacionesPage> {
  final DioClient _dio = locator<DioClient>();
  static final _money = NumberFormat.currency(
      locale: 'es_PE', symbol: 'S/ ', decimalDigits: 2);

  List<Sede> _sedes = [];
  String? _sedeId;
  MotivoLiquidacion? _motivo;
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fechaFin = DateTime.now();

  bool _loading = false;
  bool _exporting = false;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    final state = context.read<EmpresaContextCubit>().state;
    if (state is EmpresaContextLoaded) {
      _sedes = state.context.sedes;
    }
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _dio.get(
        '/reportes-financieros/liquidaciones',
        queryParameters: {
          'fechaInicio': DateFormat('yyyy-MM-dd').format(_fechaInicio),
          'fechaFin': DateFormat('yyyy-MM-dd').format(_fechaFin),
          if (_sedeId != null) 'sedeId': _sedeId,
          if (_motivo != null) 'motivo': _motivo!.apiValue,
        },
      );
      if (mounted) {
        setState(() {
          _data = response.data as Map<String, dynamic>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is DioException
              ? (e.response?.data?['message']?.toString() ?? e.message ?? 'Error')
              : e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _exportar() async {
    setState(() => _exporting = true);
    try {
      final response = await _dio.get(
        '/reportes-financieros/export/liquidaciones',
        queryParameters: {
          'fechaInicio': DateFormat('yyyy-MM-dd').format(_fechaInicio),
          'fechaFin': DateFormat('yyyy-MM-dd').format(_fechaFin),
          if (_sedeId != null) 'sedeId': _sedeId,
          if (_motivo != null) 'motivo': _motivo!.apiValue,
        },
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(minutes: 5),
        ),
      );
      final bytes = response.data as List<int>;
      final fileName =
          'liquidaciones_${DateFormat('yyyyMMdd').format(_fechaInicio)}_${DateFormat('yyyyMMdd').format(_fechaFin)}.xlsx';
      String filePath;
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          filePath = '${downloadDir.path}/$fileName';
        } else {
          final extDir = await getExternalStorageDirectory();
          filePath =
              '${extDir?.path ?? (await getApplicationDocumentsDirectory()).path}/$fileName';
        }
      } else {
        final dir = await getApplicationDocumentsDirectory();
        filePath = '${dir.path}/$fileName';
      }
      await File(filePath).writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exportado: $filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _pickFecha({required bool inicio}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: inicio ? _fechaInicio : _fechaFin,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (inicio) {
          _fechaInicio = picked;
        } else {
          _fechaFin = picked;
        }
      });
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Liquidaciones y pérdidas',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          showLogo: false,
          actions: [
            if (_data != null)
              IconButton(
                icon: _exporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download),
                onPressed: _exporting ? null : _exportar,
                tooltip: 'Exportar a Excel',
              ),
          ],
        ),
        body: Column(
          children: [
            _buildFiltros(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _FechaPicker(
                  label: 'Desde',
                  fecha: _fechaInicio,
                  onTap: () => _pickFecha(inicio: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FechaPicker(
                  label: 'Hasta',
                  fecha: _fechaFin,
                  onTap: () => _pickFecha(inicio: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (_sedes.length > 1) ...[
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _sedeId,
                    decoration: const InputDecoration(
                      labelText: 'Sede',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas')),
                      ..._sedes.map((s) =>
                          DropdownMenuItem(value: s.id, child: Text(s.nombre))),
                    ],
                    onChanged: (v) {
                      setState(() => _sedeId = v);
                      _cargar();
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: DropdownButtonFormField<MotivoLiquidacion?>(
                  initialValue: _motivo,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    ...MotivoLiquidacion.values.map((m) => DropdownMenuItem(
                        value: m, child: Text(m.label))),
                  ],
                  onChanged: (v) {
                    setState(() => _motivo = v);
                    _cargar();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 40),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (_data == null) return const SizedBox.shrink();
    final resumen = _data!['resumen'] as Map<String, dynamic>;
    final porMotivo = (_data!['porMotivo'] as List).cast<Map<String, dynamic>>();
    final porProducto = (_data!['porProducto'] as List).cast<Map<String, dynamic>>();

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildResumenCards(resumen),
          const SizedBox(height: 16),
          if (porMotivo.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.local_fire_department,
                        size: 50, color: Colors.deepOrange.shade300),
                    const SizedBox(height: 8),
                    const Text('Sin ventas bajo costo en el periodo',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            )
          else ...[
            _sectionTitle('Por motivo'),
            ...porMotivo.map(_buildMotivoRow),
            const SizedBox(height: 16),
            _sectionTitle('Por producto'),
            ...porProducto.take(50).map(_buildProductoRow),
            if (porProducto.length > 50)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Mostrando 50 de ${porProducto.length}. Exportá a Excel para ver todos.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildResumenCards(Map<String, dynamic> r) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _ResumenCard(
              titulo: 'Líneas bajo costo',
              valor: '${r['cantidadLineas']}',
              color: AppColors.blue1,
              icon: Icons.list_alt,
            )),
            const SizedBox(width: 8),
            Expanded(
                child: _ResumenCard(
              titulo: 'Ventas afectadas',
              valor: '${r['cantidadVentas']}',
              color: Colors.indigo,
              icon: Icons.receipt_long,
            )),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _ResumenCard(
              titulo: 'Ingreso recuperado',
              valor: _money.format((r['ingresoTotal'] as num).toDouble()),
              color: Colors.green.shade700,
              icon: Icons.trending_up,
            )),
            const SizedBox(width: 8),
            Expanded(
                child: _ResumenCard(
              titulo: 'Pérdida total',
              valor: _money.format((r['perdidaTotal'] as num).toDouble()),
              color: Colors.red.shade700,
              icon: Icons.trending_down,
            )),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMotivoRow(Map<String, dynamic> m) {
    final motivoKey = m['motivo'] as String;
    final motivo = MotivoLiquidacionX.fromApi(motivoKey)?.label ??
        (motivoKey == 'SIN_LIQUIDACION_AUTORIZADA'
            ? 'Autorización gerencial (sin liquidación)'
            : motivoKey);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        title: Text(motivo, style: const TextStyle(fontSize: 13)),
        subtitle: Text('${m['cantidadLineas']} líneas',
            style: const TextStyle(fontSize: 11)),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_money.format((m['perdida'] as num).toDouble()),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700)),
            Text('Pérdida',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductoRow(Map<String, dynamic> p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        title: Text(p['descripcion'] as String,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        subtitle: Text(
          'Cantidad: ${(p['cantidadVendida'] as num).toStringAsFixed(0)}  •  Ingreso: ${_money.format((p['ingreso'] as num).toDouble())}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Text(
          _money.format((p['perdida'] as num).toDouble()),
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700),
        ),
      ),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;
  final IconData icon;
  const _ResumenCard({
    required this.titulo,
    required this.valor,
    required this.color,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _FechaPicker extends StatelessWidget {
  final String label;
  final DateTime fecha;
  final VoidCallback onTap;
  const _FechaPicker({required this.label, required this.fecha, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          isDense: true,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormatter.formatDate(fecha),
                style: const TextStyle(fontSize: 12)),
            Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}
