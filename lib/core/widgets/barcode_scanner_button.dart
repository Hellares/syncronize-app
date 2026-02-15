import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_colors.dart';

/// Botón reutilizable que abre un escáner de código de barras.
/// Al detectar un código, lo retorna via [onScanned] y cierra el escáner.
///
/// Uso con un TextEditingController:
/// ```dart
/// BarcodeScannerButton(
///   onScanned: (code) => myController.text = code,
/// )
/// ```
class BarcodeScannerButton extends StatelessWidget {
  final ValueChanged<String> onScanned;
  final IconData icon;
  final double iconSize;
  final Color? iconColor;

  const BarcodeScannerButton({
    super.key,
    required this.onScanned,
    this.icon = Icons.qr_code_scanner,
    this.iconSize = 17,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    // return IconButton(
    //   padding: EdgeInsets.zero,
    //   icon: Icon(icon, size: iconSize, color: iconColor ?? AppColors.blue1),
    //   tooltip: 'Escanear código de barras',
    //   onPressed: () => _openScanner(context),
    // );
    return GestureDetector(
      onTap: () => _openScanner(context),
      child: Padding(
        padding: EdgeInsets.only(right: 2),
        child: Icon(
          icon,
          size: iconSize, // ← compensas un poco el tamaño visual si quieres
          color: iconColor ?? AppColors.blue1,
        ),
      ),
    );
  }

  Future<void> _openScanner(BuildContext context) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _BarcodeScannerPage()),
    );
    if (result != null) {
      onScanned(result);
    }
  }
}

class _BarcodeScannerPage extends StatefulWidget {
  const _BarcodeScannerPage();

  @override
  State<_BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage> {
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _hasScanned = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _cameraController,
              builder: (_, state, __) {
                return Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
            onPressed: () => _cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _cameraController, onDetect: _onDetect),
          // Overlay con guía de escaneo
          Center(
            child: Container(
              width: 280,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.blue1, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Instrucción
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Apunta al código de barras',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    _hasScanned = true;
    Navigator.of(context).pop(barcode!.rawValue);
  }
}
