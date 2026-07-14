import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/constants/storage_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_switch_tile.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../data/datasources/empresa_remote_datasource.dart';

/// Vinculación del WhatsApp de la empresa (Evolution API): se escanea un
/// QR una sola vez (como WhatsApp Web) y el sistema envía solo las
/// notificaciones — p.ej. el ticket de envío del premio al ganador.
class IntegracionWhatsappPage extends StatefulWidget {
  const IntegracionWhatsappPage({super.key});

  @override
  State<IntegracionWhatsappPage> createState() =>
      _IntegracionWhatsappPageState();
}

class _IntegracionWhatsappPageState extends State<IntegracionWhatsappPage> {
  final _empresaDs = locator<EmpresaRemoteDataSource>();
  final _localStorage = locator<LocalStorageService>();

  final _plantillaCtrl = TextEditingController();
  final _plantillaPagoDinamicaCtrl = TextEditingController();
  final _plantillaPagoSorteoCtrl = TextEditingController();
  final _plantillaConfDinamicaCtrl = TextEditingController();
  final _plantillaConfSorteoCtrl = TextEditingController();
  final _agenciaCtrl = TextEditingController();
  final _numeroPagoCtrl = TextEditingController();

  bool _loading = true;
  bool _guardando = false;
  bool _vinculando = false;
  bool _disponible = true;
  bool _habilitado = true;
  String? _estado; // CONECTADO | PENDIENTE_QR | DESCONECTADO | null
  String? _numero;
  String _plantillaDefault = '';
  String _plantillaPagoDinamicaDefault = '';
  String _plantillaPagoSorteoDefault = '';
  String _plantillaConfDinamicaDefault = '';
  String _plantillaConfSorteoDefault = '';

  /// QR vigente (bytes decodificados del data-uri) mientras se vincula.
  Uint8List? _qrBytes;
  Timer? _pollTimer;
  int _pollIntentos = 0;

  String? get _empresaId => _localStorage.getString(StorageConstants.tenantId);

  bool get _conectado => _estado == 'CONECTADO';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _plantillaCtrl.dispose();
    _plantillaPagoDinamicaCtrl.dispose();
    _plantillaPagoSorteoCtrl.dispose();
    _plantillaConfDinamicaCtrl.dispose();
    _plantillaConfSorteoCtrl.dispose();
    _agenciaCtrl.dispose();
    _numeroPagoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final id = _empresaId;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final cfg = await _empresaDs.getWhatsapp(id);
      if (!mounted) return;
      setState(() {
        _disponible = cfg['disponible'] != false;
        _estado = cfg['estado'] as String?;
        _numero = cfg['numero'] as String?;
        _habilitado = cfg['habilitado'] != false;
        _plantillaDefault = (cfg['plantillaDefault'] as String?) ?? '';
        _plantillaCtrl.text =
            (cfg['plantillaPremio'] as String?) ?? _plantillaDefault;
        _plantillaPagoDinamicaDefault =
            (cfg['plantillaPagoDinamicaDefault'] as String?) ?? '';
        _plantillaPagoDinamicaCtrl.text =
            (cfg['plantillaPagoDinamica'] as String?) ??
                _plantillaPagoDinamicaDefault;
        _plantillaPagoSorteoDefault =
            (cfg['plantillaPagoSorteoDefault'] as String?) ?? '';
        _plantillaPagoSorteoCtrl.text =
            (cfg['plantillaPagoSorteo'] as String?) ??
                _plantillaPagoSorteoDefault;
        _plantillaConfDinamicaDefault =
            (cfg['plantillaConfirmacionDinamicaDefault'] as String?) ?? '';
        _plantillaConfDinamicaCtrl.text =
            (cfg['plantillaConfirmacionDinamica'] as String?) ??
                _plantillaConfDinamicaDefault;
        _plantillaConfSorteoDefault =
            (cfg['plantillaConfirmacionSorteoDefault'] as String?) ?? '';
        _plantillaConfSorteoCtrl.text =
            (cfg['plantillaConfirmacionSorteo'] as String?) ??
                _plantillaConfSorteoDefault;
        _agenciaCtrl.text = (cfg['agenciaEnvio'] as String?) ?? 'SHALOM';
        _numeroPagoCtrl.text = (cfg['numeroPago'] as String?) ?? '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('No se pudo cargar la configuración: ${_msg(e)}', ok: false);
    }
  }

