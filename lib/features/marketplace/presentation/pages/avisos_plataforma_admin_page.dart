import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/custom_switch_tile.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text.dart'
    show CustomText, FieldType;
import '../../data/models/banner_marketplace_model.dart';
import '../widgets/banner_empresas_slider.dart';
import '../widgets/banner_paletas.dart';

/// Avisos del DUEÑO de la plataforma en el slider del marketplace
/// (festividades, promoción del app). Solo SUPER ADMIN — el backend valida
/// con SuperAdminGuard; esta pantalla se enlaza únicamente para ese rol.
class AvisosPlataformaAdminPage extends StatefulWidget {
  const AvisosPlataformaAdminPage({super.key});

  @override
  State<AvisosPlataformaAdminPage> createState() =>
      _AvisosPlataformaAdminPageState();
}

class _AvisosPlataformaAdminPageState extends State<AvisosPlataformaAdminPage> {
  final _dio = locator<DioClient>();
  bool _loading = true;
  List<Map<String, dynamic>> _avisos = const [];
  List<Map<String, dynamic>> _lotties = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _dio.get('/admin/avisos-marketplace'),
        _dio.get('/marketplace/lottie-fondos'),
      ]);
      if (!mounted) return;
      setState(() {
        _avisos = (results[0].data as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
        _lotties = (results[1].data as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      SnackBarHelper.showError(context, 'No se pudieron cargar los avisos');
    }
  }

  Future<void> _eliminar(Map<String, dynamic> aviso) async {
    final ok = await ConfirmDialog.show(
      context: context,
      type: ConfirmDialogType.destructive,
      title: 'Eliminar aviso',
      message: '¿Eliminar "${aviso['texto']}"? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
    );
    if (ok != true) return;
    try {
      await _dio.delete('/admin/avisos-marketplace/${aviso['id']}');
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Aviso eliminado');
      _load();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Error al eliminar: $e');
    }
  }

  Future<void> _abrirForm([Map<String, dynamic>? aviso]) async {
    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _AvisoFormPage(aviso: aviso, lotties: _lotties),
      ),
    );
    if (guardado == true) _load();
  }

  /// Estado legible del aviso según vigencia + isActive.
  String _estado(Map<String, dynamic> a) {
    if (a['isActive'] != true) return 'INACTIVO';
    final now = DateTime.now();
    final desde = DateTime.tryParse(a['vigenciaDesde'] as String? ?? '');
    final hasta = DateTime.tryParse(a['vigenciaHasta'] as String? ?? '');
    if (desde != null && now.isBefore(desde)) return 'PROGRAMADO';
    if (hasta != null && now.isAfter(hasta)) return 'VENCIDO';
    return 'VIGENTE';
  }

  Color _estadoColor(String estado) => switch (estado) {
        'VIGENTE' => Colors.green.shade600,
        'PROGRAMADO' => Colors.orange.shade700,
        'VENCIDO' => Colors.red.shade400,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Avisos del Marketplace',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blue1,
        onPressed: () => _abrirForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: GradientContainer(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _avisos.isEmpty
                ? Center(
                    child: Text(
                      'Sin avisos.\nCrea uno para promocionar el app\no una festividad.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                    itemCount: _avisos.length,
                    itemBuilder: (context, i) => _buildAvisoCard(_avisos[i]),
                  ),
      ),
    );
  }

  Widget _buildAvisoCard(Map<String, dynamic> aviso) {
    final estado = _estado(aviso);
    final df = DateFormat('dd/MM/yy');
    final desde = DateTime.tryParse(aviso['vigenciaDesde'] as String? ?? '');
    final hasta = DateTime.tryParse(aviso['vigenciaHasta'] as String? ?? '');
    final vigencia = desde == null && hasta == null
        ? 'Siempre'
        : '${desde != null ? df.format(desde.toLocal()) : '…'} → '
            '${hasta != null ? df.format(hasta.toLocal()) : '…'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: BannerMarketplaceCard(banner: _modelo(aviso)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _estadoColor(estado).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    estado,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _estadoColor(estado),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vigencia,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: AppColors.blue1,
                  onPressed: () => _abrirForm(aviso),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: Colors.red.shade400,
                  onPressed: () => _eliminar(aviso),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BannerMarketplaceModel _modelo(Map<String, dynamic> a) {
    final lottie = a['lottieFondo'] as Map<String, dynamic>?;
    return BannerMarketplaceModel(
      id: a['id'] as String? ?? '',
      texto: a['texto'] as String? ?? '',
      colorFondo: a['colorFondo'] as String? ?? '#C62828',
      colorTexto: a['colorTexto'] as String?,
      colorBrillo: a['colorBrillo'] as String?,
      lottieUrl: lottie?['url'] as String?,
      lottieConfig: lottie?['config'] as Map<String, dynamic>?,
      empresaId: '',
      nombreEmpresa: (a['titulo'] as String?) ?? 'Syncronize',
      logo: a['logoUrl'] as String?,
      subdominio: null, // el listado admin no navega
    );
  }
}

