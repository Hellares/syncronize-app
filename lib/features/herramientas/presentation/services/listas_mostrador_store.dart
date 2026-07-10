import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../producto/domain/entities/precio_nivel.dart';
import '../../../venta/domain/entities/venta_detalle_input.dart';

/// Lista de la calculadora de mostrador guardada EN EL CELULAR
/// (SharedPreferences — nunca toca el backend). Es un snapshot completo
/// de los items (precios/niveles/ofertas DEL MOMENTO en que se guardó)
/// para re-abrir, re-imprimir o re-compartir la cotización después.
class ListaMostradorGuardada {
  final String id;
  final DateTime fecha;

  /// Nombre opcional puesto por el vendedor (ej. el cliente). Si es null
  /// la lista se identifica solo por fecha/hora.
  final String? nombre;
  final String? sedeId;
  final String? sedeNombre;
  final List<VentaDetalleInput> items;

  const ListaMostradorGuardada({
    required this.id,
    required this.fecha,
    this.nombre,
    this.sedeId,
    this.sedeNombre,
    required this.items,
  });

  double get total => items.fold(0, (s, i) => s + i.total);

  Map<String, dynamic> toJson() => {
        'id': id,
        'f': fecha.toIso8601String(),
        if (nombre != null) 'n': nombre,
        if (sedeId != null) 'sid': sedeId,
        if (sedeNombre != null) 'sn': sedeNombre,
        'items': items.map(_itemToJson).toList(),
      };

  static ListaMostradorGuardada fromJson(Map<String, dynamic> j) {
    return ListaMostradorGuardada(
      id: j['id'] as String,
      fecha: DateTime.parse(j['f'] as String),
      nombre: j['n'] as String?,
      sedeId: j['sid'] as String?,
      sedeNombre: j['sn'] as String?,
      items: (j['items'] as List)
          .map((e) => _itemFromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // ── Serialización de items ───────────────────────────────────────────
  // Solo los campos que la calculadora usa (los de combo/VIP/orden no
  // aplican aquí). Los niveles van completos para que el stepper siga
  // recalculando precios por mayor al re-abrir la lista.

  static Map<String, dynamic> _itemToJson(VentaDetalleInput i) => {
        if (i.productoId != null) 'pid': i.productoId,
        if (i.varianteId != null) 'vid': i.varianteId,
        'd': i.descripcion,
        'c': i.cantidad,
        'pu': i.precioUnitario,
        if (i.precioBase != null) 'pb': i.precioBase,
        'igv': i.precioIncluyeIgv,
        'pigv': i.porcentajeIGV,
        if (i.stockDisponible != null) 'sd': i.stockDisponible,
        if (i.nivelAplicado != null) 'na': i.nivelAplicado,
        if (i.descuentoNivelPct != null) 'dnp': i.descuentoNivelPct,
        if (i.enOferta) 'of': true,
        if (i.enLiquidacion) 'liq': true,
        if (i.precioAntesOferta != null) 'pao': i.precioAntesOferta,
        if (i.niveles.isNotEmpty)
          'niv': i.niveles.map(_nivelToJson).toList(),
      };

  static VentaDetalleInput _itemFromJson(Map<String, dynamic> j) {
    return VentaDetalleInput(
      productoId: j['pid'] as String?,
      varianteId: j['vid'] as String?,
      descripcion: j['d'] as String? ?? '',
      cantidad: _d(j['c']) ?? 1,
      precioUnitario: _d(j['pu']) ?? 0,
      precioBase: _d(j['pb']),
      precioIncluyeIgv: j['igv'] as bool? ?? false,
      porcentajeIGV: _d(j['pigv']) ?? 18.0,
      stockDisponible: (j['sd'] as num?)?.toInt(),
      nivelAplicado: j['na'] as String?,
      descuentoNivelPct: _d(j['dnp']),
      enOferta: j['of'] as bool? ?? false,
      enLiquidacion: j['liq'] as bool? ?? false,
      precioAntesOferta: _d(j['pao']),
      niveles: ((j['niv'] as List?) ?? const [])
          .map((e) => _nivelFromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static Map<String, dynamic> _nivelToJson(PrecioNivel n) => {
        'id': n.id,
        'n': n.nombre,
        'cm': n.cantidadMinima,
        if (n.cantidadMaxima != null) 'cx': n.cantidadMaxima,
        'tp': n.tipoPrecio.value,
        if (n.precio != null) 'p': n.precio,
        if (n.porcentajeDesc != null) 'pd': n.porcentajeDesc,
        'o': n.orden,
        'a': n.isActive,
      };

  static PrecioNivel _nivelFromJson(Map<String, dynamic> j) {
    // creadoEn/actualizadoEn no se usan en el cálculo — epoch 0 al restaurar.
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    return PrecioNivel(
      id: j['id'] as String? ?? '',
      nombre: j['n'] as String? ?? '',
      cantidadMinima: (j['cm'] as num?)?.toInt() ?? 1,
      cantidadMaxima: (j['cx'] as num?)?.toInt(),
      tipoPrecio: TipoPrecioNivel.fromString(j['tp'] as String? ?? ''),
      precio: _d(j['p']),
      porcentajeDesc: _d(j['pd']),
      orden: (j['o'] as num?)?.toInt() ?? 0,
      isActive: j['a'] as bool? ?? true,
      creadoEn: epoch,
      actualizadoEn: epoch,
    );
  }

  static double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
}

/// Persistencia local de las listas guardadas (tope [_max], más reciente
/// primero). Cada operación relee prefs para no pisar datos entre
/// aperturas del sheet.
class ListasMostradorStore {
  static const _key = 'calculadora_mostrador_listas';
  static const _max = 50;

  static Future<List<ListaMostradorGuardada>> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      final out = <ListaMostradorGuardada>[];
      for (final e in list) {
        // Entrada corrupta no tumba el resto del historial.
        try {
          out.add(ListaMostradorGuardada.fromJson(e as Map<String, dynamic>));
        } catch (_) {}
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  static Future<void> guardar(ListaMostradorGuardada lista) async {
    final listas = await cargar();
    listas.insert(0, lista);
    if (listas.length > _max) listas.removeRange(_max, listas.length);
    await _persist(listas);
  }

  /// Upsert: reemplaza la lista con el mismo id (o la crea si ya no
  /// existe) y la sube al tope — "guardar cambios" sobre una lista
  /// abierta desde el historial.
  static Future<void> actualizar(ListaMostradorGuardada lista) async {
    final listas = await cargar();
    listas.removeWhere((l) => l.id == lista.id);
    listas.insert(0, lista);
    if (listas.length > _max) listas.removeRange(_max, listas.length);
    await _persist(listas);
  }

  static Future<void> eliminar(String id) async {
    final listas = await cargar();
    listas.removeWhere((l) => l.id == id);
    await _persist(listas);
  }

  static Future<void> _persist(List<ListaMostradorGuardada> listas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(listas.map((l) => l.toJson()).toList()));
  }
}
