import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/utils/granular_permissions_catalog.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/widgets/currency/currency_textfield.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/network/dio_client.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/caja.dart';
import '../bloc/caja_activa_cubit.dart';
import '../bloc/caja_activa_state.dart';
import '../bloc/caja_movimientos_cubit.dart';
import '../bloc/cerrar_caja_cubit.dart';
import '../bloc/caja_movimientos_state.dart';
import '../bloc/arqueos_caja_cubit.dart';
import '../utils/movimiento_grouping.dart';
import '../widgets/movimiento_group_card.dart';
import '../widgets/resumen_caja_card.dart';
import 'arqueos_lista_page.dart';
import 'cerrar_caja_page.dart';
import 'historial_caja_page.dart';
import 'movimientos_caja_page.dart';
import 'nuevo_movimiento_page.dart';
import 'realizar_arqueo_page.dart';

class CajaPage extends StatelessWidget {
  /// Si se provee, la página entra en **modo vista admin**: carga esa
  /// caja por id (no la caja activa del usuario actual), oculta el form
  /// de abrir caja y propaga `esCajaPropia=false` al cerrar. Pensado
  /// para que un admin abra el dashboard de otro cajero desde el monitor
  /// y opere igual que el cajero (arqueo, cerrar, ver movimientos).
  ///
  /// Si es `null` (default), modo cajero: carga "mi caja activa".
  final String? cajaId;

  const CajaPage({super.key, this.cajaId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final cubit = locator<CajaActivaCubit>();
            // Disparo inicial: por id (admin) o por usuario actual (cajero).
            if (cajaId != null) {
              cubit.loadCajaPorId(cajaId!);
            } else {
              cubit.loadCajaActiva();
            }
            return cubit;
          },
        ),
        BlocProvider(create: (_) => locator<CajaMovimientosCubit>()),
      ],
      child: _CajaView(esVistaAdmin: cajaId != null),
    );
  }
}

class _CajaView extends StatefulWidget {
  final bool esVistaAdmin;

  const _CajaView({this.esVistaAdmin = false});

  @override
  State<_CajaView> createState() => _CajaViewState();
}

class _CajaViewState extends State<_CajaView> {
  final _montoAperturaController = TextEditingController();
  final _observacionesController = TextEditingController();
  String? _selectedSedeId;
  String? _selectedEmisorSedeId;
  List<Map<String, dynamic>> _emisores = [];

  @override
  void initState() {
    super.initState();
    _cargarEmisores();
  }

