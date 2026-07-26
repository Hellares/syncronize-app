import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';

/// Captura la firma del cliente y devuelve el PNG en bytes (null si cancela).
///
/// El lienzo es apaisado a propósito: firmar en una franja ancha sale más
/// natural que en un cuadrado. Quien firma es el CLIENTE, no el técnico, así
/// que el texto habla en segunda persona y el botón de limpiar está a mano.
class FirmaSheet extends StatefulWidget {
  final String titulo;

  const FirmaSheet({super.key, required this.titulo});

  static Future<Uint8List?> show(BuildContext context, {String? titulo}) {
    return showModalBottomSheet<Uint8List>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FirmaSheet(titulo: titulo ?? 'Firma'),
    );
  }

  @override
  State<FirmaSheet> createState() => _FirmaSheetState();
}

class _FirmaSheetState extends State<FirmaSheet> {
  late final SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 2.5,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    // Habilita/deshabilita "Guardar" según haya trazo.
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hayTrazo = _controller.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.draw_outlined,
                    size: 18, color: AppColors.blue1),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue1,
                    ),
                  ),
                ),
                if (hayTrazo)
                  TextButton.icon(
                    onPressed: () => setState(_controller.clear),
                    icon: const Icon(Icons.refresh, size: 15),
                    label: const Text('Limpiar',
                        style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            Text(
              'Firma dentro del recuadro con el dedo o un lápiz táctil',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.blue1.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: Signature(
                controller: _controller,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomButton(
                  text: 'Cancelar',
                  onPressed: () => Navigator.pop(context),
                  backgroundColor: Colors.transparent,
                  borderColor: AppColors.blue3,
                  borderWidth: 0.6,
                  textColor: AppColors.blue3,
                  enableShadows: false,
                ),
                const SizedBox(width: 8),
                CustomButton(
                  text: 'Guardar firma',
                  // Sin trazo no se guarda: una firma en blanco no prueba nada.
                  onPressed: !hayTrazo
                      ? null
                      : () async {
                          final bytes = await _controller.toPngBytes();
                          if (!context.mounted) return;
                          Navigator.pop(context, bytes);
                        },
                  backgroundColor:
                      hayTrazo ? AppColors.blue1 : Colors.grey.shade300,
                  borderColor:
                      hayTrazo ? AppColors.blue1 : Colors.grey.shade300,
                  borderWidth: 0.6,
                  textColor: Colors.white,
                  enableShadows: false,
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
