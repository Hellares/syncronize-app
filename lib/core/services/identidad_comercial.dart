/// Con qué nombre, logo y color se presenta la empresa ante el CLIENTE.
///
/// 🔴 `Empresa.nombre` NO es el nombre comercial: el alta por RUC lo llena con
/// la razón social, y en prod las cuatro empresas lo tienen igual a
/// `razonSocial` ("JAYLI FLORES S.A.C.", "CAMPOS SERIN DANIEL ALONSO"). Lo que
/// el cliente tiene que leer es el NOMBRE COMERCIAL —"JAYLILAND", "CJ MOVILS"—,
/// que vive en `ConfiguracionDocumentos.nombreComercial`, el mismo que ya usan
/// la cotización, el ticket de venta y la orden de servicio a través de
/// `PdfDocumentStyle`.
///
/// Todo lo que salga del sistema hacia afuera —la ficha PNG del producto y el
/// catálogo en PDF— resuelve su membrete por acá, así el día que la empresa
/// cambie su marca no queda una pantalla mostrando la razón social.
///
/// El color también sale de la configuración: hay empresas con la marca en rojo
/// (#DB0D0D) y clavarles el azul del sistema les borra lo que eligieron.
library;

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';

import '../../features/configuracion_documentos/domain/entities/configuracion_documento_completa.dart';
import '../../features/configuracion_documentos/domain/usecases/get_configuracion_completa_usecase.dart';
import '../../features/empresa/domain/entities/empresa_info.dart';
import '../di/injection_container.dart';
import '../theme/app_colors.dart';
import '../utils/resource.dart';
import 'pdf/pdf_color_utils.dart';

class IdentidadComercial {
  /// El nombre comercial, o la razón social si la empresa no configuró uno.
  final String nombre;
  final String? ruc;
  final String? telefono;
  final String? direccion;
  final String? logoUrl;

  /// Hex del color primario elegido por la empresa. Null = el azul del sistema.
  final String? colorPrimarioHex;

  /// El pie configurado ("Gracias por su preferencia"), que cierra la ficha y
  /// el catálogo igual que cierra la cotización.
  final String? textoPie;

  const IdentidadComercial({
    required this.nombre,
    this.ruc,
    this.telefono,
    this.direccion,
    this.logoUrl,
    this.colorPrimarioHex,
    this.textoPie,
  });

  /// Lo que se puede armar sin la configuración de documentos: el plan B
  /// cuando la llamada falla o el usuario está sin red.
  factory IdentidadComercial.deEmpresa(EmpresaInfo empresa) =>
      IdentidadComercial(
        nombre: empresa.nombre,
        ruc: empresa.ruc,
        telefono: empresa.telefono,
        direccion: empresa.direccionFiscal,
        logoUrl: empresa.logo,
      );

  Color get color {
    final hex = (colorPrimarioHex ?? '').replaceFirst('#', '');
    if (hex.length != 6 && hex.length != 8) return AppColors.blue1;
    final valor = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
    return valor == null ? AppColors.blue1 : Color(valor);
  }

  PdfColor get colorPdf => hexToPdfColor(
        colorPrimarioHex ?? '',
        fallback: const PdfColor.fromInt(0xFF004A94),
      );
}

/// Resuelve la identidad pidiendo la configuración de documentos.
///
/// Va por la plantilla de COTIZACION porque es la que la empresa realmente
/// edita —no hay un tipo CATALOGO en `TipoDocumento`— y de ahí salen el nombre
/// comercial, el logo y los colores, que son globales de la empresa. Con
/// [sedeId] el backend además resuelve la dirección y el teléfono de esa sede.
///
/// Nunca lanza: si la llamada falla, la ficha se arma igual con los datos de la
/// empresa. Un catálogo sin membrete perfecto es mejor que un botón que no hace
/// nada.
Future<IdentidadComercial> resolverIdentidadComercial({
  required EmpresaInfo empresa,
  String? sedeId,
}) async {
  try {
    final res = await locator<GetConfiguracionCompletaUseCase>()(
      tipo: 'COTIZACION',
      formato: 'A4',
      sedeId: sedeId,
    );
    if (res is! Success<ConfiguracionDocumentoCompleta>) {
      return IdentidadComercial.deEmpresa(empresa);
    }
    final completa = res.data;
    final config = completa.configuracion;
    return IdentidadComercial(
      // 🔴 `?? empresa.nombre` no alcanza: un texto opcional que el usuario
      // borró llega como cadena VACÍA, no como null, y dejaría el membrete sin
      // nombre.
      nombre: _oNulo(config.nombreComercial) ?? empresa.nombre,
      ruc: _oNulo(config.ruc) ?? empresa.ruc,
      telefono: _oNulo(completa.telefonoEfectivo) ?? empresa.telefono,
      direccion: _oNulo(completa.direccionEfectiva) ?? empresa.direccionFiscal,
      logoUrl: _oNulo(config.logoUrl) ?? empresa.logo,
      colorPrimarioHex: _oNulo(completa.colorPrimarioEfectivo),
      textoPie: _oNulo(config.textoPiePagina),
    );
  } catch (_) {
    return IdentidadComercial.deEmpresa(empresa);
  }
}

String? _oNulo(String? valor) {
  final limpio = (valor ?? '').trim();
  return limpio.isEmpty ? null : limpio;
}
