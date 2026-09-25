import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_colors.dart';

/// Qué pasó con una lectura. Lo decide quien sabe del carrito; el sheet solo
/// lo muestra.
class LecturaEscaneada {
  final bool ok;
  final String mensaje;

  /// La lectura agregó una unidad y tiene sentido ofrecer "+1" para sumar
  /// otra igual sin volver a timbrar. No lo es abrir el selector de variante
  /// ni un error.
  final bool repetible;

  const LecturaEscaneada.ok(this.mensaje, {this.repetible = true}) : ok = true;
  const LecturaEscaneada.error(this.mensaje)
      : ok = false,
        repetible = false;
}

/// Escáner de la venta rápida: queda ABIERTO y cada lectura entra al carrito,
/// como en un POS con lector.
///
/// El escáner de a uno obligaba a abrir y cerrar la cámara por cada producto.
/// Acá la cámara vive en media pantalla —la grilla y el badge del carrito
/// siguen visibles arriba— y se cierra con "Listo".
///
/// Reusa las dos guardas del escáner de IMEI
/// ([mostrarEscanerIdentificadores]): `mobile_scanner` emite la MISMA lectura
/// varias veces por segundo mientras el código siga en cuadro.
Future<void> mostrarEscanerVenta(
  BuildContext context, {
  required Future<LecturaEscaneada> Function(String codigo) onCodigo,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EscanerVentaSheet(onCodigo: onCodigo),
  );
}

class _EscanerVentaSheet extends StatefulWidget {
  final Future<LecturaEscaneada> Function(String codigo) onCodigo;

  const _EscanerVentaSheet({required this.onCodigo});

  @override
  State<_EscanerVentaSheet> createState() => _EscanerVentaSheetState();
}

class _EscanerVentaSheetState extends State<_EscanerVentaSheet> {
  final _camara = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  /// Anti-repetición: el mismo código dentro de esta ventana se ignora. Para
  /// sumar otro igual se saca el producto del cuadro y se vuelve a pasar, o
  /// se usa "+1".
  static const _ventanaRepeticion = Duration(milliseconds: 2000);
  String? _ultimo;
  DateTime _ultimoEn = DateTime.fromMillisecondsSinceEpoch(0);

  /// Mientras se resuelve una lectura (o está abierto el selector de
  /// variante encima) no se procesa otra: dos resoluciones cruzadas
  /// agregarían en desorden o abrirían dos sheets.
  bool _ocupado = false;

  String? _mensaje;
  bool _mensajeEsError = false;

  /// Último código que agregó algo: es el que repite el botón "+1".
  String? _repetible;
  int _agregados = 0;

  @override
  void dispose() {
    _camara.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture captura) {
    final codigo = captura.barcodes.firstOrNull?.rawValue?.trim();
    if (codigo == null || codigo.isEmpty || _ocupado) return;

    final ahora = DateTime.now();
    if (codigo == _ultimo && ahora.difference(_ultimoEn) < _ventanaRepeticion) {
      return;
    }
    _ultimo = codigo;
    _ultimoEn = ahora;
    _procesar(codigo);
  }

  Future<void> _procesar(String codigo) async {
    setState(() => _ocupado = true);
    LecturaEscaneada r;
    try {
      r = await widget.onCodigo(codigo);
    } catch (_) {
      r = const LecturaEscaneada.error('No se pudo buscar el código');
    }
    if (!mounted) return;
    if (r.ok) {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
    } else {
      HapticFeedback.heavyImpact();
    }
    setState(() {
      _ocupado = false;
      _mensaje = r.mensaje;
      _mensajeEsError = !r.ok;
      if (r.ok && r.repetible) {
        _agregados++;
        _repetible = codigo;
      } else if (!r.ok) {
        _repetible = null;
      }
    });
    // La ventana anti-repetición corre desde que TERMINÓ: si abrir el
    // selector de variante tardó, el código sigue en cuadro al volver.
    _ultimoEn = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Media pantalla: alcanza para apuntar y deja ver la grilla y el
      // carrito arriba.
      height: MediaQuery.of(context).size.height * 0.55,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.qr_code_scanner, size: 18, color: AppColors.blue1),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Escanear productos',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (_agregados > 0)
                    Text(
                      '$_agregados agregado${_agregados == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.green.shade700,
                      ),
                    ),
                  IconButton(
                    tooltip: 'Linterna',
                    icon: ValueListenableBuilder(
                      valueListenable: _camara,
                      builder: (_, estado, __) => Icon(
                        estado.torchState == TorchState.on
                            ? Icons.flash_on
                            : Icons.flash_off,
                        size: 20,
                      ),
                    ),
                    onPressed: () => _camara.toggleTorch(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(controller: _camara, onDetect: _onDetect),
                  // Guía de encuadre.
                  Center(
                    child: Container(
                      width: 260,
                      height: 110,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.blue1, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  if (_ocupado)
                    const Positioned(
                      top: 12,
                      right: 12,
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (_mensaje != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _mensajeEsError
                              ? Colors.red.shade700.withValues(alpha: 0.92)
                              : Colors.green.shade700.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _mensajeEsError
                                  ? Icons.error_outline
                                  : Icons.check_circle_outline,
                              size: 15,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _mensaje!,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    // Seis iguales no se timbran seis veces.
                    if (_repetible != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _ocupado ? null : () => _procesar(_repetible!),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text(
                            '+1 igual',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    if (_repetible != null) const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.blue1),
                        child: const Text(
                          'Listo',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
