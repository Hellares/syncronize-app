/// Cómo se presentan los tipos de campo de las plantillas de servicio, y todo
/// lo específico de servicios: consultas externas, columnas de TABLA y anchos.
///
/// 📍 **Las etiquetas y los íconos ya NO viven acá**: se mudaron a
/// `core/constants/tipos_dato.dart`, que es el catálogo compartido con los
/// atributos de producto. Acá quedó la lista de qué tipos ofrece servicios
/// ([kTiposCampoServicio], reexportada) y los helpers de siempre.
///
/// Antes esto vivía duplicado en cuatro pantallas —`configuracion_campos_page`,
/// `plantillas_servicio_page`, `servicio_form_page` y `catalogo_plantillas_page`—
/// con ~14 mapas repetidos. Agregar `CODIGO_BARRAS` obligaba a tocar todos, y
/// al fallar dos el tipo quedó invisible en el selector que la gente usaba.
///
/// **Para agregar un tipo de campo hay que tocar exactamente 3 lugares:**
///  1. el catálogo de `core/constants/tipos_dato.dart` + la lista de servicios,
///  2. el `case` en `dynamic_form_renderer.dart` (cómo se captura el dato),
///  3. el enum `TipoCampoServicio` del backend + su migración.
///
/// Las claves son los valores del enum del backend, tal cual viajan en JSON.
library;

import 'package:flutter/material.dart';
import 'package:syncronize/core/constants/tipos_dato.dart';

// El catálogo compartido se reexporta para que las pantallas de servicio
// sigan importando un solo archivo.
export 'package:syncronize/core/constants/tipos_dato.dart'
    show
        kTiposCampoServicio,
        kTipoDatoLabels,
        kTipoDatoLabelsCortos,
        kTipoDatoIcons;

/// Datos que trae cada tipo con consulta externa, y el nombre sugerido de la
/// columna que los recibe. El ORDEN importa: así se crean las acompañantes.
///
/// Cada acompañante guarda `dato` (qué recibe) y `acompanaA` (quién la
/// alimenta), así una placa puede llenar varias columnas de una sola
/// consulta. Sin `dato` declarado se cae al criterio viejo: la siguiente
/// columna de TEXTO recibe el nombre.
const kDatosDeConsulta = <String, Map<String, String>>{
  'DOCUMENTO_IDENTIDAD': {'nombre': 'NOMBRE'},
  'PLACA_VEHICULO': {
    'marca': 'MARCA',
    'modelo': 'MODELO',
    'color': 'COLOR',
    'serie': 'SERIE',
    'motor': 'MOTOR',
    'vin': 'VIN',
  },
  'LICENCIA_CONDUCIR': {
    'nombre': 'NOMBRE',
    'categoria': 'CATEGORIA',
    'vencimiento': 'VENCE',
    'estado': 'ESTADO',
  },
  // La celda de producto guarda el nombre; estos son los datos extra.
  'PRODUCTO_CATALOGO': {'precio': 'PRECIO', 'codigo': 'CODIGO'},
};

bool tipoTieneConsulta(String tipo) => kDatosDeConsulta.containsKey(tipo);

/// Datos que vienen MARCADOS al crear la columna. Los demás quedan a mano:
/// una placa devuelve seis datos y crear seis columnas por defecto llenaría
/// la tabla de cosas que casi nadie mira (serie, motor, VIN).
const kDatosSugeridos = <String, List<String>>{
  'DOCUMENTO_IDENTIDAD': ['nombre'],
  'PLACA_VEHICULO': ['marca', 'modelo', 'color'],
  'LICENCIA_CONDUCIR': ['nombre', 'categoria', 'vencimiento'],
  'PRODUCTO_CATALOGO': ['precio'],
};

/// Reparte los datos de una consulta en las columnas de la fila.
///
/// Prefiere las columnas que declaran `dato` (una placa puede llenar marca,
/// modelo y color de una sola consulta). Si no hay ninguna declarada, cae al
/// criterio viejo —la siguiente columna de TEXTO recibe el nombre— para no
/// romper las columnas DNI creadas antes de que existiera `dato`.
void volcarDatosDeConsulta({
  required Map<String, String> datos,
  required List<Map<String, dynamic>> columnas,
  required String origen,
  required void Function(String columna, String valor) escribir,
  required void Function(String mensaje) sinDestino,
}) {
  var escritos = 0;

  // Camino normal: cada columna declara qué dato recibe.
  columnasPorDato(columnas, origen).forEach((dato, columna) {
    final v = datos[dato];
    if (v != null && v.trim().isNotEmpty) {
      escribir(columna, v);
      escritos++;
    }
  });
  if (escritos > 0) return;

  // Respaldo: sin columnas marcadas (creadas a mano, o definición aún no
  // refrescada) se reparte EN ORDEN sobre las columnas de texto que siguen.
  //
  // 🔴 Antes este respaldo solo sabía colocar `datos['nombre']`, así que con
  // una placa —que devuelve marca/modelo/color y ningún `nombre`— no escribía
  // nada y solo mostraba un aviso: "trae los datos pero no los llena".
  final valores =
      datos.values.where((v) => v.trim().isNotEmpty).toList(growable: false);
  final destinos = columnasTextoDespuesDe(columnas, origen);
  for (var i = 0; i < destinos.length && i < valores.length; i++) {
    escribir(destinos[i], valores[i]);
    escritos++;
  }

  if (escritos == 0) sinDestino(valores.join(' · '));
}

/// Columnas de TEXTO que siguen a [desde], en orden. Son los destinos de
/// respaldo cuando ninguna declara `dato`.
List<String> columnasTextoDespuesDe(
  List<Map<String, dynamic>> columnas,
  String desde,
) {
  final i = columnas.indexWhere((c) => c['nombre'] == desde);
  if (i < 0) return const [];
  return [
    for (final c in columnas.skip(i + 1))
      if ((c['tipo'] as String? ?? 'TEXTO') == 'TEXTO') c['nombre'] as String,
  ];
}

/// Columnas acompañantes declaradas de [origen], indexadas por el dato que
/// reciben.
Map<String, String> columnasPorDato(
  List<Map<String, dynamic>> columnas,
  String origen,
) =>
    {
      for (final c in columnas)
        if (c['acompanaA'] == origen && c['dato'] != null)
          c['dato'] as String: c['nombre'] as String,
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
  'PLACA_VEHICULO': 'Placa',
  'LICENCIA_CONDUCIR': 'Licencia',
  'FOTO': 'Foto',
  'PRODUCTO_CATALOGO': 'Producto del catálogo',
};

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
///
/// Delegan en el catálogo compartido; se conservan con este nombre porque los
/// usan las cuatro pantallas de servicio.
String tipoCampoLabel(String tipo) => tipoDatoLabel(tipo);

String tipoCampoLabelCorto(String tipo) => tipoDatoLabelCorto(tipo);

IconData tipoCampoIcon(String tipo) => tipoDatoIcono(tipo);

String categoriaLabel(String categoria) =>
    kCategoriaLabels[categoria] ?? categoria;
