import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../domain/entities/empresa_permissions.dart';
import '../bloc/empresa_context/empresa_context_cubit.dart';
import '../bloc/empresa_context/empresa_context_state.dart';

/// Item de acceso rápido. Cada uno declara qué permiso necesita; si el
/// usuario actual no lo tiene, la card se oculta. La lista visible se
/// reorganiza en filas de 5 — sin huecos ni cards inútiles.
///
/// El `id` es estable y se usa para guardar las preferencias del
/// usuario en `UsuarioSedeRol.accesosRapidosOcultos`. NO cambiarlos
/// — si lo hacés, los usuarios existentes pueden perder su configuración.
class _AccesoItem {
  final String id;
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  final bool Function(EmpresaPermissions p) puedeVer;
  final int badge;

  const _AccesoItem({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
    required this.puedeVer,
    this.badge = 0,
  });
}

/// Catálogo público de IDs disponibles. Lo usa `usuario_form_page` para
/// renderizar los checkboxes de "ocultos" sin duplicar el catálogo.
class AccesosRapidosCatalogo {
  static const ventaRapida = 'venta-rapida';
  static const ventaAvanzada = 'venta-avanzada';
  static const colaPos = 'cola-pos';
  static const ventas = 'ventas';
  static const cotizaciones = 'cotizaciones';
  static const caja = 'caja';
  static const monitorCajas = 'monitor-cajas';
  static const historialCajas = 'historial-cajas';
  static const tesoreria = 'tesoreria';
  static const cajaChica = 'caja-chica';
  static const cuentasPorCobrar = 'cuentas-por-cobrar';
  static const finanzas = 'finanzas';
  static const facturacion = 'facturacion';
  static const productos = 'productos';
  static const servicios = 'servicios';
  static const monitorProductos = 'monitor-productos';
  static const ordenesServicio = 'ordenes-servicio';
  static const flujoDocs = 'flujo-docs';
  static const guiasRemision = 'guias-remision';
  static const sorteos = 'sorteos';
  static const config = 'config';

  /// (id, label) — útil para listados administrativos (form de usuario).
  static const items = <(String, String)>[
    (ventaRapida, 'Venta Rápida'),
    (ventaAvanzada, 'Venta Avanzada'),
    (colaPos, 'Cola POS'),
    (ventas, 'Ventas'),
    (cotizaciones, 'Cotizaciones'),
    (caja, 'Caja'),
    (monitorCajas, 'Monitor Cajas'),
    (historialCajas, 'Historial de Cajas'),
    (tesoreria, 'Tesorería'),
    (cajaChica, 'Caja Chica'),
    (cuentasPorCobrar, 'Cuentas por Cobrar'),
    (finanzas, 'Finanzas'),
    (facturacion, 'Facturación'),
    (productos, 'Productos'),
    (servicios, 'Servicios'),
    (monitorProductos, 'Monitor Productos'),
    (ordenesServicio, 'Órdenes de Servicio'),
    (flujoDocs, 'Flujo de Documentos'),
    (guiasRemision, 'Guías de Remisión'),
    (sorteos, 'Sorteos'),
    (config, 'Configuración'),
  ];
}

class AccesosRapidosSection extends StatefulWidget {
  final int colaPosCount;

  const AccesosRapidosSection({
    super.key,
    this.colaPosCount = 0,
  });

  @override
  State<AccesosRapidosSection> createState() => _AccesosRapidosSectionState();
}

class _AccesosRapidosSectionState extends State<AccesosRapidosSection> {
  /// El orden que eligió el usuario arrastrando, como lista de ids.
  ///
  /// Null = todavía no se leyó de disco, o nunca ordenó nada: se usa el orden
  /// del catálogo tal cual.
  List<String>? _orden;

  /// Clave de preferencias, por EMPRESA y por USUARIO: en un mostrador el
  /// mismo teléfono lo usan varios cajeros, y el orden de uno no tiene por qué
  /// pisarle el del otro.
  String? _clavePrefs;

  bool _yaCargue = false;

