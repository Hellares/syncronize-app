import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text.dart' show CustomText;

class PrestamosPage extends StatefulWidget {
  const PrestamosPage({super.key});

  @override
  State<PrestamosPage> createState() => _PrestamosPageState();
}

class _PrestamosPageState extends State<PrestamosPage> {
  final _dio = locator<DioClient>();
  final _currencyFormat = NumberFormat.currency(locale: 'es_PE', symbol: 'S/');

  List<Map<String, dynamic>> _prestamos = [];
  Map<String, dynamic>? _resumen;
  bool _isLoading = true;
  String _filtroEstado = 'TODOS';

  final List<String> _filtros = ['TODOS', 'ACTIVO', 'PAGADO', 'VENCIDO'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _dio.get('/prestamos/resumen'),
        _dio.get('/prestamos'),
      ]);
      if (mounted) {
        setState(() {
          _resumen = futures[0].data as Map<String, dynamic>?;
          _prestamos = List<Map<String, dynamic>>.from(
            (futures[1].data as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
          );
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPrestamos() async {
    try {
      final queryParams = <String, dynamic>{};
      if (_filtroEstado != 'TODOS') {
        queryParams['estado'] = _filtroEstado;
      }
      final response = await _dio.get('/prestamos', queryParameters: queryParams);
      if (mounted) {
        setState(() {
          _prestamos = List<Map<String, dynamic>>.from(
            (response.data as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
          );
        });
      }
    } catch (_) {}
  }

  double _parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Color _getEstadoColor(String? estado) {
    switch (estado?.toUpperCase()) {
      case 'ACTIVO':
        return AppColors.blue1;
      case 'PAGADO':
        return AppColors.green;
      case 'VENCIDO':
        return AppColors.red;
      default:
        return AppColors.grey;
    }
  }

  Color _getTipoColor(String? tipo) {
    switch (tipo?.toUpperCase()) {
      case 'BANCARIO':
        return AppColors.blue1;
      case 'PERSONAL':
        return AppColors.orange;
      case 'PROVEEDOR':
        return const Color(0xFF7B1FA2);
      case 'OTRO':
        return AppColors.blueGrey;
      default:
        return AppColors.grey;
    }
  }

  IconData _getTipoIcon(String? tipo) {
    switch (tipo?.toUpperCase()) {
      case 'BANCARIO':
        return Icons.account_balance;
      case 'PERSONAL':
        return Icons.person;
      case 'PROVEEDOR':
        return Icons.store;
      case 'OTRO':
        return Icons.more_horiz;
      default:
        return Icons.attach_money;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Prestamos',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadData,
            tooltip: 'Recargar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCrearPrestamoDialog,
        backgroundColor: AppColors.blue1,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.blue1,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _buildResumenCard(),
                    const SizedBox(height: 12),
                    _buildFilterChips(),
                    const SizedBox(height: 12),
                    if (_prestamos.isEmpty)
                      _buildEmptyState()
                    else
                      ..._prestamos.map(_buildPrestamoCard),
                  ],
                ),
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // RESUMEN CARD
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildResumenCard() {
    final totalDeuda = _parseDecimal(_resumen?['totalDeuda']);
    final totalOriginal = _parseDecimal(_resumen?['totalOriginal']);
    final totalPagado = _parseDecimal(_resumen?['totalPagado']);
    final porcentaje = _parseDecimal(_resumen?['porcentajePagado']);
    final cantActivos = _resumen?['cantidadActivos'] ?? 0;

    return GradientContainer(
      borderColor: AppColors.blue1.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: AppColors.blue1, size: 22),
              const SizedBox(width: 8),
              AppSubtitle('Resumen de Prestamos', fontSize: 13, color: AppColors.blue3),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$cantActivos activos',
                  style: TextStyle(fontSize: 10, color: AppColors.blue1, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildResumenItem(
                  label: 'Total Original',
                  value: _currencyFormat.format(totalOriginal),
                  color: AppColors.blue3,
                ),
              ),
              Expanded(
                child: _buildResumenItem(
                  label: 'Total Pagado',
                  value: _currencyFormat.format(totalPagado),
                  color: AppColors.green,
                ),
              ),
              Expanded(
                child: _buildResumenItem(
                  label: 'Deuda Actual',
                  value: _currencyFormat.format(totalDeuda),
                  color: AppColors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (porcentaje / 100).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.grey.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      porcentaje >= 100
                          ? AppColors.green
                          : porcentaje >= 50
                              ? AppColors.orange
                              : AppColors.blue1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${porcentaje.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Porcentaje pagado del total',
            style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenItem({required String label, required String value, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FILTER CHIPS
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildFilterChips() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filtros.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filtro = _filtros[index];
          final isSelected = _filtroEstado == filtro;
          return ChoiceChip(
            label: Text(
              filtro == 'TODOS' ? 'Todos' : filtro[0] + filtro.substring(1).toLowerCase(),
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white : AppColors.blue3,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.blue1,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? AppColors.blue1 : AppColors.blue1.withValues(alpha: 0.3),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (_) {
              setState(() => _filtroEstado = filtro);
              _loadPrestamos();
            },
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No hay prestamos registrados',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              'Presiona + para agregar uno',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRESTAMO CARD
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildPrestamoCard(Map<String, dynamic> prestamo) {
    final montoOriginal = _parseDecimal(prestamo['montoOriginal']);
    final saldoPendiente = _parseDecimal(prestamo['saldoPendiente']);
    final montoPagado = montoOriginal - saldoPendiente;
    final progreso = montoOriginal > 0 ? (montoPagado / montoOriginal).clamp(0.0, 1.0) : 0.0;
    final tipo = prestamo['tipo'] as String? ?? '';
    final estado = prestamo['estado'] as String? ?? '';
    final entidad = prestamo['entidadPrestamo'] as String? ?? '-';
    final fechaVencimiento = prestamo['fechaVencimiento'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _showRegistrarPagoSheet(prestamo),
        child: GradientContainer(
          borderColor: _getEstadoColor(estado).withValues(alpha: 0.3),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: entidad + tipo badge
              Row(
                children: [
                  Icon(_getTipoIcon(tipo), size: 18, color: _getTipoColor(tipo)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entidad,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Tipo badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getTipoColor(tipo).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      tipo.isNotEmpty ? tipo[0] + tipo.substring(1).toLowerCase() : '-',
                      style: TextStyle(fontSize: 9, color: _getTipoColor(tipo), fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Estado badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getEstadoColor(estado).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      estado.isNotEmpty ? estado[0] + estado.substring(1).toLowerCase() : '-',
                      style: TextStyle(fontSize: 9, color: _getEstadoColor(estado), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Amounts
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Monto original', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                        const SizedBox(height: 2),
                        Text(
                          _currencyFormat.format(montoOriginal),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.blue3),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Saldo pendiente', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                        const SizedBox(height: 2),
                        Text(
                          _currencyFormat.format(saldoPendiente),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: saldoPendiente > 0 ? AppColors.red : AppColors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progreso,
                  minHeight: 6,
                  backgroundColor: Colors.grey.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progreso >= 1.0
                        ? AppColors.green
                        : progreso >= 0.5
                            ? AppColors.orange
                            : AppColors.blue1,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Footer: percentage + vencimiento
              Row(
                children: [
                  Text(
                    '${(progreso * 100).toStringAsFixed(1)}% pagado',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  if (fechaVencimiento != null) ...[
                    Icon(Icons.calendar_today, size: 11, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'Vence: ${_formatDate(fechaVencimiento)}',
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CREAR PRESTAMO DIALOG
  // ═══════════════════════════════════════════════════════════════════════
  void _showCrearPrestamoDialog() {
    final entidadCtrl = TextEditingController();
    final montoCtrl = TextEditingController();
    final tasaInteresCtrl = TextEditingController();
    final cantidadCuotasCtrl = TextEditingController();
    final montoCuotaCtrl = TextEditingController();
    final descripcionCtrl = TextEditingController();
    String tipo = 'BANCARIO';
    DateTime? fechaDesembolso;
    DateTime? fechaVencimiento;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.account_balance_wallet, color: AppColors.blue1, size: 20),
                const SizedBox(width: 8),
                const Text('Nuevo Prestamo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipo
                    Text('Tipo de prestamo', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: ['BANCARIO', 'PERSONAL', 'PROVEEDOR', 'OTRO'].map((t) {
                        final isSelected = tipo == t;
                        return ChoiceChip(
                          label: Text(
                            t[0] + t.substring(1).toLowerCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? Colors.white : AppColors.blue3,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: _getTipoColor(t),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: _getTipoColor(t).withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (_) => setDialogState(() => tipo = t),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // Entidad
                    CustomText(
                      controller: entidadCtrl,
                      label: 'Entidad del prestamo *',
                      hintText: 'Ej: BCP, Juan Perez, Proveedor XYZ',
                      borderColor: AppColors.blue1,
                      required: true,
                    ),
                    const SizedBox(height: 10),
                    // Monto original
                    CustomText(
                      controller: montoCtrl,
                      label: 'Monto original *',
                      hintText: '0.00',
                      borderColor: AppColors.blue1,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      required: true,
                    ),
                    const SizedBox(height: 10),
                    // Tasa de interes
                    CustomText(
                      controller: tasaInteresCtrl,
                      label: 'Tasa de interes (%)',
                      hintText: 'Ej: 12.5',
                      borderColor: AppColors.blue1,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 10),
                    // Cuotas row
                    Row(
                      children: [
                        Expanded(
                          child: CustomText(
                            controller: cantidadCuotasCtrl,
                            label: 'Cant. cuotas',
                            hintText: 'Ej: 12',
                            borderColor: AppColors.blue1,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomText(
                            controller: montoCuotaCtrl,
                            label: 'Monto cuota',
                            hintText: '0.00',
                            borderColor: AppColors.blue1,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Fecha desembolso
                    Text('Fecha de desembolso *', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: fechaDesembolso ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) setDialogState(() => fechaDesembolso = picked);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.blue1.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: AppColors.blue1),
                            const SizedBox(width: 8),
                            Text(
                              fechaDesembolso != null
                                  ? DateFormat('dd/MM/yyyy').format(fechaDesembolso!)
                                  : 'Seleccionar fecha',
                              style: TextStyle(
                                fontSize: 11,
                                color: fechaDesembolso != null ? AppColors.blue3 : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Fecha vencimiento
                    Text('Fecha de vencimiento', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: fechaVencimiento ?? DateTime.now().add(const Duration(days: 365)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2040),
                        );
                        if (picked != null) setDialogState(() => fechaVencimiento = picked);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.blue1.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event, size: 14, color: AppColors.blue1),
                            const SizedBox(width: 8),
                            Text(
                              fechaVencimiento != null
                                  ? DateFormat('dd/MM/yyyy').format(fechaVencimiento!)
                                  : 'Seleccionar fecha (opcional)',
                              style: TextStyle(
                                fontSize: 11,
                                color: fechaVencimiento != null ? AppColors.blue3 : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Descripcion
                    CustomText(
                      controller: descripcionCtrl,
                      label: 'Descripcion',
                      hintText: 'Nota adicional (opcional)',
                      borderColor: AppColors.blue1,
                      maxLines: 3,
                      height: null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: Text('Cancelar', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ),
              CustomButton(
                text: 'Crear Prestamo',
                isLoading: isSubmitting,
                backgroundColor: AppColors.blue1,
                height: 36,
                fontSize: 11,
                onPressed: () async {
                  if (entidadCtrl.text.trim().isEmpty || montoCtrl.text.trim().isEmpty || fechaDesembolso == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Completa los campos obligatorios'), backgroundColor: AppColors.red),
                    );
                    return;
                  }

                  setDialogState(() => isSubmitting = true);
                  try {
                    final body = <String, dynamic>{
                      'tipo': tipo,
                      'entidadPrestamo': entidadCtrl.text.trim(),
                      'montoOriginal': double.tryParse(montoCtrl.text.trim()) ?? 0,
                      'fechaDesembolso': DateFormat('yyyy-MM-dd').format(fechaDesembolso!),
                    };
                    if (tasaInteresCtrl.text.trim().isNotEmpty) {
                      body['tasaInteres'] = double.tryParse(tasaInteresCtrl.text.trim());
                    }
                    if (cantidadCuotasCtrl.text.trim().isNotEmpty) {
                      body['cantidadCuotas'] = int.tryParse(cantidadCuotasCtrl.text.trim());
                    }
                    if (montoCuotaCtrl.text.trim().isNotEmpty) {
                      body['montoCuota'] = double.tryParse(montoCuotaCtrl.text.trim());
                    }
                    if (fechaVencimiento != null) {
                      body['fechaVencimiento'] = DateFormat('yyyy-MM-dd').format(fechaVencimiento!);
                    }
                    if (descripcionCtrl.text.trim().isNotEmpty) {
                      body['descripcion'] = descripcionCtrl.text.trim();
                    }

                    await _dio.post('/prestamos', data: body);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Prestamo creado exitosamente'), backgroundColor: AppColors.green),
                      );
                    }
                  } catch (e) {
                    setDialogState(() => isSubmitting = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // REGISTRAR PAGO BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════════════
  void _showRegistrarPagoSheet(Map<String, dynamic> prestamo) {
    final montoCtrl = TextEditingController();
    final referenciaCtrl = TextEditingController();
    String metodoPago = 'TRANSFERENCIA';
    bool isSubmitting = false;

    final prestamoId = prestamo['id'];
    final entidad = prestamo['entidadPrestamo'] as String? ?? '-';
    final saldoPendiente = _parseDecimal(prestamo['saldoPendiente']);
    final montoOriginal = _parseDecimal(prestamo['montoOriginal']);
    final montoPagado = montoOriginal - saldoPendiente;
    final progreso = montoOriginal > 0 ? (montoPagado / montoOriginal).clamp(0.0, 1.0) : 0.0;

    final metodos = ['EFECTIVO', 'TRANSFERENCIA', 'TARJETA', 'YAPE', 'PLIN', 'OTRO'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  // Title
                  Row(
                    children: [
                      Icon(Icons.payment, color: AppColors.blue1, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Registrar Pago',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.blue3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Prestamo info card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.blue1.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.blue1.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entidad, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.blue3)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('Original: ', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                            Text(_currencyFormat.format(montoOriginal), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.blue3)),
                            const Spacer(),
                            Text('Pendiente: ', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                            Text(
                              _currencyFormat.format(saldoPendiente),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.red),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progreso,
                            minHeight: 5,
                            backgroundColor: Colors.grey.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue1),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('${(progreso * 100).toStringAsFixed(1)}% pagado', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Metodo de pago
                  Text('Metodo de pago', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: metodos.map((m) {
                      final isSelected = metodoPago == m;
                      return ChoiceChip(
                        label: Text(
                          m[0] + m.substring(1).toLowerCase(),
                          style: TextStyle(
                            fontSize: 9,
                            color: isSelected ? Colors.white : AppColors.blue3,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.blue1,
                        backgroundColor: Colors.white,
                        side: BorderSide(color: AppColors.blue1.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (_) => setSheetState(() => metodoPago = m),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  // Monto
                  CustomText(
                    controller: montoCtrl,
                    label: 'Monto del pago *',
                    hintText: '0.00',
                    borderColor: AppColors.blue1,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    required: true,
                  ),
                  const SizedBox(height: 10),
                  // Referencia
                  CustomText(
                    controller: referenciaCtrl,
                    label: 'Referencia',
                    hintText: 'Numero de operacion (opcional)',
                    borderColor: AppColors.blue1,
                  ),
                  const SizedBox(height: 20),
                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Registrar Pago',
                      isLoading: isSubmitting,
                      backgroundColor: AppColors.green,
                      height: 42,
                      fontSize: 12,
                      onPressed: () async {
                        if (montoCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ingresa el monto del pago'), backgroundColor: AppColors.red),
                          );
                          return;
                        }
                        final monto = double.tryParse(montoCtrl.text.trim());
                        if (monto == null || monto <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('El monto debe ser mayor a 0'), backgroundColor: AppColors.red),
                          );
                          return;
                        }

                        setSheetState(() => isSubmitting = true);
                        try {
                          final body = <String, dynamic>{
                            'metodoPago': metodoPago,
                            'monto': monto,
                          };
                          if (referenciaCtrl.text.trim().isNotEmpty) {
                            body['referencia'] = referenciaCtrl.text.trim();
                          }
                          await _dio.post('/prestamos/$prestamoId/pago', data: body);
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Pago registrado exitosamente'), backgroundColor: AppColors.green),
                            );
                          }
                        } catch (e) {
                          setSheetState(() => isSubmitting = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
