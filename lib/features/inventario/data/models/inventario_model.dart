import '../../domain/entities/inventario.dart';

class InventarioModel extends Inventario {
  const InventarioModel({
    required super.id,
    required super.codigo,
    required super.nombre,
    super.descripcion,
    required super.tipoInventario,
    required super.estado,
    required super.sedeId,
    super.sedeNombre,
    super.responsableNombre,
    super.fechaPlanificada,
    super.fechaInicio,
    super.fechaFinConteo,
    super.totalProductosEsperados,
    super.totalProductosContados,
    super.totalDiferencias,
    super.totalSobrantes,
    super.totalFaltantes,
    super.observaciones,
    super.items,
    required super.creadoEn,
  });

  factory InventarioModel.fromJson(Map<String, dynamic> json) {
    // Parse sede nombre
    final sede = json['sede'] as Map<String, dynamic>?;
    final sedeNombre = sede?['nombre'] as String? ?? json['sedeNombre'] as String?;

    // Parse responsable nombre
    String? responsableNombre;
    final responsable = json['responsable'] as Map<String, dynamic>?;
    if (responsable != null) {
      final persona = responsable['persona'] as Map<String, dynamic>?;
      if (persona != null) {
        responsableNombre =
            '${persona['nombres'] ?? ''} ${persona['apellidos'] ?? ''}'.trim();
      }
      if (responsableNombre == null || responsableNombre.isEmpty) {
        responsableNombre = responsable['email'] as String?;
      }
    }

    // Parse items list
    List<InventarioItem>? items;
    if (json['items'] != null) {
      final itemsList = json['items'] as List;
      items = itemsList
          .map((e) => InventarioItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return InventarioModel(
      id: json['id'] as String,
      codigo: json['codigo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      tipoInventario: TipoInventario.fromString(
        json['tipoInventario'] as String? ?? 'COMPLETO',
      ),
      estado: EstadoInventario.fromString(
        json['estado'] as String? ?? 'PLANIFICADO',
      ),
      sedeId: json['sedeId'] as String? ?? '',
      sedeNombre: sedeNombre,
      responsableNombre: responsableNombre,
      fechaPlanificada: json['fechaPlanificada'] != null
          ? DateTime.parse(json['fechaPlanificada'] as String)
          : null,
      fechaInicio: json['fechaInicio'] != null
          ? DateTime.parse(json['fechaInicio'] as String)
          : null,
      fechaFinConteo: json['fechaFinConteo'] != null
          ? DateTime.parse(json['fechaFinConteo'] as String)
          : null,
      totalProductosEsperados: _toInt(json['totalProductosEsperados']),
      totalProductosContados: _toInt(json['totalProductosContados']),
      totalDiferencias: _toInt(json['totalDiferencias']),
      totalSobrantes: _toInt(json['totalSobrantes']),
      totalFaltantes: _toInt(json['totalFaltantes']),
      observaciones: json['observaciones'] as String?,
      items: items,
      creadoEn: json['creadoEn'] != null
          ? DateTime.parse(json['creadoEn'] as String)
          : DateTime.now(),
    );
  }

  Inventario toEntity() => this;

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class InventarioItemModel extends InventarioItem {
  const InventarioItemModel({
    required super.id,
    super.productoStockId,
    required super.nombreProducto,
    super.codigoProducto,
    super.codigoBarras,
    required super.cantidadSistema,
    super.cantidadContada,
    super.diferencia,
    super.esDiferencia,
    super.tipoRestante,
    required super.estadoConteo,
    super.ubicacionFisica,
    super.observaciones,
    super.ajusteAplicado,
  });

  factory InventarioItemModel.fromJson(Map<String, dynamic> json) {
    // Parse producto info
    final productoStock = json['productoStock'] as Map<String, dynamic>?;
    final producto = productoStock?['producto'] as Map<String, dynamic>?;

    String nombreProducto = json['nombreProducto'] as String? ?? '';
    String? codigoProducto = json['codigoProducto'] as String?;
    String? codigoBarras = json['codigoBarras'] as String?;

    if (producto != null) {
      if (nombreProducto.isEmpty) {
        nombreProducto = producto['nombre'] as String? ?? '';
      }
      codigoProducto ??= producto['codigo'] as String?;
      codigoBarras ??= producto['codigoBarras'] as String?;
    }

    return InventarioItemModel(
      id: json['id'] as String,
      productoStockId: json['productoStockId'] as String?,
      nombreProducto: nombreProducto,
      codigoProducto: codigoProducto,
      codigoBarras: codigoBarras,
      cantidadSistema: _toInt(json['cantidadSistema']),
      cantidadContada: json['cantidadContada'] != null
          ? _toInt(json['cantidadContada'])
          : null,
      diferencia: json['diferencia'] != null
          ? _toInt(json['diferencia'])
          : null,
      esDiferencia: json['esDiferencia'] as bool? ?? false,
      tipoRestante: json['tipoRestante'] as String?,
      estadoConteo: json['estadoConteo'] as String? ?? 'PENDIENTE',
      ubicacionFisica: json['ubicacionFisica'] as String?,
      observaciones: json['observaciones'] as String?,
      ajusteAplicado: json['ajusteAplicado'] as bool? ?? false,
    );
  }

  InventarioItem toEntity() => this;

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
