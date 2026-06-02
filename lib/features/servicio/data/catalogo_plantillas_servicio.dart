import 'package:flutter/material.dart';

/// Plantilla predefinida del catálogo
class CatalogoPlantilla {
  final String nombre;
  final String descripcion;
  final IconData icono;
  final Color color;
  final List<Map<String, dynamic>> campos;

  const CatalogoPlantilla({
    required this.nombre,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.campos,
  });

  int get camposCount => campos.length;

  List<String> get categorias =>
      campos.map((c) => c['categoria'] as String? ?? 'GENERAL').toSet().toList();
}

/// Catálogo de plantillas predefinidas disponibles para todas las empresas.
///
/// NOTA: estas plantillas NO repiten los campos que la orden de servicio ya
/// captura de forma nativa (Equipo/tipo, Marca, Número de serie, Condición del
/// equipo, Problema reportado) ni precios/costos ni fechas (recepción/entrega),
/// porque esos viven en el formulario de la orden. Aquí solo van campos
/// adicionales propios del tipo de equipo (IMEI, patrón, accesorios, falla, etc.).
final List<CatalogoPlantilla> catalogoPlantillas = [
  _reparacionCelulares,
  _reparacionLaptops,
  _reparacionPCs,
  _reparacionTablets,
  _reparacionImpresoras,
  _servicioTecnicoGeneral,
];

// ═══════════════════════════════════════════
// 1. REPARACIÓN DE CELULARES
// ═══════════════════════════════════════════
final _reparacionCelulares = CatalogoPlantilla(
  nombre: 'Reparación de Celulares',
  descripcion:
      'Campos adicionales para servicio técnico de celulares: IMEI, patrón de desbloqueo, accesorios y tipo de falla.',
  icono: Icons.smartphone,
  color: Colors.blue,
  campos: [
    // --- EQUIPO_CLIENTE ---
    {
      'nombre': 'Modelo',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': true,
      'placeholder': 'Ej: Galaxy S24, iPhone 15 Pro',
      'orden': 1,
    },
    {
      'nombre': 'IMEI',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'placeholder': 'Número IMEI de 15 dígitos',
      'orden': 2,
    },
    {
      'nombre': 'Color del equipo',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'placeholder': 'Ej: Negro, Blanco, Azul',
      'orden': 3,
    },
    {
      'nombre': 'Patrón de desbloqueo',
      'tipoCampo': 'PATRON_DESBLOQUEO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'descripcion': 'Patrón o PIN proporcionado por el cliente',
      'orden': 4,
    },
    {
      'nombre': 'Accesorios recibidos',
      'tipoCampo': 'CHECKBOX_MULTIPLE',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'opciones': [
        'Cargador',
        'Cable USB',
        'Audífonos',
        'Funda/Case',
        'Protector de pantalla',
        'Caja original',
        'Chip SIM',
        'Memoria SD',
      ],
      'orden': 5,
    },
    // --- DIAGNOSTICO ---
    {
      'nombre': 'Tipo de falla',
      'tipoCampo': 'OPCION_SIMPLES',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'opciones': [
        'Pantalla rota/dañada',
        'No enciende',
        'Batería agotada',
        'Problemas de carga',
        'Falla de software',
        'Cámara dañada',
        'Altavoz/micrófono',
        'Botones no funcionan',
        'Mojado/líquido',
        'Placa dañada',
        'Conector de carga',
      ],
      'permiteOtro': true,
      'orden': 6,
    },
    {
      'nombre': 'Evidencia fotográfica',
      'tipoCampo': 'ARCHIVO',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'descripcion': 'Fotos del estado del equipo al momento de recepción',
      'orden': 7,
    },
    // --- COMPONENTE ---
    {
      'nombre': 'Componentes a reemplazar',
      'tipoCampo': 'TEXTO_AREA',
      'categoria': 'COMPONENTE',
      'esRequerido': false,
      'placeholder': 'Lista de repuestos necesarios',
      'orden': 8,
    },
  ],
);

