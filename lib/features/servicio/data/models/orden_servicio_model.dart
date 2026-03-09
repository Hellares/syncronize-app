import 'package:syncronize/core/utils/type_converters.dart';
import '../../domain/entities/orden_servicio.dart';
import 'componente_model.dart';

class OrdenServicioModel extends OrdenServicio {
  OrdenServicioModel({
    required super.id,
    required super.empresaId,
    required super.clienteId,
    super.tecnicoId,
    super.sedeId,
    required super.codigo,
    required super.tipoServicio,
    super.prioridad,
    super.tipoEquipo,
    super.marcaEquipo,
    super.numeroSerie,
    super.modeloEquipoId,
    super.diagnostico,
    super.descripcionProblema,
    super.sintomas,
    super.costoTotal,
    super.adelanto,
    super.descuento,
    super.metodoPagoAdelanto,
    super.tiempoEstimado,
    super.fechaEntrega,
    required super.estado,
    super.estadoDiagnostico,
    super.notas,
    super.accesorios,
    super.condicionEquipo,
    super.datosPersonalizados,
    super.servicioId,
    super.incluirAvisoMantenimiento,
    super.fechaAvisoPersonalizado,
    super.origenOrden,
    super.cantidadReingresos,
    super.motivoReingreso,
    required super.creadoEn,
    required super.actualizadoEn,
    super.cliente,
    super.tecnico,
    super.modeloEquipo,
    super.componentes,
    super.tercerizacionOrigen,
    super.tercerizacionDestino,
  });

  factory OrdenServicioModel.fromJson(Map<String, dynamic> json) {
    return OrdenServicioModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      clienteId: json['clienteId'] as String,
      tecnicoId: json['tecnicoId'] as String?,
      sedeId: json['sedeId'] as String?,
      codigo: json['codigo'] as String,
      tipoServicio: json['tipoServicio'] as String,
      prioridad: json['prioridad'] as String? ?? 'NORMAL',
      tipoEquipo: json['tipoEquipo'] as String?,
      marcaEquipo: json['marcaEquipo'] as String?,
      numeroSerie: json['numeroSerie'] as String?,
      modeloEquipoId: json['modeloEquipoId'] as String?,
      diagnostico: json['diagnostico'],
      descripcionProblema: json['descripcionProblema'] as String?,
      sintomas: json['sintomas'],
      costoTotal: json['costoTotal'] != null ? toSafeDouble(json['costoTotal']) : null,
      adelanto: json['adelanto'] != null ? toSafeDouble(json['adelanto']) : null,
      descuento: json['descuento'] != null ? toSafeDouble(json['descuento']) : null,
      metodoPagoAdelanto: json['metodoPagoAdelanto'] as String?,
      tiempoEstimado: json['tiempoEstimado'] as int?,
      fechaEntrega: json['fechaEntrega'] != null ? DateTime.parse(json['fechaEntrega'] as String) : null,
      estado: json['estado'] as String,
      estadoDiagnostico: json['estadoDiagnostico'] as String? ?? 'PENDIENTE',
      notas: json['notas'] as String?,
      accesorios: json['accesorios'],
      condicionEquipo: json['condicionEquipo'] as String?,
      datosPersonalizados: json['datosPersonalizados'] != null
          ? Map<String, dynamic>.from(json['datosPersonalizados'] as Map)
          : null,
      servicioId: json['servicioId'] as String?,
      incluirAvisoMantenimiento: json['incluirAvisoMantenimiento'] as bool? ?? true,
      fechaAvisoPersonalizado: json['fechaAvisoPersonalizado'] != null
          ? DateTime.parse(json['fechaAvisoPersonalizado'] as String)
          : null,
      origenOrden: json['origenOrden'] as String? ?? 'CLIENTE_FINAL',
      cantidadReingresos: json['cantidadReingresos'] as int? ?? 0,
      motivoReingreso: json['motivoReingreso'] as String?,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      cliente: json['cliente'] != null
          ? OrdenClienteModel.fromJson(json['cliente'] as Map<String, dynamic>)
          : null,
      tecnico: json['tecnico'] != null
          ? OrdenTecnicoModel.fromJson(json['tecnico'] as Map<String, dynamic>)
          : null,
      modeloEquipo: json['modeloEquipo'] != null
          ? OrdenModeloEquipoModel.fromJson(json['modeloEquipo'] as Map<String, dynamic>)
          : null,
      componentes: json['componentes'] != null
          ? (json['componentes'] as List)
              .map((e) => OrdenComponenteModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      tercerizacionOrigen: json['tercerizacionOrigen'] != null
          ? TercerizacionResumenModel.fromJson(json['tercerizacionOrigen'] as Map<String, dynamic>)
          : null,
      tercerizacionDestino: json['tercerizacionDestino'] != null
          ? TercerizacionResumenModel.fromJson(json['tercerizacionDestino'] as Map<String, dynamic>)
          : null,
    );
  }
}

class TercerizacionResumenModel extends TercerizacionResumen {
  const TercerizacionResumenModel({
    required super.id,
    required super.estado,
    super.precioB2B,
    super.empresaOrigenId,
    super.empresaDestinoId,
    super.empresaOrigen,
    super.empresaDestino,
  });