  /// Índice que se está arrastrando, para atenuar su casilla de origen.
  int? _arrastrando;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Acá y no en initState: la clave sale de los blocs, y el contexto para
    // leerlos recién está listo en este punto.
    if (_yaCargue) return;
    _yaCargue = true;
    _cargarOrden();
  }

  Future<void> _cargarOrden() async {
    final empresa = context.read<EmpresaContextCubit>().state;
    final auth = context.read<AuthBloc>().state;
    if (empresa is! EmpresaContextLoaded || auth is! Authenticated) return;
    final clave =
        'accesos_rapidos_orden:${empresa.context.empresa.id}:${auth.user.id}';

    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getStringList(clave);
    if (!mounted) return;
    setState(() {
      // La clave se guarda igual aunque no haya nada leído: es la que se va a
      // usar para grabar el primer reordenamiento.
      _clavePrefs = clave;
      _orden = guardado;
    });
  }

  /// Aplica el orden guardado sobre los accesos que el usuario puede ver.
  ///
  /// 🔴 El orden guardado NO es una lista blanca. Un id guardado que ya no
  /// existe se ignora, y un acceso visible que no figura en lo guardado va al
  /// FINAL: así, cuando agreguemos una pantalla nueva al catálogo, aparece
  /// igual en vez de quedar invisible para todo el que ya había ordenado su
  /// dashboard.
  List<_AccesoItem> _ordenar(List<_AccesoItem> visibles) {
    final orden = _orden;
    if (orden == null || orden.isEmpty) return visibles;

    final porId = {for (final it in visibles) it.id: it};
    final ordenados = <_AccesoItem>[];
    for (final id in orden) {
      final item = porId.remove(id);
      if (item != null) ordenados.add(item);
    }
    // `where` sobre la lista original conserva el orden del catálogo entre los
    // que sobraron.
    ordenados.addAll(visibles.where((it) => porId.containsKey(it.id)));
    return ordenados;
  }

  Future<void> _mover(List<_AccesoItem> actuales, int desde, int hasta) async {
    if (desde == hasta || desde < 0 || desde >= actuales.length) return;

    final ids = actuales.map((it) => it.id).toList();
    final id = ids.removeAt(desde);
    ids.insert(hasta.clamp(0, ids.length), id);

    setState(() => _orden = ids);

    final clave = _clavePrefs;
    if (clave == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(clave, ids);
  }

  /// Items disponibles. Se filtran en build según permisos del rol del
  /// usuario en la empresa actual. Cuando agregues nuevas pantallas,
  /// declarar acá con el `puedeVer` apropiado.
  List<_AccesoItem> _itemsCatalogo(
    int colaPosCount,
    EmpresaPermissions permisos,
  ) {
    // Operativo = ve ventas pero no es admin. El backend filtra el
    // listado a sus propias ventas, así que ajustamos el label para
    // que el cajero/vendedor entienda que son sus ventas.
    final esAdmin = permisos.canManageUsers || permisos.canManageSettings;
    final esOperativoVentas = permisos.canViewVentas && !esAdmin;
    return [
        // Operaciones de venta
        _AccesoItem(
          id: AccesosRapidosCatalogo.ventaRapida,
          icon: Icons.flash_on,
          label: 'V. Rápida',
          color: AppColors.green,
          route: '/empresa/venta-rapida',
          puedeVer: (p) => p.canManageVentas,
        ),
        _AccesoItem(
          id: AccesosRapidosCatalogo.colaPos,
          icon: Icons.receipt_long,
          label: 'Cola POS',
          color: AppColors.orange,
          route: '/empresa/cola-pos',
          puedeVer: (p) => p.canViewVentas,
          badge: colaPosCount,
        ),
        _AccesoItem(
          id: AccesosRapidosCatalogo.ventas,
          icon: Icons.shopping_bag,
          label: esOperativoVentas ? 'Mis Ventas' : 'Ventas',
          color: Colors.indigo,
          route: '/empresa/ventas',
          puedeVer: (p) => p.canViewVentas,
        ),
        _AccesoItem(
          id: AccesosRapidosCatalogo.cotizaciones,
          icon: Icons.request_quote,
          label: 'Cotizaciones',
          color: Colors.purple,
          route: '/empresa/cotizaciones',
          puedeVer: (p) => p.canViewCotizaciones,
        ),
        _AccesoItem(
          id: AccesosRapidosCatalogo.sorteos,
          icon: Icons.card_giftcard,
          label: 'Sorteos',
          color: Colors.deepPurple,
          route: '/empresa/sorteos',
          puedeVer: (p) => p.canViewVentas,
        ),

        // Caja & finanzas
        _AccesoItem(
          id: AccesosRapidosCatalogo.caja,
          icon: Icons.account_balance_wallet,
          label: 'Caja',
          color: AppColors.blue1,
          route: '/empresa/caja',
          puedeVer: (p) => p.canViewCaja,
        ),
        _AccesoItem(
          id: AccesosRapidosCatalogo.monitorCajas,
          icon: Icons.monitor_heart,
          label: 'Monitor Cajas',
          color: Colors.deepOrange,
          route: '/empresa/caja/monitor',
          puedeVer: (p) => p.canViewCaja,
        ),
        _AccesoItem(
          id: AccesosRapidosCatalogo.historialCajas,
          icon: Icons.history,
          label: 'Historial Cajas',
          color: Colors.brown,
          route: '/empresa/caja/historial',
          puedeVer: (p) => p.canViewCaja,
        ),
        _AccesoItem(
          id: AccesosRapidosCatalogo.finanzas,
          icon: Icons.analytics,
          label: 'Finanzas',
          color: Colors.deepPurple,
          route: '/empresa/resumen-financiero',
          puedeVer: (p) => p.canViewReports || p.canViewStatistics,
        ),
        _AccesoItem(
          id: AccesosRapidosCatalogo.facturacion,
          icon: Icons.description,
          label: 'Facturación',
          color: Colors.teal,
          route: '/empresa/monitor-facturacion',
          puedeVer: (p) => p.canManageInvoices,
        ),

        // Catálogo
        _AccesoItem(
          id: AccesosRapidosCatalogo.productos,
          icon: Icons.inventory,
          label: 'Productos',
          color: Colors.blue.shade800,
          route: '/empresa/productos',
          puedeVer: (p) => p.canViewProducts,
        ),
        _AccesoItem(
          id: AccesosRapidosCatalogo.servicios,
          icon: Icons.room_service,
          label: 'Servicios',
          color: Colors.blue,
          route: '/empresa/servicios',
          puedeVer: (p) => p.canViewServices,
        ),
        _AccesoItem(
          id: AccesosRapidosCatalogo.monitorProductos,
          icon: Icons.inventory_2,
          label: 'Monitor Prod.',
          color: Colors.deepOrange,
          route: '/empresa/monitor-productos',
          puedeVer: (p) => p.canViewProducts,
        ),

        // Operativo / herramientas
        _AccesoItem(
          id: AccesosRapidosCatalogo.ordenesServicio,
          icon: Icons.build_circle,
          label: 'Órdenes Serv.',
          color: Colors.orange.shade700,
          route: '/empresa/ordenes',
          puedeVer: (p) => p.canManageOrders,
        ),
        _AccesoItem(
          id: AccesosRapidosCatalogo.flujoDocs,
          icon: Icons.account_tree,
          label: 'Flujo Docs',
          color: Colors.deepPurple,
          route: '/empresa/flujo-documentos',
          puedeVer: (p) => p.canViewVentas,
        ),
      ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
      buildWhen: (a, b) => a.runtimeType != b.runtimeType,
      builder: (context, state) {
        if (state is! EmpresaContextLoaded) {
          return const SizedBox.shrink();
        }
        final permisos = state.context.permissions;
        final ocultos = permisos.accesosRapidosOcultos.toSet();
        final visibles = _itemsCatalogo(widget.colaPosCount, permisos)
            // Filtro 1: permiso del rol (vendedor no ve productos, etc.).
            .where((it) => it.puedeVer(permisos))
            // Filtro 2: override del admin por usuario (oculto explícito).
            .where((it) => !ocultos.contains(it.id))
            .toList();

        if (visibles.isEmpty) return const SizedBox.shrink();

        // Filtro 3: el orden que el propio usuario eligió arrastrando.
        final items = _ordenar(visibles);

        // Reorganización en filas de máx 5 — densidad consistente con el
        // diseño previo. Los huecos de la última fila se compensan con
        // `Expanded` para mantener el ancho de las cards.
        const porFila = 5;
        final filas = <int>[];
        for (var i = 0; i < items.length; i += porFila) {
          filas.add(i);
        }

        return GradientContainer(
          borderColor: AppColors.blueborder,
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              for (var f = 0; f < filas.length; f++) ...[
                if (f > 0) const SizedBox(height: 6),
                _Fila(
                  items: items,
                  desde: filas[f],
                  itemsPorFila: porFila,
                  arrastrando: _arrastrando,
                  onArrastreInicia: (i) => setState(() => _arrastrando = i),
                  onArrastreTermina: () => setState(() => _arrastrando = null),
                  onSoltar: (desde, hasta) => _mover(items, desde, hasta),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Fila de hasta `itemsPorFila` cards. Si la fila tiene menos elementos,
/// los `SizedBox` invisibles ocupan el ancho restante para que las cards
/// no se estiren y mantengan el tamaño visual consistente.
class _Fila extends StatelessWidget {
  /// La lista COMPLETA de accesos, no solo los de esta fila: el índice que
  /// viaja en el arrastre es global, así que soltar una card en otra fila
  /// tiene que poder resolverse igual.
  final List<_AccesoItem> items;

  /// Índice global del primer item de esta fila.
  final int desde;
  final int itemsPorFila;
  final int? arrastrando;
  final void Function(int indice) onArrastreInicia;
  final VoidCallback onArrastreTermina;
  final void Function(int desde, int hasta) onSoltar;

  const _Fila({
    required this.items,
    required this.desde,
    required this.itemsPorFila,
    required this.arrastrando,
    required this.onArrastreInicia,
    required this.onArrastreTermina,
    required this.onSoltar,
  });

  @override
  Widget build(BuildContext context) {
    final hasta = (desde + itemsPorFila).clamp(0, items.length);
    final enLaFila = hasta - desde;

    // LayoutBuilder para saber cuánto mide una card: el "fantasma" que sigue
    // al dedo se dibuja FUERA del layout, así que no hereda el ancho del
    // `Expanded` y hay que dárselo a mano.
    return LayoutBuilder(
      builder: (context, restricciones) {
        // Si alguna vez esta sección cae en un contexto sin ancho acotado (un
        // scroll horizontal, una Row sin Expanded), el ancho sale infinito y
        // el SizedBox del fantasma revienta al arrastrar. Un ancho fijo de
        // respaldo mantiene la card usable en vez de tumbar la pantalla.
        final anchoDisponible = restricciones.maxWidth.isFinite
            ? restricciones.maxWidth
            : itemsPorFila * 78.0;
        final anchoCard = anchoDisponible / itemsPorFila - 6;
        return Row(
          children: [
            for (var i = desde; i < hasta; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _CasillaArrastrable(
                    item: items[i],
                    indice: i,
                    anchoCard: anchoCard,
                    seEstaArrastrando: arrastrando == i,
                    onArrastreInicia: onArrastreInicia,
                    onArrastreTermina: onArrastreTermina,
                    onSoltar: onSoltar,
                  ),
                ),
              ),
            // Espaciadores invisibles para que la última fila incompleta no
            // estire las cards visibles.
            for (var i = enLaFila; i < itemsPorFila; i++)
              const Expanded(child: SizedBox.shrink()),
          ],
        );
      },
    );
  }
}

/// Una card de acceso rápido que se puede tomar con un mantenido y soltar
/// sobre otra para intercambiar el orden.
///
/// Es `LongPressDraggable` y no un `ReorderableListView` porque esto es una
/// GRILLA de 5 por fila: el reorderable de Flutter solo sabe de listas de una
/// sola columna. Y el mantenido, además de ser lo que pidió el usuario, es lo
/// que deja el tap simple libre para abrir la pantalla — que es lo que la card
/// hace el 99 % de las veces.
class _CasillaArrastrable extends StatelessWidget {
  final _AccesoItem item;
  final int indice;
  final double anchoCard;
  final bool seEstaArrastrando;
  final void Function(int indice) onArrastreInicia;
  final VoidCallback onArrastreTermina;
  final void Function(int desde, int hasta) onSoltar;

  const _CasillaArrastrable({
    required this.item,
    required this.indice,
    required this.anchoCard,
    required this.seEstaArrastrando,
    required this.onArrastreInicia,
    required this.onArrastreTermina,
    required this.onSoltar,
  });

  @override
  Widget build(BuildContext context) {
    final card = _AccesoRapidoCard(
      icon: item.icon,
      label: item.label,
      color: item.color,
      badgeCount: item.badge,
      onTap: () => context.push(item.route),
    );

    return DragTarget<int>(
      onWillAcceptWithDetails: (detalles) => detalles.data != indice,
      onAcceptWithDetails: (detalles) => onSoltar(detalles.data, indice),
      builder: (context, candidatos, __) {
        final recibiendo = candidatos.isNotEmpty;
        return LongPressDraggable<int>(
          data: indice,
          onDragStarted: () {
            // Vibración corta: es la única señal de que la card "se despegó",
            // porque el dedo la tapa justo cuando empieza a moverse.
            HapticFeedback.selectionClick();
            onArrastreInicia(indice);
          },
          onDragEnd: (_) => onArrastreTermina(),
          onDraggableCanceled: (_, __) => onArrastreTermina(),
          // El fantasma que sigue al dedo. Necesita ancho propio y un
          // `Material`: fuera del árbol normal no hereda ni las restricciones
          // ni el tema, y sin Material el texto sale con el subrayado amarillo
          // del renderizado sin estilo.
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.9,
              child: SizedBox(width: anchoCard, child: card),
            ),
          ),
          // El hueco que deja mientras viaja.
          childWhenDragging: Opacity(opacity: 0.25, child: card),
          child: AnimatedScale(
            // La casilla que va a recibir se agranda apenas: dice dónde va a
            // caer sin mover a las demás de lugar.
            scale: recibiendo ? 1.06 : 1,
            duration: const Duration(milliseconds: 120),
            child: AnimatedOpacity(
              opacity: seEstaArrastrando ? 0.25 : 1,
              duration: const Duration(milliseconds: 120),
              child: card,
            ),
          ),
        );
      },
    );
  }
}

class _AccesoRapidoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int badgeCount;
  final VoidCallback onTap;

  const _AccesoRapidoCard({
    required this.icon,
    required this.label,
    required this.color,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              color.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.4),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 8.5,
                color: color.withValues(alpha: 0.9),
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
