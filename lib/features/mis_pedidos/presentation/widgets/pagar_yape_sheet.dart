import 'dart:async';
import 'dart:io' show Platform;

import 'package:android_intent_plus/android_intent.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';

/// Hoja de pago Yape/Plin AUTOMÁTICO (api-yape), genérica: sirve para pagar
/// un pedido del marketplace o el adelanto de separación de una cotización.
///
/// Al abrirse llama a `POST cobroPath`:
/// - Si la empresa tiene el cobro automático habilitado, muestra el QR + el
///   monto EXACTO a yapear (payAmount con céntimos únicos) y espera la
///   confirmación automática (poll de `pollPath` cada 4s; `esPagado` evalúa
///   la respuesta — el webhook confirma solo).
/// - Si no está habilitado, cierra devolviendo `false` → la página cae al
///   flujo manual.
///
/// Devuelve `true` si el pago se confirmó.
class PagarYapeSheet extends StatefulWidget {
  /// Endpoint POST que crea el charge (devuelve habilitado/payAmount/qr/celular).
  final String cobroPath;

  /// Body opcional del POST (ej. `{monto: 50}` para pago parcial de una
  /// cotización). Null = el backend decide el monto.
  final Map<String, dynamic>? cobroBody;

  /// Endpoint GET que se pollea para detectar la confirmación.
  final String pollPath;

  /// Evalúa la respuesta del poll: true = pagado (cierra con éxito).
  final bool Function(Map<String, dynamic> data) esPagado;

  const PagarYapeSheet({
    super.key,
    required this.cobroPath,
    this.cobroBody,
    required this.pollPath,
    required this.esPagado,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String cobroPath,
    Map<String, dynamic>? cobroBody,
    required String pollPath,
    required bool Function(Map<String, dynamic> data) esPagado,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => PagarYapeSheet(
        cobroPath: cobroPath,
        cobroBody: cobroBody,
        pollPath: pollPath,
        esPagado: esPagado,
      ),
    );
  }

  @override
  State<PagarYapeSheet> createState() => _PagarYapeSheetState();
}

class _PagarYapeSheetState extends State<PagarYapeSheet> {
  static const Color _morado = Color(0xFF742284); // Yape brand

  bool _cargando = true;
  bool _habilitado = false;
  double? _payAmount;
  String? _qrUrl;
  String? _celular; // número Yape del comercio (se copia, NO se muestra)
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _iniciarCobro();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _iniciarCobro() async {
    try {
      final resp = await locator<DioClient>()
          .post(widget.cobroPath, data: widget.cobroBody);
      final data = resp.data as Map<String, dynamic>;
      if (!mounted) return;

      final habilitado = data['habilitado'] as bool? ?? false;
      if (!habilitado) {
        // Sin cobro automático → la página cae al flujo manual (foto).
        Navigator.of(context).pop(false);
        return;
      }

      setState(() {
        _cargando = false;
        _habilitado = true;
        _payAmount = (data['payAmount'] as num?)?.toDouble();
        _qrUrl = data['qrYapeUrl'] as String?;
        _celular = data['celular'] as String?;
      });

      // Poll: el webhook valida el pago solo → el estado del pedido cambia.
      _poll = Timer.periodic(const Duration(seconds: 4), (_) => _verificarPago());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo iniciar el cobro. Intenta de nuevo.';
      });
    }
  }

  /// Copia el número Yape del comercio al portapapeles (SIN mostrarlo en
  /// pantalla) y abre la app de Yape para que el comprador pague de una.
  Future<void> _copiarNumeroYAbrirYape() async {
    final celular = _celular;
    if (celular == null || celular.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: celular));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Número copiado ✓ — pégalo en Yape y envía el monto exacto'),
        backgroundColor: Color(0xFF742284),
      ),
    );
    // Abrir la app Yape. 1º por PACKAGE (infalible si está instalada — no
    // depende de que Yape registre el scheme), 2º deeplink, 3º Play Store.
    if (Platform.isAndroid) {
      try {
        const intent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          category: 'android.intent.category.LAUNCHER',
          package: 'com.bcp.innovacxion.yapeapp',
        );
        await intent.launch();
        return;
      } catch (_) {}
    }
    try {
      final abierto = await launchUrl(
        Uri.parse('yape://'),
        mode: LaunchMode.externalApplication,
      );
      if (abierto) return;
    } catch (_) {}
    try {
      await launchUrl(
        Uri.parse('https://play.google.com/store/apps/details?id=com.bcp.innovacxion.yapeapp'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  Future<void> _verificarPago() async {
    try {
      final resp = await locator<DioClient>().get(widget.pollPath);
      if (widget.esPagado(resp.data as Map<String, dynamic>)) {
        _poll?.cancel();
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (_) {
      // Silencioso: el siguiente tick reintenta.
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _morado.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded, color: _morado, size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Pagar con Yape',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_cargando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: _morado),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade600, fontSize: 13)),
              )
            else if (_habilitado) ...[
              // QR del comercio
              if (_qrUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: _qrUrl!,
                    width: 190,
                    height: 190,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const SizedBox(
                      width: 190,
                      height: 190,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.qr_code_2_rounded, size: 120, color: _morado),
                  ),
                )
              else
                const Icon(Icons.qr_code_2_rounded, size: 120, color: _morado),
              const SizedBox(height: 12),

              // Monto EXACTO (los céntimos identifican tu pago)
              const Text(
                'Yapea EXACTAMENTE',
                style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
              ),
              GestureDetector(
                onLongPress: () {
                  if (_payAmount != null) {
                    Clipboard.setData(ClipboardData(text: _payAmount!.toStringAsFixed(2)));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Monto copiado')),
                    );
                  }
                },
                child: Text(
                  'S/ ${_payAmount?.toStringAsFixed(2) ?? '--'}',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: _morado,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Los céntimos identifican tu pago. No redondees el monto.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 14),

              // Copiar el número Yape del comercio (sin mostrarlo) y abrir Yape.
              if (_celular != null && _celular!.isNotEmpty) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _copiarNumeroYAbrirYape,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _morado,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 17),
                    label: const Text(
                      'Copiar número y abrir Yape',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Se copia el número del comercio; pégalo en Yape al elegir a quién yapear.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 10),
              ],

              // Estado de espera
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _morado.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _morado),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Esperando tu pago… la confirmación es automática',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
