import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../../../core/fonts/app_fonts.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/services/bluetooth_printer_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/custom_button.dart';

class BluetoothPrinterSheet extends StatefulWidget {
  final List<int> ticketBytes;

  const BluetoothPrinterSheet({super.key, required this.ticketBytes});

  @override
  State<BluetoothPrinterSheet> createState() => _BluetoothPrinterSheetState();
}

class _BluetoothPrinterSheetState extends State<BluetoothPrinterSheet> {
  List<BluetoothInfo> _devices = [];
  bool _isScanning = false;
  bool _isPrinting = false;
  bool _isConnecting = false;
  String? _connectedMac;
  String? _lastPrinterMac;
  String? _statusMessage;
  int _paperSize = 80;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _lastPrinterMac = await BluetoothPrinterService.getLastPrinterMac();
    _paperSize = await BluetoothPrinterService.getPaperSize();

    final btOn = await BluetoothPrinterService.isBluetoothOn();
    if (!btOn) {
      setState(() => _statusMessage = 'Bluetooth desactivado. Activa el Bluetooth e intenta de nuevo.');
      return;
    }

    final connected = await BluetoothPrinterService.isConnected();
    if (connected && _lastPrinterMac != null) {
      setState(() => _connectedMac = _lastPrinterMac);
    }

    _scanDevices();
  }

  Future<void> _scanDevices() async {
    setState(() {
      _isScanning = true;
      _statusMessage = null;
    });

    try {
      final devices = await BluetoothPrinterService.scanDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          _isScanning = false;
          if (devices.isEmpty) {
            _statusMessage = 'No se encontraron impresoras vinculadas. Vincula tu impresora desde la configuracion de Bluetooth del dispositivo.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _statusMessage = 'Error al buscar dispositivos: $e';
        });
      }
    }
  }

  Future<void> _connectAndPrint(BluetoothInfo device) async {
    final mac = device.macAdress;

    // Conectar si no está conectado a esta impresora
    if (_connectedMac != mac) {
      setState(() {
        _isConnecting = true;
        _statusMessage = 'Conectando a ${device.name}...';
      });

      // Desconectar la anterior si hay
      if (_connectedMac != null) {
        await BluetoothPrinterService.disconnect();
      }

      final connected = await BluetoothPrinterService.connect(mac);
      if (!connected) {
        if (mounted) {
          setState(() {
            _isConnecting = false;
            _statusMessage = 'No se pudo conectar a ${device.name}. Verifica que la impresora este encendida.';
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _connectedMac = mac;
          _isConnecting = false;
        });
      }
    }

    // Imprimir
    setState(() {
      _isPrinting = true;
      _statusMessage = 'Imprimiendo...';
    });

    try {
      final result = await BluetoothPrinterService.printTicket(widget.ticketBytes);
      if (mounted) {
        setState(() => _isPrinting = false);
        if (result) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket impreso correctamente'), backgroundColor: Colors.green),
          );
        } else {
          setState(() => _statusMessage = 'Error al imprimir. Intenta de nuevo.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPrinting = false;
          _statusMessage = 'Error al imprimir: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.print_outlined, color: AppColors.blue1, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppTitle('Impresora Bluetooth', fontSize: 15, color: AppColors.blue1),
                      AppLabelText(
                        'Selecciona una impresora termica',
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ],
                  ),
                ),
                // Paper size toggle
                InkWell(
                  onTap: () {
                    final newSize = _paperSize == 80 ? 58 : 80;
                    setState(() => _paperSize = newSize);
                    BluetoothPrinterService.setPaperSize(newSize);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bluechip,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_paperSize}mm',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue1,
                        fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 20, color: Colors.grey.shade400),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status message
            if (_statusMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GradientContainer(
                  gradient: AppGradients.blueWhiteBlue(),
                  shadowStyle: ShadowStyle.none,
                  borderColor: _statusMessage!.contains('Error') || _statusMessage!.contains('desactivado')
                      ? Colors.red.shade200
                      : AppColors.blueborder,
                  borderWidth: 0.6,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Icon(
                          _isPrinting || _isConnecting
                              ? Icons.bluetooth_searching
                              : _statusMessage!.contains('Error') || _statusMessage!.contains('desactivado')
                                  ? Icons.error_outline
                                  : Icons.info_outline,
                          size: 16,
                          color: _statusMessage!.contains('Error') || _statusMessage!.contains('desactivado')
                              ? Colors.red.shade400
                              : AppColors.blue1,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Device list
            if (_isScanning)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue1),
                    ),
                    SizedBox(height: 8),
                    Text('Buscando dispositivos...', style: TextStyle(fontSize: 11)),
                  ],
                ),
              )
            else if (_devices.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _devices.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    final isConnected = _connectedMac == device.macAdress;
                    final isLast = _lastPrinterMac == device.macAdress;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: isConnected
                              ? Colors.green.withValues(alpha: 0.1)
                              : AppColors.blue1.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                          size: 18,
                          color: isConnected ? Colors.green : AppColors.blue1,
                        ),
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              device.name.isNotEmpty ? device.name : 'Sin nombre',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.blue2,
                                fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isLast && !isConnected) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Reciente',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade700,
                                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                                ),
                              ),
                            ),
                          ],
                          if (isConnected) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Conectada',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        device.macAdress,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade500,
                          fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                        ),
                      ),
                      trailing: (_isConnecting || _isPrinting)
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue1),
                            )
                          : Icon(Icons.print_outlined, size: 18, color: AppColors.blue1),
                      onTap: (_isConnecting || _isPrinting) ? null : () => _connectAndPrint(device),
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Buscar impresoras',
                    icon: const Icon(Icons.refresh, size: 14, color: AppColors.blue1),
                    isOutlined: true,
                    borderColor: AppColors.blue1,
                    textColor: AppColors.blue1,
                    enableShadows: false,
                    height: 38,
                    borderRadius: 8,
                    isLoading: _isScanning,
                    onPressed: _isScanning ? null : _scanDevices,
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 8),
          ],
        ),
      ),
    );
  }
}
