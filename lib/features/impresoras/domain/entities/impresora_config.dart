import 'package:equatable/equatable.dart';

enum TipoConexionImpresora {
  bluetooth,
  ethernet; // V2 — preparado pero no expuesto aún en UI

  String get label {
    switch (this) {
      case TipoConexionImpresora.bluetooth:
        return 'Bluetooth';
      case TipoConexionImpresora.ethernet:
        return 'Ethernet';
    }
  }

  String get apiValue => name;

  static TipoConexionImpresora fromString(String? value) {
    if (value == 'ethernet') return TipoConexionImpresora.ethernet;
    return TipoConexionImpresora.bluetooth;
  }
}

enum AnchoPapel {
  mm58,
  mm80;

  int get mm => this == mm58 ? 58 : 80;
  String get label => '${mm}mm';

  static AnchoPapel fromMm(int mm) => mm == 58 ? AnchoPapel.mm58 : AnchoPapel.mm80;
}

/// Configuración local (SharedPreferences) de una impresora térmica.
/// No se sincroniza con backend: las impresoras Bluetooth son físicas del
/// dispositivo del cajero, cada celular tiene su propia configuración.
class ImpresoraConfig extends Equatable {
  final String id;
  final String nombre;
  final TipoConexionImpresora tipoConexion;
  final String direccion; // MAC Bluetooth o IP (V2)
  final AnchoPapel anchoPapel;
  final int tamanoFuentePx; // 24 (default ESC-POS size 0) | 28 | 32
  final bool autoImprimirVentaRapida;
  final bool esPrincipal;

  const ImpresoraConfig({
    required this.id,
    required this.nombre,
    required this.tipoConexion,
    required this.direccion,
    required this.anchoPapel,
    this.tamanoFuentePx = 24,
    this.autoImprimirVentaRapida = false,
    this.esPrincipal = false,
  });

  ImpresoraConfig copyWith({
    String? nombre,
    TipoConexionImpresora? tipoConexion,
    String? direccion,
    AnchoPapel? anchoPapel,
    int? tamanoFuentePx,
    bool? autoImprimirVentaRapida,
    bool? esPrincipal,
  }) {
    return ImpresoraConfig(
      id: id,
      nombre: nombre ?? this.nombre,
      tipoConexion: tipoConexion ?? this.tipoConexion,
      direccion: direccion ?? this.direccion,
      anchoPapel: anchoPapel ?? this.anchoPapel,
      tamanoFuentePx: tamanoFuentePx ?? this.tamanoFuentePx,
      autoImprimirVentaRapida:
          autoImprimirVentaRapida ?? this.autoImprimirVentaRapida,
      esPrincipal: esPrincipal ?? this.esPrincipal,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'tipoConexion': tipoConexion.apiValue,
        'direccion': direccion,
        'anchoPapelMm': anchoPapel.mm,
        'tamanoFuentePx': tamanoFuentePx,
        'autoImprimirVentaRapida': autoImprimirVentaRapida,
        'esPrincipal': esPrincipal,
      };

  factory ImpresoraConfig.fromJson(Map<String, dynamic> json) {
    return ImpresoraConfig(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? '',
      tipoConexion: TipoConexionImpresora.fromString(json['tipoConexion'] as String?),
      direccion: json['direccion'] as String? ?? '',
      anchoPapel: AnchoPapel.fromMm((json['anchoPapelMm'] as int?) ?? 80),
      tamanoFuentePx: (json['tamanoFuentePx'] as int?) ?? 24,
      autoImprimirVentaRapida: json['autoImprimirVentaRapida'] as bool? ?? false,
      esPrincipal: json['esPrincipal'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        tipoConexion,
        direccion,
        anchoPapel,
        tamanoFuentePx,
        autoImprimirVentaRapida,
        esPrincipal,
      ];
}
