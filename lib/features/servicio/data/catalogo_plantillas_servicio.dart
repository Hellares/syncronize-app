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

/// Catálogo de plantillas predefinidas disponibles para todas las empresas
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
      'Plantilla completa para servicio técnico de celulares. Incluye datos del equipo, IMEI, patrón de desbloqueo, diagnóstico y costos.',
  icono: Icons.smartphone,
  color: Colors.blue,
  campos: [
    // --- EQUIPO_CLIENTE ---
    {
      'nombre': 'Marca del celular',
      'tipoCampo': 'OPCION_SIMPLES',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': true,
      'placeholder': 'Selecciona la marca',
      'opciones': [
        'Samsung',
        'Apple',
        'Xiaomi',
        'Huawei',
        'Motorola',
        'Oppo',
        'Realme',
        'Vivo',
        'OnePlus',
        'Nokia',
        'LG',
        'Honor',
      ],
      'permiteOtro': true,
      'orden': 1,
    },
    {
      'nombre': 'Modelo',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': true,
      'placeholder': 'Ej: Galaxy S24, iPhone 15 Pro',
      'orden': 2,
    },
    {
      'nombre': 'IMEI',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'placeholder': 'Número IMEI de 15 dígitos',
      'orden': 3,
    },
    {
      'nombre': 'Color del equipo',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'placeholder': 'Ej: Negro, Blanco, Azul',
      'orden': 4,
    },
    {
      'nombre': 'Patrón de desbloqueo',
      'tipoCampo': 'PATRON_DESBLOQUEO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'descripcion': 'Patrón o PIN proporcionado por el cliente',
      'orden': 5,
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
      'orden': 6,
    },
    // --- DIAGNOSTICO ---
    {
      'nombre': 'Problema reportado por el cliente',
      'tipoCampo': 'TEXTO_AREA',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': true,
      'placeholder': 'Describe el problema que reporta el cliente',
      'orden': 7,
    },
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
      'orden': 8,
    },
    {
      'nombre': 'Diagnóstico técnico',
      'tipoCampo': 'TEXTO_AREA',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'placeholder': 'Resultado del diagnóstico realizado por el técnico',
      'orden': 9,
    },
    {
      'nombre': 'Evidencia fotográfica',
      'tipoCampo': 'ARCHIVO',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'descripcion': 'Fotos del estado del equipo al momento de recepción',
      'orden': 10,
    },
    // --- COMPONENTE ---
    {
      'nombre': 'Componentes a reemplazar',
      'tipoCampo': 'TEXTO_AREA',
      'categoria': 'COMPONENTE',
      'esRequerido': false,
      'placeholder': 'Lista de repuestos necesarios',
      'orden': 11,
    },
    // --- COSTOS ---
    {
      'nombre': 'Costo de repuestos',
      'tipoCampo': 'NUMERO',
      'categoria': 'COSTOS',
      'esRequerido': false,
      'placeholder': '0.00',
      'orden': 12,
    },
    {
      'nombre': 'Costo de mano de obra',
      'tipoCampo': 'NUMERO',
      'categoria': 'COSTOS',
      'esRequerido': false,
      'placeholder': '0.00',
      'orden': 13,
    },
    // --- TIEMPOS ---
    {
      'nombre': 'Fecha de recepción',
      'tipoCampo': 'FECHA',
      'categoria': 'TIEMPOS',
      'esRequerido': true,
      'orden': 14,
    },
    {
      'nombre': 'Fecha estimada de entrega',
      'tipoCampo': 'FECHA',
      'categoria': 'TIEMPOS',
      'esRequerido': false,
      'orden': 15,
    },
  ],
);

