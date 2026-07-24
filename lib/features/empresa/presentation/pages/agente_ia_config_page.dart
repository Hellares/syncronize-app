import 'package:flutter/material.dart';

import '../../../../core/constants/storage_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_switch_tile.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../data/datasources/empresa_remote_datasource.dart';

/// Configuración del agente IA vendedor por WhatsApp, por empresa.
///
/// La empresa edita personalidad y alcance (SOLO_CONSULTA / VENDE) y — si trae
/// su propio proveedor de IA (BYOK) — su API key, que el backend guarda cifrada
/// y devuelve enmascarada. Cambiar el proveedor/key requiere que el super admin
/// vuelva a aprobarlo.
class AgenteIaConfigPage extends StatefulWidget {
  const AgenteIaConfigPage({super.key});

  @override
  State<AgenteIaConfigPage> createState() => _AgenteIaConfigPageState();
}

class _AgenteIaConfigPageState extends State<AgenteIaConfigPage> {
  final _empresaDs = locator<EmpresaRemoteDataSource>();
  final _localStorage = locator<LocalStorageService>();

  final _nombreCtrl = TextEditingController();
  final _personalidadCtrl = TextEditingController();
  final _bienvenidaCtrl = TextEditingController();
  final _horarioCtrl = TextEditingController();
  final _proveedorModeloCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();

  bool _loading = true;
  bool _guardando = false;

  bool _habilitado = false;
  String _modo = 'SOLO_CONSULTA';
  bool _puedeCobrarYape = false;
  bool _escalarAHumano = true;

  bool _proveedorPropio = false;
  String? _proveedorTipo;
  bool _proveedorAprobado = false;
  String? _apiKeyMask;

  String? _modeloProveedorGlobal;
  int _maxProductos = 5;

  static const _tiposProveedor = ['claude', 'openai', 'gemini'];

  String? get _empresaId => _localStorage.getString(StorageConstants.tenantId);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _personalidadCtrl.dispose();
    _bienvenidaCtrl.dispose();
    _horarioCtrl.dispose();
    _proveedorModeloCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final id = _empresaId;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final cfg = await _empresaDs.getAgenteIa(id);
      if (!mounted) return;
      setState(() {
        _habilitado = cfg['habilitado'] == true;
        _nombreCtrl.text = (cfg['nombreAgente'] as String?) ?? '';
        _personalidadCtrl.text = (cfg['promptPersonalidad'] as String?) ?? '';
        _bienvenidaCtrl.text = (cfg['mensajeBienvenida'] as String?) ?? '';
        _horarioCtrl.text = (cfg['horarioTexto'] as String?) ?? '';
        _modo = (cfg['modo'] as String?) ?? 'SOLO_CONSULTA';
        _puedeCobrarYape = cfg['puedeCobrarYape'] == true;
        _escalarAHumano = cfg['escalarAHumano'] == true;
        _proveedorPropio = cfg['proveedorPropio'] == true;
        _proveedorTipo = cfg['proveedorTipo'] as String?;
        _proveedorModeloCtrl.text = (cfg['proveedorModelo'] as String?) ?? '';
        _apiKeyMask = cfg['proveedorApiKeyMask'] as String?;
        _proveedorAprobado = cfg['proveedorAprobado'] == true;
        _modeloProveedorGlobal = cfg['modeloProveedor'] as String?;
        _maxProductos = (cfg['maxProductosMostrar'] as num?)?.toInt() ?? 5;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('No se pudo cargar la configuración: $e', ok: false);
    }
  }

