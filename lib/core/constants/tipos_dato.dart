/// Catálogo ÚNICO de tipos de dato: etiquetas e íconos.
///
/// Lo comparten las plantillas de servicio (`TipoCampoServicio`) y los
/// atributos de producto (`AtributoTipo`). Antes cada pantalla traía su propio
/// mapa: servicios llegó a tener cuatro copias —y un tipo quedó invisible en el
/// selector que la gente usaba— y productos tenía otras seis, que ni siquiera
/// coincidían entre sí (SELECT se pintaba con `Icons.list` en una pantalla y
/// con `arrow_drop_down_circle_outlined` en otra).
///
/// **Los mapas son el SUPERCONJUNTO**: contienen las claves de los dos enums.
/// Nadie debe iterarlos para armar un selector; para eso están las listas
/// ordenadas [kTiposCampoServicio] y [kTiposAtributoProducto], que definen qué
/// ofrece cada pantalla y en qué orden.
///
/// Los dos enums comparten vocabulario pero NO nombres internos: servicios dice
/// `OPCION_SIMPLES` donde productos dice `SELECT`. Unificarlos obligaría a
/// migrar filas vivas de las dos tablas por un cambio que el usuario no ve; lo
/// que sí se unificó es la etiqueta, que es lo que él lee.
///
/// **Para agregar un tipo:** la entrada acá, la lista de la(s) pantalla(s) que
/// lo ofrecen, el `case` que lo captura (`dynamic_form_renderer.dart` para
/// servicios, `atributo_input_widget.dart` para productos) y el enum del
/// backend con su migración.
library;

import 'package:flutter/material.dart';

/// Etiqueta completa: selectores y formularios, donde hay ancho.
const kTipoDatoLabels = <String, String>{
  // ── Tipos de campo de servicio ──
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
  'PLACA_VEHICULO': 'Placa (con autocompletado)',
  'LICENCIA_CONDUCIR': 'Licencia de conducir',
  'FOTO': 'Foto',
  'PRODUCTO_CATALOGO': 'Producto del catálogo',

  // ── Propios de los atributos de producto ──
  // Mismo texto que su equivalente de servicios, distinto nombre interno.
  'SELECT': 'Selección simple',
  'MULTI_SELECT': 'Selección múltiple',
  'SELECT_DEPENDIENTE': 'Selección dependiente',
  'BOOLEAN': 'Sí/No',
  // Legacy: no son tipos de dato sino nombres de atributo. Fuera del selector,
  // pero siguen acá para que una fila vieja no se muestre con la clave cruda.
  'COLOR': 'Color',
  'TALLA': 'Talla',
  'MATERIAL': 'Material',
  'CAPACIDAD': 'Capacidad',
};

/// Etiqueta corta: chips y listados, donde no entra la larga.
const kTipoDatoLabelsCortos = <String, String>{
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
  'PLACA_VEHICULO': 'Placa',
  'LICENCIA_CONDUCIR': 'Licencia',
  'FOTO': 'Foto',
  'PRODUCTO_CATALOGO': 'Producto',

  'SELECT': 'Selección',
  'MULTI_SELECT': 'Multi-selección',
  'SELECT_DEPENDIENTE': 'Dependiente',
  'BOOLEAN': 'Sí/No',
  'COLOR': 'Color',
  'TALLA': 'Talla',
  'MATERIAL': 'Material',
  'CAPACIDAD': 'Capacidad',
};

const kTipoDatoIcons = <String, IconData>{
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
  'PLACA_VEHICULO': Icons.directions_car_outlined,
  'LICENCIA_CONDUCIR': Icons.card_membership_outlined,
  'FOTO': Icons.photo_camera_outlined,
  'PRODUCTO_CATALOGO': Icons.inventory_2_outlined,

  // Mismos íconos que sus equivalentes de servicios.
  'SELECT': Icons.radio_button_checked,
  'MULTI_SELECT': Icons.checklist,
  'SELECT_DEPENDIENTE': Icons.account_tree_outlined,
  'BOOLEAN': Icons.check_box,
  'COLOR': Icons.palette,
  'TALLA': Icons.straighten,
  'MATERIAL': Icons.category,
  'CAPACIDAD': Icons.storage,
};

