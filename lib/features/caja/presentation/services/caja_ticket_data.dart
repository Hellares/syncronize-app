import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/features/empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import 'package:syncronize/features/empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import 'package:syncronize/features/venta/data/datasources/venta_remote_datasource.dart';

import '../../domain/entities/caja.dart';

/// Datos resueltos para el header del ticket (sede > empresa fallback).
/// Mismo patron que ticket de venta: si la sede tiene su propia razon
/// social/RUC/direccion/telefono configurados en SUNAT, ganan sobre la
/// data raw de empresa.
class CajaTicketData {
  final String empresaNombre;
  final String? razonSocial;
  final String? ruc;
  final String? direccion;
  final String? telefono;
  final Uint8List? logoBytes;

  const CajaTicketData({
    required this.empresaNombre,
    this.razonSocial,
    this.ruc,
    this.direccion,
    this.telefono,
    this.logoBytes,
  });
}

/// Resuelve los datos efectivos para tickets de cierre/arqueo.
/// La caja tiene `sedeId` (operativa) y opcional `sedeFacturacionId`
/// (RUC emisor configurado al abrir). Para el header del ticket
/// preferimos la sede de la caja: es donde fisicamente esta el cajero
/// y por eso la direccion mostrada debe ser la sede real.
Future<CajaTicketData> resolverCajaTicketData(
  BuildContext context,
  Caja caja,
) async {
  final empresaState = context.read<EmpresaContextCubit>().state;
  String empresaNombre = '';
  String? razonSocial;
  String? ruc;
  String? direccion;
  String? telefono;
  Uint8List? logoBytes;
  String? logoUrl;

  if (empresaState is EmpresaContextLoaded) {
    final empresa = empresaState.context.empresa;
    empresaNombre = empresa.nombre;
    razonSocial = empresa.razonSocial;
    ruc = empresa.ruc;
    direccion = empresa.direccionFiscal;
    telefono = empresa.telefono;
    logoUrl = empresa.logo;
  }

  // Sobreescribir con datos efectivos de la sede (mismo patron que
  // ticket de venta). Silencioso si falla: dejamos los de empresa.
  try {
    final datasource = locator<VentaRemoteDataSource>();
    final config = await datasource.getConfiguracionSunat(sedeId: caja.sedeId);
    final rucSede = config['ruc'] as String?;
    final razonSede = config['razonSocial'] as String?;
    final nombreComercialSede = config['nombreComercial'] as String?;
    final dirSede = config['direccionFiscal'] as String?;
    final telSede = config['telefono'] as String?;
    if (nombreComercialSede != null && nombreComercialSede.isNotEmpty) {
      empresaNombre = nombreComercialSede;
    }
    if (rucSede != null && rucSede.isNotEmpty) ruc = rucSede;
    if (razonSede != null && razonSede.isNotEmpty) razonSocial = razonSede;
    if (dirSede != null && dirSede.isNotEmpty) direccion = dirSede;
    if (telSede != null && telSede.isNotEmpty) telefono = telSede;
  } catch (_) {}

  if (logoUrl != null && logoUrl.isNotEmpty) {
    try {
      final response = await http.get(Uri.parse(logoUrl));
      if (response.statusCode == 200) logoBytes = response.bodyBytes;
    } catch (_) {}
  }

  return CajaTicketData(
    empresaNombre: empresaNombre,
    razonSocial: razonSocial,
    ruc: ruc,
    direccion: direccion,
    telefono: telefono,
    logoBytes: logoBytes,
  );
}