// ═══════════════════════════════════════════
// 2. REPARACIÓN DE LAPTOPS
// ═══════════════════════════════════════════
final _reparacionLaptops = CatalogoPlantilla(
  nombre: 'Reparación de Laptops',
  descripcion:
      'Campos adicionales para laptops/notebooks: contraseña, accesorios, estado de componentes y tipo de falla.',
  icono: Icons.laptop_mac,
  color: Colors.indigo,
  campos: [
    // --- EQUIPO_CLIENTE ---
    {
      'nombre': 'Modelo',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': true,
      'placeholder': 'Ej: Pavilion 15, ThinkPad X1',
      'orden': 1,
    },
    {
      'nombre': 'Contraseña del equipo',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'placeholder': 'Contraseña de inicio de sesión',
      'orden': 2,
    },
    {
      'nombre': 'Incluye cargador',
      'tipoCampo': 'CHECKBOX',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'orden': 3,
    },
    {
      'nombre': 'Accesorios recibidos',
      'tipoCampo': 'CHECKBOX_MULTIPLE',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'opciones': [
        'Cargador',
        'Mouse',
        'Maletín/Funda',
        'Disco externo',
        'USB/Pendrive',
      ],
      'orden': 4,
    },
    // --- DIAGNOSTICO ---
    {
      'nombre': 'Tipo de falla',
      'tipoCampo': 'OPCION_SIMPLES',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'opciones': [
        'No enciende',
        'Pantalla dañada/rota',
        'Teclado no funciona',
        'Problemas de batería',
        'Sobrecalentamiento',
        'Lentitud/rendimiento',
        'Virus/malware',
        'Disco duro dañado',
        'Falla de RAM',
        'Puerto USB/HDMI dañado',
        'Bisagras rotas',
        'Problema de red/WiFi',
        'Sonido no funciona',
      ],
      'permiteOtro': true,
      'orden': 5,
    },
    {
      'nombre': 'Estado de componentes',
      'tipoCampo': 'OBJETO',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'descripcion': 'Estado actual de los componentes principales',
      'opciones': [
        {'nombre': 'Pantalla', 'tipo': 'OPCION_SIMPLES', 'opciones': ['Bueno', 'Regular', 'Malo', 'No aplica']},
        {'nombre': 'Teclado', 'tipo': 'OPCION_SIMPLES', 'opciones': ['Bueno', 'Regular', 'Malo', 'No aplica']},
        {'nombre': 'Batería', 'tipo': 'OPCION_SIMPLES', 'opciones': ['Bueno', 'Regular', 'Malo', 'No aplica']},
        {'nombre': 'Cargador', 'tipo': 'OPCION_SIMPLES', 'opciones': ['Bueno', 'Regular', 'Malo', 'No aplica']},
        {'nombre': 'Disco duro', 'tipo': 'OPCION_SIMPLES', 'opciones': ['Bueno', 'Regular', 'Malo', 'No aplica']},
      ],
      'orden': 6,
    },
    {
      'nombre': 'Evidencia fotográfica',
      'tipoCampo': 'ARCHIVO',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'descripcion': 'Fotos del estado del equipo',
      'orden': 7,
    },
  ],
);

// ═══════════════════════════════════════════
// 3. REPARACIÓN DE PCs
// ═══════════════════════════════════════════
final _reparacionPCs = CatalogoPlantilla(
  nombre: 'Reparación de PCs',
  descripcion:
      'Campos adicionales para computadoras de escritorio: contraseña, periféricos, especificaciones y tipo de falla.',
  icono: Icons.desktop_windows,
  color: Colors.teal,
  campos: [
    // --- EQUIPO_CLIENTE ---
    {
      'nombre': 'Modelo',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'placeholder': 'Modelo del equipo',
      'orden': 1,
    },
    {
      'nombre': 'Contraseña del equipo',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'placeholder': 'Contraseña de inicio de sesión',
      'orden': 2,
    },
    {
      'nombre': 'Periféricos recibidos',
      'tipoCampo': 'CHECKBOX_MULTIPLE',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'opciones': [
        'Monitor',
        'Teclado',
        'Mouse',
        'Cable de poder',
        'Cable HDMI/VGA',
        'Parlantes',
        'Webcam',
      ],
      'orden': 3,
    },
    // --- DIAGNOSTICO ---
    {
      'nombre': 'Tipo de falla',
      'tipoCampo': 'OPCION_SIMPLES',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'opciones': [
        'No enciende',
        'Pantalla azul/BSOD',
        'Lentitud/rendimiento',
        'Sobrecalentamiento',
        'Ruidos extraños',
        'Virus/malware',
        'Disco duro dañado',
        'Falla de RAM',
        'Fuente de poder',
        'Tarjeta madre',
        'Problema de red',
        'No muestra imagen',
      ],
      'permiteOtro': true,
      'orden': 4,
    },
    {
      'nombre': 'Especificaciones del equipo',
      'tipoCampo': 'OBJETO',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'descripcion': 'Componentes internos identificados',
      'opciones': [
        {'nombre': 'Procesador', 'tipo': 'TEXTO'},
        {'nombre': 'RAM', 'tipo': 'TEXTO'},
        {'nombre': 'Disco duro/SSD', 'tipo': 'TEXTO'},
        {'nombre': 'Tarjeta gráfica', 'tipo': 'TEXTO'},
        {'nombre': 'Sistema operativo', 'tipo': 'TEXTO'},
      ],
      'orden': 5,
    },
    {
      'nombre': 'Evidencia fotográfica',
      'tipoCampo': 'ARCHIVO',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'descripcion': 'Fotos del estado del equipo',
      'orden': 6,
    },
  ],
);

