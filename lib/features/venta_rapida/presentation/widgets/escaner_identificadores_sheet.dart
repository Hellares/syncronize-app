import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_colors.dart';

/// Escáner que queda ABIERTO y va llenando los identificadores de una línea.
///
/// El escáner de a uno obliga a entrar y salir de pantalla completa por cada
/// equipo: vendiendo tres celulares son tres viajes, y en el medio se pierde
/// de vista qué se está timbrando. Acá la cámara vive en un sheet de media
/// pantalla —el carrito queda visible arriba— y cada lectura cae en la
/// siguiente casilla vacía.
///
/// Se cierra solo al completar la última.
Future<void> mostrarEscanerIdentificadores(
  BuildContext context, {
  required String etiqueta,
  required int unidades,
  required List<String> actuales,
  required int indiceInicial,
  required void Function(int indice, String valor) onCapturado,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EscanerSheet(
      etiqueta: etiqueta,
      unidades: unidades,
      actuales: actuales,
      indiceInicial: indiceInicial,
      onCapturado: onCapturado,
    ),
  );
}

class _EscanerSheet extends StatefulWidget {
  final String etiqueta;
  final int unidades;
  final List<String> actuales;
  final int indiceInicial;
  final void Function(int indice, String valor) onCapturado;

  const _EscanerSheet({
    required this.etiqueta,
    required this.unidades,
    required this.actuales,
    required this.indiceInicial,
    required this.onCapturado,
  });

  @override
  State<_EscanerSheet> createState() => _EscanerSheetState();
}

class _EscanerSheetState extends State<_EscanerSheet> {
  final _camara = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  /// Copia local que avanza con cada lectura. No se lee del padre en cada
  /// detección porque el sheet no se reconstruye con el state del carrito.
  late List<String> _valores;

  /// El lector dispara la MISMA lectura muchas veces por segundo mientras el
  /// código siga en cuadro. Sin este guard, un solo equipo llenaba las tres
  /// casillas de una.
  String? _ultimo;
  DateTime _ultimoEn = DateTime.fromMillisecondsSinceEpoch(0);

  /// Aviso efímero sobre la cámara ("ya cargado", "listo").
  String? _mensaje;
  bool _mensajeEsError = false;

  @override
  void initState() {
    super.initState();
    _valores = List<String>.generate(
      widget.unidades,
      (i) => i < widget.actuales.length ? widget.actuales[i] : '',
    );
  }

  @override
  void dispose() {
    _camara.dispose();
    super.dispose();
  }

  int get _cargados => _valores.where((v) => v.trim().isNotEmpty).length;

  /// Siguiente casilla a llenar: desde la que se tocó hacia adelante y, si
  /// esas ya están, la primera vacía de arriba.
  int? get _siguienteIndice {
    for (var i = widget.indiceInicial; i < _valores.length; i++) {
      if (_valores[i].trim().isEmpty) return i;
    }
    for (var i = 0; i < _valores.length; i++) {
      if (_valores[i].trim().isEmpty) return i;
    }
    return null;
  }

  void _onDetect(BarcodeCapture captura) {
    final codigo = captura.barcodes.firstOrNull?.rawValue?.trim();
    if (codigo == null || codigo.isEmpty) return;

    final ahora = DateTime.now();
    if (codigo == _ultimo &&
        ahora.difference(_ultimoEn) < const Duration(milliseconds: 1500)) {
      return;
    }
    _ultimo = codigo;
    _ultimoEn = ahora;

    // Dos unidades no comparten IMEI: si ya está, es que se timbró dos veces
    // el mismo equipo. El backend lo rechazaría igual, pero recién al cobrar.
    if (_valores.any((v) => v.trim() == codigo)) {
      HapticFeedback.heavyImpact();
      setState(() {
        _mensaje = 'Ese ${widget.etiqueta} ya está cargado';
        _mensajeEsError = true;
      });
      return;
    }

    final i = _siguienteIndice;
    if (i == null) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _valores[i] = codigo;
      _mensaje = '${i + 1} · $codigo';
      _mensajeEsError = false;
    });
    widget.onCapturado(i, codigo);

    // Completo: se cierra solo, con un respiro para que se vea la última.
    if (_cargados == widget.unidades) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) Navigator.of(context).maybePop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final completo = _cargados == widget.unidades;
    return SizedBox(
      // Media pantalla: la cámara alcanza para apuntar y el carrito sigue
      // visible arriba, que es de dónde salió el pedido.
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
                  Icon(Icons.qr_code_scanner,
                      size: 18, color: AppColors.blue1),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.etiqueta,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '$_cargados de ${widget.unidades}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: completo ? Colors.green.shade700 : AppColors.blue1,
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
                              : Colors.black.withValues(alpha: 0.72),
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
                                maxLines: 1,
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
            // Lo capturado hasta ahora, para poder revisar sin cerrar.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: SizedBox(
                height: 26,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.unidades,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final v = _valores[i].trim();
                    final lleno = v.isNotEmpty;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: lleno
                            ? Colors.green.withValues(alpha: 0.10)
                            : Colors.grey.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: lleno
                              ? Colors.green.shade400
                              : Colors.grey.shade400,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        lleno ? '${i + 1} · $v' : '${i + 1} · —',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: lleno
                              ? Colors.green.shade800
                              : Colors.grey.shade600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(
                      completo ? 'Listo' : 'Cerrar y completar a mano',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
