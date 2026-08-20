import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/confirm_dialog.dart';
import 'package:syncronize/core/widgets/popup_item.dart';
import 'package:syncronize/core/widgets/custom_search_field.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/unidad_presentacion.dart';
import '../../../../core/utils/resource.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/producto_atributo.dart';
import '../../domain/entities/producto_stock.dart';
import '../../domain/entities/stock_por_sede_info.dart';
import '../../domain/entities/producto_variante.dart';
import '../../domain/usecases/get_stock_variante_en_sede_usecase.dart';
import '../bloc/producto_atributo/producto_atributo_cubit.dart';
import '../bloc/producto_atributo/producto_atributo_state.dart';
import '../bloc/producto_variante/producto_variante_cubit.dart';
import '../bloc/producto_variante/producto_variante_state.dart';
import '../bloc/precio_nivel/precio_nivel_cubit.dart';
import '../bloc/variante_atributo/variante_atributo_cubit.dart';
import '../bloc/configurar_precios/configurar_precios_cubit.dart';
import '../bloc/sede_selection/sede_selection_cubit.dart';
import 'analisis_variantes_page.dart';
import 'grupos_mayoreo_page.dart';
import 'edicion_masiva_stock_page.dart';
import '../widgets/filtro_variantes.dart';
import '../widgets/producto_variante_form_dialog.dart';
import '../widgets/generar_combinaciones_dialog.dart';
import '../bloc/ajustar_stock/ajustar_stock_cubit.dart';
import '../widgets/ajustar_stock_dialog.dart';
import '../widgets/configurar_precios_dialog.dart';

class ProductoVariantesPage extends StatelessWidget {
  final String productoId;
  final String productoNombre;
  final bool productoIsActive;
  final String? categoriaId;
  const ProductoVariantesPage({
    super.key,
    required this.productoId,
    required this.productoNombre,
    this.productoIsActive = true, // Por defecto true para compatibilidad
    this.categoriaId,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => locator<ProductoVarianteCubit>(),
        ),
        BlocProvider(
          create: (_) => locator<ProductoAtributoCubit>(),
        ),
      ],
      child: _ProductoVariantesView(
        productoId: productoId,
        productoNombre: productoNombre,
        productoIsActive: productoIsActive,
        categoriaId: categoriaId,
      ),
    );
  }
}

class _ProductoVariantesView extends StatefulWidget {
  final String productoId;
  final String productoNombre;
  final bool productoIsActive;
  final String? categoriaId;

  const _ProductoVariantesView({
    required this.productoId,
    required this.productoNombre,
    required this.productoIsActive,
    this.categoriaId,
  });

  @override
  State<_ProductoVariantesView> createState() => _ProductoVariantesViewState();
}

class _ProductoVariantesViewState extends State<_ProductoVariantesView> {
  String? _empresaId;
  String? _sedeId;
  List<ProductoAtributo> _atributosDisponibles = [];

