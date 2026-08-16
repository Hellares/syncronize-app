import 'package:equatable/equatable.dart';
import 'package:syncronize/config/environment/env_config.dart';

import 'perfil_trama.dart';

/// Cómo se habla con el equipo.
///
/// 🔴 No es un detalle cosmético: son DOS pilas de Bluetooth distintas, con
/// paquetes distintos, y una balanza solo funciona con la suya. El clásico
/// (SPP) es el mismo que usan las térmicas; BLE es otro mundo (servicios,
/// características, notificaciones).
///
/// La elección se guarda por equipo porque el cliente tiene balanzas de marcas
/// y proveedores distintos, y bien puede haber una de cada tipo en el mismo
/// mostrador.
enum TipoTransporte {
  /// Bluetooth clásico / SPP — `flutter_blue_classic`.
  clasico,

  /// Bluetooth Low Energy — `flutter_bluetooth_serial_ble`.
  ble,

  /// No hay equipo: genera tramas de mentira.
  ///
  /// 🔑 Es un transporte más y no un modo escondido a propósito. Así el visor
  /// y la venta se pueden probar sin hardware, y al mismo tiempo **nadie pesa
  /// con datos falsos sin saberlo**: hay que elegirlo explícitamente al
  /// configurar la balanza, y tanto la lista como el visor lo gritan.
  simulador;

  String get label {
    switch (this) {
      case TipoTransporte.clasico:
        return 'Bluetooth clásico (SPP)';
      case TipoTransporte.ble:
        return 'Bluetooth LE (BLE)';
      case TipoTransporte.simulador:
        return 'Simulador (sin equipo real)';
    }
  }

  String get ayuda {
    switch (this) {
      case TipoTransporte.clasico:
        return 'El mismo tipo que las impresoras térmicas. Si la balanza se empareja desde los ajustes de Android, es esta.';
      case TipoTransporte.ble:
        return 'No aparece en el emparejado de Android; se descubre al escanear desde la app.';
      case TipoTransporte.simulador:
        return 'Genera pesos de prueba para ver el flujo completo sin balanza. NO usar para vender.';
    }
  }

  bool get esSimulador => this == TipoTransporte.simulador;

  /// 🔴 El simulador NO existe en un build de producción.
  ///
  /// Es la única barrera que de verdad impide emitir un comprobante fiscal con
  /// un peso inventado. Los avisos naranjas ayudan, pero son avisos: alcanza
  /// con que alguien los ignore una vez. Acá el simulador directamente no se
  /// puede elegir ni usar.
  ///
  /// `EnvConfig.isProd` es una constante de COMPILACIÓN (`fromEnvironment`),
  /// así que en el APK de prod esta rama es muerta y el compilador puede
  /// sacarla del binario. No es un `if` que alguien pueda saltear.
  bool get disponibleEnEsteBuild => !esSimulador || !EnvConfig.isProd;

  /// Los que se ofrecen al configurar una balanza.
  static List<TipoTransporte> get elegibles =>
      values.where((t) => t.disponibleEnEsteBuild).toList();

  /// Los transportes reales todavía no están implementados: la config se puede
  /// dejar lista, pero al pesar el visor lo dice en vez de fingir.
  bool get puedeConectar => esSimulador && disponibleEnEsteBuild;

  static TipoTransporte fromString(String? v) {
    switch (v) {
      case 'ble':
        return TipoTransporte.ble;
      case 'simulador':
        return TipoTransporte.simulador;
      default:
        return TipoTransporte.clasico;
    }
  }
}

/// Una balanza configurada en este dispositivo.
///
/// Igual que las impresoras: la config es LOCAL (SharedPreferences) con
/// respaldo en el backend por dispositivo. Una balanza es física del mostrador
/// donde está el celular, no de la empresa: dos cajas pueden tener modelos
/// distintos y ninguna quiere la config de la otra.
class BalanzaConfig extends Equatable {
  final String id;
  final String nombre;
  final TipoTransporte transporte;

  /// MAC (clásico) o identificador del periférico (BLE).
  final String direccion;

  /// Cómo leer lo que manda. Es lo que cambia de marca a marca.
  final PerfilTrama perfil;

  /// La que se usa sin preguntar cuando se pide un peso. Con una sola balanza
  /// configurada da igual; con dos, evita un selector en cada venta.
  final bool esPrincipal;

  const BalanzaConfig({
    required this.id,
    required this.nombre,
    required this.transporte,
    required this.direccion,
    required this.perfil,
    this.esPrincipal = false,
  });

  BalanzaConfig copyWith({
    String? nombre,
    TipoTransporte? transporte,
    String? direccion,
    PerfilTrama? perfil,
    bool? esPrincipal,
  }) {
    return BalanzaConfig(
      id: id,
      nombre: nombre ?? this.nombre,
      transporte: transporte ?? this.transporte,
      direccion: direccion ?? this.direccion,
      perfil: perfil ?? this.perfil,
      esPrincipal: esPrincipal ?? this.esPrincipal,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'transporte': transporte.name,
        'direccion': direccion,
        'perfil': perfil.toJson(),
        'esPrincipal': esPrincipal,
      };

  factory BalanzaConfig.fromJson(Map<String, dynamic> json) {
    return BalanzaConfig(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? '',
      transporte: TipoTransporte.fromString(json['transporte'] as String?),
      direccion: json['direccion'] as String? ?? '',
      perfil: json['perfil'] is Map<String, dynamic>
          ? PerfilTrama.fromJson(json['perfil'] as Map<String, dynamic>)
          : PerfilesTrama.casToledo,
      esPrincipal: json['esPrincipal'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, nombre, transporte, direccion, perfil, esPrincipal];
}