  /// Pide el QR y arranca el polling del estado (el webhook actualiza el
  /// backend apenas se escanea).
  Future<void> _vincular() async {
    final id = _empresaId;
    if (id == null) return;
    setState(() => _vinculando = true);
    try {
      final res = await _empresaDs.vincularWhatsapp(id);
      if (!mounted) return;
      final estado = res['estado'] as String?;
      if (estado == 'CONECTADO') {
        setState(() {
          _vinculando = false;
          _estado = 'CONECTADO';
          _qrBytes = null;
        });
        _snack('WhatsApp ya estaba conectado ✅', ok: true);
        return;
      }
      final qr = res['qrBase64'] as String?;
      setState(() {
        _vinculando = false;
        _estado = estado;
        _qrBytes = qr != null ? _decodeDataUri(qr) : null;
      });
      _iniciarPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() => _vinculando = false);
      _snack(_msg(e), ok: false);
    }
  }

  void _iniciarPolling() {
    _pollTimer?.cancel();
    _pollIntentos = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (t) async {
      final id = _empresaId;
      if (id == null || !mounted) return t.cancel();
      // El QR rota cada ~40s; a los 2 min dejamos de esperar.
      if (++_pollIntentos > 40) {
        t.cancel();
        if (mounted) setState(() => _qrBytes = null);
        return;
      }
      try {
        final cfg = await _empresaDs.getWhatsapp(id);
        if (!mounted) return t.cancel();
        final estado = cfg['estado'] as String?;
        if (estado == 'CONECTADO') {
          t.cancel();
          setState(() {
            _estado = 'CONECTADO';
            _numero = cfg['numero'] as String?;
            _qrBytes = null;
          });
          _snack('¡WhatsApp vinculado! ✅', ok: true);
        }
      } catch (_) {
        // seguimos intentando hasta el límite
      }
    });
  }

  Future<void> _desvincular() async {
    final id = _empresaId;
    if (id == null) return;
    final ok = await ConfirmDialog.show(
      context: context,
      type: ConfirmDialogType.destructive,
      title: 'Desvincular WhatsApp',
      message: 'Se cerrará la sesión y los envíos automáticos se detendrán. '
          'La plantilla se conserva. ¿Desvincular?',
      confirmText: 'Desvincular',
      icon: Icons.link_off,
    );
    if (ok != true) return;
    try {
      await _empresaDs.desvincularWhatsapp(id);
      if (!mounted) return;
      setState(() {
        _estado = 'DESCONECTADO';
        _numero = null;
        _qrBytes = null;
      });
      _pollTimer?.cancel();
      _snack('WhatsApp desvinculado', ok: true);
    } catch (e) {
      if (!mounted) return;
      _snack(_msg(e), ok: false);
    }
  }

  Future<void> _guardar({bool restaurarDefault = false}) async {
    final id = _empresaId;
    if (id == null) return;
    final numeroPago = _numeroPagoCtrl.text.trim();
    if (numeroPago.isNotEmpty &&
        !RegExp(r'^9\d{8}$').hasMatch(numeroPago)) {
      _snack('El celular de pagos debe tener 9 dígitos (empieza en 9)',
          ok: false);
      return;
    }
    setState(() => _guardando = true);
    try {
      final texto =
          restaurarDefault ? '' : _plantillaCtrl.text.trimRight();
      final textoPagoDin =
          restaurarDefault ? '' : _plantillaPagoDinamicaCtrl.text.trimRight();
      final textoPagoSor =
          restaurarDefault ? '' : _plantillaPagoSorteoCtrl.text.trimRight();
      final textoConfDin =
          restaurarDefault ? '' : _plantillaConfDinamicaCtrl.text.trimRight();
      final textoConfSor =
          restaurarDefault ? '' : _plantillaConfSorteoCtrl.text.trimRight();
      // Si el texto es idéntico a la default, guardamos '' (= default):
      // así futuras mejoras de la plantilla del sistema le llegan solas.
      final esDefault = texto.trim() == _plantillaDefault.trim();
      final esDefaultPagoDin =
          textoPagoDin.trim() == _plantillaPagoDinamicaDefault.trim();
      final esDefaultPagoSor =
          textoPagoSor.trim() == _plantillaPagoSorteoDefault.trim();
      final esDefaultConfDin =
          textoConfDin.trim() == _plantillaConfDinamicaDefault.trim();
      final esDefaultConfSor =
          textoConfSor.trim() == _plantillaConfSorteoDefault.trim();
      final cfg = await _empresaDs.updateWhatsapp(
        empresaId: id,
        data: {
          'plantillaPremio': esDefault || restaurarDefault ? '' : texto,
          'plantillaPagoDinamica':
              esDefaultPagoDin || restaurarDefault ? '' : textoPagoDin,
          'plantillaPagoSorteo':
              esDefaultPagoSor || restaurarDefault ? '' : textoPagoSor,
          'plantillaConfirmacionDinamica':
              esDefaultConfDin || restaurarDefault ? '' : textoConfDin,
          'plantillaConfirmacionSorteo':
              esDefaultConfSor || restaurarDefault ? '' : textoConfSor,
          'agenciaEnvio': _agenciaCtrl.text.trim(),
          // '' = quitar (el bot usa Yape de la integración o el vinculado).
          'numeroPago': numeroPago,
          'habilitado': _habilitado,
        },
      );
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _plantillaCtrl.text =
            (cfg['plantillaPremio'] as String?) ?? _plantillaDefault;
        _plantillaPagoDinamicaCtrl.text =
            (cfg['plantillaPagoDinamica'] as String?) ??
                _plantillaPagoDinamicaDefault;
        _plantillaPagoSorteoCtrl.text =
            (cfg['plantillaPagoSorteo'] as String?) ??
                _plantillaPagoSorteoDefault;
        _plantillaConfDinamicaCtrl.text =
            (cfg['plantillaConfirmacionDinamica'] as String?) ??
                _plantillaConfDinamicaDefault;
        _plantillaConfSorteoCtrl.text =
            (cfg['plantillaConfirmacionSorteo'] as String?) ??
                _plantillaConfSorteoDefault;
        _agenciaCtrl.text = (cfg['agenciaEnvio'] as String?) ?? 'SHALOM';
        _numeroPagoCtrl.text = (cfg['numeroPago'] as String?) ?? '';
      });
      _snack('Configuración guardada', ok: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _snack(_msg(e), ok: false);
    }
  }

  Uint8List? _decodeDataUri(String dataUri) {
    try {
      final coma = dataUri.indexOf(',');
      return base64Decode(coma >= 0 ? dataUri.substring(coma + 1) : dataUri);
    } catch (_) {
      return null;
    }
  }

  String _msg(Object e) {
    final s = e.toString();
    return s.length > 160 ? '${s.substring(0, 160)}…' : s;
  }

  void _snack(String msg, {required bool ok}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 12)),
      backgroundColor: ok ? Colors.green.shade700 : AppColors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SmartAppBar(title: 'WhatsApp de la empresa'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const AppSubtitle(
                  'Vincula el WhatsApp de tu negocio (como WhatsApp Web) y el '
                  'sistema enviará solo las notificaciones a tus clientes — '
                  'p.ej. el ticket de envío del premio al ganador del sorteo.',
                  fontSize: 11,
                  color: AppColors.blueGrey,
                ),
                const SizedBox(height: 14),
                _cardEstado(),
                if (_qrBytes != null) ...[
                  const SizedBox(height: 14),
                  _cardQr(),
                ],
                const SizedBox(height: 14),
                _cardPlantilla(),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _cardEstado() {
    final (color, icono, texto) = switch (_estado) {
      'CONECTADO' => (
          Colors.green.shade700,
          Icons.check_circle,
          'Conectado${_numero != null ? ' — +$_numero' : ''}',
        ),
      'PENDIENTE_QR' => (
          Colors.orange.shade800,
          Icons.qr_code_scanner,
          'Esperando escaneo del QR',
        ),
      'DESCONECTADO' => (
          AppColors.red,
          Icons.link_off,
          'Desconectado — vuelve a vincular',
        ),
      _ => (AppColors.blueGrey, Icons.info_outline, 'Sin vincular'),
    };
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: AppSubtitle(texto, fontSize: 12, color: color),
                ),
              ],
            ),
            if (!_disponible) ...[
              const SizedBox(height: 8),
              const AppSubtitle(
                'El servicio de WhatsApp no está disponible en este ambiente.',
                fontSize: 10.5,
                color: AppColors.red,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: _vinculando
                        ? 'Generando QR…'
                        : _conectado
                            ? 'Regenerar QR'
                            : 'Vincular WhatsApp',
                    backgroundColor: Colors.green.shade700,
                    textColor: Colors.white,
                    icon: const Icon(Icons.qr_code_2,
                        size: 16, color: Colors.white),
                    iconColor: Colors.white,
                    onPressed:
                        (_vinculando || !_disponible) ? null : _vincular,
                  ),
                ),
                if (_conectado) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomButton(
                      text: 'Desvincular',
                      isOutlined: true,
                      borderColor: AppColors.red,
                      textColor: AppColors.red,
                      enableShadows: false,
                      onPressed: _desvincular,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardQr() {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            AppTitle('Escanea con el WhatsApp del negocio',
                fontSize: 13, color: AppColors.blue1),
            const SizedBox(height: 4),
            const AppSubtitle(
              'WhatsApp → menú ⋮ → Dispositivos vinculados → Vincular '
              'dispositivo. El QR caduca en ~40 s: si expira toca '
              '"Regenerar QR".',
              fontSize: 10.5,
              color: AppColors.blueGrey,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Image.memory(
                _qrBytes!,
                width: 230,
                height: 230,
                gaplessPlayback: true,
              ),
            ),
            const SizedBox(height: 8),
            const AppSubtitle(
              'Esperando el escaneo…',
              fontSize: 10.5,
              color: AppColors.blueGrey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardPlantilla() {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTitle('Mensaje del premio enviado',
                fontSize: 13, color: AppColors.blue1),
            const SizedBox(height: 4),
            const AppSubtitle(
              'Variables: {saludo} {ganador} {premio} {agencia} {destino} '
              '{orden} {codigo} {clave} {empresa}. Las líneas cuyas '
              'variables queden vacías no se envían.',
              fontSize: 10,
              color: AppColors.blueGrey,
            ),
            const SizedBox(height: 10),
            CustomText(
              controller: _agenciaCtrl,
              label: 'Agencia de envíos (el bot la informa, no la pregunta)',
              hintText: 'ej. SHALOM',
              borderColor: AppColors.blue1,
              textCase: TextCase.upper,
            ),
            const SizedBox(height: 10),
            CustomText(
              controller: _plantillaCtrl,
              label: 'Plantilla (editable)',
              borderColor: AppColors.blue1,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              minLines: 6,
            ),
            const SizedBox(height: 14),
            AppTitle('Instrucciones de pago (bot)',
                fontSize: 13, color: AppColors.blue1),
            const SizedBox(height: 4),
            const AppSubtitle(
              'Mensaje del bot tras registrar al participante — uno por '
              'tipo. Variables: {monto} (precio de la participación) '
              '{numero} (celular de pagos) {empresa}. Puedes agregar el '
              'nombre de tu cuenta Yape, ej. "Yapea *{monto}* al '
              '*{numero}* (SYNCRONIZE)".',
              fontSize: 10,
              color: AppColors.blueGrey,
            ),
            const SizedBox(height: 10),
            CustomText(
              controller: _numeroPagoCtrl,
              label: 'Celular para pagos — {numero}',
              hintText: 'vacío = Yape configurado o el WhatsApp vinculado',
              borderColor: AppColors.blue1,
              keyboardType: TextInputType.phone,
              maxLength: 9,
            ),
            const SizedBox(height: 10),
            CustomText(
              controller: _plantillaPagoDinamicaCtrl,
              label: 'Pago — dinámicas (editable)',
              borderColor: AppColors.blue1,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              minLines: 4,
            ),
            const SizedBox(height: 10),
            CustomText(
              controller: _plantillaPagoSorteoCtrl,
              label: 'Pago — sorteos (editable)',
              borderColor: AppColors.blue1,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              minLines: 4,
            ),
            const SizedBox(height: 14),
            AppTitle('Confirmación de pago (bot)',
                fontSize: 13, color: AppColors.blue1),
            const SizedBox(height: 4),
            const AppSubtitle(
              'Cabecera del mensaje cuando VALIDAS el pago (después el bot '
              'pide/confirma los datos de envío). Variables: {nombre} '
              '{titulo} {ticket} {empresa}.',
              fontSize: 10,
              color: AppColors.blueGrey,
            ),
            const SizedBox(height: 10),
            CustomText(
              controller: _plantillaConfDinamicaCtrl,
              label: 'Confirmación — dinámicas (editable)',
              borderColor: AppColors.blue1,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              minLines: 3,
            ),
            const SizedBox(height: 10),
            CustomText(
              controller: _plantillaConfSorteoCtrl,
              label: 'Confirmación — sorteos (editable)',
              borderColor: AppColors.blue1,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              minLines: 3,
            ),
            const SizedBox(height: 6),
            CustomSwitchTile(
              title: 'Envíos automáticos habilitados',
              subtitle:
                  'Si se apaga, vuelve el envío manual de 2 pasos del app',
              value: _habilitado,
              onChanged: (v) => setState(() => _habilitado = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Restaurar default',
                    isOutlined: true,
                    borderColor: AppColors.blue1,
                    textColor: AppColors.blue1,
                    enableShadows: false,
                    onPressed: _guardando
                        ? null
                        : () {
                            _plantillaCtrl.text = _plantillaDefault;
                            _plantillaPagoDinamicaCtrl.text =
                                _plantillaPagoDinamicaDefault;
                            _plantillaPagoSorteoCtrl.text =
                                _plantillaPagoSorteoDefault;
                            _plantillaConfDinamicaCtrl.text =
                                _plantillaConfDinamicaDefault;
                            _plantillaConfSorteoCtrl.text =
                                _plantillaConfSorteoDefault;
                            _guardar(restaurarDefault: true);
                          },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomButton(
                    text: _guardando ? 'Guardando…' : 'Guardar',
                    backgroundColor: AppColors.blue1,
                    textColor: Colors.white,
                    onPressed: _guardando ? null : _guardar,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