/// Formulario de creación/edición de un aviso de plataforma.
class _AvisoFormPage extends StatefulWidget {
  const _AvisoFormPage({this.aviso, required this.lotties});

  final Map<String, dynamic>? aviso;
  final List<Map<String, dynamic>> lotties;

  @override
  State<_AvisoFormPage> createState() => _AvisoFormPageState();
}

class _AvisoFormPageState extends State<_AvisoFormPage> {
  final _dio = locator<DioClient>();
  final _textoController = TextEditingController();
  final _tituloController = TextEditingController();
  final _linkController = TextEditingController();

  bool _saving = false;
  bool _activo = true;
  String _colorFondo = '#C62828';
  String? _colorTexto;
  String? _colorBrillo;
  String? _lottieFondoId;
  DateTime? _desde;
  DateTime? _hasta;

  @override
  void initState() {
    super.initState();
    final a = widget.aviso;
    if (a != null) {
      _textoController.text = a['texto'] as String? ?? '';
      _tituloController.text = a['titulo'] as String? ?? '';
      _linkController.text = a['link'] as String? ?? '';
      _activo = a['isActive'] == true;
      _colorFondo = a['colorFondo'] as String? ?? '#C62828';
      _colorTexto = a['colorTexto'] as String?;
      _colorBrillo = a['colorBrillo'] as String?;
      _lottieFondoId = a['lottieFondoId'] as String?;
      _desde = DateTime.tryParse(a['vigenciaDesde'] as String? ?? '')?.toLocal();
      _hasta = DateTime.tryParse(a['vigenciaHasta'] as String? ?? '')?.toLocal();
    }
  }

