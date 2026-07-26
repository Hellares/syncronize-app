/// Fuente ÚNICA de verdad para presentar los tipos de campo de las
/// plantillas de servicio (etiquetas, íconos, categorías).
///
/// Antes esto vivía duplicado en cuatro pantallas —`configuracion_campos_page`,
/// `plantillas_servicio_page`, `servicio_form_page` y `catalogo_plantillas_page`—
/// con ~14 mapas repetidos. Agregar `CODIGO_BARRAS` obligaba a tocar todos, y
/// al fallar dos el tipo quedó invisible en el selector que la gente usaba.
///
/// **Para agregar un tipo de campo hay que tocar exactamente 3 lugares:**
///  1. este archivo,
///  2. el `case` en `dynamic_form_renderer.dart` (cómo se captura el dato),
///  3. el enum `TipoCampoServicio` del backend + su migración.
///
/// Las claves son los valores del enum del backend, tal cual viajan en JSON.
library;

import 'package:flutter/material.dart';

/// Etiqueta completa: selectores y formularios, donde hay ancho.
const kTipoCampoLabels = <String, String>{
  'TEXTO': 'Texto',
  'NUMERO': 'Número',
  'EMAIL': 'Email',
  'FECHA': 'Fecha',
  'HORA': 'Hora',
  'TEXTO_AREA': 'Texto largo',
  'OPCION_SIMPLES': 'Selección simple',
  'OPCION_MULTIPLE': 'Selección múltiple',
  'CHECKBOX': 'Checkbox',
  'CHECKBOX_MULTIPLE': 'Checkbox múltiple',
  'ARCHIVO': 'Archivo',
  'TELEFONO': 'Teléfono',
  'URL': 'URL',
  'OBJETO': 'Objeto (sub-campos)',
  'PATRON_DESBLOQUEO': 'Patrón desbloqueo',
  'INSPECCION_VISUAL': 'Inspección visual',
  'CODIGO_BARRAS': 'Código de barras (IMEI, serie)',
  'PIN_CLAVE': 'PIN / clave de desbloqueo',
  'MONEDA': 'Monto (S/)',
  'FIRMA': 'Firma del cliente',
  'DOCUMENTO_IDENTIDAD': 'DNI / RUC (con autocompletado)',
  'TABLA': 'Tabla (columnas y filas)',
};

/// Etiqueta corta: chips del catálogo de plantillas, donde no entra la larga.
const kTipoCampoLabelsCortos = <String, String>{
  'TEXTO': 'Texto',
  'NUMERO': 'Número',
  'EMAIL': 'Email',
  'TELEFONO': 'Teléfono',
  'URL': 'URL',
  'TEXTO_AREA': 'Texto largo',
  'OPCION_SIMPLES': 'Selección',
  'OPCION_MULTIPLE': 'Multi-selección',
  'CHECKBOX': 'Sí/No',
  'CHECKBOX_MULTIPLE': 'Checks múltiple',
  'FECHA': 'Fecha',
  'HORA': 'Hora',
  'ARCHIVO': 'Archivo',
  'OBJETO': 'Objeto',
  'PATRON_DESBLOQUEO': 'Patrón',
  'INSPECCION_VISUAL': 'Inspección',
  'CODIGO_BARRAS': 'Código de barras',
  'PIN_CLAVE': 'PIN / clave',
  'MONEDA': 'Monto',
  'FIRMA': 'Firma',
  'DOCUMENTO_IDENTIDAD': 'DNI / RUC',
  'TABLA': 'Tabla',
};

const kTipoCampoIcons = <String, IconData>{
  'TEXTO': Icons.text_fields,
  'NUMERO': Icons.pin,
  'EMAIL': Icons.email,
  'FECHA': Icons.calendar_today,
  'HORA': Icons.access_time,
  'TEXTO_AREA': Icons.notes,
  'OPCION_SIMPLES': Icons.radio_button_checked,
  'OPCION_MULTIPLE': Icons.checklist,
  'CHECKBOX': Icons.check_box,
  'CHECKBOX_MULTIPLE': Icons.playlist_add_check,
  'ARCHIVO': Icons.attach_file,
  'TELEFONO': Icons.phone,
  'URL': Icons.link,
  'OBJETO': Icons.account_tree_outlined,
  'PATRON_DESBLOQUEO': Icons.pattern,
  'INSPECCION_VISUAL': Icons.car_crash_outlined,
  'CODIGO_BARRAS': Icons.barcode_reader,
  'PIN_CLAVE': Icons.lock_outline,
  'MONEDA': Icons.payments_outlined,
  'FIRMA': Icons.draw_outlined,
  'DOCUMENTO_IDENTIDAD': Icons.badge_outlined,
  'TABLA': Icons.table_chart_outlined,
};

