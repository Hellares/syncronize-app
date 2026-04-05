import 'package:flutter/material.dart';

/// Tipos de silueta disponibles
enum TipoSilueta {
  autoSuperior,
}

const siluetaLabels = {
  TipoSilueta.autoSuperior: 'Auto (vista superior)',
};

const siluetaIcons = {
  TipoSilueta.autoSuperior: Icons.directions_car,
};

/// Rutas de assets por tipo de silueta
const siluetaAssets = {
  TipoSilueta.autoSuperior: 'assets/img/auto.png',
};

/// Parsea string a TipoSilueta
TipoSilueta parseSilueta(String? value) {
  switch (value) {
    case 'AUTO_SUPERIOR':
      return TipoSilueta.autoSuperior;
    default:
      return TipoSilueta.autoSuperior;
  }
}

String siluetaToString(TipoSilueta tipo) {
  switch (tipo) {
    case TipoSilueta.autoSuperior:
      return 'AUTO_SUPERIOR';
  }
}