// ═══════════════════════════════════════════
// 2. REPARACIÓN DE LAPTOPS
// ═══════════════════════════════════════════
final _reparacionLaptops = CatalogoPlantilla(
  nombre: 'Reparación de Laptops',
  descripcion:
      'Plantilla para servicio técnico de laptops/notebooks. Incluye inspección visual, estado de componentes y diagnóstico.',
  icono: Icons.laptop_mac,
  color: Colors.indigo,
  campos: [
    // --- EQUIPO_CLIENTE ---
    {
      'nombre': 'Marca',
      'tipoCampo': 'OPCION_SIMPLES',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': true,
      'placeholder': 'Selecciona la marca',
      'opciones': [
        'HP',
        'Dell',
        'Lenovo',
        'Asus',
        'Acer',
        'Apple',
        'MSI',
        'Toshiba',
        'Samsung',
        'Huawei',
      ],
      'permiteOtro': true,
      'orden': 1,
    },
    {
      'nombre': 'Modelo',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': true,
      'placeholder': 'Ej: Pavilion 15, ThinkPad X1',
      'orden': 2,
    },
    {
      'nombre': 'Número de serie',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'placeholder': 'S/N del equipo',
      'orden': 3,
    },
    {
      'nombre': 'Contraseña del equipo',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'placeholder': 'Contraseña de inicio de sesión',
      'orden': 4,
    },
    {
      'nombre': 'Incluye cargador',
      'tipoCampo': 'CHECKBOX',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'orden': 5,
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
      'orden': 6,
    },
    {
      'nombre': 'Inspección visual',
      'tipoCampo': 'INSPECCION_VISUAL',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'descripcion': 'Marcar daños visibles en el equipo',
      'orden': 7,
    },
    // --- DIAGNOSTICO ---
    {
      'nombre': 'Problema reportado',
      'tipoCampo': 'TEXTO_AREA',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': true,
      'placeholder': 'Describe el problema que reporta el cliente',
      'orden': 8,
    },
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
      'orden': 9,
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
      'orden': 10,
    },
    {
      'nombre': 'Diagnóstico técnico',
      'tipoCampo': 'TEXTO_AREA',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'placeholder': 'Resultado del diagnóstico',
      'orden': 11,
    },
    {
      'nombre': 'Evidencia fotográfica',
      'tipoCampo': 'ARCHIVO',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'descripcion': 'Fotos del estado del equipo',
      'orden': 12,
    },
    // --- COSTOS ---
    {
      'nombre': 'Costo de repuestos',
      'tipoCampo': 'NUMERO',
      'categoria': 'COSTOS',
      'esRequerido': false,
      'placeholder': '0.00',
      'orden': 13,
    },
    {
      'nombre': 'Costo de mano de obra',
      'tipoCampo': 'NUMERO',
      'categoria': 'COSTOS',
      'esRequerido': false,
      'placeholder': '0.00',
      'orden': 14,
    },
    // --- TIEMPOS ---
    {
      'nombre': 'Fecha de recepción',
      'tipoCampo': 'FECHA',
      'categoria': 'TIEMPOS',
      'esRequerido': true,
      'orden': 15,
    },
    {
      'nombre': 'Fecha estimada de entrega',
      'tipoCampo': 'FECHA',
      'categoria': 'TIEMPOS',
      'esRequerido': false,
      'orden': 16,
    },
  ],
);