  /// Buscador del listado. Un producto migrado puede tener decenas de
  /// variantes —EDREDONES tiene 76— y encontrar una para editarle el precio o
  /// el stock significaba scrollear a ojo.
  /// Buscador + filtro numérico, el MISMO que usan la edición masiva y el
  /// análisis. Vive en `FiltroVariantes` y no copiado acá porque la lógica
  /// tiene trampas (el SKU no puede entrar al match por fragmentos, el stock
  /// solo se suma entre variantes de la misma presentación) que ya costaron
  /// encontrar una vez.
  final _filtro = FiltroVariantes();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _filtro.dispose();
    super.dispose();
  }

  List<ProductoVariante> _filtrar(List<ProductoVariante> variantes) =>
      _filtro.filtrar(variantes, _valorDelCampo);

  /// La presentación de la variante: sin esto el filtro numérico de un granel
  /// pediría el precio POR GRAMO (0.008) cuando en pantalla dice S/8.00/kg.
  UnidadPresentacion _presentacionDe(ProductoVariante v) {
    if (v.tienePresentacionPropia) {
      return UnidadPresentacion(
        factor: v.factorPresentacion!,
        simbolo: v.unidadPresentacionSimbolo,
      );
    }
    return UnidadPresentacion(
      factor: 1,
      simbolo: v.unidadMedidaId != null ? v.unidadMedida?.displayCorto : null,
    );
  }

  double? _precioDe(ProductoVariante v) =>
      _sedeId == null ? null : v.stockSedeInfo(_sedeId!)?.precio;

  double? _costoDe(ProductoVariante v) =>
      _sedeId == null ? null : v.stockSedeInfo(_sedeId!)?.precioCosto;

  /// 🔴 `PrecioNivel` no tiene `sedeId`: el precio por mayor NO depende de la
  /// sede, a diferencia de precio y costo.
  double? _mayorDe(ProductoVariante v) => v.nivelPorMayor?.precio;

  /// El valor del campo pedido, en unidad de PRESENTACIÓN — la misma en la
  /// que se ve en la card y en la que se teclea el filtro.
  double? _valorDelCampo(ProductoVariante v, CampoPrecio campo) {
    final u = _presentacionDe(v);
    final crudo = switch (campo) {
      CampoPrecio.venta => _precioDe(v),
      CampoPrecio.costo => _costoDe(v),
      CampoPrecio.mayor => _mayorDe(v),
    };
    return crudo == null ? null : u.precio(crudo);
  }

  /// Cuántas se ven y cuánto stock suman. `stock` en null = "mixto": sumar
  /// 5000 g de un granel con 2 sacos da un número que no significa nada.
  ({int cantidad, String? stock}) _resumenVisible(List<ProductoVariante> vis) {
    if (vis.isEmpty) return (cantidad: 0, stock: null);

    final u0 = _presentacionDe(vis.first);
    var total = 0.0;
    var mismaUnidad = true;
    for (final v in vis) {
      final u = _presentacionDe(v);
      if (u.factor != u0.factor || u.simboloVisible != u0.simboloVisible) {
        mismaUnidad = false;
      }
      total += v.stockTotal;
    }
    if (!mismaUnidad) return (cantidad: vis.length, stock: null);

    final texto = u0.cantidadTexto(total);
    return (
      cantidad: vis.length,
      stock: u0.simboloVisible == null ? '$texto u' : texto,
    );
  }

  Future<void> _loadData() async {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _empresaId = empresaState.context.empresa.id;
      _sedeId = _getSedeIdActual(empresaState.context.sedes);
    }

    if (_empresaId != null) {
      context.read<ProductoVarianteCubit>().loadVariantes(
            productoId: widget.productoId,
            empresaId: _empresaId!,
          );
      context.read<ProductoAtributoCubit>().loadAtributos(_empresaId!);
    }
  }

  String _getSedeIdActual(List<dynamic> sedes) {
    if (sedes.isEmpty) {
      throw Exception('No hay sedes disponibles');
    }

    final selectedSedeId = context.read<SedeSelectionCubit>().selectedSedeId;

    if (selectedSedeId != null && sedes.any((s) => s.id == selectedSedeId)) {
      return selectedSedeId;
    }

    if (sedes.length == 1) {
      return sedes.first.id;
    }

    try {
      final sedePrincipal = sedes.firstWhere((s) => s.esPrincipal);
      return sedePrincipal.id;
    } catch (e) {
      return sedes.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue1 ,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Gestión de Variantes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white),),
            Text(
              widget.productoNombre,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: AppColors.white),
            ),
          ],
        ),
        actions: [
          // Los grupos de mayoreo son IMPLÍCITOS (dos variantes combinan
          // cuando tienen el mismo nivel cargado), así que sin esta pantalla
          // no hay forma de saber cuáles suman entre sí — ni de notar que a
          // una le cambiaron el precio y quedó fuera de su grupo.
          IconButton(
            tooltip: 'Grupos de mayoreo',
            icon: const Icon(Icons.workspaces_outline, size: 18),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GruposMayoreoPage(
                  productoId: widget.productoId,
                  productoNombre: widget.productoNombre,
                  sedeIdInicial: _sedeId,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Análisis de variantes',
            icon: const Icon(Icons.insights_outlined, size: 18),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AnalisisVariantesPage(
                  productoId: widget.productoId,
                  productoNombre: widget.productoNombre,
                  sedeIdInicial: _sedeId,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Edición masiva de stock y precios',
            icon: const Icon(Icons.table_chart_outlined, size: 18),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EdicionMasivaStockPage(
                    productoId: widget.productoId,
                    productoNombre: widget.productoNombre,
                    sedeIdInicial: _sedeId,
                  ),
                ),
              );
              // Refrescar al volver: la grilla pudo cambiar stock/precios
              _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18,),
            onPressed: _loadData,
          ),
        ],
      ),
      
      body: MultiBlocListener(
        listeners: [
          BlocListener<ProductoVarianteCubit, ProductoVarianteState>(
            listener: (context, state) {
              if (state is ProductoVarianteOperationSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is ProductoVarianteError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (state is ProductoVarianteStockUpdated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
          BlocListener<ProductoAtributoCubit, ProductoAtributoState>(
            listener: (context, state) {
              if (state is ProductoAtributoLoaded) {
                List<ProductoAtributo> atributosFiltrados;
                if (widget.categoriaId != null) {
                  // Filtrar atributos por categoría usando el método del cubit
                  final cubit = context.read<ProductoAtributoCubit>();
                  final lista = cubit.getAtributosPorCategoria(widget.categoriaId);
                  atributosFiltrados = lista.cast<ProductoAtributo>();
                } else {
                  atributosFiltrados = state.atributos;
                }
                setState(() {
                  _atributosDisponibles = atributosFiltrados;
                });
              }
            },
          ),
        ],
        child: BlocBuilder<ProductoVarianteCubit, ProductoVarianteState>(
          builder: (context, state) {
            if (state is ProductoVarianteLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProductoVarianteError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar variantes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            final variantes = _getVariantes(state);

            if (variantes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'No hay variantes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text('Crea la primera variante de este producto'),
                  ],
                ),
              );
            }

            final filtradas = _filtrar(variantes);
            // Se calcula UNA vez por build, no por fila: la unión de ejes es
            // lo que permite detectar a la variante a la que le falta uno.
            final ejes = _EjesProducto.de(variantes, _atributosDisponibles);

            return Column(
              children: [
                // El buscador aparece recién cuando hay suficientes como para
                // que scrollear moleste; con 3 o 4 se ven todas de una.
                if (variantes.length >= 6)
                  _buildBuscador(variantes.length, filtradas),
                Expanded(
                  child: filtradas.isEmpty
                      ? _buildSinResultados()
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          child: Container(
                            // El marco envuelve el VIEWPORT, no cada fila: la
                            // lista se lee como una sola tabla y las filas
                            // siguen virtualizadas (91 variantes).
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFDBE4EE), width: 1),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0F043261),
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: RefreshIndicator(
                              onRefresh: () async => _loadData(),
                              child: ListView.builder(
                                padding: const EdgeInsets.only(bottom: 76),
                                itemCount: filtradas.length,
                                itemBuilder: (context, index) {
                                  final variante = filtradas[index];
                                  return _VarianteFila(
                                    variante: variante,
                                    ejes: ejes,
                                    sedeId: _sedeId,
                                    ultima: index == filtradas.length - 1,
                                    onEdit: () => _showVarianteDialog(variante),
                                    onDelete: () => _confirmDelete(variante),
                                    onUpdateStock: () =>
                                        _showStockDialog(variante),
                                    onPrecioTap: () =>
                                        _handlePrecioTap(variante),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  /// Buscador + embudo. El embudo va A LA DERECHA del buscador y despliega la
  /// fila de filtro por precio (venta / costo / por mayor), la misma que la
  /// edición masiva y el análisis.
  ///
  /// El caso que más se usa no es buscar un monto sino el operador `vacío`:
  /// "mostrame las que TODAVÍA no tienen precio por mayor", que es lo que se
  /// revisa al terminar de cargar una lista.
  Widget _buildBuscador(int total, List<ProductoVariante> visibles) {
    final resumen = _resumenVisible(visibles);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ResumenVariantes(
                cantidad: resumen.cantidad,
                total: total,
                stock: resumen.stock,
                filtrando: _filtro.activo,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomSearchField(
                  controller: _filtro.busqueda,
                  hintText: 'Buscar por nombre, atributo o SKU…',
                  borderColor: AppColors.blue1,
                  // Sin debounce: se filtra la lista que ya está en memoria.
                  debounceDelay: Duration.zero,
                  onChanged: (_) => setState(() {}),
                  onClear: () => setState(() {}),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                style: IconButton.styleFrom(
                  minimumSize: Size.zero,
                  fixedSize: const Size(34, 34),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: AppColors.blue1
                      .withValues(alpha: _filtro.filtraPrecio ? 0.20 : 0.08),
                  foregroundColor: AppColors.blue1,
                ),
                tooltip: 'Filtrar por precio',
                icon: Icon(
                  _filtro.filtraPrecio
                      ? Icons.filter_alt
                      : Icons.filter_alt_outlined,
                  size: 17,
                ),
                onPressed: () => setState(_filtro.alternarPanel),
              ),
            ],
          ),
          if (_filtro.abierto)
            FilaFiltroPrecio(
              filtro: _filtro,
              onCambio: () => setState(() {}),
            ),
        ],
      ),
    );
  }

  /// Por qué no se ve nada. Con el embudo abierto la lista puede quedar vacía
  /// sin que se haya tecleado una letra, y un "coincide con ..." sin texto
  /// haría buscar un error donde no lo hay.
  String _mensajeSinResultados() {
    final texto = _filtro.busqueda.text.trim();
    final partes = <String>[
      if (texto.isNotEmpty) 'coincide con "$texto"',
      if (_filtro.filtraPrecio)
        'pasa el filtro de ${_filtro.campo.etiqueta.toLowerCase()}',
    ];
    if (partes.isEmpty) return 'No hay variantes para mostrar';
    return 'Ninguna variante ${partes.join(' y ')}';
  }

  Widget _buildSinResultados() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            AppSubtitle(
              _mensajeSinResultados(),
              fontSize: 11,
              color: Colors.grey.shade600,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      heroTag: 'producto_variantes_fab',
      onPressed: _showAgregarVarianteMenu,
      backgroundColor: AppColors.blue1,
      foregroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: const Icon(Icons.add, size: 20),
      label: const Text(
        'Agregar',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }

  /// Bottom sheet estilizado con las opciones para agregar variantes.
  void _showAgregarVarianteMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.blue1.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.tune,
                          color: AppColors.blue1, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const AppSubtitle('Agregar variantes'),
                  ],
                ),
              ),
              const Divider(height: 1),
              _menuOpcion(
                icon: Icons.add,
                titulo: 'Nueva variante',
                subtitulo: 'Crear una variante manualmente',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showVarianteDialog(null);
                },
              ),
              _menuOpcion(
                icon: Icons.auto_awesome,
                titulo: 'Generar combinaciones',
                subtitulo: 'Crea variantes desde los atributos del producto',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showGenerarCombinacionesDialog();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuOpcion({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.blue1.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.blue1, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showGenerarCombinacionesDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => GenerarCombinacionesDialog(
        productoId: widget.productoId,
        productoNombre: widget.productoNombre,
        atributosDisponibles: _atributosDisponibles,
        onSave: (data) {
          Navigator.of(dialogContext).pop();
          if (_empresaId != null) {
            context.read<ProductoVarianteCubit>().generarCombinaciones(
                  productoId: widget.productoId,
                  empresaId: _empresaId!,
                  data: data,
                );
          }
        },
      ),
    );
  }

  List<ProductoVariante> _getVariantes(ProductoVarianteState state) {
    if (state is ProductoVarianteLoaded) {
      return state.variantes;
    } else if (state is ProductoVarianteOperationSuccess) {
      return state.variantes;
    }
    return [];
  }

  void _showVarianteDialog(ProductoVariante? variante) {
    if (_empresaId == null) return;
    showDialog(
      context: context,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => locator<PrecioNivelCubit>()),
          BlocProvider(create: (_) => locator<VarianteAtributoCubit>()),
        ],
        child: ProductoVarianteFormDialog(
          productoId: widget.productoId,
          productoNombre: widget.productoNombre,
          productoIsActive: widget.productoIsActive,
          empresaId: _empresaId!,
          variante: variante,
          atributosDisponibles: _atributosDisponibles,
          // Las otras variantes del producto, para elegir en cuál se convierte
          // ésta al abrirla. Se excluye a sí misma: no puede abrirse en sí.
          variantesHermanas: _getVariantes(
            context.read<ProductoVarianteCubit>().state,
          ).where((v) => v.id != variante?.id).toList(),
          onSave: (data) async {
            if (_empresaId == null) return;

            // Cerrar el dialog primero para evitar race conditions
            // ("setState after dispose" si el cubit emite mientras el dialog está cerrando)
            Navigator.of(dialogContext).pop();

            if (variante == null) {
              context.read<ProductoVarianteCubit>().crearVariante(
                    productoId: widget.productoId,
                    empresaId: _empresaId!,
                    data: data,
                  );
            } else {
              context.read<ProductoVarianteCubit>().actualizarVariante(
                    varianteId: variante.id,
                    productoId: widget.productoId,
                    empresaId: _empresaId!,
                    data: data,
                  );
            }
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ProductoVariante variante) async {
    final confirma = await ConfirmDialog.show(
      context: context,
      type: ConfirmDialogType.destructive,
      title: 'Eliminar variante',
      message:
          '¿Estás seguro de eliminar la variante "${variante.nombre}"? '
          'Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
    );
    if (confirma != true) return;
    if (!mounted) return;
    if (_empresaId != null) {
      context.read<ProductoVarianteCubit>().eliminarVariante(
            varianteId: variante.id,
            productoId: widget.productoId,
            empresaId: _empresaId!,
          );
    }
  }

  /// Los bultos cerrados que se abren en [destino], con lo que cuesta cada uno
  /// en la sede actual. El costo del granel sale de ahí, pero vive en la fila
  /// del SACO: sin traerlo al diálogo hay que salir, anotar el costo del saco
  /// y dividirlo a mano por el rendimiento para poder fijar el precio.
  List<CostoDesdeBulto> _costosDesdeBultoDe(ProductoVariante destino) {
    final sedeId = _sedeId;
    if (sedeId == null) return const [];

    final origenes = <CostoDesdeBulto>[];
    final hermanas =
        _getVariantes(context.read<ProductoVarianteCubit>().state);
    for (final hermana in hermanas) {
      if (hermana.varianteAperturaId != destino.id) continue;
      final rendimiento = hermana.rendimientoApertura ?? 0;
      final costo = hermana.stockSedeInfo(sedeId)?.precioCosto ?? 0;
      // Sin costo cargado no hay cuenta que mostrar: ese bulto todavía no se
      // compró en esta sede.
      if (rendimiento <= 0 || costo <= 0) continue;
      origenes.add(CostoDesdeBulto(
        nombre: hermana.nombre,
        costoBulto: costo,
        rendimiento: rendimiento,
      ));
    }
    return origenes;
  }

  // Rearmar el nombre vive DENTRO del diálogo de editar, al lado del campo de
  // nombre (`producto_variante_form_dialog.dart`): el menú de la tarjeta
  // admite cuatro ítems como máximo —lo assertea `popup_item.dart`— y un
  // quinto tiraba la pantalla roja.

  Future<void> _handlePrecioTap(ProductoVariante variante) async {
    if (_empresaId == null || _sedeId == null) return;

    // Se arma ANTES del await: después el estado del cubit puede haber
    // cambiado y leerlo con el context viejo es el camino a un crash.
    final costosDesdeBulto = _costosDesdeBultoDe(variante);

    try {
      final getStockUseCase = locator<GetStockVarianteEnSedeUseCase>();
      final result = await getStockUseCase(
        varianteId: variante.id,
        sedeId: _sedeId!,
      );

      if (!mounted) return;

      if (result is Success<ProductoStock>) {
        final stock = result.data;

        showDialog(
          context: context,
          builder: (dialogContext) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => locator<ConfigurarPreciosCubit>(),
              ),
            ],
            child: ConfigurarPreciosDialog(
              stock: stock,
              empresaId: _empresaId!,
              // Sin esto el diálogo pide el precio por unidad de VENTA: para
              // un granel en gramos eso es un número sub-céntimo que no entra
              // en un campo de moneda de 2 decimales. Con la presentación,
              // cobra por kg y guarda por gramo.
              unidadPresentacionSimbolo: variante.unidadPresentacionSimbolo,
              factorPresentacion: variante.factorPresentacion,
              costosDesdeBulto: costosDesdeBulto,
            ),
          ),
        ).then((result) {
          if (result == true && mounted) {
            _loadData();
          }
        });
      } else if (result is Error<ProductoStock>) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar stock: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showStockDialog(ProductoVariante variante) async {
    if (_empresaId == null || _sedeId == null) return;

    try {
      final getStockUseCase = locator<GetStockVarianteEnSedeUseCase>();
      final result = await getStockUseCase(
        varianteId: variante.id,
        sedeId: _sedeId!,
      );

      if (!mounted) return;

      if (result is Success<ProductoStock>) {
        final stock = result.data;

        showDialog(
          context: context,
          builder: (dialogContext) => BlocProvider(
            create: (_) => locator<AjustarStockCubit>(),
            child: AjustarStockDialog(
              stock: stock,
              empresaId: _empresaId!,
            ),
          ),
        ).then((result) {
          if (result == true && mounted) {
            _loadData();
          }
        });
      } else if (result is Error<ProductoStock>) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar stock: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
/// Los ejes que tiene el producto: la unión de los atributos que usan sus
/// variantes, en el orden en que se compone el nombre.
///
/// Sirve para dos cosas a la vez: ordenar el breadcrumb de cada fila y —lo
/// importante— detectar a la variante que NO los tiene todos. Esa variante es
/// INALCANZABLE en el sheet de venta (ver
/// feedback_variante_sin_todos_los_atributos) y hasta ahora se veía igual que
/// las demás, así que el hueco recién aparecía al no poder venderla.
class _EjesProducto {
  /// Ids de atributo, ordenados como se compone el nombre.
  final List<String> ids;

  /// id → "Género", para poder decir cuál falta.
  final Map<String, String> nombres;

  const _EjesProducto(this.ids, this.nombres);

  static _EjesProducto de(
    List<ProductoVariante> variantes,
    List<ProductoAtributo> disponibles,
  ) {
    final nombres = <String, String>{};
    // Set con orden de inserción: si `orden` no está cargado, el fallback es
    // el orden en que los manda el backend, que ya es el bueno.
    final vistos = <String>{};
    for (final v in variantes) {
      for (final av in v.atributosValores) {
        vistos.add(av.atributoId);
        nombres[av.atributoId] = av.atributo.nombre;
      }
    }
    final orden = {for (final a in disponibles) a.id: a.orden};
    final ids = vistos.toList()
      ..sort((a, b) => (orden[a] ?? 9999).compareTo(orden[b] ?? 9999));
    return _EjesProducto(ids, nombres);
  }
}

/// Una fila de la tabla de variantes.
///
/// Es densa a propósito: un producto como EDREDONES tiene 91 variantes y con
/// la card anterior entraban dos por pantalla.
///
/// La jerarquía va al revés que antes: manda el valor del ÚLTIMO eje —lo único
/// que distingue a esta variante de sus hermanas— y los demás bajan a un
/// breadcrumb. Antes el nombre completo salía a 10px y el número de stock a
/// 16px bold: el dato menos importante era el más grande de la card.
class _VarianteFila extends StatelessWidget {
  final ProductoVariante variante;
  final _EjesProducto ejes;
  final String? sedeId;
  final bool ultima;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onUpdateStock;
  final VoidCallback onPrecioTap;

  const _VarianteFila({
    required this.variante,
    required this.ejes,
    required this.sedeId,
    required this.ultima,
    required this.onEdit,
    required this.onDelete,
    required this.onUpdateStock,
    required this.onPrecioTap,
  });

  static const _divisor = Color(0xFFEEF2F6);
  static const _rielAgotada = Color(0xFFCFD8E3);
  static const _textoTenue = Color(0xFF7D97B3);
  static const _rojoFalta = Color(0xFFD32F6B);
  static const _ambar = Color(0xFFC2701E);

  @override
  Widget build(BuildContext context) {
    final agotada = variante.stockTotal == 0;
    final faltantes = _faltantes();

    return Container(
      decoration: BoxDecoration(
        // Fondo rosado tenue: la variante inalcanzable tiene que saltar en una
        // lista de 91, no esperar a que alguien lea el badge.
        color: faltantes.isEmpty ? AppColors.white : const Color(0xFFFEF7FA),
        border: Border(
          left: BorderSide(color: _colorRiel(faltantes), width: 3),
          bottom: ultima
              ? BorderSide.none
              : const BorderSide(color: _divisor, width: 1),
        ),
      ),
      child: Opacity(
        opacity: agotada ? 0.55 : 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 2, 6),
          child: Row(
            children: [
              Expanded(child: _identidad(faltantes)),
              const SizedBox(width: 8),
              _precioYStock(agotada),
              _menu(),
            ],
          ),
        ),
      ),
    );
  }

  /// Título + breadcrumb + el badge que resume el estado comercial.
  Widget _identidad(List<String> faltantes) {
    final valores = {
      for (final av in variante.atributosValores) av.atributoId: av.valor,
    };
    final presentes = ejes.ids.where(valores.containsKey).toList();
    final titulo =
        presentes.isEmpty ? variante.nombre : valores[presentes.last]!;
    // Con un solo eje no hay nada que poner de contexto, y el SKU es lo que
    // más sirve para identificarla a mano.
    final breadcrumb = presentes.length <= 1
        ? variante.sku
        : presentes
            .sublist(0, presentes.length - 1)
            .map((id) => valores[id]!)
            .join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: AppSubtitle(
                titulo,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            _badge(faltantes),
          ],
        ),
        const SizedBox(height: 1),
        AppLabelText(
          breadcrumb,
          fontSize: 9,
          color: _textoTenue,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// UN solo badge, por prioridad: primero lo que impide vender, después lo
  /// que impide vender BIEN. Dos badges no entran en una fila de este alto, y
  /// el eje faltante siempre gana — sin él la variante ni se ofrece.
  Widget _badge(List<String> faltantes) {
    if (faltantes.isNotEmpty) {
      final texto = faltantes.length == 1
          ? 'falta ${ejes.nombres[faltantes.first] ?? 'un eje'}'
          : 'faltan ${faltantes.length} ejes';
      return _chip(texto, _rojoFalta, Icons.warning_amber_rounded);
    }
    final nivel = variante.nivelPorMayor;
    if (nivel == null) {
      return _chip('sin mayoreo', _ambar, Icons.info_outline);
    }
    final precio = nivel.precio;
    // 🔴 `cantidadMinima` se guarda en unidad de VENTA: en un granel en gramos
    // "desde 3 kg" son 3000, y el chip decia "x3000" al lado de un precio que
    // ya estaba en kilos. Las dos mitades tienen que hablar la misma unidad.
    final u = _presentacion;
    final desde = u.activa
        ? u.cantidadTexto(nivel.cantidadMinima)
        : '${nivel.cantidadMinima}';
    return _chip(
      precio == null ? nivel.nombre : '${_precioTexto(precio)} x$desde',
      AppColors.green,
      Icons.layers_outlined,
    );
  }

  Widget _chip(String texto, Color color, IconData icono) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 10, color: color),
        const SizedBox(width: 2),
        Text(
          texto,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _precioYStock(bool agotada) {
    final stockInfo = _stockInfo();
    final enLiq = stockInfo?.isLiquidacionActiva ?? false;
    final enOferta = stockInfo?.isOfertaActiva ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (enLiq || enOferta) ...[
              Icon(
                enLiq ? Icons.local_fire_department : Icons.local_offer,
                size: 10,
                color: enLiq ? Colors.deepOrange.shade700 : AppColors.greendark,
              ),
              const SizedBox(width: 3),
            ],
            AppSubtitle(
              _precioTexto(stockInfo?.precioEfectivo ?? 0.0),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: enLiq ? Colors.deepOrange.shade700 : AppColors.blue3,
            ),
          ],
        ),
        const SizedBox(height: 1),
        Text(
          agotada ? 'agotada' : _stockTexto(variante.stockTotal),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: agotada ? _textoTenue : _colorStock(),
          ),
        ),
      ],
    );
  }

  Widget _menu() {
    return CustomActionMenu(
      yNudge: 33,
      menuWidth: 100,
      borderRadius: 8,
      itemHeight: 30,
      // 44×44 de área táctil: el ícono queda chico pero el toque entra. Antes
      // el objetivo era de 24 px, por debajo del mínimo de Material.
      trigger: const SizedBox(
        width: 44,
        height: 44,
        child: Icon(Icons.more_vert, size: 16, color: Color(0xFF8AA3BD)),
      ),
      items: [
        ActionMenuItem(
          type: ActionMenuType.edit,
          label: 'Editar',
          icon: Icons.edit_outlined,
          color: AppColors.blue1,
        ),
        ActionMenuItem(
          type: ActionMenuType.precio,
          label: 'Precio',
          icon: Icons.attach_money,
          color: AppColors.blue1,
        ),
        ActionMenuItem(
          type: ActionMenuType.stock,
          label: 'Stock',
          icon: Icons.inventory,
          color: AppColors.green,
        ),
        // 🔴 El menú admite CUATRO ítems como máximo (`popup_item.dart` lo
        // asserta). Renombrar vive dentro del diálogo de editar.
        ActionMenuItem(
          type: ActionMenuType.delete,
          label: 'Eliminar',
          icon: Icons.delete_outlined,
          color: AppColors.red,
        ),
      ],
      onSelected: (ActionMenuType value) {
        switch (value) {
          case ActionMenuType.edit:
            onEdit();
            break;
          case ActionMenuType.precio:
            onPrecioTap();
            break;
          case ActionMenuType.stock:
            onUpdateStock();
            break;
          case ActionMenuType.delete:
            onDelete();
            break;
          default:
            break;
        }
      },
    );
  }

  /// Los ejes del producto que a ESTA variante le faltan.
  List<String> _faltantes() {
    if (ejes.ids.isEmpty) return const [];
    final tiene = {
      for (final av in variante.atributosValores) av.atributoId,
    };
    return ejes.ids.where((id) => !tiene.contains(id)).toList();
  }

  StockPorSedeInfo? _stockInfo() {
    final stocks = variante.stocksPorSede;
    if (stocks == null || stocks.isEmpty) return null;
    return stocks
            .where((s) => s.precioConfigurado && s.precio != null)
            .firstOrNull ??
        stocks.first;
  }

  /// El riel de la izquierda: el estado se lee sin leer.
  Color _colorRiel(List<String> faltantes) {
    if (faltantes.isNotEmpty) return AppColors.red;
    if (variante.stockTotal == 0) return _rielAgotada;
    if (_bajoMinimo()) return AppColors.orange;
    return AppColors.green;
  }

  Color _colorStock() => _bajoMinimo() ? _ambar : AppColors.greendark;

  bool _bajoMinimo() {
    if (sedeId == null) return false;
    final minimo = variante.stockSedeInfo(sedeId!)?.stockMinimo;
    return minimo != null && minimo > 0 && variante.stockTotal <= minimo;
  }

  /// La presentación de esta variante, si vende agrupado (gramos → kg).
  ///
  /// 🔴 Sin esto la fila miente dos veces en un granel: el precio se guarda
  /// POR UNIDAD DE VENTA —S/0.008 el gramo— y saldría "S/0.01", un precio que
  /// no existe y encima redondeado; y el stock saldría "22000" en vez de
  /// "22 kg".
  UnidadPresentacion get _presentacion => UnidadPresentacion(
        factor: variante.factorPresentacion ?? 1,
        simbolo: variante.unidadPresentacionSimbolo,
      );

  /// "S/ 8.00/kg" en granel, "S/ 75.00" en lo que se vende por unidad.
  String _precioTexto(double porUnidadDeVenta) {
    final p = _presentacion;
    if (!p.activa) return 'S/${porUnidadDeVenta.toStringAsFixed(2)}';
    return p.precioTexto(porUnidadDeVenta);
  }

  /// "22 kg" en granel, "22 u" en lo que se vende por unidad.
  String _stockTexto(int enUnidadDeVenta) {
    final p = _presentacion;
    if (!p.activa) return '$enUnidadDeVenta u';
    return p.cantidadTexto(enUnidadDeVenta);
  }
}
