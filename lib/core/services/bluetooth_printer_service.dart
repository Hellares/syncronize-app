import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothPrinterService {
  static const _lastPrinterKey = 'last_bt_printer_mac';

  /// Verifica si el Bluetooth está encendido
  static Future<bool> isBluetoothOn() async {
    return await PrintBluetoothThermal.bluetoothEnabled;
  }

  /// Verifica si hay una impresora conectada
  static Future<bool> isConnected() async {
    return await PrintBluetoothThermal.connectionStatus;
  }

  /// Escanea dispositivos Bluetooth vinculados
  static Future<List<BluetoothInfo>> scanDevices() async {
    final devices = await PrintBluetoothThermal.pairedBluetooths;
    return devices;
  }

  /// Conecta a una impresora por MAC address
  static Future<bool> connect(String macAddress) async {
    final result = await PrintBluetoothThermal.connect(
      macPrinterAddress: macAddress,
    );
    if (result) {
      await _saveLastPrinter(macAddress);
    }
    return result;
  }

  /// Desconecta la impresora actual
  static Future<bool> disconnect() async {
    return await PrintBluetoothThermal.disconnect;
  }

  /// Envía bytes ESC/POS a la impresora
  static Future<bool> printTicket(List<int> bytes) async {
    final connected = await isConnected();
    if (!connected) return false;
    final result = await PrintBluetoothThermal.writeBytes(Uint8List.fromList(bytes));
    return result;
  }

  /// Guarda la última impresora usada
  static Future<void> _saveLastPrinter(String mac) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPrinterKey, mac);
  }

  /// Obtiene la MAC de la última impresora usada
  static Future<String?> getLastPrinterMac() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastPrinterKey);
  }

  /// Obtiene el tamaño de papel configurado (58mm o 80mm)
  static Future<int> getPaperSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('bt_printer_paper_size') ?? 80;
  }

  /// Guarda el tamaño de papel
  static Future<void> setPaperSize(int size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bt_printer_paper_size', size);
  }
}