  Future<void> _cargarEmisores() async {
    try {
      final dio = locator<DioClient>();
      final response = await dio.get('/sunat/emisores');
      if (mounted && response.data is List) {
        setState(() {
          _emisores = (response.data as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _montoAperturaController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        // Altura fija un poco mayor para acomodar el subtítulo (código
        // de caja + estado) cuando hay caja abierta. Cuando no hay
        // caja, el subtítulo está vacío y el espacio sobra — preferimos
        // eso a que cambie el alto del AppBar al rebuild.
        preferredSize: const Size.fromHeight(52),
        child: BlocBuilder<CajaActivaCubit, CajaActivaState>(
          builder: (context, state) {
            final caja = state is CajaActivaAbierta ? state.caja : null;
            return SmartAppBar(
              title: caja?.codigo ?? 'Caja',
              subtitle: caja?.estado.label,
              customHeight: 52,
              backgroundColor: AppColors.blue1,
              foregroundColor: AppColors.white,
              actions: [
                // Auditoría (apertura → cierre) de la caja actual.
                BlocBuilder<CajaActivaCubit, CajaActivaState>(
                  builder: (context, state) {
                    if (state is! CajaActivaAbierta)
                      return const SizedBox.shrink();
                    return IconButton(
                      tooltip: 'Auditoría de esta caja',
                      icon: const Icon(Icons.assignment_outlined),
                      onPressed: () => context.push(
                        '/empresa/caja/auditoria/${state.caja.id}',
                      ),
                    );
                  },
                ),
                // Acceso a arqueos solo cuando hay caja abierta (mira el estado
                // del cubit del padre, no recrea uno).
                BlocBuilder<CajaActivaCubit, CajaActivaState>(
                  builder: (context, state) {
                    if (state is! CajaActivaAbierta)
                      return const SizedBox.shrink();
                    return IconButton(
                      tooltip: 'Arqueos de esta caja',
                      icon: const Icon(Icons.fact_check_outlined),
                      onPressed: () =>
                          _navigateToArqueosLista(context, state.caja),
                    );
                  },
                ),
                // Historial de cajas: solo lo ven roles admin (SUPER/EMPRESA/SEDE).
                // El cajero/vendedor opera sobre su caja actual; el repaso
                // histórico es responsabilidad de quien supervisa.
                BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
                  builder: (context, empresaState) {
                    if (empresaState is! EmpresaContextLoaded) {
                      return const SizedBox.shrink();
                    }
                    final esAdmin =
                        empresaState.context.primaryRole?.isAdminRole ?? false;
                    if (!esAdmin) return const SizedBox.shrink();
                    return IconButton(
                      tooltip: 'Historial de cajas',
                      icon: const Icon(Icons.history_rounded),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => locator<CajaActivaCubit>(),
                              child: const HistorialCajaPage(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
      // Botón "Cerrar Caja" fijo abajo. Visibilidad:
      //  - Hay caja abierta (CajaActivaAbierta)
      //  - Y el usuario es admin (siempre puede) O tiene el permiso
      //    granular explícito `caja.cerrar`. Esto excluye al rol CAJERO
      //    por sí solo — si el admin no le dio el permiso individual,
      //    no ve el botón. Mantiene el control fino que el admin
      //    configuró por usuario/sede.
      bottomNavigationBar: BlocBuilder<CajaActivaCubit, CajaActivaState>(
        builder: (context, state) {
          if (state is! CajaActivaAbierta) return const SizedBox.shrink();
          return BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
            builder: (context, empresaState) {
              if (empresaState is! EmpresaContextLoaded) {
                return const SizedBox.shrink();
              }
              final esAdmin =
                  empresaState.context.primaryRole?.isAdminRole ?? false;
              final tieneGranular = empresaState
                  .context
                  .permissions
                  .granularPermissions
                  .contains(GranularPermissionId.cajaCerrar);
              if (!esAdmin && !tieneGranular) {
                // Sin botón → dejamos un colchón inferior para que el
                // último card de movimientos no quede pegado al borde
                // del celular. Mantiene el SafeArea para devices con
                // notch/gesture bar.
                return const SafeArea(child: SizedBox(height: 10));
              }
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Cerrar Caja',
                      backgroundColor: AppColors.red,
                      onPressed: () =>
                          _navigateToCerrarCaja(context, state.caja.id),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      body: GradientContainer(
        child: BlocConsumer<CajaActivaCubit, CajaActivaState>(
          listener: (context, state) {
            if (state is CajaActivaError) {
              SnackBarHelper.showError(context, state.message);
            }
            if (state is CajaActivaAbierta) {
              // Load movimientos when caja becomes active
              context.read<CajaMovimientosCubit>().loadMovimientos(
                state.caja.id,
              );
            }
          },
          builder: (context, state) {
            if (state is CajaActivaLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CajaActivaSinCaja) {
              // En modo admin no mostramos el form para abrir caja
              // — esa pantalla es del cajero dueño.
              if (widget.esVistaAdmin) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Esta caja ya no está disponible',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return _buildAbrirCajaView(context);
            }

            if (state is CajaActivaAbierta) {
              return _buildCajaDashboard(context, state.caja);
            }

            if (state is CajaActivaError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Reintentar',
                      onPressed: () {
                        // En vista admin reintentamos por id de la caja
                        // (sale del último estado conocido). Para
                        // simplicidad, en error no hay id a mano → si es
                        // admin, mejor que cierre y reabra desde el monitor.
                        if (widget.esVistaAdmin) {
                          Navigator.of(context).pop();
                          return;
                        }
                        context.read<CajaActivaCubit>().loadCajaActiva();
                      },
                    ),
                  ],
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildAbrirCajaView(BuildContext context) {
    final empresaState = context.watch<EmpresaContextCubit>().state;
    final sedes = empresaState is EmpresaContextLoaded
        ? empresaState.context.sedes
        : [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.point_of_sale_rounded,
            size: 70,
            color: AppColors.blue1.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 20),
          const AppSubtitle(
            'No hay caja abierta',
            fontSize: 20,
            color: AppColors.blue3,
          ),
          const SizedBox(height: 8),
          const Text(
            'Abre una caja para comenzar a registrar movimientos',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GradientContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSubtitle(
                  'Abrir Caja',
                  fontSize: 16,
                  color: AppColors.blue3,
                ),
                const SizedBox(height: 16),
                // Sede selector
                CustomDropdown<String>(
                  label: 'Sede',
                  hintText: 'Selecciona una sede',
                  value: _selectedSedeId,
                  borderColor: AppColors.blue1,
                  prefixIcon: const Icon(Icons.store_rounded, size: 18),
                  items: sedes
                      .map(
                        (sede) => DropdownItem<String>(
                          value: sede.id,
                          label: sede.nombre,
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedSedeId = value);
                  },
                ),
                const SizedBox(height: 16),
                // Monto apertura
                CurrencyTextField(
                  controller: _montoAperturaController,
                  label: 'Monto de Apertura',
                  borderColor: AppColors.blue1,
                ),
                const SizedBox(height: 16),
                // Emisor por defecto (solo si hay 2+ emisores)
                if (_emisores.length > 1) ...[
                  CustomDropdown<String>(
                    label: 'Emisor por defecto (RUC)',
                    hintText: 'Selecciona el RUC para facturar',
                    value: _selectedEmisorSedeId,
                    borderColor: Colors.green.shade700,
                    prefixIcon: Icon(
                      Icons.receipt_long,
                      size: 18,
                      color: Colors.green.shade700,
                    ),
                    items: _emisores
                        .map(
                          (e) => DropdownItem<String>(
                            value: e['id'] as String? ?? '',
                            label: '${e['ruc']} - ${e['razonSocial']}',
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedEmisorSedeId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                // Observaciones
                CustomText(
                  controller: _observacionesController,
                  label: 'Observaciones (opcional)',
                  borderColor: AppColors.blue1,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Abrir Caja',
                    backgroundColor: AppColors.green,
                    onPressed: _abrirCaja,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _abrirCaja() {
    if (_selectedSedeId == null) {
      SnackBarHelper.showError(context, 'Selecciona una sede');
      return;
    }

    final monto = double.tryParse(
      _montoAperturaController.text.replaceAll(',', '.'),
    );
    if (monto == null || monto < 0) {
      SnackBarHelper.showError(context, 'Ingresa un monto valido');
      return;
    }

    context.read<CajaActivaCubit>().abrirCaja(
      sedeId: _selectedSedeId!,
      montoApertura: monto,
      observaciones: _observacionesController.text.isNotEmpty
          ? _observacionesController.text
          : null,
      sedeFacturacionId: _selectedEmisorSedeId,
    );
  }

  Widget _buildCajaDashboard(BuildContext context, Caja caja) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'S/ ',
      decimalDigits: 2,
    );

    return Column(
      children: [
        // Card fijo (no scrollea): cajero + apertura. Va arriba del
        // contenido scrollable para que esa metadata operativa esté
        // siempre visible mientras el admin/cajero recorre movimientos
        // y resúmenes.
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
          child: GradientContainer(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Cajero',
                    caja.usuarioNombre ?? '-',
                    Icons.person_rounded,
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _buildInfoItemEnd(
                      'Apertura',
                      DateFormatter.formatDateTime(caja.fechaApertura),
                      Icons.access_time_rounded,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Resto del dashboard scrolleable.
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              final cubit = context.read<CajaActivaCubit>();
              // En vista admin recargamos por id de la caja que estamos
              // viendo (no la "caja activa del usuario actual", que sería
              // la del propio admin si tiene una abierta — eso causaba el
              // bug de saltar de la caja 17 a la 14 al hacer pull-to-refresh).
              if (widget.esVistaAdmin) {
                await cubit.loadCajaPorId(caja.id);
              } else {
                await cubit.loadCajaActiva();
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          'Nuevo Mov.',
                          Icons.add_circle_rounded,
                          AppColors.blue2,
                          () => _navigateToNuevoMovimiento(context, caja.id),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          'Ver Movimientos',
                          Icons.list_alt_rounded,
                          AppColors.blue1,
                          () => _navigateToMovimientos(context, caja.id),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          'Arqueo',
                          Icons.fact_check_rounded,
                          AppColors.green,
                          () => _navigateToRealizarArqueo(context, caja),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Resumen card
                  BlocBuilder<CajaMovimientosCubit, CajaMovimientosState>(
                    builder: (context, movState) {
                      if (movState is CajaMovimientosLoaded &&
                          movState.resumen != null) {
                        return ResumenCajaCard(
                          resumen: movState.resumen!,
                          montoApertura: caja.montoApertura,
                        );
                      }
                      if (movState is CajaMovimientosLoading) {
                        return const GradientContainer(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Recent movements
                  BlocBuilder<CajaMovimientosCubit, CajaMovimientosState>(
                    builder: (context, movState) {
                      if (movState is CajaMovimientosLoaded) {
                        // Agrupamos por venta primero, luego cortamos a 5 GRUPOS
                        // (no 5 movimientos), asi una venta multi-pago cuenta
                        // como 1 entrada y no monopoliza la lista de recientes.
                        final groups = groupMovimientosByVenta(
                          movState.movimientos,
                        ).take(5).toList();
                        if (groups.isEmpty) {
                          return GradientContainer(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long_rounded,
                                    size: 40,
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Sin movimientos aun',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return GradientContainer(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const AppSubtitle(
                                    'MOVIMIENTOS RECIENTES',
                                    fontSize: 11,
                                    color: AppColors.blue3,
                                  ),
                                  if (movState.movimientos.length >
                                      groups.fold<int>(
                                        0,
                                        (s, g) => s + g.items.length,
                                      ))
                                    GestureDetector(
                                      onTap: () => _navigateToMovimientos(
                                        context,
                                        caja.id,
                                      ),
                                      child: const Text(
                                        'Ver todos',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.blue2,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...groups.map(
                                (g) => MovimientoGroupCard(
                                  group: g,
                                  currencyFormat: currencyFormat,
                                  compact: true,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItemEnd(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(width: 6),
        Icon(icon, size: 16, color: AppColors.textSecondary),
      ],
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: GradientContainer(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToNuevoMovimiento(BuildContext context, String cajaId) {
    final movCubit = context.read<CajaMovimientosCubit>();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => NuevoMovimientoPage(cajaId: cajaId),
          ),
        )
        .then((result) {
          if (result == true) {
            movCubit.loadMovimientos(cajaId);
          }
        });
  }

  void _navigateToMovimientos(BuildContext context, String cajaId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CajaMovimientosCubit>(),
          child: MovimientosCajaPage(cajaId: cajaId),
        ),
      ),
    );
  }

  void _navigateToRealizarArqueo(BuildContext context, Caja caja) {
    final movCubit = context.read<CajaMovimientosCubit>();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: movCubit),
                BlocProvider(create: (_) => locator<ArqueosCajaCubit>()),
              ],
              child: RealizarArqueoPage(caja: caja),
            ),
          ),
        )
        .then((_) => movCubit.loadMovimientos(caja.id));
  }

  void _navigateToArqueosLista(BuildContext context, Caja caja) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => locator<ArqueosCajaCubit>(),
          child: ArqueosListaPage(caja: caja),
        ),
      ),
    );
  }

  void _navigateToCerrarCaja(BuildContext context, String cajaId) {
    final cajaCubit = context.read<CajaActivaCubit>();
    final movCubit = context.read<CajaMovimientosCubit>();
    final esAdmin = widget.esVistaAdmin;
    Navigator.of(context)
        .push<bool>(
          MaterialPageRoute(
            builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: cajaCubit),
                BlocProvider.value(value: movCubit),
                BlocProvider(create: (_) => locator<CerrarCajaCubit>()),
              ],
              // En modo admin: la caja no es del usuario actual; la page
              // sabe no refrescar su CajaActivaCubit local.
              child: CerrarCajaPage(cajaId: cajaId, esCajaPropia: !esAdmin),
            ),
          ),
        )
        .then((cerrado) {
          // En modo admin NO recargamos nunca con loadCajaActiva: ese
          // método trae "mi caja activa" (la del admin) y pisaría la
          // caja ajena que estábamos viendo — bug observado al volver
          // sin cerrar.
          if (esAdmin) {
            // Si cerró exitosamente, salimos al monitor para que se
            // refresque el listado de cajas abiertas.
            if (cerrado == true && context.mounted) {
              Navigator.of(context).pop();
            }
            // Si volvió sin cerrar (cerrado != true), no hacemos nada:
            // el CajaActivaCubit ya tiene la caja ajena correcta.
            return;
          }
          // Cajero: reload state para que el dashboard reaccione.
          cajaCubit.loadCajaActiva();
        });
  }
}
