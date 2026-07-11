/// Catálogo curado de códigos de producto SUNAT (UNSPSC 8 dígitos).
///
/// Fuente: anexos 25.1, 25.2 y 25.3 del Catálogo N.° 25 — "Reglas de
/// validación actualizado al 24.04.2026" (cpe.sunat.gob.pe), vigencia
/// 01.08.2026. Desde esa fecha un código INVÁLIDO en el comprobante es
/// RECHAZO (ERR-3496): por eso el campo se elige de esta lista y nunca
/// es texto libre.
///
/// El código es OPCIONAL: solo es obligatorio para RUCs del padrón 12
/// de SUNAT ("obligado a enviar código de producto") y en liquidaciones
/// de compra. Sin código, el XML sale sin el tag y SUNAT no valida nada.
class CodigoProductoSunat {
  final String codigo;
  final String descripcion;
  final String grupo;

  const CodigoProductoSunat({
    required this.codigo,
    required this.descripcion,
    required this.grupo,
  });
}

/// Grupos (en orden de presentación).
class GruposCodigoSunat {
  static const genericos = 'Genéricos (comodín aceptado por SUNAT)';
  static const detraccion = 'Bienes con detracción (25.2)';
  static const percepcion = 'Bienes con percepción (25.3)';
  static const oro = 'Oro y minería (25.1)';
  static const explosivos = 'Explosivos (25.1)';
  static const quimicos = 'Insumos químicos (25.1)';
  static const combustibles = 'Combustibles (25.1)';
  static const maquinaria = 'Maquinaria y equipos (25.1)';
  static const otrosBienes = 'Otros bienes (25.1)';
  static const servicios = 'Servicios (25.1)';

  static const List<String> orden = [
    genericos,
    detraccion,
    percepcion,
    combustibles,
    otrosBienes,
    oro,
    explosivos,
    quimicos,
    maquinaria,
    servicios,
  ];
}

