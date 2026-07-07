import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/storage_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/custom_switch_tile.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text.dart'
    show CustomText, FieldType;
import '../../../marketplace/data/models/banner_marketplace_model.dart';
import '../../../marketplace/presentation/widgets/banner_empresas_slider.dart';
import '../../../marketplace/presentation/widgets/banner_paletas.dart';
import '../bloc/empresa_context/empresa_context_cubit.dart';
import '../bloc/empresa_context/empresa_context_state.dart';

/// Configuración del banner promocional de la empresa en el marketplace.
/// Feature premium: si la empresa no tiene BANNER_MARKETPLACE vigente se
/// muestra bloqueada (el backend también lo valida en el PUT).
class BannerMarketplaceConfigPage extends StatefulWidget {
  const BannerMarketplaceConfigPage({super.key});

  @override
  State<BannerMarketplaceConfigPage> createState() =>
      _BannerMarketplaceConfigPageState();
}

class _BannerMarketplaceConfigPageState
    extends State<BannerMarketplaceConfigPage> {
  final _dio = locator<DioClient>();
  final _localStorage = locator<LocalStorageService>();
  final _textoController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _habilitado = false;
  DateTime? _vigenteHasta; // fin del contrato/pack activo
  Map<String, dynamic>? _solicitudPendiente; // pack esperando aprobación
  bool _bannerActivo = true;
  String _colorFondo = paletaFondoBanner.first;
  String? _colorTexto; // null = contraste automático
  String? _colorBrillo; // null = default del app (verde)
  String? _lottieFondoId;
  List<Map<String, dynamic>> _lotties = const [];
  // Nombre COMERCIAL (fallback nombre fiscal) + logo: lo que verá el público.
  String? _nombreEmpresa;
  String? _logoEmpresa;
  // Rendimiento publicitario del mes (impresiones/taps) que reporta el backend.
  Map<String, dynamic>? _metricasMes;

  String? get _empresaId => _localStorage.getString(StorageConstants.tenantId);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _textoController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final empresaId = _empresaId;
    if (empresaId == null) return;
    try {
      final results = await Future.wait([
        _dio.get('/empresas/$empresaId/banner-marketplace'),
        _dio.get('/marketplace/lottie-fondos'),
      ]);
      final data = results[0].data as Map<String, dynamic>;
      final banner = data['banner'] as Map<String, dynamic>?;
      final lotties = (results[1].data as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _habilitado = data['habilitado'] == true;
        _vigenteHasta =
            DateTime.tryParse(data['vigenteHasta'] as String? ?? '')?.toLocal();
        _solicitudPendiente =
            data['solicitudPendiente'] as Map<String, dynamic>?;
        _nombreEmpresa = data['nombreEmpresa'] as String?;
        _logoEmpresa = data['logo'] as String?;
        _metricasMes = data['metricasMes'] as Map<String, dynamic>?;
        _lotties = lotties;
        if (banner != null) {
          _textoController.text = banner['texto'] as String? ?? '';
          _colorFondo = banner['colorFondo'] as String? ?? paletaFondoBanner.first;
          _colorTexto = banner['colorTexto'] as String?;
          _colorBrillo = banner['colorBrillo'] as String?;
          _lottieFondoId = banner['lottieFondoId'] as String?;
          _bannerActivo = banner['isActive'] == true;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      SnackBarHelper.showError(context, 'No se pudo cargar la configuración');
    }
  }

  Future<void> _save() async {
    final empresaId = _empresaId;
    if (empresaId == null) return;
    final texto = _textoController.text.trim();
    if (texto.isEmpty) {
      SnackBarHelper.showError(context, 'Escribe el texto de tu promoción');
      return;
    }
    setState(() => _saving = true);
    try {
      await _dio.put(
        '/empresas/$empresaId/banner-marketplace',
        data: {
          'texto': texto,
          'colorFondo': _colorFondo,
          'colorTexto': _colorTexto,
          'colorBrillo': _colorBrillo,
          'lottieFondoId': _lottieFondoId,
          'isActive': _bannerActivo,
        },
      );
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Banner guardado');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Map<String, dynamic>? get _lottieSeleccionado {
    if (_lottieFondoId == null) return null;
    for (final l in _lotties) {
      if (l['id'] == _lottieFondoId) return l;
    }
    return null;
  }

  /// Dialog "Solicitar mostrar": packs de días con precio; al confirmar se
  /// crea la solicitud y se ofrece avisar al admin por WhatsApp.
  Future<void> _solicitarMostrar() async {
    final empresaId = _empresaId;
    if (empresaId == null) return;
    if (_textoController.text.trim().isEmpty) {
      SnackBarHelper.showError(
          context, 'Primero configura y guarda tu banner');
      return;
    }

    // Packs + WhatsApp del admin desde el backend (precios centralizados).
    List<Map<String, dynamic>> packs;
    String? whatsapp;
    try {
      final response = await _dio.get('/marketplace/banner-packs');
      final data = response.data as Map<String, dynamic>;
      packs = (data['packs'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      whatsapp = data['whatsapp'] as String?;
    } catch (_) {
      if (mounted) {
        SnackBarHelper.showError(context, 'No se pudieron cargar los packs');
      }
      return;
    }
    if (!mounted || packs.isEmpty) return;

    final dias = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Solicitar mostrar banner',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Elige por cuántos días quieres mostrar tu banner en el inicio del marketplace. Corre desde que el administrador lo activa.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 8),
          for (final p in packs)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, p['dias'] as int),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined,
                      size: 18, color: AppColors.blue1),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${p['dias']} ${p['dias'] == 1 ? 'día' : 'días'}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    'S/ ${p['precio']}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue1),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    if (dias == null || !mounted) return;

    try {
      await _dio.post(
        '/empresas/$empresaId/banner-marketplace/solicitud',
        data: {'dias': dias},
      );
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Error al solicitar: $e');
      return;
    }
    if (!mounted) return;
    await _load(); // refresca el estado (aparece "solicitud pendiente")

    if (!mounted) return;
    final pack = packs.firstWhere((p) => p['dias'] == dias);
    final abrirWsp = whatsapp != null &&
        await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Solicitud enviada',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                content: Text(
                  'Pack de $dias ${dias == 1 ? 'día' : 'días'} por S/ ${pack['precio']}. '
                  'Coordina el pago con el administrador para que active tu banner.',
                  style: const TextStyle(fontSize: 12),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cerrar'),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366)),
                    onPressed: () => Navigator.pop(ctx, true),
                    icon: const Icon(Icons.chat, size: 16),
                    label: const Text('Avisar por WhatsApp'),
                  ),
                ],
              ),
            ) ==
            true;
    if (abrirWsp) {
      final msg = Uri.encodeComponent(
        'Hola, soy ${_nombreEmpresa ?? 'una empresa'} del marketplace Syncronize. '
        'Acabo de solicitar mostrar mi banner: pack de $dias ${dias == 1 ? 'día' : 'días'} '
        'por S/ ${pack['precio']}. ¿Cómo coordino el pago?',
      );
      launchUrl(
        Uri.parse('https://wa.me/$whatsapp?text=$msg'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  /// Card de estado del contrato: activo / pendiente / botón solicitar.
  Widget _buildEstadoContrato() {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    if (_habilitado) {
      return _estadoBox(
        color: Colors.green,
        icon: Icons.check_circle_outline,
        texto: _vigenteHasta == null
            ? 'Tu banner está ACTIVO (sin vencimiento)'
            : 'Tu banner está ACTIVO hasta el ${df.format(_vigenteHasta!)}',
      );
    }
    if (_solicitudPendiente != null) {
      final s = _solicitudPendiente!;
      return _estadoBox(
        color: Colors.orange,
        icon: Icons.hourglass_top,
        texto:
            'Solicitud enviada: ${s['dias']} día(s) por S/ ${s['monto']}. Esperando activación del administrador.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _estadoBox(
          color: Colors.grey,
          icon: Icons.visibility_off_outlined,
          texto:
              'Tu banner aún NO es visible al público. Configúralo, guárdalo y solicita mostrarlo.',
        ),
        const SizedBox(height: 8),
        CustomButton(
          text: 'Solicitar mostrar banner',
          isLoading: false,
          onPressed: _solicitarMostrar,
        ),
      ],
    );
  }

  Widget _estadoBox({
    required MaterialColor color,
    required IconData icon,
    required String texto,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color.shade800),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Banner en Marketplace',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
      ),
      body: GradientContainer(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildForm(context),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estado del contrato: activo / solicitud pendiente / solicitar.
          _buildEstadoContrato(),
          const SizedBox(height: 16),
          const Text('Vista previa',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildPreview(context),
          if (_metricasMes != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.visibility_outlined,
                    size: 15, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${_metricasMes!['impresiones'] ?? 0} vistas este mes',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
                const SizedBox(width: 14),
                Icon(Icons.touch_app_outlined,
                    size: 15, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${_metricasMes!['taps'] ?? 0} visitas a tu tienda',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          CustomText(
            controller: _textoController,
            label: 'Texto de la promoción',
            hintText: 'Ej: POR COMPRAS MAYORES A S/25 UNA MICA GRATIS',
            borderColor: AppColors.blue1,
            fieldType: FieldType.text,
            maxLength: 90,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          const Text('Color de fondo',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final hex in paletaFondoBanner)
                _colorDot(
                  hex: hex,
                  selected: _colorFondo == hex,
                  onTap: () => setState(() => _colorFondo = hex),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Color del texto',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // "Auto" = contraste automático según el fondo.
              _autoDot(
                selected: _colorTexto == null,
                onTap: () => setState(() => _colorTexto = null),
              ),
              for (final hex in paletaTextoBanner)
                _colorDot(
                  hex: hex,
                  selected: _colorTexto == hex,
                  onTap: () => setState(() => _colorTexto = hex),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Color del brillo (luz que recorre el texto)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final hex in paletaBrilloBanner)
                _colorDot(
                  hex: hex,
                  selected: _colorBrillo == hex,
                  onTap: () => setState(() => _colorBrillo = hex),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Fondo animado',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildLottieSelector(),
          const SizedBox(height: 8),
          CustomSwitchTile(
            title: 'Banner activo',
            subtitle: 'Desactívalo para ocultarlo sin perder la configuración',
            value: _bannerActivo,
            onChanged: (v) => setState(() => _bannerActivo = v),
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: 'Guardar banner',
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final ctxState = context.watch<EmpresaContextCubit>().state;
    final empresa =
        ctxState is EmpresaContextLoaded ? ctxState.context.empresa : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BannerMarketplaceCard(
        banner: BannerMarketplaceModel(
          id: 'preview',
          texto: _textoController.text.trim().isEmpty
              ? 'Tu promoción se verá así'
              : _textoController.text.trim(),
          colorFondo: _colorFondo,
          colorTexto: _colorTexto,
          colorBrillo: _colorBrillo,
          lottieUrl: _lottieSeleccionado?['url'] as String?,
          lottieConfig: _lottieSeleccionado?['config'] as Map<String, dynamic>?,
          empresaId: '',
          nombreEmpresa: (_nombreEmpresa?.isNotEmpty == true
                  ? _nombreEmpresa
                  : empresa?.nombre) ??
              'Tu empresa',
          logo: _logoEmpresa ?? empresa?.logo,
          subdominio: null, // el preview no navega
        ),
      ),
    );
  }

  Widget _colorDot({
    required String hex,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final color = Color(0xFF000000 |
        (int.tryParse(hex.substring(1), radix: 16) ?? 0x1565C0));
    // Check en contraste con el color del punto (falla en blanco/dorado si no).
    final check =
        color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
    return GestureDetector(
      onTap: onTap,
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

  /// Punto "Auto": contraste automático del texto según el fondo.
  Widget _autoDot({required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.blue1 : Colors.grey.shade300,
            width: selected ? 3 : 1,
          ),
        ),
        child: Icon(Icons.auto_fix_high,
            size: 16, color: selected ? AppColors.blue1 : Colors.grey),
      ),
    );
  }

  Widget _buildLottieSelector() {
    return SizedBox(
      height: 72,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildLottieOption(null, 'Sin fondo', null),
          for (final l in _lotties)
            _buildLottieOption(
              l['id'] as String?,
              l['nombre'] as String? ?? '',
              l['url'] as String?,
            ),
        ],
      ),
    );
  }

  Widget _buildLottieOption(String? id, String nombre, String? url) {
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
