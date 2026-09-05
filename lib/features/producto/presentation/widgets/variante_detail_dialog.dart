import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/services/identidad_comercial.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/utils/resource.dart';
import 'package:syncronize/core/utils/unidad_presentacion.dart';
import 'package:syncronize/core/widgets/info_chip.dart';
import 'package:syncronize/core/widgets/styled_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../bloc/sede_selection/sede_selection_cubit.dart';
import '../pages/compartir_producto_page.dart';
import '../../domain/entities/atributo_plantilla.dart';
import '../../domain/entities/producto_variante.dart';
import '../../domain/repositories/plantilla_repository.dart';
import 'ficha_atributos.dart';

/// Muestra un diálogo con los detalles completos de una variante de producto.
///
/// Va sobre `StyledDialog` como el resto de los diálogos del app: antes era un
/// `showGeneralDialog` con su propio Container, su sombra y su botón de cerrar
/// armados a mano, y se notaba al lado de los demás.
///
/// [plantillasIds] son las secciones que tiene guardadas el PRODUCTO. Una
/// variante no guarda las suyas, así que si no se pasan, la ficha se agrupa
/// recorriendo las plantillas y viendo cuál reclama cada atributo.
///
/// [plantillas] son el catálogo YA cargado. Pasarlo evita el parpadeo: sin
/// ellas el diálogo tiene que ir a la red y hasta que vuelve muestra la ficha
/// sin agrupar. Quien abre el diálogo casi siempre las tiene a mano.
void showVarianteDetailDialog({
  required BuildContext context,
  required ProductoVariante variante,
  List<String> plantillasIds = const [],
  List<AtributoPlantilla> plantillas = const [],
}) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => StyledDialog(
      accentColor: AppColors.blue1,
      icon: Icons.inventory_2_outlined,
      titulo: variante.nombre,
      // 🔴 El contenido NO trae scroll propio: StyledDialog ya scrollea, y dos
      // scrolls anidados rompen el alto.
      content: [
        _VarianteDetailContent(
          variante: variante,
          plantillasIds: plantillasIds,
          plantillas: plantillas,
        ),
      ],
      actions: [
        // Compartir ESTA variante: es la que tiene el precio y los atributos
        // que el cliente preguntó. En el producto padre el botón no existe.
        Expanded(
          child: CustomButton(
            text: 'Compartir',
            backgroundColor: AppColors.blue1,
            textColor: AppColors.white,
            onPressed: () => _compartirVariante(
              dialogContext,
              variante,
              plantillasIds,
              plantillas,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CustomButton(
            text: 'Cerrar',
            backgroundColor: AppColors.white,
            borderColor: Colors.grey.shade400,
            textColor: Colors.grey.shade700,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      ],
    ),
  );
}

/// Arma la ficha de la variante y abre la vista previa para compartirla.
///
/// 🔴 El precio sale del stock de la SEDE elegida; si no hay una elegida o esa
/// sede no tiene precio, cae al primer stock con precio configurado. Sin eso,
/// una variante con precio solo en otra sede se compartiria en S/ 0.
Future<void> _compartirVariante(
  BuildContext context,
  ProductoVariante variante,
  List<String> plantillasIds,
  List<AtributoPlantilla> plantillas,
) async {
  final empresaState = context.read<EmpresaContextCubit>().state;
  if (empresaState is! EmpresaContextLoaded) return;
  final empresa = empresaState.context.empresa;

  final stocks = variante.stocksPorSede ?? const [];
  final sedeElegida = context.read<SedeSelectionCubit>().selectedSedeId;
  final stock = stocks.where((s) => s.sedeId == sedeElegida && s.precio != null).firstOrNull ??
      stocks.where((s) => s.precio != null).firstOrNull ??
      (stocks.isEmpty ? null : stocks.first);

  final precio = stock == null ? 0.0 : (variante.precioEfectivoEnSede(stock.sedeId) ?? 0);
  final lista = stock == null ? null : variante.precioEnSede(stock.sedeId);

  // TODAS las fotos de la variante: cada una suele ser un color distinto.
  final fotos = variante.fotos();

  // 🔴 La ficha se presenta con el NOMBRE COMERCIAL y el color de la marca:
  // `empresa.nombre` es la razón social.
  final identidad = await resolverIdentidadComercial(
    empresa: empresa,
    sedeId: stock?.sedeId ?? sedeElegida,
  );

  if (!context.mounted) return;
  Navigator.of(context).pop();
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CompartirProductoPage(
        empresaId: empresa.id,
        titulo: variante.nombre,
        codigo: variante.codigoEmpresa,
        fotos: fotos,
        atributosValores: variante.atributosValores,
        plantillasIds: plantillasIds,
        precio: precio,
        precioAnterior: (lista != null && lista > precio) ? lista : null,
        empresaNombre: identidad.nombre,
        empresaTelefono: identidad.telefono,
        empresaLogo: identidad.logoUrl,
        empresaColor: identidad.color,
        textoPie: identidad.textoPie,
      ),
    ),
  );
}

