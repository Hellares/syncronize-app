import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/usecases/export_reportes_usecase.dart';

class ReportesFinancierosPage extends StatefulWidget {
  const ReportesFinancierosPage({super.key});

  @override
  State<ReportesFinancierosPage> createState() => _ReportesFinancierosPageState();
}

class _ReportesFinancierosPageState extends State<ReportesFinancierosPage> {
  // Libro contable
  int _mesSeleccionado = DateTime.now().month;
  int _anioSeleccionado = DateTime.now().year;
  bool _exportingLibro = false;
  double _progressLibro = 0;

  // Cuentas por cobrar
  bool _exportingCobrar = false;
  double _progressCobrar = 0;

  // Cuentas por pagar
  bool _exportingPagar = false;
  double _progressPagar = 0;

  final _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  Future<String> _getDownloadPath(String fileName) async {
    if (Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) return '${downloadDir.path}/$fileName';
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) return '${extDir.path}/$fileName';
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

  Future<void> _exportLibroContable() async {
    setState(() { _exportingLibro = true; _progressLibro = 0; });

    final granted = await _requestStoragePermission();
    if (!granted) {
      _showMessage('Se necesita permiso de almacenamiento', isError: true);
      setState(() => _exportingLibro = false);
      return;
    }

    final useCase = locator<ExportLibroContableUseCase>();
    final result = await useCase(
      mes: _mesSeleccionado,
      anio: _anioSeleccionado,
      onReceiveProgress: (received, total) {
        if (total > 0 && mounted) setState(() => _progressLibro = received / total);
      },
    );

    if (result is Success<List<int>>) {
      final mesStr = _mesSeleccionado.toString().padLeft(2, '0');
      final fileName = 'libro_contable_${mesStr}_$_anioSeleccionado.xlsx';
      final filePath = await _getDownloadPath(fileName);
      await File(filePath).writeAsBytes(result.data);
      _showMessage('Exportado: $filePath');
    } else if (result is Error<List<int>>) {
      _showMessage(result.message, isError: true);
    }

    setState(() => _exportingLibro = false);
  }

  Future<void> _exportCuentasCobrar() async {
    setState(() { _exportingCobrar = true; _progressCobrar = 0; });

    final granted = await _requestStoragePermission();
    if (!granted) {
      _showMessage('Se necesita permiso de almacenamiento', isError: true);
      setState(() => _exportingCobrar = false);
      return;
    }

    final useCase = locator<ExportCuentasCobrarUseCase>();
    final result = await useCase(
      onReceiveProgress: (received, total) {
        if (total > 0 && mounted) setState(() => _progressCobrar = received / total);
      },
    );

    if (result is Success<List<int>>) {
      final fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final fileName = 'cuentas_por_cobrar_$fecha.xlsx';
      final filePath = await _getDownloadPath(fileName);
      await File(filePath).writeAsBytes(result.data);
      _showMessage('Exportado: $filePath');
    } else if (result is Error<List<int>>) {
      _showMessage(result.message, isError: true);
    }

    setState(() => _exportingCobrar = false);
  }

  Future<void> _exportCuentasPagar() async {
    setState(() { _exportingPagar = true; _progressPagar = 0; });

    final granted = await _requestStoragePermission();
    if (!granted) {
      _showMessage('Se necesita permiso de almacenamiento', isError: true);
      setState(() => _exportingPagar = false);
      return;
    }

    final useCase = locator<ExportCuentasPagarUseCase>();
    final result = await useCase(
      onReceiveProgress: (received, total) {
        if (total > 0 && mounted) setState(() => _progressPagar = received / total);
      },
    );

    if (result is Success<List<int>>) {
      final fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final fileName = 'cuentas_por_pagar_$fecha.xlsx';
      final filePath = await _getDownloadPath(fileName);
      await File(filePath).writeAsBytes(result.data);
      _showMessage('Exportado: $filePath');
    } else if (result is Error<List<int>>) {
      _showMessage(result.message, isError: true);
    }

    setState(() => _exportingPagar = false);
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
        title: 'Reportes Financieros',
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Libro Contable Export
              GradientContainer(
                borderColor: AppColors.blueborder,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.menu_book, size: 20, color: Colors.indigo),
                          SizedBox(width: 8),
                          Text('Libro Contable', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Exporta todos los movimientos contables del mes seleccionado con saldo acumulado.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown<int>(
                              label: 'Mes',
                              value: _mesSeleccionado,
                              items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(_meses[i], style: const TextStyle(fontSize: 13)))),
                              onChanged: (v) => setState(() => _mesSeleccionado = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown<int>(
                              label: 'Año',
                              value: _anioSeleccionado,
                              items: List.generate(5, (i) {
                                final y = DateTime.now().year - i;
                                return DropdownMenuItem(value: y, child: Text('$y', style: const TextStyle(fontSize: 13)));
                              }),
                              onChanged: (v) => setState(() => _anioSeleccionado = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildExportButton(
                        loading: _exportingLibro,
                        progress: _progressLibro,
                        color: Colors.indigo,
                        onExport: _exportLibroContable,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Cuentas por Cobrar Export
              _ExportCard(
                icon: Icons.account_balance_wallet,
                color: Colors.orange,
                title: 'Cuentas por Cobrar',
                description: 'Exporta el detalle de todas las ventas a crédito pendientes con saldo, fecha de vencimiento y estado.',
                loading: _exportingCobrar,
                progress: _progressCobrar,
                onExport: _exportCuentasCobrar,
              ),
              const SizedBox(height: 16),

              // Cuentas por Pagar Export
              _ExportCard(
                icon: Icons.receipt_long,
                color: Colors.red,
                title: 'Cuentas por Pagar',
                description: 'Exporta el detalle de todas las compras a crédito pendientes con saldo, proveedor y estado.',
                loading: _exportingPagar,
                progress: _progressPagar,
                onExport: _exportCuentasPagar,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildExportButton({
    required bool loading,
    required double progress,
    required Color color,
    required VoidCallback onExport,
  }) {
    return Column(
      children: [
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
          Text('${(progress * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: loading ? null : onExport,
            icon: loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.download, size: 18),
            label: Text(loading ? (progress > 0 ? 'Descargando...' : 'Generando...') : 'Descargar Excel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ),
      ],
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
  final VoidCallback onExport;

  const _ExportCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.loading,
    required this.progress,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
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
                Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
              Text('${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: loading ? null : onExport,
                icon: loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download, size: 18),
                label: Text(loading ? (progress > 0 ? 'Descargando...' : 'Generando...') : 'Descargar Excel'),
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