// ═══════════════════════════════════════════
// 3. REPARACIÓN DE PCs
// ═══════════════════════════════════════════
final _reparacionPCs = CatalogoPlantilla(
  nombre: 'Reparación de PCs',
  descripcion:
      'Plantilla para servicio técnico de computadoras de escritorio. Incluye tipo de equipo, componentes internos y diagnóstico.',
  icono: Icons.desktop_windows,
  color: Colors.teal,
  campos: [
    // --- EQUIPO_CLIENTE ---
    {
      'nombre': 'Tipo de equipo',
      'tipoCampo': 'OPCION_SIMPLES',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': true,
      'opciones': ['Desktop (Torre)', 'All-in-One', 'Mini PC', 'Workstation'],
      'orden': 1,
    },
    {
      'nombre': 'Marca',
      'tipoCampo': 'OPCION_SIMPLES',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'opciones': [
        'HP',
        'Dell',
        'Lenovo',
        'Asus',
        'Acer',
        'Apple',
        'Ensamblado/Custom',
      ],
      'permiteOtro': true,
      'orden': 2,
    },
    {
      'nombre': 'Modelo',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'placeholder': 'Modelo del equipo',
      'orden': 3,
    },
    {
      'nombre': 'Número de serie',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'placeholder': 'S/N del equipo',
      'orden': 4,
    },
    {
      'nombre': 'Contraseña del equipo',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'placeholder': 'Contraseña de inicio de sesión',
      'orden': 5,
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
      'orden': 6,
    },
    {
      'nombre': 'Inspección visual',
      'tipoCampo': 'INSPECCION_VISUAL',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'descripcion': 'Marcar daños visibles en el equipo',
      'orden': 7,
    },
    // --- DIAGNOSTICO ---
    {
      'nombre': 'Problema reportado',
      'tipoCampo': 'TEXTO_AREA',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': true,
      'placeholder': 'Describe el problema que reporta el cliente',
      'orden': 8,
    },
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
      'orden': 9,
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
      'orden': 10,
    },
    {
      'nombre': 'Diagnóstico técnico',
      'tipoCampo': 'TEXTO_AREA',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'placeholder': 'Resultado del diagnóstico',
      'orden': 11,
    },
    {
      'nombre': 'Evidencia fotográfica',
      'tipoCampo': 'ARCHIVO',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'descripcion': 'Fotos del estado del equipo',
      'orden': 12,
    },
    // --- COSTOS ---
    {
      'nombre': 'Costo de repuestos',
      'tipoCampo': 'NUMERO',
      'categoria': 'COSTOS',
      'esRequerido': false,
      'placeholder': '0.00',
      'orden': 13,
    },
    {
      'nombre': 'Costo de mano de obra',
      'tipoCampo': 'NUMERO',
      'categoria': 'COSTOS',
      'esRequerido': false,
      'placeholder': '0.00',
      'orden': 14,
    },
    // --- TIEMPOS ---
    {
      'nombre': 'Fecha de recepción',
      'tipoCampo': 'FECHA',
      'categoria': 'TIEMPOS',
      'esRequerido': true,
      'orden': 15,
    },
    {
      'nombre': 'Fecha estimada de entrega',
      'tipoCampo': 'FECHA',
      'categoria': 'TIEMPOS',
      'esRequerido': false,
      'orden': 16,
    },
  ],
);

// ═══════════════════════════════════════════
// 4. REPARACIÓN DE TABLETS
// ═══════════════════════════════════════════
final _reparacionTablets = CatalogoPlantilla(
  nombre: 'Reparación de Tablets',
  descripcion:
      'Plantilla para servicio técnico de tablets/iPads. Incluye datos del equipo, patrón de desbloqueo y diagnóstico.',
  icono: Icons.tablet_mac,
  color: Colors.deepPurple,
  campos: [
    // --- EQUIPO_CLIENTE ---
    {
      'nombre': 'Marca',
      'tipoCampo': 'OPCION_SIMPLES',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': true,
      'placeholder': 'Selecciona la marca',
      'opciones': [
        'Apple (iPad)',
        'Samsung',
        'Huawei',
        'Lenovo',
        'Xiaomi',
        'Amazon (Fire)',
      ],
      'permiteOtro': true,
      'orden': 1,
    },
    {
      'nombre': 'Modelo',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': true,
      'placeholder': 'Ej: iPad Pro 12.9, Galaxy Tab S9',
      'orden': 2,
    },
    {
      'nombre': 'Número de serie',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'placeholder': 'S/N del equipo',
      'orden': 3,
    },
    {
      'nombre': 'IMEI',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'placeholder': 'Solo si tiene conexión celular',
      'orden': 4,
    },
    {
      'nombre': 'Patrón de desbloqueo',
      'tipoCampo': 'PATRON_DESBLOQUEO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'descripcion': 'Patrón o PIN proporcionado por el cliente',
      'orden': 5,
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
      'orden': 6,
    },
    // --- DIAGNOSTICO ---
    {
      'nombre': 'Problema reportado',
      'tipoCampo': 'TEXTO_AREA',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': true,
      'placeholder': 'Describe el problema que reporta el cliente',
      'orden': 7,
    },
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
      'orden': 8,
    },
    {
      'nombre': 'Diagnóstico técnico',
      'tipoCampo': 'TEXTO_AREA',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'placeholder': 'Resultado del diagnóstico',
      'orden': 9,
    },
    {
      'nombre': 'Evidencia fotográfica',
      'tipoCampo': 'ARCHIVO',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'descripcion': 'Fotos del estado del equipo',
      'orden': 10,
    },
    // --- COMPONENTE ---
    {
      'nombre': 'Componentes a reemplazar',
      'tipoCampo': 'TEXTO_AREA',
      'categoria': 'COMPONENTE',
      'esRequerido': false,
      'placeholder': 'Lista de repuestos necesarios',
      'orden': 11,
    },
    // --- COSTOS ---
    {
      'nombre': 'Costo de repuestos',
      'tipoCampo': 'NUMERO',
      'categoria': 'COSTOS',
      'esRequerido': false,
      'placeholder': '0.00',
      'orden': 12,
    },
    {
      'nombre': 'Costo de mano de obra',
      'tipoCampo': 'NUMERO',
      'categoria': 'COSTOS',
      'esRequerido': false,
      'placeholder': '0.00',
      'orden': 13,
    },
    // --- TIEMPOS ---
    {
      'nombre': 'Fecha de recepción',
      'tipoCampo': 'FECHA',
      'categoria': 'TIEMPOS',
      'esRequerido': true,
      'orden': 14,
    },
    {
      'nombre': 'Fecha estimada de entrega',
      'tipoCampo': 'FECHA',
      'categoria': 'TIEMPOS',
      'esRequerido': false,
      'orden': 15,
    },
  ],
);