class _VarianteDetailContent extends StatefulWidget {
  final ProductoVariante variante;
  final List<String> plantillasIds;
  final List<AtributoPlantilla> plantillas;

  const _VarianteDetailContent({
    required this.variante,
    required this.plantillasIds,
    required this.plantillas,
  });

  @override
  State<_VarianteDetailContent> createState() => _VarianteDetailContentState();
}

class _VarianteDetailContentState extends State<_VarianteDetailContent> {
  int _currentImageIndex = 0;
  late final PageController _pageController;

  /// Para agrupar la ficha. Best-effort: si no llegan, los atributos se
  /// muestran en una sola tabla, que es como se veían antes.
  List<AtributoPlantilla> _plantillas = const [];

  /// Ya sabemos si hay plantillas o no (llegaron, o el intento falló).
  ///
  /// 🔴 Sin esto la ficha se dibujaba PLANA y un instante después saltaba a
  /// agrupada: el `getPlantillas` va a la red en cada apertura —el repositorio
  /// no cachea— y el primer frame sale con la lista vacía. Mientras no esté
  /// resuelto no se dibuja nada: mostrar el agrupado equivocado y corregirlo a
  /// la vista es peor que esperar dos frames.
  bool _resuelto = false;

  List<ProductoVarianteArchivo> get _archivosImagenes {
    final archivos = widget.variante.archivos;
    if (archivos == null || archivos.isEmpty) return [];
    return archivos;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Si quien abrió el diálogo ya tenía el catálogo, se usa y listo: ni red
    // ni parpadeo.
    if (widget.plantillas.isNotEmpty) {
      _plantillas = widget.plantillas;
      _resuelto = true;
    } else if (widget.variante.atributosValores.isNotEmpty) {
      _cargarPlantillas();
    } else {
      _resuelto = true;
    }
  }

