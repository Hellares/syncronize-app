import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// Configuración de la integración Yape (api-yape) por empresa.
/// Mapea la empresa con su cuenta en api-yape para que los cobros Yape/Plin se
/// validen automáticamente. Los secretos se guardan enmascarados: dejar el
/// campo en blanco conserva el valor actual.
class IntegracionYapePage extends StatefulWidget {
  const IntegracionYapePage({super.key});

  @override
  State<IntegracionYapePage> createState() => _IntegracionYapePageState();
}

class _IntegracionYapePageState extends State<IntegracionYapePage> {
  final _empresaDs = locator<EmpresaRemoteDataSource>();
  final _localStorage = locator<LocalStorageService>();

  final _apiBaseUrlCtrl = TextEditingController(
    text: 'https://yape.syncronize.net.pe',
  );
  final _accountIdCtrl = TextEditingController();
  final _accountApiKeyCtrl = TextEditingController();
  final _webhookSecretCtrl = TextEditingController();

  bool _loading = true;
  bool _guardando = false;
  bool _probando = false;
  bool _habilitado = true;
  bool _configurado = false;
  String? _accountApiKeyMask;
  String? _webhookSecretMask;
  String _webhookUrl = '';

  String? get _empresaId => _localStorage.getString(StorageConstants.tenantId);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _apiBaseUrlCtrl.dispose();
    _accountIdCtrl.dispose();
    _accountApiKeyCtrl.dispose();
    _webhookSecretCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final id = _empresaId;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final cfg = await _empresaDs.getIntegracionYape(id);
      if (!mounted) return;
      setState(() {
        _configurado = cfg['configurado'] == true;
        _habilitado = cfg['habilitado'] == true;
        if (cfg['apiBaseUrl'] != null) {
          _apiBaseUrlCtrl.text = cfg['apiBaseUrl'] as String;
        }
        if (cfg['accountId'] != null) {
          _accountIdCtrl.text = cfg['accountId'] as String;
        }
        _accountApiKeyMask = cfg['accountApiKeyMask'] as String?;
        _webhookSecretMask = cfg['webhookSecretMask'] as String?;
        _webhookUrl = (cfg['webhookUrl'] as String?) ?? '';
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
        'apiBaseUrl': _apiBaseUrlCtrl.text.trim(),
        'accountId': _accountIdCtrl.text.trim(),
        'habilitado': _habilitado,
      };
      // Secretos: solo se mandan si el usuario escribió uno nuevo.
      final apiKey = _accountApiKeyCtrl.text.trim();
      final whSecret = _webhookSecretCtrl.text.trim();
      if (apiKey.isNotEmpty) data['accountApiKey'] = apiKey;
      if (whSecret.isNotEmpty) data['webhookSecret'] = whSecret;

      final cfg = await _empresaDs.updateIntegracionYape(
        empresaId: id,
        data: data,
      );
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _configurado = cfg['configurado'] == true;
        _accountApiKeyMask = cfg['accountApiKeyMask'] as String?;
        _webhookSecretMask = cfg['webhookSecretMask'] as String?;
        _webhookUrl = (cfg['webhookUrl'] as String?) ?? _webhookUrl;
        _accountApiKeyCtrl.clear();
        _webhookSecretCtrl.clear();
      });
      _snack('Integración guardada', ok: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _snack(_mensajeError(e), ok: false);
    }
  }

  Future<void> _probar() async {
    final id = _empresaId;
    if (id == null) return;
    setState(() => _probando = true);
    try {
      final res = await _empresaDs.probarIntegracionYape(id);
      if (!mounted) return;
      setState(() => _probando = false);
      final ok = res['ok'] == true;
      _snack((res['mensaje'] as String?) ?? (ok ? 'Conexión OK' : 'Falló'),
          ok: ok);
    } catch (e) {
      if (!mounted) return;
      setState(() => _probando = false);
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
      appBar: const SmartAppBar(title: 'Integración Yape'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const AppSubtitle(
                  'Conecta tu cuenta de api-yape para validar automáticamente '
                  'los cobros Yape/Plin. Crea la cuenta en el panel de api-yape '
                  'y pega aquí sus credenciales.',
                  fontSize: 11,
                  color: AppColors.blueGrey,
                ),
                const SizedBox(height: 14),
                _buildEstadoChip(),
                const SizedBox(height: 14),
                _buildFormCard(),
                const SizedBox(height: 14),
                _buildWebhookCard(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Guardar',
                        backgroundColor: AppColors.blue1,
                        textColor: AppColors.white,
                        onPressed: _guardando ? null : _guardar,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomButton(
                        text: _probando ? 'Probando…' : 'Probar conexión',
                        isOutlined: true,
                        borderColor: AppColors.blue1,
                        textColor: AppColors.blue1,
                        enableShadows: false,
                        onPressed: (_probando || !_configurado) ? null : _probar,
                      ),
                    ),
                  ],
                ),
                if (!_configurado) ...[
                  const SizedBox(height: 8),
                  const AppSubtitle(
                    'Guarda la configuración para habilitar la prueba de conexión.',
                    fontSize: 10,
                    color: AppColors.blueGrey,
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _buildEstadoChip() {
    final activo = _configurado && _habilitado;
    final color = activo ? Colors.green : AppColors.blueGrey;
    return Row(
      children: [
        Icon(activo ? Icons.check_circle : Icons.info_outline,
            size: 16, color: color),
        const SizedBox(width: 6),
        AppSubtitle(
          _configurado
              ? (_habilitado ? 'Integración activa' : 'Configurada (deshabilitada)')
              : 'Sin configurar',
          fontSize: 11,
          color: color,
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTitle('Credenciales api-yape',
                fontSize: 14, color: AppColors.blue1),
            const SizedBox(height: 14),
            CustomText(
              label: 'URL base de api-yape',
              controller: _apiBaseUrlCtrl,
              hintText: 'https://yape.syncronize.net.pe',
            ),
            const SizedBox(height: 12),
            CustomText(
              label: 'Account ID',
              controller: _accountIdCtrl,
              hintText: 'id de la cuenta en api-yape',
            ),
            const SizedBox(height: 12),
            CustomText(
              label: 'Account API Key (acc_…)',
              controller: _accountApiKeyCtrl,
              hintText: _accountApiKeyMask != null
                  ? 'Actual: $_accountApiKeyMask — dejar vacío para conservar'
                  : 'acc_…',
            ),
            const SizedBox(height: 12),
            CustomText(
              label: 'Webhook Secret (whsec_…)',
              controller: _webhookSecretCtrl,
              hintText: _webhookSecretMask != null
                  ? 'Actual: $_webhookSecretMask — dejar vacío para conservar'
                  : 'whsec_…',
            ),
            const SizedBox(height: 6),
            CustomSwitchTile(
              title: 'Integración habilitada',
              subtitle: 'Si se apaga, los cobros vuelven a modo manual',
              value: _habilitado,
              onChanged: (v) => setState(() => _habilitado = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebhookCard() {
    if (_webhookUrl.isEmpty) return const SizedBox.shrink();
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTitle('Webhook a configurar en api-yape',
                fontSize: 13, color: AppColors.blue1),
            const SizedBox(height: 6),
            const AppSubtitle(
              'En el panel admin de api-yape, pega esta URL en el webhook de la '
              'cuenta para que confirme los pagos:',
              fontSize: 10,
              color: AppColors.blueGrey,
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      _webhookUrl,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.blue1),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _webhookUrl));
                      _snack('URL copiada', ok: true);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.copy, size: 16, color: AppColors.blue1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
