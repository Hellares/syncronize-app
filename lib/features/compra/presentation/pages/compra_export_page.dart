import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/usecases/export_compra_analytics_usecase.dart';

class CompraExportPage extends StatefulWidget {
  final String empresaId;

  const CompraExportPage({super.key, required this.empresaId});

  @override
  State<CompraExportPage> createState() => _CompraExportPageState();
}

class _CompraExportPageState extends State<CompraExportPage> {
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fechaFin = DateTime.now();
  bool _exportingProductos = false;
  bool _exportingProveedores = false;
  double _progressProductos = 0;
  double _progressProveedores = 0;

  final _df = DateFormat('dd/MM/yyyy');
  final _dfApi = DateFormat('yyyy-MM-dd');

  static const _maxMonths = 3;

  bool get _rangoExcedido {
    final diff = DateTime(_fechaFin.year, _fechaFin.month + 1, 0)
        .difference(DateTime(_fechaInicio.year, _fechaInicio.month, 1));
    return diff.inDays > _maxMonths * 31;
  }

  Future<void> _selectDate(bool isInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isInicio ? _fechaInicio : _fechaFin,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isInicio) {
          _fechaInicio = picked;
          if (_fechaInicio.isAfter(_fechaFin)) _fechaFin = _fechaInicio;
          // Auto-ajustar fin si excede 3 meses
          final maxFin = DateTime(_fechaInicio.year, _fechaInicio.month + _maxMonths, _fechaInicio.day);
          if (_fechaFin.isAfter(maxFin)) _fechaFin = maxFin.isAfter(DateTime.now()) ? DateTime.now() : maxFin;
        } else {
          _fechaFin = picked;
          if (_fechaFin.isBefore(_fechaInicio)) _fechaInicio = _fechaFin;
          // Auto-ajustar inicio si excede 3 meses
          final minInicio = DateTime(_fechaFin.year, _fechaFin.month - _maxMonths, _fechaFin.day);
          if (_fechaInicio.isBefore(minInicio)) _fechaInicio = minInicio;
        }
      });
    }
  }

  Future<String> _getDownloadPath(String fileName) async {
    if (Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        return '${downloadDir.path}/$fileName';
      }
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        return '${extDir.path}/$fileName';
      }
    }
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$fileName';
  }

  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;
    final storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) return true;
    final manageStatus = await Permission.manageExternalStorage.request();
    return manageStatus.isGranted;
  }

  Future<void> _exportPorProducto() async {
    setState(() {
      _exportingProductos = true;
      _progressProductos = 0;
    });

    final granted = await _requestStoragePermission();
    if (!granted) {
      _showMessage('Se necesita permiso de almacenamiento', isError: true);
      setState(() => _exportingProductos = false);
      return;
    }

    final useCase = locator<ExportComprasPorProductoUseCase>();
    final result = await useCase(
      empresaId: widget.empresaId,
      fechaInicio: _dfApi.format(_fechaInicio),
      fechaFin: _dfApi.format(_fechaFin),
      onReceiveProgress: (received, total) {
        if (total > 0 && mounted) {
          setState(() => _progressProductos = received / total);
        }
      },
    );

    if (result is Success<List<int>>) {
      final fileName = 'compras_productos_${_dfApi.format(_fechaInicio)}_${_dfApi.format(_fechaFin)}.xlsx';
      final filePath = await _getDownloadPath(fileName);
      final file = File(filePath);
      await file.writeAsBytes(result.data);
      _showMessage('Exportado: $filePath');
    } else if (result is Error<List<int>>) {
      _showMessage(result.message, isError: true);
    }

    setState(() => _exportingProductos = false);
  }

  Future<void> _exportPorProveedor() async {
    setState(() {
      _exportingProveedores = true;
      _progressProveedores = 0;
    });

    final granted = await _requestStoragePermission();
    if (!granted) {
      _showMessage('Se necesita permiso de almacenamiento', isError: true);
      setState(() => _exportingProveedores = false);
      return;
    }

    final useCase = locator<ExportComprasPorProveedorUseCase>();
    final result = await useCase(
      empresaId: widget.empresaId,
      fechaInicio: _dfApi.format(_fechaInicio),
      fechaFin: _dfApi.format(_fechaFin),
      onReceiveProgress: (received, total) {
        if (total > 0 && mounted) {
          setState(() => _progressProveedores = received / total);
        }
      },
    );

    if (result is Success<List<int>>) {
      final fileName = 'compras_proveedores_${_dfApi.format(_fechaInicio)}_${_dfApi.format(_fechaFin)}.xlsx';
      final filePath = await _getDownloadPath(fileName);
      final file = File(filePath);
      await file.writeAsBytes(result.data);
      _showMessage('Exportado: $filePath');
    } else if (result is Error<List<int>>) {
      _showMessage(result.message, isError: true);
    }

    setState(() => _exportingProveedores = false);
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 12)),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        duration: Duration(seconds: isError ? 4 : 6),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
        title: 'Exportar Compras',
      ),
      body: GradientBackground(
        style: GradientStyle.minimal,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Range Selection
              GradientContainer(
                shadowStyle: ShadowStyle.neumorphic,
                borderColor: AppColors.blueborder,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.date_range, size: 18, color: AppColors.blue1),
                          SizedBox(width: 8),
                          Text(
                            'Rango de Fechas',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _DateButton(
                              label: 'Desde',
                              date: _df.format(_fechaInicio),
                              onTap: () => _selectDate(true),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                          ),
                          Expanded(
                            child: _DateButton(
                              label: 'Hasta',
                              date: _df.format(_fechaFin),
                              onTap: () => _selectDate(false),
                            ),
                          ),
                        ],
                      ),
                      if (_rangoExcedido) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange.shade700),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'El rango maximo es de $_maxMonths meses',
                                style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Export por Producto
              _ExportCard(
                icon: Icons.inventory_2,
                color: Colors.blue,
                title: 'Exportar por Producto',
                description:
                    'Genera un Excel con el detalle de cada producto comprado: '
                    'cantidad, precio unitario, descuento, IGV, subtotal, total. '
                    'Incluye hoja de resumen agrupado por producto.',
                loading: _exportingProductos,
                progress: _progressProductos,
                enabled: !_rangoExcedido,
                onExport: _exportPorProducto,
              ),
              const SizedBox(height: 16),

              // Export por Proveedor
              _ExportCard(
                icon: Icons.local_shipping,
                color: Colors.teal,
                title: 'Exportar por Proveedor',
                description:
                    'Genera un Excel con resumen por proveedor (total compras, '
                    'monto total, descuentos, impuestos) y detalle de cada compra.',
                loading: _exportingProveedores,
                progress: _progressProveedores,
                enabled: !_rangoExcedido,
                onExport: _exportPorProveedor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String date;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppColors.blue1),
                const SizedBox(width: 6),
                Text(date, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool loading;
  final double progress;
  final bool enabled;
  final VoidCallback onExport;

  const _ExportCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.loading,
    required this.progress,
    this.enabled = true,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            if (loading && progress > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: loading || !enabled ? null : onExport,
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.download, size: 18),
                label: Text(loading
                    ? (progress > 0 ? 'Descargando...' : 'Generando...')
                    : 'Descargar Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