  Future<void> _cargarPlantillas() async {
    try {
      final res = await locator<PlantillaRepository>().getPlantillas();
      if (!mounted) return;
      if (res is Success<List<AtributoPlantilla>>) {
        setState(() => _plantillas = res.data);
      }
    } catch (_) {
      // Silencio a propósito: agrupar es un lujo, ver la variante no.
    } finally {
      // Pase lo que pase se destraba: si falló, la ficha se muestra plana,
      // que es como se veía antes de agrupar.
      if (mounted) setState(() => _resuelto = true);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final variante = widget.variante;
    final stocks = variante.stocksPorSede;
    final imagenes = _archivosImagenes;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imagenes.isNotEmpty) ...[
          _buildImageCarousel(imagenes),
          const SizedBox(height: 12),
        ],

        // El nombre ya está en el título del diálogo: acá solo va el aviso de
        // que la variante no se puede vender.
        if (!variante.isActive) ...[
          InfoChip(
            icon: Icons.block,
            text: 'INACTIVA',
            fontSize: 9,
            iconSize: 11,
            borderRadius: 4,
            textColor: AppColors.red,
            backgroundColor: Colors.red.shade50,
            borderColor: Colors.red.shade200,
            borderWidth: 0.6,
          ),
          const SizedBox(height: 10),
        ],

        // Códigos
        _buildDetailRow(Icons.tag, 'Código', variante.codigoEmpresa),
        _buildDetailRow(Icons.qr_code, 'SKU', variante.sku),
        if (variante.codigoBarras != null && variante.codigoBarras!.isNotEmpty)
          _buildDetailRow(
              Icons.qr_code_scanner, 'Código de barras', variante.codigoBarras!),

        // Unidad de medida
        if (variante.unidadMedida != null)
          _buildDetailRow(
              Icons.straighten, 'Unidad', variante.unidadDisplayCompleto),

        // Peso
        if (variante.peso != null)
          _buildDetailRow(Icons.scale, 'Peso', '${variante.peso} kg'),

        // Dimensiones
        if (variante.dimensiones != null && variante.dimensiones!.isNotEmpty)
          _buildDetailRow(Icons.aspect_ratio, 'Dimensiones',
              _formatDimensiones(variante.dimensiones!)),

        // Atributos, agrupados en las mismas secciones que el detalle del
        // producto y con la misma tabla.
        if (variante.atributosValores.isNotEmpty) ..._buildFichaAtributos(),

        // Stock por sede
        if (stocks != null && stocks.isNotEmpty) ...[
          _buildSeccion('STOCK POR SEDE'),
          ...stocks.map(
            (stock) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.store, size: 13, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: AppText(
                      stock.sedeNombre,
                      size: 11,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InfoChip(
                    text: _stockTexto(stock.cantidad),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    borderRadius: 4,
                    textColor: stock.cantidad > 0 ? Colors.green : AppColors.red,
                    backgroundColor:
                        (stock.cantidad > 0 ? Colors.green : AppColors.red)
                            .withValues(alpha: 0.1),
                  ),
                  if (stock.precioConfigurado && stock.precio != null) ...[
                    const SizedBox(width: 8),
                    AppText(
                      _precioTexto(stock.precioEfectivo ?? stock.precio!),
                      size: 11,
                      fontWeight: FontWeight.bold,
                      color: stock.isOfertaActiva
                          ? Colors.green
                          : AppColors.textPrimary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],

        // Fechas
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 8),
        _buildDetailRow(Icons.calendar_today, 'Creado',
            DateFormatter.formatDateTime(variante.creadoEn)),
        _buildDetailRow(Icons.update, 'Actualizado',
            DateFormatter.formatDateTime(variante.actualizadoEn)),
      ],
    );
  }

  /// La ficha de la variante, con las mismas secciones y la misma tabla que el
  /// detalle del producto.
  ///
  /// A diferencia del detalle, acá NO se colapsa a la primera sección: el
  /// diálogo se abre justamente para ver todo, y ya scrollea.
  List<Widget> _buildFichaAtributos() {
    // Todavía no sabemos cómo agrupar: no se dibuja nada. Dibujar la ficha
    // plana acá es justamente el parpadeo que se quiere evitar.
    if (!_resuelto) return const [];

    final (secciones, sueltos) = agruparAtributosPorSeccion(
      atributosValores: widget.variante.atributosValores,
      plantillasIds: widget.plantillasIds,
      plantillas: _plantillas,
    );

    // Sin secciones —plantillas todavía cargando, o atributos que ninguna
    // reclama— va una sola tabla, sin encabezados.
    if (secciones.isEmpty) {
      return [
        _buildSeccion('ATRIBUTOS'),
        TablaAtributos(widget.variante.atributosValores),
      ];
    }

    // 🔴 El título va con `TituloSeccionAtributos`, el MISMO del detalle del
    // producto: acá había un encabezado propio que no pasaba el nombre a
    // mayúsculas, y al lado de plantillas escritas en mayúsculas el rótulo
    // salía desalineado del resto.
    return [
      for (final (nombre, valores) in secciones) ...[
        const SizedBox(height: 4),
        TituloSeccionAtributos(nombre),
        const SizedBox(height: 5),
        TablaAtributos(valores),
      ],
      // Los sueltos van uno por uno, titulados con su propio nombre.
      ...seccionesDeAtributosSueltos(sueltos),
    ];
  }

  /// La presentación de la variante, si vende agrupado (gramos → kg).
  ///
  /// 🔴 En un granel el precio se guarda POR UNIDAD DE VENTA —S/0.008 el
  /// gramo— y sin esto salía "S/0.01", un precio que no existe; y el stock
  /// salía "9000" en vez de "9 kg".
  UnidadPresentacion get _presentacion => UnidadPresentacion(
        factor: widget.variante.factorPresentacion ?? 1,
        simbolo: widget.variante.unidadPresentacionSimbolo,
      );

  String _precioTexto(double porUnidadDeVenta) {
    final p = _presentacion;
    if (!p.activa) return 'S/ ${porUnidadDeVenta.toStringAsFixed(2)}';
    return p.precioTexto(porUnidadDeVenta);
  }

  String _stockTexto(int enUnidadDeVenta) {
    final p = _presentacion;
    if (!p.activa) return '$enUnidadDeVenta';
    return p.cantidadTexto(enUnidadDeVenta);
  }

  Widget _buildSeccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: AppSubtitle(
        titulo,
        font: AppFont.amazonEmberMedium,
        fontSize: 10,
        color: AppColors.blue1,
      ),
    );
  }

  Widget _buildImageCarousel(List<ProductoVarianteArchivo> imagenes) {
    // Adentro del StyledDialog la imagen ya no toca los bordes del diálogo:
    // se redondea por los cuatro lados, no solo arriba.
    if (imagenes.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imagenes.first.url,
          height: 170,
          width: double.infinity,
          fit: BoxFit.contain,
          placeholder: (_, __) => Container(
            height: 100,
            color: Colors.grey[200],
          ),
          errorWidget: (context, url, error) => Container(
            height: 100,
            color: Colors.grey[200],
            child: Icon(Icons.inventory_2_outlined,
                size: 48, color: Colors.grey[400]),
          ),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 170,
            child: PageView.builder(
              controller: _pageController,
              itemCount: imagenes.length,
              onPageChanged: (index) {
                setState(() => _currentImageIndex = index);
              },
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: imagenes[index].url,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.inventory_2_outlined,
                        size: 48, color: Colors.grey[400]),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(imagenes.length, (index) {
            return Container(
              width: _currentImageIndex == index ? 16 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: _currentImageIndex == index
                    ? AppColors.blue1
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

Widget _buildDetailRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        AppText(
          '$label: ',
          size: 11,
          color: Colors.grey[600],
        ),
        Expanded(
          child: AppText(
            value,
            size: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

String _formatDimensiones(Map<String, dynamic> dimensiones) {
  final parts = <String>[];
  if (dimensiones['largo'] != null) parts.add('L: ${dimensiones['largo']}');
  if (dimensiones['ancho'] != null) parts.add('A: ${dimensiones['ancho']}');
  if (dimensiones['alto'] != null) parts.add('Al: ${dimensiones['alto']}');
  return parts.isNotEmpty ? parts.join(' × ') : '-';
}