// ═══════════════════════════════════════════
// 5. REPARACIÓN DE IMPRESORAS
// ═══════════════════════════════════════════
final _reparacionImpresoras = CatalogoPlantilla(
  nombre: 'Reparación de Impresoras',
  descripcion:
      'Plantilla para servicio técnico de impresoras. Incluye tipo de impresora, diagnóstico y costos.',
  icono: Icons.print,
  color: Colors.orange,
  campos: [
    // --- EQUIPO_CLIENTE ---
    {
      'nombre': 'Tipo de impresora',
      'tipoCampo': 'OPCION_SIMPLES',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': true,
      'opciones': [
        'Inyección de tinta',
        'Láser',
        'Matricial',
        'Térmica',
        'Multifuncional',
        'Plotter',
      ],
      'orden': 1,
    },
    {
      'nombre': 'Marca',
      'tipoCampo': 'OPCION_SIMPLES',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': true,
      'opciones': [
        'HP',
        'Epson',
        'Canon',
        'Brother',
        'Samsung',
        'Xerox',
        'Ricoh',
        'Lexmark',
      ],
      'permiteOtro': true,
      'orden': 2,
    },
    {
      'nombre': 'Modelo',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': true,
      'placeholder': 'Modelo de la impresora',
      'orden': 3,
    },
    {
      'nombre': 'Número de serie',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'placeholder': 'S/N del equipo',
      'orden': 4,
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
      'orden': 5,
    },
    {
      'nombre': 'Inspección visual',
      'tipoCampo': 'INSPECCION_VISUAL',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'descripcion': 'Marcar daños visibles en el equipo',
      'orden': 6,
    },
    // --- DIAGNOSTICO ---
    {
      'nombre': 'Problema reportado',
      'tipoCampo': 'TEXTO_AREA',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': true,
      'placeholder': 'Describe el problema que reporta el cliente',
      'orden': 7,
    },
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
      'orden': 8,
    },
    {
      'nombre': 'Diagnóstico técnico',
      'tipoCampo': 'TEXTO_AREA',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'placeholder': 'Resultado del diagnóstico',
      'orden': 9,
    },
    {
      'nombre': 'Evidencia fotográfica',
      'tipoCampo': 'ARCHIVO',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'descripcion': 'Fotos del estado del equipo',
      'orden': 10,
    },
    // --- COSTOS ---
    {
      'nombre': 'Costo de repuestos',
      'tipoCampo': 'NUMERO',
      'categoria': 'COSTOS',
      'esRequerido': false,
      'placeholder': '0.00',
      'orden': 11,
    },
    {
      'nombre': 'Costo de mano de obra',
      'tipoCampo': 'NUMERO',
      'categoria': 'COSTOS',
      'esRequerido': false,
      'placeholder': '0.00',
      'orden': 12,
    },
    // --- TIEMPOS ---
    {
      'nombre': 'Fecha de recepción',
      'tipoCampo': 'FECHA',
      'categoria': 'TIEMPOS',
      'esRequerido': true,
      'orden': 13,
    },
    {
      'nombre': 'Fecha estimada de entrega',
      'tipoCampo': 'FECHA',
      'categoria': 'TIEMPOS',
      'esRequerido': false,
      'orden': 14,
    },
  ],
);