  factory TercerizacionResumenModel.fromJson(Map<String, dynamic> json) {
    return TercerizacionResumenModel(
      id: json['id'] as String,
      estado: json['estado'] as String,
      precioB2B: json['precioB2B'] != null
          ? double.tryParse(json['precioB2B'].toString())
          : null,
      empresaOrigenId: json['empresaOrigenId'] as String?,
      empresaDestinoId: json['empresaDestinoId'] as String?,
      empresaOrigen: json['empresaOrigen'] != null
          ? EmpresaB2BResumenModel.fromJson(json['empresaOrigen'] as Map<String, dynamic>)
          : null,
      empresaDestino: json['empresaDestino'] != null
          ? EmpresaB2BResumenModel.fromJson(json['empresaDestino'] as Map<String, dynamic>)
          : null,
    );
  }
}

class EmpresaB2BResumenModel extends EmpresaB2BResumen {
  const EmpresaB2BResumenModel({
    required super.id,
    required super.nombre,
    super.logo,
    super.telefono,
  });

  factory EmpresaB2BResumenModel.fromJson(Map<String, dynamic> json) {
    return EmpresaB2BResumenModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? '',
      logo: json['logo'] as String?,
      telefono: json['telefono'] as String?,
    );
  }
}

class OrdenClienteModel extends OrdenCliente {
  const OrdenClienteModel({
    required super.id,
    super.nombre,
    super.apellido,
    super.email,
    super.telefono,
    super.documentoNumero,
  });

  factory OrdenClienteModel.fromJson(Map<String, dynamic> json) {
    // Los datos personales están en la relación persona
    final persona = json['persona'] as Map<String, dynamic>?;
    return OrdenClienteModel(
      id: json['id'] as String,
      nombre: persona?['nombres'] as String? ?? json['nombre'] as String?,
      apellido: persona?['apellidos'] as String? ?? json['apellido'] as String?,
      email: persona?['email'] as String? ?? json['email'] as String?,
      telefono: persona?['telefono'] as String? ?? json['telefono'] as String?,
      documentoNumero: persona?['dni'] as String? ?? json['documentoNumero'] as String?,
    );
  }
}

class OrdenTecnicoModel extends OrdenTecnico {
  const OrdenTecnicoModel({
    required super.id,
    super.nombre,
    super.apellido,
    super.email,
  });

  factory OrdenTecnicoModel.fromJson(Map<String, dynamic> json) {
    final persona = json['persona'] as Map<String, dynamic>?;
    return OrdenTecnicoModel(
      id: json['id'] as String,
      nombre: persona?['nombres'] as String? ?? json['nombre'] as String?,
      apellido: persona?['apellidos'] as String? ?? json['apellido'] as String?,
      email: json['email'] as String?,
    );
  }
}

class OrdenModeloEquipoModel extends OrdenModeloEquipo {
  const OrdenModeloEquipoModel({
    required super.id,
    required super.marca,
    required super.modelo,
  });

  factory OrdenModeloEquipoModel.fromJson(Map<String, dynamic> json) {
    return OrdenModeloEquipoModel(
      id: json['id'] as String,
      marca: json['marca'] as String? ?? '',
      modelo: json['modelo'] as String? ?? '',
    );
  }
}

class OrdenComponenteModel extends OrdenComponente {
  const OrdenComponenteModel({
    required super.id,
    required super.ordenServicioId,
    required super.componenteId,
    required super.tipoAccion,
    super.estadoComponente,
    super.descripcionAccion,
    super.costoAccion,
    super.tiempoAccion,
    super.costoRepuestos,
    super.resultadoAccion,
    super.pruebaRealizada,
    super.observaciones,
    super.garantiaMeses,
    super.componente,
  });

  factory OrdenComponenteModel.fromJson(Map<String, dynamic> json) {
    return OrdenComponenteModel(
      id: json['id'] as String,
      ordenServicioId: json['ordenServicioId'] as String,
      componenteId: json['componenteId'] as String,
      tipoAccion: json['tipoAccion'] as String,
      estadoComponente: json['estadoComponente'] as String? ?? 'INGRESADO',
      descripcionAccion: json['descripcionAccion'] as String?,
      costoAccion: json['costoAccion'] != null ? toSafeDouble(json['costoAccion']) : null,
      tiempoAccion: json['tiempoAccion'] as int?,
      costoRepuestos: json['costoRepuestos'] != null ? toSafeDouble(json['costoRepuestos']) : null,
      resultadoAccion: json['resultadoAccion'] as String?,
      pruebaRealizada: json['pruebaRealizada'] as bool? ?? false,
      observaciones: json['observaciones'] as String?,
      garantiaMeses: json['garantiaMeses'] as int?,
      componente: json['componente'] != null
          ? ComponenteModel.fromJson(json['componente'] as Map<String, dynamic>)
          : null,
    );
  }
}

class HistorialOrdenServicioModel extends HistorialOrdenServicio {
  const HistorialOrdenServicioModel({
    required super.id,
    required super.ordenServicioId,
    required super.estadoAnterior,
    required super.estadoNuevo,
    super.notas,
    super.diagnostico,
    super.comunicarCliente,
    super.creadoPor,
    required super.creadoEn,
  });

  factory HistorialOrdenServicioModel.fromJson(Map<String, dynamic> json) {
    return HistorialOrdenServicioModel(
      id: json['id'] as String,
      ordenServicioId: json['ordenServicioId'] as String,
      estadoAnterior: json['estadoAnterior'] as String,
      estadoNuevo: json['estadoNuevo'] as String,
      notas: json['notas'] as String?,
      diagnostico: json['diagnostico'],
      comunicarCliente: json['comunicarCliente'] as bool? ?? false,
      creadoPor: json['creadoPor'] as String?,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
    );
  }
}
