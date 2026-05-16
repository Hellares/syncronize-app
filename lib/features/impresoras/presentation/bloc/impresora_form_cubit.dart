import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/impresora_config.dart';
import '../../domain/services/impresoras_manager.dart';
import 'impresora_form_state.dart';

@injectable
class ImpresoraFormCubit extends Cubit<ImpresoraFormState> {
  final ImpresorasManager _manager;
  ImpresoraFormCubit(this._manager) : super(const ImpresoraFormInitial());

  Future<void> cargarParaEditar(String id) async {
    emit(const ImpresoraFormLoading());
    final imp = await _manager.getById(id);
    if (isClosed) return;
    if (imp == null) {
      emit(const ImpresoraFormError('Impresora no encontrada'));
      return;
    }
    emit(ImpresoraFormEditing(imp));
  }

  Future<void> scanBluetooth() async {
    emit(const ImpresoraFormScanning());
    try {
      final result = await _manager.scanBluetooth();
      if (isClosed) return;
      if (!result.ok) {
        emit(ImpresoraFormError(result.error!));
        return;
      }
      emit(ImpresoraFormDevicesFound(result.devices));
    } catch (e) {
      if (isClosed) return;
      emit(ImpresoraFormError('Error escaneando dispositivos: $e'));
    }
  }

  Future<ImpresoraConfig?> guardar({
    String? idExistente,
    required String nombre,
    required TipoConexionImpresora tipoConexion,
    required String direccion,
    required AnchoPapel anchoPapel,
    required int tamanoFuentePx,
    required bool autoImprimirVentaRapida,
    required bool esPrincipal,
  }) async {
    emit(const ImpresoraFormSaving());
    try {
      ImpresoraConfig resultado;
      if (idExistente != null) {
        resultado = await _manager.actualizar(
          ImpresoraConfig(
            id: idExistente,
            nombre: nombre,
            tipoConexion: tipoConexion,
            direccion: direccion,
            anchoPapel: anchoPapel,
            tamanoFuentePx: tamanoFuentePx,
            autoImprimirVentaRapida: autoImprimirVentaRapida,
            esPrincipal: esPrincipal,
          ),
        );
      } else {
        resultado = await _manager.crear(
          ImpresoraConfig(
            id: '', // ignorado, manager genera uno nuevo
            nombre: nombre,
            tipoConexion: tipoConexion,
            direccion: direccion,
            anchoPapel: anchoPapel,
            tamanoFuentePx: tamanoFuentePx,
            autoImprimirVentaRapida: autoImprimirVentaRapida,
            esPrincipal: esPrincipal,
          ),
        );
      }
      if (isClosed) return resultado;
      emit(ImpresoraFormSaved(resultado));
      return resultado;
    } catch (e) {
      if (!isClosed) emit(ImpresoraFormError('No se pudo guardar: $e'));
      return null;
    }
  }

  /// Imprime un ticket simple de prueba en la impresora con los datos
  /// actuales del form (sin necesidad de guardar primero).
  Future<void> imprimirPrueba({
    required String nombre,
    required TipoConexionImpresora tipoConexion,
    required String direccion,
    required AnchoPapel anchoPapel,
  }) async {
    if (direccion.isEmpty) {
      emit(const ImpresoraFormPrintResult(
        ok: false,
        message: 'Elige un dispositivo primero',
      ));
      return;
    }
    emit(const ImpresoraFormPrinting());
    try {
      final bytes = await _generarBytesPrueba(
        nombre: nombre,
        anchoPapel: anchoPapel,
      );
      final ok = await _manager.imprimirEn(
        ImpresoraConfig(
          id: '_test',
          nombre: nombre,
          tipoConexion: tipoConexion,
          direccion: direccion,
          anchoPapel: anchoPapel,
        ),
        bytes,
      );
      if (isClosed) return;
      emit(ImpresoraFormPrintResult(
        ok: ok,
        message: ok
            ? 'Ticket de prueba enviado'
            : 'No se pudo conectar. Causas comunes:\n'
              '• La impresora está apagada o fuera de rango.\n'
              '• Otro celular está conectado a la misma impresora '
              '(Bluetooth solo permite 1 a la vez).\n'
              '• Apagá la impresora 5 seg y prendela para reset.',
      ));
    } catch (e) {
      if (isClosed) return;
      emit(ImpresoraFormPrintResult(
        ok: false,
        message: 'Error imprimiendo: $e',
      ));
    }
  }

  Future<List<int>> _generarBytesPrueba({
    required String nombre,
    required AnchoPapel anchoPapel,
  }) async {
    final profile = await CapabilityProfile.load();
    final paper = anchoPapel == AnchoPapel.mm58 ? PaperSize.mm58 : PaperSize.mm80;
    final gen = Generator(paper, profile);

    final List<int> bytes = [];
    bytes.addAll(gen.text(
      'TICKET DE PRUEBA',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    ));
    bytes.addAll(gen.feed(1));
    bytes.addAll(gen.text(
      'Impresora: $nombre',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(gen.text(
      'Papel: ${anchoPapel.label}',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(gen.hr());
    bytes.addAll(gen.text(
      'Si lees esto, la conexion funciona correctamente.',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(gen.hr());
    bytes.addAll(gen.text(
      DateTime.now().toString().substring(0, 19),
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(gen.feed(2));
    bytes.addAll(gen.cut());
    return bytes;
  }
}
