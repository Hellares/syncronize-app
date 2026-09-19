import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/core/utils/granular_permissions_catalog.dart';

/// Paridad del catálogo de permisos especiales con el del BACKEND.
///
/// Está duplicado a mano, y el backend RECHAZA con 400 los ids que no conoce:
/// un permiso que exista solo acá rompe el guardado del usuario, y uno que
/// exista solo allá es una capacidad que el admin no puede dar desde el app.
///
/// 🔴 Si el repo del backend no está al lado, el test se SALTA en vez de
/// fallar.
void main() {
  test('🔴 el catálogo del backend tiene los mismos ids', () {
    final archivo = File(
      '../backend/src/auth/services/granular-permissions.catalog.ts',
    );
    if (!archivo.existsSync()) {
      markTestSkipped('El repo del backend no está en ../backend');
      return;
    }

    final fuente = archivo.readAsStringSync();
    final inicio = fuente.indexOf('GRANULAR_PERMISSIONS_CATALOG');
    final enBackend = RegExp(r"^\s*id: '([^']+)',", multiLine: true)
        .allMatches(fuente.substring(inicio))
        .map((m) => m.group(1)!)
        .toSet();
    final enApp = kGranularPermissionsCatalog.map((p) => p.id).toSet();

    expect(enBackend, isNotEmpty);
    expect(enApp.difference(enBackend), isEmpty,
        reason: 'Ids que el app manda y el backend va a rechazar con 400');
    expect(enBackend.difference(enApp), isEmpty,
        reason: 'Permisos que el admin no puede dar desde el app');
  });
}