// ═══════════════════════════════════════════
// 6. SERVICIO TÉCNICO GENERAL
// ═══════════════════════════════════════════
final _servicioTecnicoGeneral = CatalogoPlantilla(
  nombre: 'Servicio Técnico General',
  descripcion:
      'Plantilla genérica adaptable a cualquier tipo de equipo o dispositivo. Ideal como punto de partida para personalizar.',
  icono: Icons.build_outlined,
  color: Colors.blueGrey,
  campos: [
    // --- EQUIPO_CLIENTE ---
    {
      'nombre': 'Tipo de equipo',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': true,
      'placeholder': 'Ej: Televisor, Consola, Microondas, etc.',
      'orden': 1,
    },
    {
      'nombre': 'Marca',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'placeholder': 'Marca del equipo',
      'orden': 2,
    },
    {
      'nombre': 'Modelo',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'placeholder': 'Modelo del equipo',
      'orden': 3,
    },
    {
      'nombre': 'Número de serie',
      'tipoCampo': 'TEXTO',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'placeholder': 'S/N del equipo',
      'orden': 4,
    },
    {
      'nombre': 'Accesorios recibidos',
      'tipoCampo': 'TEXTO_AREA',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'placeholder': 'Lista de accesorios que deja el cliente',
      'orden': 5,
    },
    {
      'nombre': 'Inspección visual',
      'tipoCampo': 'INSPECCION_VISUAL',
      'categoria': 'EQUIPO_CLIENTE',
      'esRequerido': false,
      'descripcion': 'Marcar daños visibles en el equipo',
      'orden': 6,
    },
    // --- DIAGNOSTICO ---
    {
      'nombre': 'Problema reportado',
      'tipoCampo': 'TEXTO_AREA',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': true,
      'placeholder': 'Describe el problema que reporta el cliente',
      'orden': 7,
    },
    {
      'nombre': 'Diagnóstico técnico',
      'tipoCampo': 'TEXTO_AREA',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'placeholder': 'Resultado del diagnóstico',
      'orden': 8,
    },
    {
      'nombre': 'Evidencia fotográfica',
      'tipoCampo': 'ARCHIVO',
      'categoria': 'DIAGNOSTICO',
      'esRequerido': false,
      'descripcion': 'Fotos del estado del equipo',
      'orden': 9,
    },
    // --- COMPONENTE ---
    {
      'nombre': 'Componentes/repuestos necesarios',
      'tipoCampo': 'TEXTO_AREA',
      'categoria': 'COMPONENTE',
      'esRequerido': false,
      'placeholder': 'Lista de repuestos necesarios',
      'orden': 10,
    },
    // --- COSTOS ---
    {
      'nombre': 'Costo de repuestos',
      'tipoCampo': 'NUMERO',
      'categoria': 'COSTOS',
      'esRequerido': false,
      'placeholder': '0.00',
      'orden': 11,
    },
    {
      'nombre': 'Costo de mano de obra',
      'tipoCampo': 'NUMERO',
      'categoria': 'COSTOS',
      'esRequerido': false,
      'placeholder': '0.00',
      'orden': 12,
    },
    // --- TIEMPOS ---
    {
      'nombre': 'Fecha de recepción',
      'tipoCampo': 'FECHA',
      'categoria': 'TIEMPOS',
      'esRequerido': true,
      'orden': 13,
    },
    {
      'nombre': 'Fecha estimada de entrega',
      'tipoCampo': 'FECHA',
      'categoria': 'TIEMPOS',
      'esRequerido': false,
      'orden': 14,
    },
  ],
);
