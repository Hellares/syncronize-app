import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../../../core/widgets/custom_switch_tile.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text.dart'
    show CustomText, FieldType;

/// ADMIN (dueño de la plataforma): vende/controla el espacio publicitario.
/// Lista empresas y permite activar/desactivar la característica
/// BANNER_MARKETPLACE con vencimiento (contrato). El backend valida el rol.
class PublicidadEmpresasAdminPage extends StatefulWidget {
  const PublicidadEmpresasAdminPage({super.key});

  @override
  State<PublicidadEmpresasAdminPage> createState() =>
      _PublicidadEmpresasAdminPageState();
}

class _PublicidadEmpresasAdminPageState
    extends State<PublicidadEmpresasAdminPage> {
  final _dio = locator<DioClient>();
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _loading = true;
  List<Map<String, dynamic>> _empresas = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final response = await _dio.get('/admin/empresas', queryParameters: {
        'page': 1,
        'pageSize': 50,
        if (_searchController.text.trim().isNotEmpty)
          'search': _searchController.text.trim(),
      });
      final data = response.data as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _empresas = (data['items'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      SnackBarHelper.showError(context, 'No se pudieron cargar las empresas');
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Future<void> _abrirGestion(Map<String, dynamic> empresa) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BannerContratoSheet(empresa: empresa),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Publicidad de Empresas',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
      ),
      body: GradientContainer(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: CustomText(
                controller: _searchController,
                label: 'Buscar empresa',
                hintText: 'Nombre, RUC o subdominio',
                borderColor: AppColors.blue1,
                fieldType: FieldType.text,
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                      itemCount: _empresas.length,
                      itemBuilder: (context, i) {
                        final e = _empresas[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            dense: true,
                            title: Text(
                              e['nombre'] as String? ?? '',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Plan: ${e['planNombre'] ?? '—'}'
                              '${e['ruc'] != null ? ' · RUC ${e['ruc']}' : ''}',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade600),
                            ),
                            trailing: const Icon(Icons.campaign_outlined,
                                size: 20, color: AppColors.blue1),
                            onTap: () => _abrirGestion(e),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet: contrato del banner (característica BANNER_MARKETPLACE) de una
/// empresa — habilitado + vigencia (null = permanente).
class _BannerContratoSheet extends StatefulWidget {
  const _BannerContratoSheet({required this.empresa});

  final Map<String, dynamic> empresa;

  @override
  State<_BannerContratoSheet> createState() => _BannerContratoSheetState();
}

class _BannerContratoSheetState extends State<_BannerContratoSheet> {
  final _dio = locator<DioClient>();
  bool _loading = true;
  bool _saving = false;
  bool _habilitado = false;
  DateTime? _vigenteHasta;

  String get _empresaId => widget.empresa['id'] as String;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response =
          await _dio.get('/admin/empresas/$_empresaId/caracteristicas');
      final rows = (response.data as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      final row = rows.firstWhere(
        (r) => r['caracteristica'] == 'BANNER_MARKETPLACE',
        orElse: () => const {},
      );
      if (!mounted) return;
      setState(() {
        _habilitado = row['habilitado'] == true;
        _vigenteHasta =
            DateTime.tryParse(row['vigenteHasta'] as String? ?? '')?.toLocal();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _dio.patch(
        '/admin/empresas/$_empresaId/caracteristicas',
        data: {
          'caracteristica': 'BANNER_MARKETPLACE',
          'habilitado': _habilitado,
          // Vence al final del día elegido; null = permanente.
          'vigenteHasta': _vigenteHasta
              ?.add(const Duration(hours: 23, minutes: 59))
              .toUtc()
              .toIso8601String(),
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      SnackBarHelper.showSuccess(context, 'Contrato de banner actualizado');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _vigenteHasta ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1095)),
    );
    if (picked != null) setState(() => _vigenteHasta = picked);
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: _loading
            ? const SizedBox(
                height: 120, child: Center(child: CircularProgressIndicator()))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.empresa['nombre'] as String? ?? '',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Banner en el marketplace (contrato de publicidad)',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  CustomSwitchTile(
                    title: 'Banner habilitado',
                    subtitle:
                        'La empresa podrá configurar y mostrar su banner',
                    value: _habilitado,
                    onChanged: (v) => setState(() => _habilitado = v),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickFecha,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event_outlined,
                              size: 16, color: AppColors.blue1),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _vigenteHasta == null
                                  ? 'Vigente: permanente (sin vencimiento)'
                                  : 'Vigente hasta: ${df.format(_vigenteHasta!)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          if (_vigenteHasta != null)
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _vigenteHasta = null),
                              child: Icon(Icons.close,
                                  size: 16, color: Colors.grey.shade500),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Guardar contrato',
                    isLoading: _saving,
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
      ),
    );
  }
}