  Future<void> _guardar() async {
    final id = _empresaId;
    if (id == null) return;
    setState(() => _guardando = true);
    try {
      final data = <String, dynamic>{
        'habilitado': _habilitado,
        'nombreAgente': _nombreCtrl.text.trim(),
        'promptPersonalidad': _personalidadCtrl.text.trim(),
        'mensajeBienvenida': _bienvenidaCtrl.text.trim(),
        'horarioTexto': _horarioCtrl.text.trim(),
        'modo': _modo,
        'puedeCobrarYape': _puedeCobrarYape,
        'escalarAHumano': _escalarAHumano,
        'proveedorPropio': _proveedorPropio,
      };
      if (_proveedorPropio) {
        if (_proveedorTipo != null) data['proveedorTipo'] = _proveedorTipo;
        data['proveedorModelo'] = _proveedorModeloCtrl.text.trim();
      }
      // La API key solo se manda si el usuario escribió una nueva.
      final apiKey = _apiKeyCtrl.text.trim();
      if (apiKey.isNotEmpty) data['proveedorApiKey'] = apiKey;

      final cfg = await _empresaDs.updateAgenteIa(empresaId: id, data: data);
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _apiKeyMask = cfg['proveedorApiKeyMask'] as String?;
        _proveedorAprobado = cfg['proveedorAprobado'] == true;
        _apiKeyCtrl.clear();
      });
      _snack('Configuración guardada', ok: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _snack(_mensajeError(e), ok: false);
    }
  }

  String _mensajeError(Object e) {
    final s = e.toString();
    return s.length > 160 ? '${s.substring(0, 160)}…' : s;
  }

  void _snack(String msg, {required bool ok}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? Colors.green : AppColors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SmartAppBar(title: 'Agente IA'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const AppSubtitle(
                  'Un asistente por WhatsApp que responde consultas de tu '
                  'catálogo y — si lo activas — registra ventas para que el '
                  'cliente pague por Yape. Tú defines su nombre, tono y alcance.',
                  fontSize: 11,
                  color: AppColors.blueGrey,
                ),
                const SizedBox(height: 14),
                _buildEstadoChip(),
                const SizedBox(height: 14),
                _buildPersonalidadCard(),
                const SizedBox(height: 14),
                _buildAlcanceCard(),
                const SizedBox(height: 14),
                _buildProveedorCard(),
                const SizedBox(height: 20),
                CustomButton(
                  text: _guardando ? 'Guardando…' : 'Guardar',
                  backgroundColor: AppColors.blue1,
                  textColor: AppColors.white,
                  onPressed: _guardando ? null : _guardar,
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildEstadoChip() {
    final color = _habilitado ? Colors.green : AppColors.blueGrey;
    return Row(
      children: [
        Icon(_habilitado ? Icons.check_circle : Icons.info_outline,
            size: 16, color: color),
        const SizedBox(width: 6),
        AppSubtitle(
          _habilitado ? 'Agente activo' : 'Agente apagado',
          fontSize: 11,
          color: color,
        ),
      ],
    );
  }

  Widget _buildPersonalidadCard() {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTitle('Personalidad', fontSize: 14, color: AppColors.blue1),
            const SizedBox(height: 12),
            CustomText(
              label: 'Nombre del agente',
              controller: _nombreCtrl,
              hintText: 'Sofía, asistente de tu tienda…',
              maxLength: 40,
            ),
            const SizedBox(height: 12),
            CustomText(
              label: 'Tono y estilo',
              controller: _personalidadCtrl,
              hintText:
                  'Cercano y breve. Trata de usted. No prometas descuentos.',
              maxLines: 4,
              minLines: 3,
              maxLength: 500,
              helperText:
                  'Solo define cómo habla. Las reglas de seguridad y los '
                  'precios los pone el sistema.',
            ),
            const SizedBox(height: 12),
            CustomText(
              label: 'Mensaje de bienvenida',
              controller: _bienvenidaCtrl,
              hintText: '¡Hola! ¿En qué te ayudo hoy?',
              maxLines: 2,
              minLines: 1,
              maxLength: 300,
            ),
            const SizedBox(height: 12),
            CustomText(
              label: 'Horario de atención (opcional)',
              controller: _horarioCtrl,
              hintText: 'Lun a Sáb de 9am a 7pm',
              maxLength: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlcanceCard() {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTitle('Alcance', fontSize: 14, color: AppColors.blue1),
            const SizedBox(height: 6),
            const AppSubtitle(
              '¿Qué puede hacer el agente?',
              fontSize: 11,
              color: AppColors.blueGrey,
            ),
            const SizedBox(height: 10),
            _buildModoSelector(),
            const SizedBox(height: 4),
            if (_modo == 'VENDE')
              CustomSwitchTile(
                title: 'Puede cobrar por Yape',
                subtitle:
                    'Al confirmar el pedido genera el cobro con monto exacto',
                value: _puedeCobrarYape,
                onChanged: (v) => setState(() => _puedeCobrarYape = v),
              ),
            CustomSwitchTile(
              title: 'Derivar a un humano',
              subtitle: 'Si no puede resolver, avisa que atenderá una persona',
              value: _escalarAHumano,
              onChanged: (v) => setState(() => _escalarAHumano = v),
            ),
            const Divider(height: 24),
            CustomSwitchTile(
              title: 'Agente encendido',
              subtitle: 'Interruptor maestro. Apágalo para pausarlo por completo',
              value: _habilitado,
              onChanged: (v) => setState(() => _habilitado = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModoSelector() {
    Widget opcion(String valor, String titulo, String desc, IconData icono) {
      final sel = _modo == valor;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _modo = valor),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: sel ? AppColors.blue1.withValues(alpha: 0.08) : AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: sel ? AppColors.blue1 : Colors.grey.shade300,
                width: sel ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(icono,
                    size: 22,
                    color: sel ? AppColors.blue1 : AppColors.blueGrey),
                const SizedBox(height: 6),
                AppSubtitle(titulo,
                    fontSize: 12,
                    color: sel ? AppColors.blue1 : AppColors.blueGrey),
                const SizedBox(height: 2),
                AppSubtitle(desc,
                    fontSize: 9,
                    textAlign: TextAlign.center,
                    color: AppColors.blueGrey),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        opcion('SOLO_CONSULTA', 'Solo consulta',
            'Responde sobre productos', Icons.chat_bubble_outline),
        const SizedBox(width: 10),
        opcion('VENDE', 'Vende', 'Consulta y registra ventas',
            Icons.shopping_cart_outlined),
      ],
    );
  }

  Widget _buildProveedorCard() {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTitle('Proveedor de IA', fontSize: 14, color: AppColors.blue1),
            const SizedBox(height: 6),
            AppSubtitle(
              _modeloProveedorGlobal != null
                  ? 'Por defecto usamos el motor de Syncronize ($_modeloProveedorGlobal). '
                      'Muestra hasta $_maxProductos productos por respuesta.'
                  : 'Por defecto usamos el motor de Syncronize.',
              fontSize: 10,
              color: AppColors.blueGrey,
            ),
            const SizedBox(height: 6),
            CustomSwitchTile(
              title: 'Usar mi propio proveedor',
              subtitle: 'Trae tu cuenta (Claude/OpenAI/Gemini) y tu API key',
              value: _proveedorPropio,
              onChanged: (v) => setState(() => _proveedorPropio = v),
            ),
            if (_proveedorPropio) ...[
              const SizedBox(height: 8),
              _buildAprobacionChip(),
              const SizedBox(height: 12),
              _buildProveedorDropdown(),
              const SizedBox(height: 12),
              CustomText(
                label: 'Modelo',
                controller: _proveedorModeloCtrl,
                hintText: 'claude-haiku-4-5-20251001',
              ),
              const SizedBox(height: 12),
              CustomText(
                label: 'API Key',
                controller: _apiKeyCtrl,
                obscureText: true,
                hintText: _apiKeyMask != null
                    ? 'Actual: $_apiKeyMask — dejar vacío para conservar'
                    : 'Pega tu API key',
                helperText:
                    'Se guarda cifrada. Un administrador de Syncronize debe '
                    'aprobarla con una prueba antes de activarse.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAprobacionChip() {
    final color = _proveedorAprobado ? Colors.green : AppColors.orange;
    return Row(
      children: [
        Icon(_proveedorAprobado ? Icons.verified : Icons.hourglass_bottom,
            size: 15, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: AppSubtitle(
            _proveedorAprobado
                ? 'Proveedor aprobado y en uso'
                : 'Pendiente de aprobación del administrador de Syncronize',
            fontSize: 10,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProveedorDropdown() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Proveedor',
        labelStyle: const TextStyle(fontSize: 12, color: AppColors.blue1),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: AppColors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _tiposProveedor.contains(_proveedorTipo)
              ? _proveedorTipo
              : null,
          hint: const Text('Elige tu proveedor',
              style: TextStyle(fontSize: 12, color: AppColors.blueGrey)),
          items: const [
            DropdownMenuItem(value: 'claude', child: Text('Claude (Anthropic)')),
            DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
            DropdownMenuItem(value: 'gemini', child: Text('Gemini (Google)')),
          ],
          onChanged: (v) => setState(() => _proveedorTipo = v),
        ),
      ),
    );
  }
}
