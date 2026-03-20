import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text.dart' show CustomText;

class ProveedorBancoPage extends StatefulWidget {
  final String empresaId;
  final String proveedorId;
  final String proveedorNombre;

  const ProveedorBancoPage({
    super.key,
    required this.empresaId,
    required this.proveedorId,
    required this.proveedorNombre,
  });

  @override
  State<ProveedorBancoPage> createState() => _ProveedorBancoPageState();
}

class _ProveedorBancoPageState extends State<ProveedorBancoPage> {
  List<dynamic> _bancos = [];
  bool _isLoading = true;

  String get _basePath => '/empresas/${widget.empresaId}/proveedores/${widget.proveedorId}/bancos';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final response = await locator<DioClient>().get(_basePath);
      if (mounted) setState(() { _bancos = response.data as List<dynamic>? ?? []; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Cuentas Bancarias',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCrearDialog,
        backgroundColor: AppColors.blue1,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: GradientBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header proveedor
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.blue1.withValues(alpha: 0.05),
              child: Row(
                children: [
                  const Icon(Icons.business, color: AppColors.blue1, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: AppSubtitle(widget.proveedorNombre, fontSize: 14)),
                ],
              ),
            ),
            // Lista
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _bancos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance_outlined, size: 56, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text('Sin cuentas bancarias', style: TextStyle(color: Colors.grey.shade500)),
                              const SizedBox(height: 16),
                              CustomButton(text: 'Agregar cuenta', onPressed: _showCrearDialog, backgroundColor: AppColors.blue1, height: 40),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.blue1,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _bancos.length,
                            itemBuilder: (context, index) {
                              final banco = _bancos[index] as Map<String, dynamic>;
                              return _BancoCard(
                                banco: banco,
                                onEditar: () => _showEditarDialog(banco),
                                onEliminar: () => _eliminar(banco['id']),
                                onMarcarPrincipal: () => _marcarPrincipal(banco['id']),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCrearDialog() => _showBancoDialog();

  void _showEditarDialog(Map<String, dynamic> banco) => _showBancoDialog(banco: banco);

  void _showBancoDialog({Map<String, dynamic>? banco}) {
    final isEdit = banco != null;
    final nombreCtrl = TextEditingController(text: banco?['nombreBanco'] ?? '');
    final cuentaCtrl = TextEditingController(text: banco?['numeroCuenta'] ?? '');
    final cciCtrl = TextEditingController(text: banco?['cci'] ?? '');
    final swiftCtrl = TextEditingController(text: banco?['swift'] ?? '');
    String tipoCuenta = banco?['tipoCuenta'] ?? 'AHORROS';
    String moneda = banco?['moneda'] ?? 'PEN';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Editar Cuenta' : 'Nueva Cuenta Bancaria', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(controller: nombreCtrl, label: 'Banco', hintText: 'Ej: BCP, Interbank', borderColor: AppColors.blue1),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: tipoCuenta,
                  decoration: InputDecoration(labelText: 'Tipo de cuenta', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  items: const [
                    DropdownMenuItem(value: 'AHORROS', child: Text('Ahorros')),
                    DropdownMenuItem(value: 'CORRIENTE', child: Text('Corriente')),
                    DropdownMenuItem(value: 'INTERBANCARIA', child: Text('Interbancaria')),
                  ],
                  onChanged: (v) => setDialogState(() => tipoCuenta = v ?? 'AHORROS'),
                ),
                const SizedBox(height: 10),
                CustomText(controller: cuentaCtrl, label: 'Número de cuenta', borderColor: AppColors.blue1),
                const SizedBox(height: 10),
                CustomText(controller: cciCtrl, label: 'CCI (opcional)', borderColor: AppColors.blue1),
                const SizedBox(height: 10),
                CustomText(controller: swiftCtrl, label: 'SWIFT (opcional)', borderColor: AppColors.blue1),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: moneda,
                  decoration: InputDecoration(labelText: 'Moneda', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  items: const [
                    DropdownMenuItem(value: 'PEN', child: Text('PEN - Soles')),
                    DropdownMenuItem(value: 'USD', child: Text('USD - Dólares')),
                  ],
                  onChanged: (v) => setDialogState(() => moneda = v ?? 'PEN'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nombreCtrl.text.isEmpty || cuentaCtrl.text.isEmpty) return;
                Navigator.pop(ctx);
                final data = {
                  'nombreBanco': nombreCtrl.text.trim(),
                  'tipoCuenta': tipoCuenta,
                  'numeroCuenta': cuentaCtrl.text.trim(),
                  'cci': cciCtrl.text.trim().isEmpty ? null : cciCtrl.text.trim(),
                  'swift': swiftCtrl.text.trim().isEmpty ? null : swiftCtrl.text.trim(),
                  'moneda': moneda,
                };
                if (isEdit) {
                  await locator<DioClient>().put('$_basePath/${banco['id']}', data: data);
                } else {
                  await locator<DioClient>().post(_basePath, data: data);
                }
                _load();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue1, foregroundColor: Colors.white),
              child: Text(isEdit ? 'Guardar' : 'Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _marcarPrincipal(String id) async {
    await locator<DioClient>().post('$_basePath/$id/principal');
    _load();
  }

  Future<void> _eliminar(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta', style: TextStyle(fontSize: 15)),
        content: const Text('¿Está seguro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await locator<DioClient>().delete('$_basePath/$id');
      _load();
    }
  }
}

class _BancoCard extends StatelessWidget {
  final Map<String, dynamic> banco;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final VoidCallback onMarcarPrincipal;

  const _BancoCard({required this.banco, required this.onEditar, required this.onEliminar, required this.onMarcarPrincipal});

  @override
  Widget build(BuildContext context) {
    final esPrincipal = banco['esPrincipal'] == true;

    return GradientContainer(
      margin: const EdgeInsets.only(bottom: 10),
      borderColor: esPrincipal ? AppColors.blue1 : AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance, size: 20, color: AppColors.blue1),
                const SizedBox(width: 8),
                Expanded(child: AppSubtitle(banco['nombreBanco'] ?? '', fontSize: 14)),
                if (esPrincipal)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.blue1.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Principal', style: TextStyle(fontSize: 10, color: AppColors.blue1, fontWeight: FontWeight.w600)),
                  ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'editar') onEditar();
                    if (v == 'principal') onMarcarPrincipal();
                    if (v == 'eliminar') onEliminar();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'editar', child: Text('Editar')),
                    if (!esPrincipal) const PopupMenuItem(value: 'principal', child: Text('Marcar como principal')),
                    const PopupMenuItem(value: 'eliminar', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _infoRow(Icons.credit_card, '${_tipoCuentaLabel(banco['tipoCuenta'])} - ${banco['moneda'] ?? 'PEN'}'),
            _infoRow(Icons.numbers, banco['numeroCuenta'] ?? ''),
            if (banco['cci'] != null && (banco['cci'] as String).isNotEmpty)
              _infoRow(Icons.swap_horiz, 'CCI: ${banco['cci']}'),
            if (banco['swift'] != null && (banco['swift'] as String).isNotEmpty)
              _infoRow(Icons.language, 'SWIFT: ${banco['swift']}'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: Colors.grey.shade700))),
        ],
      ),
    );
  }

  String _tipoCuentaLabel(String? tipo) {
    switch (tipo) {
      case 'AHORROS': return 'Ahorros';
      case 'CORRIENTE': return 'Corriente';
      case 'INTERBANCARIA': return 'Interbancaria';
      default: return tipo ?? '';
    }
  }
}