// ═══════════════════════════════════════════
// 4. REPARACIÓN DE TABLETS
// ═══════════════════════════════════════════
final _reparacionTablets = CatalogoPlantilla(
  nombre: 'Reparación de Tablets',
  descripcion:
      'Campos adicionales para tablets/iPads: IMEI, patrón de desbloqueo, accesorios y tipo de falla.',
  icono: Icons.tablet_mac,
  color: Colors.deepPurple,
  campos: [
    // --- EQUIPO_CLIENTE ---
    {
      'nombre': 'Modelo',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': true,
      'placeholder': 'Ej: iPad Pro 12.9, Galaxy Tab S9',
      'orden': 1,
    },
    {
      'nombre': 'IMEI',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'placeholder': 'Solo si tiene conexión celular',
      'orden': 2,
    },
    {
      'nombre': 'Patrón de desbloqueo',
      'tipoCampo': 'PATRON_DESBLOQUEO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'descripcion': 'Patrón o PIN proporcionado por el cliente',
      'orden': 3,
    },
    {
      'nombre': 'Accesorios recibidos',
      'tipoCampo': 'CHECKBOX_MULTIPLE',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'opciones': [
        'Cargador',
        'Cable USB',
        'Funda/Case',
        'Lápiz/Stylus',
        'Teclado externo',
      ],
      'orden': 4,
    },
    // --- DIAGNOSTICO ---
    {
      'nombre': 'Tipo de falla',
      'tipoCampo': 'OPCION_SIMPLES',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'opciones': [
        'Pantalla rota/dañada',
        'No enciende',
        'Batería agotada',
        'Problemas de carga',
        'Falla de software',
        'Botones no funcionan',
        'Mojado/líquido',
        'Conector de carga',
        'Cámara dañada',
        'Altavoz/micrófono',
      ],
      'permiteOtro': true,
      'orden': 5,
    },
    {
      'nombre': 'Evidencia fotográfica',
      'tipoCampo': 'ARCHIVO',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'descripcion': 'Fotos del estado del equipo',
      'orden': 6,
    },
    // --- COMPONENTE ---
    {
      'nombre': 'Componentes a reemplazar',
      'tipoCampo': 'TEXTO_AREA',
      'categoria': 'COMPONENTE',
      'esRequerido': false,
      'placeholder': 'Lista de repuestos necesarios',
      'orden': 7,
    },
  ],
);

// ═══════════════════════════════════════════
// 5. REPARACIÓN DE IMPRESORAS
// ═══════════════════════════════════════════
final _reparacionImpresoras = CatalogoPlantilla(
  nombre: 'Reparación de Impresoras',
  descripcion:
      'Campos adicionales para impresoras: accesorios y tipo de falla específicos de impresión.',
  icono: Icons.print,
  color: Colors.orange,
  campos: [
    // --- EQUIPO_CLIENTE ---
    {
      'nombre': 'Modelo',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': true,
      'placeholder': 'Modelo de la impresora',
      'orden': 1,
    },
    {
      'nombre': 'Accesorios recibidos',
      'tipoCampo': 'CHECKBOX_MULTIPLE',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'opciones': [
        'Cable de poder',
        'Cable USB',
        'Bandeja de papel',
        'Cartuchos/Tóner',
      ],
      'orden': 2,
    },
    // --- DIAGNOSTICO ---
    {
      'nombre': 'Tipo de falla',
      'tipoCampo': 'OPCION_SIMPLES',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'opciones': [
        'No imprime',
        'Atascos de papel',
        'Impresión borrosa',
        'Rayas en la impresión',
        'No reconoce cartuchos',
        'Error de conexión',
        'Ruidos extraños',
        'No enciende',
        'Fuga de tinta',
        'Escáner no funciona',
      ],
      'permiteOtro': true,
      'orden': 3,
    },
    {
      'nombre': 'Evidencia fotográfica',
      'tipoCampo': 'ARCHIVO',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'descripcion': 'Fotos del estado del equipo',
      'orden': 4,
    },
  ],
);

// ═══════════════════════════════════════════
// 6. SERVICIO TÉCNICO GENERAL
// ═══════════════════════════════════════════
final _servicioTecnicoGeneral = CatalogoPlantilla(
  nombre: 'Servicio Técnico General',
  descripcion:
      'Plantilla genérica adaptable a cualquier equipo. Solo campos adicionales; ideal como punto de partida para personalizar.',
  icono: Icons.build_outlined,
  color: Colors.blueGrey,
  campos: [
    // --- EQUIPO_CLIENTE ---
    {
      'nombre': 'Modelo',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'placeholder': 'Modelo del equipo',
      'orden': 1,
    },
    {
      'nombre': 'Accesorios recibidos',
      'tipoCampo': 'TEXTO_AREA',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'placeholder': 'Lista de accesorios que deja el cliente',
      'orden': 2,
    },
    // --- DIAGNOSTICO ---
    {
      'nombre': 'Evidencia fotográfica',
      'tipoCampo': 'ARCHIVO',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'descripcion': 'Fotos del estado del equipo',
      'orden': 3,
    },
    // --- COMPONENTE ---
    {
      'nombre': 'Componentes/repuestos necesarios',
      'tipoCampo': 'TEXTO_AREA',
      'categoria': 'COMPONENTE',
      'esRequerido': false,
      'placeholder': 'Lista de repuestos necesarios',
      'orden': 4,
    },
  ],
);
