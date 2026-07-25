import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/custom_switch_tile.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../../consultas_externas/domain/entities/consulta_ruc.dart';
import '../../../consultas_externas/domain/usecases/consultar_ruc_usecase.dart';
import '../widgets/sincronizar_series_dialog.dart';

/// Administración de EMISORES de facturación (multi-RUC a nivel empresa).
///
/// El RUC principal vive en la configuración de la empresa; aquí se
/// registran los RUC socio: identidad fiscal + credenciales del proveedor
/// (Syncrofact: token de la company del socio) + sus series. Cualquier
/// sede puede emitir con cualquier emisor activo.
class EmisoresFacturacionPage extends StatefulWidget {
  const EmisoresFacturacionPage({super.key});

  @override
  State<EmisoresFacturacionPage> createState() =>
      _EmisoresFacturacionPageState();
}

class _EmisoresFacturacionPageState extends State<EmisoresFacturacionPage> {
  List<Map<String, dynamic>> _emisores = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final resp = await locator<DioClient>().get('/sunat/emisores/admin');
      if (!mounted) return;
      setState(() {
        _emisores = (resp.data as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los emisores';
        _cargando = false;
      });
    }
  }

  Future<void> _eliminar(Map<String, dynamic> emisor) async {
    final ok = await ConfirmDialog.show(
      context: context,
      type: ConfirmDialogType.destructive,
      title: 'Desactivar emisor',
      message: '¿Desactivar el emisor ${emisor['razonSocial']} '
          '(RUC ${emisor['ruc']})? Dejará de aparecer al cobrar. '
          'Sus comprobantes ya emitidos no se tocan.',
      confirmText: 'Desactivar',
    );
    if (ok != true || !mounted) return;
    try {
      await locator<DioClient>().delete('/sunat/emisores/${emisor['id']}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Emisor desactivado'),
        backgroundColor: Colors.green,
      ));
      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No se pudo desactivar: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _sincronizarSeries(Map<String, dynamic> emisor) async {
    final ok = await showSincronizarSeriesDialog(
      context,
      emisorId: emisor['id'] as String,
    );
    if (ok == true && mounted) _cargar();
  }

  Future<void> _abrirForm({Map<String, dynamic>? emisor}) async {
    final guardado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EmisorFormSheet(emisor: emisor),
    );
    if (guardado == true && mounted) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Emisores de Facturación',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirForm(),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Agregar emisor'),
      ),
      body: GradientBackground(
        child: RefreshIndicator(
          onRefresh: _cargar,
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _mensajeCentrado(_error!, esError: true)
                  : _emisores.isEmpty
                      ? _mensajeCentrado(
                          'Sin emisores adicionales.\n\nRegistra aquí un RUC '
                          'socio (con su propia cuenta en el proveedor de '
                          'facturación) para emitir Boletas/Facturas con él '
                          'desde cualquier sede.')
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                          itemCount: _emisores.length,
                          itemBuilder: (_, i) => _cardEmisor(_emisores[i]),
                        ),
        ),
      ),
    );
  }

  Widget _mensajeCentrado(String texto, {bool esError = false}) {
    // ListView para que RefreshIndicator funcione con contenido corto.
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 120, 32, 0),
          child: Column(
            children: [
              Icon(
                esError ? Icons.cloud_off_outlined : Icons.account_balance_outlined,
                size: 48,
                color: esError ? Colors.red.shade300 : Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                texto,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cardEmisor(Map<String, dynamic> e) {
    final activo = e['facturacionActiva'] == true;
    final sync = e['seriesSincronizadasEn'] as String?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GradientContainer(
        borderColor: activo ? Colors.teal.shade300 : Colors.grey.shade300,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.handshake_outlined,
                      size: 18,
                      color: activo ? Colors.teal.shade700 : Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e['razonSocial']?.toString() ?? '',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('RUC ${e['ruc']}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: activo ? Colors.teal.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color:
                              activo ? Colors.teal.shade300 : Colors.grey.shade300),
                    ),
                    child: Text(
                      activo ? 'ACTIVO' : 'INACTIVO',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: activo
                              ? Colors.teal.shade700
                              : Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _chipSerie('Factura',
                      '${e['serieFactura']} · ${e['ultimoNumeroFactura']}'),
                  _chipSerie('Boleta',
                      '${e['serieBoleta']} · ${e['ultimoNumeroBoleta']}'),
                  if (sync != null)
                    _chipSerie('Sync', sync.substring(0, 10), gris: true),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Editar',
                      isOutlined: true,
                      borderColor: AppColors.blue1,
                      textColor: AppColors.blue1,
                      onPressed: () => _abrirForm(emisor: e),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomButton(
                      text: 'Sincronizar Series',
                      isOutlined: true,
                      borderColor: Colors.teal,
                      textColor: Colors.teal.shade700,
                      onPressed: () => _sincronizarSeries(e),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _eliminar(e),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.delete_outline,
                          size: 20, color: Colors.red.shade400),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipSerie(String label, String valor, {bool gris = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: gris ? Colors.grey.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: gris ? Colors.grey.shade300 : Colors.blue.shade200,
            width: 0.6),
      ),
      child: Text(
        '$label: $valor',
        style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: gris ? Colors.grey.shade600 : AppColors.blue1),
      ),
    );
  }
}

// ── Form de emisor (crear / editar) ──

class _EmisorFormSheet extends StatefulWidget {
  final Map<String, dynamic>? emisor;
  const _EmisorFormSheet({this.emisor});

  @override
  State<_EmisorFormSheet> createState() => _EmisorFormSheetState();
}

class _EmisorFormSheetState extends State<_EmisorFormSheet> {
  final _rucCtrl = TextEditingController();
  final _razonCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _rutaCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _resolucionCtrl = TextEditingController();
  bool _activo = false;
  bool _guardando = false;
  bool _probando = false;
  bool _buscandoRuc = false;
  int _rucReqId = 0;
  // Company del token en Syncrofact, detectado por "Probar Conexión". Se
  // persiste en proveedorConfig.companyId (sin él, el envío usaría el
  // company del principal y el proveedor lo rechaza).
  int? _companyIdDetectado;

  bool get _esEdicion => widget.emisor != null;

  @override
  void initState() {
    super.initState();
    final e = widget.emisor;
    if (e != null) {
      _rucCtrl.text = e['ruc']?.toString() ?? '';
      _razonCtrl.text = e['razonSocial']?.toString() ?? '';
      _direccionCtrl.text = e['direccionFiscal']?.toString() ?? '';
      _rutaCtrl.text = e['proveedorRuta']?.toString() ?? '';
      _tokenCtrl.text = e['proveedorToken']?.toString() ?? '';
      _resolucionCtrl.text = e['resolucionSunat']?.toString() ?? '';
      _activo = e['facturacionActiva'] == true;
    }
  }

  @override
  void dispose() {
    _rucCtrl.dispose();
    _razonCtrl.dispose();
    _direccionCtrl.dispose();
    _rutaCtrl.dispose();
    _tokenCtrl.dispose();
    _resolucionCtrl.dispose();
    super.dispose();
  }

  /// Autollenado SUNAT/Factiliza al completar los 11 dígitos del RUC.
  Future<void> _onRucChanged(String value) async {
    final ruc = value.trim();
    if (ruc.length != 11 || !RegExp(r'^\d{11}$').hasMatch(ruc)) {
      _rucReqId++;
      if (_buscandoRuc) setState(() => _buscandoRuc = false);
      return;
    }
    final myId = ++_rucReqId;
    setState(() => _buscandoRuc = true);
    try {
      final result = await locator<ConsultarRucUseCase>()(ruc);
      if (!mounted || myId != _rucReqId) return;
      if (result is Success<ConsultaRuc>) {
        final data = result.data;
        setState(() {
          _razonCtrl.text = data.razonSocial;
          final dir = data.direccionCompleta.isNotEmpty
              ? data.direccionCompleta
              : data.direccion;
          if (dir.isNotEmpty) _direccionCtrl.text = dir;
        });
        final advertencia = !data.esActivo
            ? 'RUC ${data.estado}: SUNAT rechazará sus comprobantes'
            : !data.esHabido
                ? 'RUC NO HABIDO: SUNAT puede rechazar sus comprobantes'
                : null;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(advertencia ?? 'Datos cargados desde SUNAT'),
          backgroundColor:
              advertencia != null ? Colors.orange.shade800 : Colors.green,
        ));
      }
    } catch (_) {
      // Consulta externa caída: se llena manual.
    } finally {
      if (mounted && myId == _rucReqId) setState(() => _buscandoRuc = false);
    }
  }

  /// Prueba credenciales tentativas contra el proveedor (no persiste).
  Future<void> _probarConexion() async {
    final ruta = _rutaCtrl.text.trim();
    final token = _tokenCtrl.text.trim();
    if (ruta.isEmpty || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Completa la URL API y el Token para probar'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    setState(() => _probando = true);
    try {
      final dio = locator<DioClient>();
      var proveedor = 'SYNCROFACT';
      try {
        final cfg = await dio.get('/sunat/configuracion');
        final p = (cfg.data as Map?)?['proveedorActivo'] as String?;
        if (p != null && p.isNotEmpty) proveedor = p;
      } catch (_) {}
      final resp = await dio.post('/sunat/configuracion/probar', data: {
        'proveedorActivo': proveedor,
        'proveedorRuta': ruta,
        'proveedorToken': token,
      });
      if (!mounted) return;
      final data = Map<String, dynamic>.from(resp.data as Map);
      final ok = data['ok'] == true;
      if (ok && data['companyId'] != null) {
        _companyIdDetectado = (data['companyId'] as num).toInt();
      }
      final branches =
          (data['branches'] as List?)?.whereType<Map>().toList() ?? const [];
      showDialog(
        context: context,
        builder: (ctx) => StyledDialog(
          accentColor: ok ? Colors.green.shade600 : Colors.red.shade600,
          icon: ok ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
          titulo: ok ? 'Conexión exitosa' : 'Conexión fallida',
          content: [
            Text(data['mensaje']?.toString() ?? '',
                style: const TextStyle(fontSize: 12)),
            if (!ok && data['error'] != null) ...[
              const SizedBox(height: 6),
              Text(data['error'].toString(),
                  style: TextStyle(fontSize: 11, color: Colors.red.shade700)),
            ],
            if (branches.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...branches.map((b) => Text(
                    '• ${b['codigo']} — ${b['nombre']} (${b['totalSeries']} series)',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade800),
                  )),
              const SizedBox(height: 6),
              Text(
                'Guarda el emisor y usa "Sincronizar Series" para traerlas.',
                style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade500),
              ),
            ],
          ],
          actions: [
            Expanded(
              child: CustomButton(
                text: 'Entendido',
                backgroundColor:
                    ok ? Colors.green.shade600 : Colors.red.shade600,
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error probando conexión: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _probando = false);
    }
  }

  Future<void> _guardar() async {
    final ruc = _rucCtrl.text.trim();
    final razon = _razonCtrl.text.trim();
    if (ruc.length != 11 || razon.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('RUC (11 dígitos) y Razón Social son obligatorios'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    setState(() => _guardando = true);
    try {
      final dio = locator<DioClient>();
      final data = <String, dynamic>{
        'razonSocial': razon,
        if (_direccionCtrl.text.trim().isNotEmpty)
          'direccionFiscal': _direccionCtrl.text.trim(),
        if (_rutaCtrl.text.trim().isNotEmpty)
          'proveedorRuta': _rutaCtrl.text.trim(),
        if (_tokenCtrl.text.trim().isNotEmpty)
          'proveedorToken': _tokenCtrl.text.trim(),
        if (_resolucionCtrl.text.trim().isNotEmpty)
          'resolucionSunat': _resolucionCtrl.text.trim(),
        'facturacionActiva': _activo,
      };
      // proveedorConfig: conservar lo existente (ej. branchId del sync) y
      // sumar el companyId detectado por "Probar Conexión".
      final cfg = Map<String, dynamic>.from(
          (widget.emisor?['proveedorConfig'] as Map?) ?? {});
      if (_companyIdDetectado != null) {
        cfg['companyId'] = _companyIdDetectado;
      }
      if (cfg.isNotEmpty) data['proveedorConfig'] = cfg;
      if (_esEdicion) {
        await dio.put('/sunat/emisores/${widget.emisor!['id']}', data: data);
      } else {
        await dio.post('/sunat/emisores', data: {'ruc': ruc, ...data});
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No se pudo guardar: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ));
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.handshake_outlined,
                    size: 18, color: Colors.teal.shade700),
                const SizedBox(width: 8),
                Text(
                  _esEdicion ? 'Editar Emisor' : 'Nuevo Emisor (RUC socio)',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 14),
            CustomText(
              controller: _rucCtrl,
              label: 'RUC',
              hintText: 'Ej: 20XXXXXXXXX (11 dígitos)',
              borderColor: Colors.teal,
              fieldType: FieldType.number,
              maxLength: 11,
              enabled: !_esEdicion,
              onChanged: _esEdicion ? null : _onRucChanged,
            ),
            if (_buscandoRuc) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: Colors.teal),
                  ),
                  const SizedBox(width: 8),
                  Text('Consultando RUC en SUNAT…',
                      style: TextStyle(
                          fontSize: 10, color: Colors.teal.shade700)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            CustomText(
              controller: _razonCtrl,
              label: 'Razón Social',
              borderColor: Colors.teal,
            ),
            const SizedBox(height: 12),
            CustomText(
              controller: _direccionCtrl,
              label: 'Dirección Fiscal',
              borderColor: Colors.teal,
            ),
            const SizedBox(height: 12),
            CustomText(
              controller: _rutaCtrl,
              label: 'URL API Facturación',
              hintText: 'URL API del proveedor (Syncrofact)',
              borderColor: Colors.teal,
            ),
            const SizedBox(height: 12),
            CustomText(
              controller: _tokenCtrl,
              label: 'Token Facturación',
              hintText: 'Token de la empresa socio en el proveedor',
              borderColor: Colors.teal,
            ),
            const SizedBox(height: 12),
            CustomText(
              controller: _resolucionCtrl,
              label: 'Resolución SUNAT (opcional)',
              borderColor: Colors.teal,
            ),
            const SizedBox(height: 8),
            CustomSwitchTile(
              title: 'Emisor activo',
              subtitle: _activo
                  ? 'Disponible al cobrar (Boleta/Factura con este RUC)'
                  : 'No aparecerá como opción al cobrar',
              subtitleStyle: TextStyle(
                color: _activo ? Colors.teal : Colors.grey.shade600,
              ),
              value: _activo,
              onChanged: (v) => setState(() => _activo = v),
              activeColor: Colors.teal,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Probar Conexión',
                    isOutlined: true,
                    borderColor: Colors.teal,
                    textColor: Colors.teal.shade700,
                    isLoading: _probando,
                    onPressed: _probando ? null : _probarConexion,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    text: _esEdicion ? 'Guardar' : 'Registrar',
                    backgroundColor: Colors.teal,
                    isLoading: _guardando,
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
