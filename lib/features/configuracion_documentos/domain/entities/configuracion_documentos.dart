import 'package:equatable/equatable.dart';

class ConfiguracionDocumentos extends Equatable {
  final String id;
  final String empresaId;
  final String? logoUrl;
  final String? nombreComercial;
  final String? ruc;
  final String? direccion;
  final String? telefono;
  final String? email;
  final String colorPrimario;
  final String colorSecundario;
  final String colorTexto;
  final String textoPiePagina;
  final bool mostrarPaginacion;

  const ConfiguracionDocumentos({
    required this.id,
    required this.empresaId,
    this.logoUrl,
    this.nombreComercial,
    this.ruc,
    this.direccion,
    this.telefono,
    this.email,
    this.colorPrimario = '#1565C0',
    this.colorSecundario = '#1E88E5',
    this.colorTexto = '#333333',
    this.textoPiePagina = 'Gracias por su preferencia',
    this.mostrarPaginacion = true,
  });

  @override
  List<Object?> get props => [
        id,
        empresaId,
        logoUrl,
        nombreComercial,
        ruc,
        direccion,
        telefono,
        email,
        colorPrimario,
        colorSecundario,
        colorTexto,
        textoPiePagina,
        mostrarPaginacion,
      ];
}
