import '../entities/lectura_peso.dart';
import '../entities/perfil_trama.dart';

/// Traduce la trama de una balanza a una [LecturaPeso].
///
/// 🔑 Es una FUNCIÓN PURA y vive aparte a propósito: acá está todo el dolor
/// que varía por marca, es lo único que se puede probar sin tener el equipo, y
/// es lo primero que hay que ajustar cuando llega una balanza desconocida.
/// Mismo criterio que el parser de ubicación de WhatsApp.
///
/// Devuelve `null` cuando la línea no matchea. Eso NO es un error: por el
/// puerto llegan fragmentos, ecos de comandos y basura del encendido, y lo
/// correcto es ignorarlos, no romper. Una balanza en continuo manda ~10 tramas
/// por segundo: la siguiente buena llega en 100 ms.
LecturaPeso? parsearTrama(String linea, PerfilTrama perfil) {
  final texto = linea.trim();
  if (texto.isEmpty) return null;

  final RegExp regex;
  try {
    regex = RegExp(perfil.patron, caseSensitive: false);
  } catch (_) {
    // La regex la escribe el usuario en la pantalla de configuración: una a
    // medio escribir no puede tumbar el visor.
    return null;
  }

  final m = regex.firstMatch(texto);
  if (m == null) return null;

  final crudoPeso = _grupo(m, 'peso');
  if (crudoPeso == null || crudoPeso.isEmpty) return null;

  // Coma decimal: hay equipos configurados en formato europeo y el mismo
  // modelo cambia de separador según cómo lo dejó el proveedor.
  final valor = double.tryParse(crudoPeso.replaceAll(',', '.'));
  if (valor == null) return null;

  // La unidad de la TRAMA gana sobre la configurada: varias balanzas cambian
  // de kg a g con un botón del equipo, y la trama es lo único que se entera.
  final unidad = UnidadPeso.fromString(_grupo(m, 'unidad')) ;
  final declaraUnidad = (_grupo(m, 'unidad') ?? '').isNotEmpty;
  final gramos = (declaraUnidad ? unidad : perfil.unidadPorDefecto).aGramos(valor);

  final negativo = _grupo(m, 'signo') == '-';

  return LecturaPeso(
    gramos: negativo ? -gramos : gramos,
    estable: _esEstable(m, perfil),
    crudo: texto,
  );
}

/// El peso está asentado.
///
/// 🔴 Si el perfil no exige estabilidad se devuelve `true` SIEMPRE. Es
/// deliberado: un equipo que no reporta el flag dejaría el botón "Usar peso"
/// deshabilitado para siempre y la caja trabada. Preferimos vender con el
/// criterio del cajero antes que bloquear por un dato que esa balanza no manda.
bool _esEstable(RegExpMatch m, PerfilTrama perfil) {
  if (!perfil.exigeEstable) return true;
  final estado = _grupo(m, 'estado');
  if (estado == null) return false;
  final normalizado = estado.trim().toUpperCase();
  return perfil.tokensEstable.any((t) => t.trim().toUpperCase() == normalizado);
}

/// Lee un grupo nombrado sin explotar si el patrón no lo declara.
///
/// `namedGroup` tira `ArgumentError` cuando el grupo no existe en la regex, y
/// los perfiles simples no traen `estado` ni `unidad`.
String? _grupo(RegExpMatch m, String nombre) {
  try {
    return m.namedGroup(nombre);
  } catch (_) {
    return null;
  }
}

/// Corta el chorro de bytes del puerto en tramas completas.
///
/// 🔴 Es el bug clásico de estas integraciones: el Bluetooth NO entrega una
/// trama por evento. Entrega los bytes como vengan, así que una lectura llega
/// partida en dos ("ST,GS,+  1." y "234kg\r\n") o dos lecturas llegan pegadas
/// en el mismo paquete. Parsear cada paquete suelto pierde pesos y, peor,
/// puede leer "1." como 1 kg.
///
/// Acumular hasta el terminador y recién ahí parsear resuelve las dos cosas.
class AcumuladorTramas {
  final String terminador;

  /// Tope del buffer. Si el terminador está mal configurado no llega nunca y
  /// el buffer crecería sin límite mientras la balanza transmite.
  final int maxBuffer;

  final StringBuffer _buffer = StringBuffer();

  AcumuladorTramas({this.terminador = '\r\n', this.maxBuffer = 4096});

  /// Agrega lo recibido y devuelve las tramas COMPLETAS que se hayan cerrado.
  /// Lo que quede a medias se guarda para el próximo paquete.
  List<String> agregar(String chunk) {
    if (terminador.isEmpty) {
      // Sin terminador no hay forma de saber dónde corta: se trata cada
      // paquete como una trama y que el parser decida.
      final t = chunk.trim();
      return t.isEmpty ? const [] : [t];
    }

    _buffer.write(chunk);
    var acumulado = _buffer.toString();

    if (acumulado.length > maxBuffer) {
      // Terminador mal configurado o ruido: se conserva solo la cola, que es
      // donde estaría una trama en curso.
      acumulado = acumulado.substring(acumulado.length - maxBuffer);
    }

    final partes = acumulado.split(terminador);
    // El último trozo es lo que quedó DESPUÉS del último terminador: puede ser
    // una trama a medio llegar, así que vuelve al buffer.
    final resto = partes.removeLast();

    _buffer
      ..clear()
      ..write(resto);

    return partes.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
  }

  void limpiar() => _buffer.clear();
}