/// Tipos que ofrece el selector de campos de una PLANTILLA DE SERVICIO, en
/// orden. Es el orden histórico del mapa: no se tocó para no mover de lugar
/// lo que la gente ya sabe dónde encontrar.
const kTiposCampoServicio = <String>[
  'TEXTO',
  'NUMERO',
  'EMAIL',
  'FECHA',
  'HORA',
  'TEXTO_AREA',
  'OPCION_SIMPLES',
  'OPCION_MULTIPLE',
  'CHECKBOX',
  'CHECKBOX_MULTIPLE',
  'ARCHIVO',
  'TELEFONO',
  'URL',
  'OBJETO',
  'PATRON_DESBLOQUEO',
  'INSPECCION_VISUAL',
  'CODIGO_BARRAS',
  'PIN_CLAVE',
  'MONEDA',
  'FIRMA',
  'DOCUMENTO_IDENTIDAD',
  'TABLA',
  'PLACA_VEHICULO',
  'LICENCIA_CONDUCIR',
  'FOTO',
  'PRODUCTO_CATALOGO',
];

/// Tipos que ofrece el selector de ATRIBUTOS DE PRODUCTO, en orden.
///
/// Arranca por los dos que tienen lista de valores porque son los únicos que
/// sirven de eje de variante, que es para lo que se crea la mayoría de los
/// atributos. Después el dato libre, y al final lo específico.
///
/// No están `TABLA` ni `OBJETO`: guardan estructura y el valor de un atributo
/// es un String con índice GIN para los filtros del marketplace. Tampoco los
/// cuatro legacy (COLOR, TALLA, MATERIAL, CAPACIDAD), que son nombres de
/// atributo disfrazados de tipo — un atributo "Color" se crea como Selección
/// llamada Color, igual que el Material de EDREDONES en producción.
const kTiposAtributoProducto = <String>[
  // Con lista de valores
  'SELECT',
  'MULTI_SELECT',
  'SELECT_DEPENDIENTE',
  // Dato libre
  'TEXTO',
  'TEXTO_AREA',
  'NUMERO',
  'MONEDA',
  'BOOLEAN',
  'FECHA',
  'HORA',
  'EMAIL',
  'TELEFONO',
  'URL',
  // Códigos e identificación
  'CODIGO_BARRAS',
  'PIN_CLAVE',
  'PATRON_DESBLOQUEO',
  'DOCUMENTO_IDENTIDAD',
  'PLACA_VEHICULO',
  'LICENCIA_CONDUCIR',
  // Archivos: el valor guardado es la URL del storage
  'FOTO',
  'FIRMA',
  'ARCHIVO',
  // Otros
  'INSPECCION_VISUAL',
  'PRODUCTO_CATALOGO',
];

/// Atributos de producto que se llenan eligiendo de una lista.
///
/// Son los únicos que EXIGEN `valores` (el resto los tiene PROHIBIDOS, ver
/// `validateAtributoValues` en el backend) y, por lo mismo, los únicos que el
/// generador de combinaciones puede usar como eje de variante — que filtra por
/// `valores.isNotEmpty`, no por el tipo.
const kTiposAtributoConLista = <String>{
  'SELECT',
  'MULTI_SELECT',
  'SELECT_DEPENDIENTE',
};

/// Legacy fuera del selector. Se siguen mostrando si una fila vieja los trae.
const kTiposAtributoLegacy = <String>{'COLOR', 'TALLA', 'MATERIAL', 'CAPACIDAD'};

// Los helpers caen al valor crudo del enum si llega un tipo que esta versión
// de la app no conoce (backend más nuevo), en vez de mostrar vacío.

String tipoDatoLabel(String tipo) => kTipoDatoLabels[tipo] ?? tipo;

String tipoDatoLabelCorto(String tipo) =>
    kTipoDatoLabelsCortos[tipo] ?? kTipoDatoLabels[tipo] ?? tipo;

IconData tipoDatoIcono(String tipo) =>
    kTipoDatoIcons[tipo] ?? Icons.text_fields;