/// Tipos admitidos DENTRO de un campo OBJETO. Es un subconjunto a propósito:
/// el renderer de sub-campos solo sabe pintar estos.
const kSubCampoTipos = <String, String>{
  'TEXTO': 'Texto',
  'CODIGO_BARRAS': 'Código de barras',
  'NUMERO': 'Número',
  'CHECKBOX': 'Sí/No',
  'OPCION_SIMPLES': 'Selección',
};

/// Tipos admitidos como COLUMNA de una TABLA. Más amplio que los sub-campos
/// de OBJETO porque la celda sí sabe pintar monto y escáner, pero deja fuera
/// los widgets altos (firma, patrón, archivo): no entran en una fila.
const kColumnaTiposTabla = <String, String>{
  'TEXTO': 'Texto',
  'NUMERO': 'Número',
  'MONEDA': 'Monto',
  'CHECKBOX': 'Sí/No',
  'OPCION_SIMPLES': 'Selección',
  'CODIGO_BARRAS': 'Código de barras',
  'DOCUMENTO_IDENTIDAD': 'DNI / RUC',
};

/// Dónde escribe el nombre una celda DNI/RUC al resolverlo: en la siguiente
/// columna de TEXTO a la derecha. Es una regla fija y predecible — se ordena
/// `DNI | Nombre` y funciona, sin configuración por columna.
/// Devuelve null si no hay ninguna después.
String? columnaDestinoNombre(
  List<Map<String, dynamic>> columnas,
  String desde,
) {
  final i = columnas.indexWhere((c) => c['nombre'] == desde);
  if (i < 0) return null;
  for (final c in columnas.skip(i + 1)) {
    if ((c['tipo'] as String? ?? 'TEXTO') == 'TEXTO') {
      return c['nombre'] as String;
    }
  }
  return null;
}

// ── Anchos de columna de una TABLA ──────────────────────────────────────
// El ancho vive en la definición de la columna (`ancho`, en píxeles), así
// que es el MISMO para todos y en todas las órdenes de esa plantilla. Al
// arrastrar se guarda ahí; si la columna no lo trae, se usa el default de
// su tipo.

const double kAnchoColumnaMin = 56;
const double kAnchoColumnaMax = 320;

/// Alto FIJO de fila, igual en lectura y en edición. Sin esto la tabla
/// "saltaba" al entrar en edición, porque un TextField mide más que un Text.
/// Con texto de 11px el mínimo cómodo ronda los 26; por debajo empieza a
/// recortarse el descendente de las letras.
const double kAltoFilaTabla = 29;

/// Un campo dentro de una celda no debe traer NINGUNA decoración propia: se
/// escribe sobre la celda, como en Excel. Poner solo `border` no alcanza —
/// si el tema define enabledBorder/focusedBorder, esos se siguen pintando.
const InputDecoration kDecoracionCelda = InputDecoration(
  isDense: true,
  filled: false,
  contentPadding: EdgeInsets.zero,
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  disabledBorder: InputBorder.none,
  errorBorder: InputBorder.none,
  focusedErrorBorder: InputBorder.none,
);

/// Numéricos y booleanos arrancan angostos: no necesitan más.
double anchoPorDefectoColumna(String tipo) =>
    (tipo == 'NUMERO' || tipo == 'MONEDA' || tipo == 'CHECKBOX') ? 78 : 132;

/// Ancho efectivo de una columna, ya recortado a los límites.
double anchoColumna(Map<String, dynamic> columna) {
  final guardado = (columna['ancho'] as num?)?.toDouble();
  final tipo = columna['tipo'] as String? ?? 'TEXTO';
  final ancho = guardado ?? anchoPorDefectoColumna(tipo);
  return ancho.clamp(kAnchoColumnaMin, kAnchoColumnaMax);
}

/// `GENERAL` solo lo usan las plantillas del catálogo precargado.
const kCategoriaLabels = <String, String>{
  'DIAGNOSTICO': 'Diagnóstico',
  'CLIENTE': 'Cliente',
  'TECNICO': 'Técnico',
  'COMPONENTE': 'Componente',
  'COSTOS': 'Costos',
  'TIEMPOS': 'Tiempos',
  'EQUIPO_CLIENTE': 'Equipo del Cliente',
  'GENERAL': 'General',
};

/// Los helpers caen al valor crudo del enum si llega un tipo que esta versión
/// de la app no conoce (backend más nuevo), en vez de mostrar vacío.
String tipoCampoLabel(String tipo) => kTipoCampoLabels[tipo] ?? tipo;

String tipoCampoLabelCorto(String tipo) =>
    kTipoCampoLabelsCortos[tipo] ?? kTipoCampoLabels[tipo] ?? tipo;

IconData tipoCampoIcon(String tipo) =>
    kTipoCampoIcons[tipo] ?? Icons.text_fields;

String categoriaLabel(String categoria) =>
    kCategoriaLabels[categoria] ?? categoria;