/// Lista completa de los anexos 25.1 + 25.2 + 25.3 (oficial SUNAT) + genéricos.
const List<CodigoProductoSunat> kCatalogoCodigosProductoSunat = [
  // ── Genéricos: valores comodín EXENTOS de la validación ERR-3496
  //    ("diferente de 8 ceros y de 8 nueves"). Para empresas del padrón 12
  //    cuyos productos NO están en los anexos — los bienes fiscalizados
  //    deben llevar su código específico, no el genérico. ──
  CodigoProductoSunat(codigo: '00000000', descripcion: 'Sin código de producto SUNAT asignado', grupo: GruposCodigoSunat.genericos),
  CodigoProductoSunat(codigo: '99999999', descripcion: 'Mercadería genérica / no clasificable', grupo: GruposCodigoSunat.genericos),

  // ── Anexo 25.2: bienes sujetos a DETRACCIÓN ──
  CodigoProductoSunat(codigo: '50111500', descripcion: 'Carnes y despojos comestibles', grupo: GruposCodigoSunat.detraccion),
  CodigoProductoSunat(codigo: '11111111', descripcion: 'Bienes gravados con el IGV por renuncia a la exoneración', grupo: GruposCodigoSunat.detraccion),
  CodigoProductoSunat(codigo: '10171503', descripcion: 'Harina, polvo y pellets de pescado, crustáceos y moluscos', grupo: GruposCodigoSunat.detraccion),
  CodigoProductoSunat(codigo: '11101600', descripcion: 'Minerales metálicos no auríferos', grupo: GruposCodigoSunat.detraccion),
  CodigoProductoSunat(codigo: '11101714', descripcion: 'Plomo', grupo: GruposCodigoSunat.detraccion),
  CodigoProductoSunat(codigo: '11111600', descripcion: 'Piedra', grupo: GruposCodigoSunat.detraccion),
  CodigoProductoSunat(codigo: '11111700', descripcion: 'Arena', grupo: GruposCodigoSunat.detraccion),
  CodigoProductoSunat(codigo: '11121600', descripcion: 'Madera', grupo: GruposCodigoSunat.detraccion),
  CodigoProductoSunat(codigo: '11140000', descripcion: 'Chatarra y materiales de desecho', grupo: GruposCodigoSunat.detraccion),
  CodigoProductoSunat(codigo: '50120000', descripcion: 'Recursos hidrobiológicos', grupo: GruposCodigoSunat.detraccion),
  CodigoProductoSunat(codigo: '50151600', descripcion: 'Aceite de pescado', grupo: GruposCodigoSunat.detraccion),
  CodigoProductoSunat(codigo: '50161509', descripcion: 'Caña de azúcar', grupo: GruposCodigoSunat.detraccion),
  CodigoProductoSunat(codigo: '50171500', descripcion: 'Páprika', grupo: GruposCodigoSunat.detraccion),
  CodigoProductoSunat(codigo: '50203205', descripcion: 'Leche cruda entera', grupo: GruposCodigoSunat.detraccion),
  CodigoProductoSunat(codigo: '50403200', descripcion: 'Maíz amarillo', grupo: GruposCodigoSunat.detraccion),

  // ── Anexo 25.3: bienes sujetos a PERCEPCIÓN ──
  CodigoProductoSunat(codigo: '50202300', descripcion: 'Agua, agua mineral y demás bebidas no alcohólicas', grupo: GruposCodigoSunat.percepcion),
  CodigoProductoSunat(codigo: '50202201', descripcion: 'Cerveza de malta', grupo: GruposCodigoSunat.percepcion),
  CodigoProductoSunat(codigo: '15101502', descripcion: 'Kerosene', grupo: GruposCodigoSunat.percepcion),
  CodigoProductoSunat(codigo: '15101504', descripcion: 'Combustible para aviación', grupo: GruposCodigoSunat.percepcion),
  CodigoProductoSunat(codigo: '15101509', descripcion: 'Combustible de uso marino (bunker)', grupo: GruposCodigoSunat.percepcion),
  CodigoProductoSunat(codigo: '15111510', descripcion: 'Gas licuado de petróleo (GLP)', grupo: GruposCodigoSunat.percepcion),
  CodigoProductoSunat(codigo: '12142104', descripcion: 'Dióxido de carbono', grupo: GruposCodigoSunat.percepcion),
  CodigoProductoSunat(codigo: '13111039', descripcion: 'Poli (tereftalato de etileno) PET en formas primarias', grupo: GruposCodigoSunat.percepcion),
  CodigoProductoSunat(codigo: '13102020', descripcion: 'Envases o preformas de PET', grupo: GruposCodigoSunat.percepcion),
  CodigoProductoSunat(codigo: '24122000', descripcion: 'Envases de vidrio (bombonas, botellas, frascos, tarros)', grupo: GruposCodigoSunat.percepcion),
  CodigoProductoSunat(codigo: '24122004', descripcion: 'Tapones, tapas, cápsulas y dispositivos de cierre', grupo: GruposCodigoSunat.percepcion),
  CodigoProductoSunat(codigo: '50221002', descripcion: 'Harina de trigo o de morcajo', grupo: GruposCodigoSunat.percepcion),
  CodigoProductoSunat(codigo: '50221110', descripcion: 'Trigo y morcajo', grupo: GruposCodigoSunat.percepcion),

  // ── Anexo 25.1: combustibles ──
  CodigoProductoSunat(codigo: '15101505', descripcion: 'Combustible diésel', grupo: GruposCodigoSunat.combustibles),
  CodigoProductoSunat(codigo: '15101506', descripcion: 'Gasolina', grupo: GruposCodigoSunat.combustibles),
  CodigoProductoSunat(codigo: '15100000', descripcion: 'Otros combustibles', grupo: GruposCodigoSunat.combustibles),

  // ── Anexo 25.1: otros bienes ──
  CodigoProductoSunat(codigo: '12352104', descripcion: 'Alcoholes o sus sustitutos', grupo: GruposCodigoSunat.otrosBienes),
  CodigoProductoSunat(codigo: '50161509', descripcion: 'Azúcares naturales o productos endulzantes', grupo: GruposCodigoSunat.otrosBienes),
  CodigoProductoSunat(codigo: '50221101', descripcion: 'Grano de cereal (arroz)', grupo: GruposCodigoSunat.otrosBienes),

  // ── Anexo 25.1: oro y minería ──
  CodigoProductoSunat(codigo: '11101616', descripcion: 'Mineral de oro', grupo: GruposCodigoSunat.oro),
  CodigoProductoSunat(codigo: '11101801', descripcion: 'Oro', grupo: GruposCodigoSunat.oro),

  // ── Anexo 25.1: explosivos ──
  CodigoProductoSunat(codigo: '12131500', descripcion: 'Explosivos', grupo: GruposCodigoSunat.explosivos),
  CodigoProductoSunat(codigo: '12131501', descripcion: 'Dinamita', grupo: GruposCodigoSunat.explosivos),
  CodigoProductoSunat(codigo: '12131502', descripcion: 'Cartuchos explosivos', grupo: GruposCodigoSunat.explosivos),
  CodigoProductoSunat(codigo: '12131503', descripcion: 'Explosivos propelentes', grupo: GruposCodigoSunat.explosivos),
  CodigoProductoSunat(codigo: '12131504', descripcion: 'Cargas explosivas', grupo: GruposCodigoSunat.explosivos),
  CodigoProductoSunat(codigo: '12131505', descripcion: 'Explosivos plásticos', grupo: GruposCodigoSunat.explosivos),
  CodigoProductoSunat(codigo: '12131506', descripcion: 'Explosivos aluminizados', grupo: GruposCodigoSunat.explosivos),
  CodigoProductoSunat(codigo: '12131508', descripcion: 'Explosivos de polvo de nitroglicerina', grupo: GruposCodigoSunat.explosivos),
  CodigoProductoSunat(codigo: '12131509', descripcion: 'Nitrato de amonio y fuel oil (ANFO)', grupo: GruposCodigoSunat.explosivos),
  CodigoProductoSunat(codigo: '12131507', descripcion: 'Explosivos de nitrato de amonio', grupo: GruposCodigoSunat.explosivos),

  // ── Anexo 25.1: insumos químicos ──
  CodigoProductoSunat(codigo: '12141726', descripcion: 'Mercurio (Hg)', grupo: GruposCodigoSunat.quimicos),
  CodigoProductoSunat(codigo: '12352117', descripcion: 'Cianuros o isocianuros', grupo: GruposCodigoSunat.quimicos),

  // ── Anexo 25.1: maquinaria y equipos ──
  CodigoProductoSunat(codigo: '20101504', descripcion: 'Cortadores de roca', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '20101600', descripcion: 'Cribas y equipos de alimentación', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '20111601', descripcion: 'Maquinaria de sondeo o de perforación', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '20111607', descripcion: 'Maquinaria para hacer túneles', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101501', descripcion: 'Cargadores frontales', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101502', descripcion: 'Niveladoras', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101505', descripcion: 'Aplanadoras', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101509', descripcion: 'Retroexcavadoras', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101511', descripcion: 'Compactadores', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101513', descripcion: 'Dragalíneas', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101514', descripcion: 'Dragas', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101516', descripcion: 'Excavadoras de fosos', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101518', descripcion: 'Raspadores elevadores', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101519', descripcion: 'Máquina giratoria con cazoleta de rastrillos abiertas', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101520', descripcion: 'Máquina giratoria con rastrillos elevadores', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101521', descripcion: 'Rastrilladora arrastrada', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101522', descripcion: 'Buldóceres de orugas', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101523', descripcion: 'Buldóceres de ruedas', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101524', descripcion: 'Excavadoras móviles', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101525', descripcion: 'Excavadoras de ruedas', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101526', descripcion: 'Excavadoras de orugas', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101528', descripcion: 'Cargadores de ruedas', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101529', descripcion: 'Cargadores sobre patines con dirección', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101530', descripcion: 'Raspadores abiertos', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101532', descripcion: 'Cargadores de orugas', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101534', descripcion: 'Excavadoras de campaña', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101602', descripcion: 'Equipo de apisonamiento', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101701', descripcion: 'Palas excavadoras', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101702', descripcion: 'Palas mecánicas para movimiento de tierra', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101713', descripcion: 'Brazo de retroexcavadora o secciones del brazo', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '22101714', descripcion: 'Kits de reparación o piezas de apisonadora', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '25181709', descripcion: 'Pala cargadora', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '26111600', descripcion: 'Generadores de potencia', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '26111603', descripcion: 'Generadores eólicos', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '39121013', descripcion: 'Convertidores rotativos eléctricos', grupo: GruposCodigoSunat.maquinaria),
  CodigoProductoSunat(codigo: '40151530', descripcion: 'Bombas de dragado', grupo: GruposCodigoSunat.maquinaria),

  // ── Anexo 25.1: servicios ──
  CodigoProductoSunat(codigo: '71101710', descripcion: 'Alquiler/leasing de maquinaria y equipo para minería', grupo: GruposCodigoSunat.servicios),
  CodigoProductoSunat(codigo: '72141701', descripcion: 'Alquiler/leasing de maquinaria para construcción', grupo: GruposCodigoSunat.servicios),
  CodigoProductoSunat(codigo: '72141702', descripcion: 'Alquiler/leasing de equipo para construcción', grupo: GruposCodigoSunat.servicios),
  CodigoProductoSunat(codigo: '73121509', descripcion: 'Servicios de purificación de metales', grupo: GruposCodigoSunat.servicios),
  CodigoProductoSunat(codigo: '73121613', descripcion: 'Servicios de fundición de metales', grupo: GruposCodigoSunat.servicios),
  CodigoProductoSunat(codigo: '73121500', descripcion: 'Procesos de fundición, refinación y formado de metales', grupo: GruposCodigoSunat.servicios),
];

/// Busca la descripción de un código (para mostrar la selección actual).
CodigoProductoSunat? buscarCodigoProductoSunat(String? codigo) {
  if (codigo == null || codigo.isEmpty) return null;
  for (final c in kCatalogoCodigosProductoSunat) {
    if (c.codigo == codigo) return c;
  }
  return null;
}