  @override
  void dispose() {
    _textoController.dispose();
    _tituloController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final texto = _textoController.text.trim();
    if (texto.isEmpty) {
      SnackBarHelper.showError(context, 'Escribe el texto del aviso');
      return;
    }
    setState(() => _saving = true);
    final data = {
      'texto': texto,
      'titulo':
          _tituloController.text.trim().isEmpty ? null : _tituloController.text.trim(),
      'link':
          _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
      'colorFondo': _colorFondo,
      'colorTexto': _colorTexto,
      'colorBrillo': _colorBrillo,
      'lottieFondoId': _lottieFondoId,
      // Desde las 00:00 del día inicial hasta las 23:59 del día final.
      'vigenciaDesde': _desde?.toUtc().toIso8601String(),
      'vigenciaHasta': _hasta
          ?.add(const Duration(hours: 23, minutes: 59))
          .toUtc()
          .toIso8601String(),
      'isActive': _activo,
    };
    try {
      final id = widget.aviso?['id'];
      if (id == null) {
        await _dio.post('/admin/avisos-marketplace', data: data);
      } else {
        await _dio.patch('/admin/avisos-marketplace/$id', data: data);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickFecha(bool esDesde) async {
    final base = esDesde ? _desde : _hasta;
    final picked = await showDatePicker(
      context: context,
      initialDate: base ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() => esDesde ? _desde = picked : _hasta = picked);
  }

  String? get _lottieUrl {
    for (final l in widget.lotties) {
      if (l['id'] == _lottieFondoId) return l['url'] as String?;
    }
    return null;
  }

  Map<String, dynamic>? get _lottieConfig {
    for (final l in widget.lotties) {
      if (l['id'] == _lottieFondoId) {
        return l['config'] as Map<String, dynamic>?;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    return Scaffold(
      appBar: SmartAppBar(
        title: widget.aviso == null ? 'Nuevo aviso' : 'Editar aviso',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
      ),
      body: GradientContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Vista previa',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BannerMarketplaceCard(
                  banner: BannerMarketplaceModel(
                    id: 'preview',
                    texto: _textoController.text.trim().isEmpty
                        ? 'Tu aviso se verá así'
                        : _textoController.text.trim(),
                    colorFondo: _colorFondo,
                    colorTexto: _colorTexto,
                    colorBrillo: _colorBrillo,
                    lottieUrl: _lottieUrl,
                    lottieConfig: _lottieConfig,
                    empresaId: '',
                    nombreEmpresa: _tituloController.text.trim().isEmpty
                        ? 'Syncronize'
                        : _tituloController.text.trim(),
                    logo: null,
                    subdominio: null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              CustomText(
                controller: _textoController,
                label: 'Texto del aviso',
                hintText: 'Ej: ¡FELIZ NAVIDAD! GRANDES OFERTAS EN EL MARKETPLACE',
                borderColor: AppColors.blue1,
                fieldType: FieldType.text,
                maxLength: 90,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              CustomText(
                controller: _tituloController,
                label: 'Título inferior (opcional)',
                hintText: 'Default: Syncronize',
                borderColor: AppColors.blue1,
                fieldType: FieldType.text,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              CustomText(
                controller: _linkController,
                label: 'Link al tocar (opcional)',
                hintText: 'Ruta interna (/marketplace) o https://…',
                borderColor: AppColors.blue1,
                fieldType: FieldType.text,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _fechaTile('Desde', _desde, () => _pickFecha(true),
                        () => setState(() => _desde = null), df),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _fechaTile('Hasta', _hasta, () => _pickFecha(false),
                        () => setState(() => _hasta = null), df),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Color de fondo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _paletaWrap(paletaFondoBanner, _colorFondo,
                  (hex) => setState(() => _colorFondo = hex ?? _colorFondo)),
              const SizedBox(height: 16),
              const Text('Color del texto',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _paletaWrap(paletaTextoBanner, _colorTexto,
                  (hex) => setState(() => _colorTexto = hex),
                  conAuto: true),
              const SizedBox(height: 16),
              const Text('Color del brillo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _paletaWrap(paletaBrilloBanner, _colorBrillo,
                  (hex) => setState(() => _colorBrillo = hex)),
              const SizedBox(height: 16),
              const Text('Fondo animado',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                height: 72,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _lottieOption(null, 'Sin fondo', null),
                    for (final l in widget.lotties)
                      _lottieOption(
                        l['id'] as String?,
                        l['nombre'] as String? ?? '',
                        l['url'] as String?,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              CustomSwitchTile(
                title: 'Aviso activo',
                subtitle: 'Desactívalo para ocultarlo sin perder la configuración',
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Guardar aviso',
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fechaTile(String label, DateTime? valor, VoidCallback onPick,
      VoidCallback onClear, DateFormat df) {
    return InkWell(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 14, color: AppColors.blue1),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                valor == null ? '$label: siempre' : '$label: ${df.format(valor)}',
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (valor != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 14, color: Colors.grey.shade500),
              ),
          ],
        ),
      ),
    );
  }

  Widget _paletaWrap(
    List<String> paleta,
    String? seleccionado,
    void Function(String?) onPick, {
    bool conAuto = false,
  }) {
    Widget dot(String hex) {
      final color = Color(0xFF000000 |
          (int.tryParse(hex.substring(1), radix: 16) ?? 0x1565C0));
      final selected = seleccionado == hex;
      final check =
          color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
      return GestureDetector(
        onTap: () => onPick(hex),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.blue1 : Colors.grey.shade300,
              width: selected ? 3 : 1,
            ),
          ),
          child: selected ? Icon(Icons.check, size: 16, color: check) : null,
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (conAuto)
          GestureDetector(
            onTap: () => onPick(null),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      seleccionado == null ? AppColors.blue1 : Colors.grey.shade300,
                  width: seleccionado == null ? 3 : 1,
                ),
              ),
              child: Icon(Icons.auto_fix_high,
                  size: 16,
                  color: seleccionado == null ? AppColors.blue1 : Colors.grey),
            ),
          ),
        ...paleta.map(dot),
      ],
    );
  }

  Widget _lottieOption(String? id, String nombre, String? url) {
    final selected = _lottieFondoId == id;
    return GestureDetector(
      onTap: () => setState(() => _lottieFondoId = id),
      child: Container(
        width: 76,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.blue1 : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (url != null)
              SizedBox(
                width: 40,
                height: 40,
                child: LottieFondoView(url: url, fit: BoxFit.contain),
              )
            else
              Icon(Icons.block, size: 24, color: Colors.grey.shade400),
            const SizedBox(height: 4),
            Text(
              nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}
