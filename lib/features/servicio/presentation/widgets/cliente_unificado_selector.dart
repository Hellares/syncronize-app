import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../../../core/widgets/floating_button_icon.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text.dart'
    show CustomText, FieldType;
import '../../../cliente/domain/entities/cliente.dart';
import '../../../cliente/presentation/bloc/cliente_list/cliente_list_cubit.dart';
import '../../../cliente/presentation/bloc/cliente_list/cliente_list_state.dart';
import '../../../cliente/presentation/bloc/cliente_form/cliente_form_cubit.dart';
import '../../../cliente/presentation/bloc/cliente_form/cliente_form_state.dart';
import '../../../consultas_externas/domain/entities/consulta_dni.dart';
import '../../../consultas_externas/domain/entities/consulta_ruc.dart';
import '../../../consultas_externas/domain/usecases/consultar_dni_usecase.dart';
import '../../../consultas_externas/domain/usecases/consultar_ruc_usecase.dart';
import '../../../cliente_empresa/domain/entities/cliente_empresa.dart';
import '../../../cliente_empresa/domain/repositories/cliente_empresa_repository.dart';

/// Tipo de cliente seleccionado
enum TipoClienteSeleccion { persona, empresa }

/// Resultado unificado de la selección de cliente
class ClienteUnificadoResult {
  final TipoClienteSeleccion tipo;

  // Persona
  final String? clienteId;
  final String? nombreCompleto;
  final String? dni;
  final String? telefono;
  final String? email;

  // Empresa
  final String? clienteEmpresaId;
  final String? razonSocial;
  final String? nombreComercial;
  final String? ruc;
  final String? contactoId;
  final String? contactoNombre;
  final String? contactoCargo;

  const ClienteUnificadoResult.persona({
    required this.clienteId,
    required this.nombreCompleto,
    this.dni,
    this.telefono,
    this.email,
  })  : tipo = TipoClienteSeleccion.persona,
        clienteEmpresaId = null,
        razonSocial = null,
        nombreComercial = null,
        ruc = null,
        contactoId = null,
        contactoNombre = null,
        contactoCargo = null;

  const ClienteUnificadoResult.empresa({
    required this.clienteEmpresaId,
    required this.razonSocial,
    this.nombreComercial,
    required this.ruc,
    this.contactoId,
    this.contactoNombre,
    this.contactoCargo,
    this.telefono,
    this.email,
  })  : tipo = TipoClienteSeleccion.empresa,
        clienteId = null,
        nombreCompleto = null,
        dni = null;

  bool get isPersona => tipo == TipoClienteSeleccion.persona;
  bool get isEmpresa => tipo == TipoClienteSeleccion.empresa;

  String get displayName {
    if (isPersona) return nombreCompleto ?? '';
    return nombreComercial ?? razonSocial ?? '';
  }

  String get displayDocumento {
    if (isPersona) return dni ?? '';
    return ruc ?? '';
  }
}

/// Bottom sheet unificado para seleccionar cliente persona o empresa.
/// Ambos tabs funcionan inline: búsqueda + registro sin abrir otro sheet.
class ClienteUnificadoSelector extends StatefulWidget {
  final String empresaId;

  const ClienteUnificadoSelector({
    super.key,
    required this.empresaId,
  });

  static Future<ClienteUnificadoResult?> show({
    required BuildContext context,
    required String empresaId,
  }) {
    return showModalBottomSheet<ClienteUnificadoResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClienteUnificadoSelector(empresaId: empresaId),
    );
  }

  @override
  State<ClienteUnificadoSelector> createState() =>
      _ClienteUnificadoSelectorState();
}

class _ClienteUnificadoSelectorState extends State<ClienteUnificadoSelector>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.bluechip,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_search,
                    color: AppColors.blue1,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                AppSubtitle('SELECCIONAR CLIENTE', fontSize: 12),
              ],
            ),
          ),
          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.blue1,
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[700],
              labelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              dividerHeight: 0,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person, size: 16),
                      SizedBox(width: 6),
                      Text('Persona'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business, size: 16),
                      SizedBox(width: 6),
                      Text('Empresa'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          // Body
          Flexible(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PersonaTab(empresaId: widget.empresaId),
                _EmpresaTab(empresaId: widget.empresaId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ─── Persona Tab (inline search + register) ───
// ═══════════════════════════════════════════════════════════════════

enum _PersonaMode { search, register }

class _PersonaTab extends StatefulWidget {
  final String empresaId;

  const _PersonaTab({required this.empresaId});

  @override
  State<_PersonaTab> createState() => _PersonaTabState();
}

class _PersonaTabState extends State<_PersonaTab>
    with AutomaticKeepAliveClientMixin {
  _PersonaMode _mode = _PersonaMode.search;

  // Search
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  late final ClienteListCubit _listCubit;

  // Register
  late final ClienteFormCubit _formCubit;
  final _dniController = TextEditingController();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();

  bool _isLookingUpDni = false;
  bool _dniFieldsFilled = false;
  String? _dniError;
  String? _origenDatos;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _listCubit = locator<ClienteListCubit>();
    _formCubit = locator<ClienteFormCubit>();
    _listCubit.loadClientes(empresaId: widget.empresaId);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _dniController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    _listCubit.close();
    _formCubit.close();
    super.dispose();
  }

  // ─── DNI Lookup ───

  Future<void> _lookupDni() async {
    final dni = _dniController.text.trim();
    if (dni.length != 8 || !RegExp(r'^\d{8}$').hasMatch(dni)) {
      setState(() => _dniError = 'Ingresa un DNI válido de 8 dígitos');
      return;
    }

    setState(() {
      _isLookingUpDni = true;
      _dniError = null;
    });

    try {
      final useCase = locator<ConsultarDniUseCase>();
      final result = await useCase(dni);
      if (!mounted) return;

      if (result is Success<ConsultaDni>) {
        final data = result.data;
        setState(() {
          _nombresController.text = data.nombres;
          _apellidosController.text = data.apellidos;
          if (data.telefono != null && data.telefono!.isNotEmpty) {
            _telefonoController.text = data.telefono!;
          }
          if (data.email != null && data.email!.isNotEmpty) {
            _emailController.text = data.email!;
          }
          _direccionController.text = data.direccion;
          _dniFieldsFilled = true;
          _origenDatos = data.origen;
          _isLookingUpDni = false;
        });
      } else if (result is Error<ConsultaDni>) {
        setState(() {
          _dniError = result.message;
          _isLookingUpDni = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dniError = 'Error al consultar';
        _isLookingUpDni = false;
      });
    }
  }

  void _onDniChanged(String value) {
    if (_dniError != null) setState(() => _dniError = null);
    if (_dniFieldsFilled) {
      setState(() {
        _nombresController.clear();
        _apellidosController.clear();
        _telefonoController.clear();
        _emailController.clear();
        _direccionController.clear();
        _dniFieldsFilled = false;
        _origenDatos = null;
      });
    }
    if (value.length == 8 && RegExp(r'^\d{8}$').hasMatch(value)) {
      _lookupDni();
    }
  }

  // ─── Submit Register ───

  bool _validateRegisterForm() {
    final dni = _dniController.text.trim();
    final nombres = _nombresController.text.trim();
    final apellidos = _apellidosController.text.trim();
    final telefono = _telefonoController.text.trim();

    if (dni.isEmpty || dni.length != 8 || !RegExp(r'^\d{8}$').hasMatch(dni)) {
      SnackBarHelper.showError(context, 'El DNI debe tener 8 dígitos');
      return false;
    }
    if (nombres.isEmpty) {
      SnackBarHelper.showError(context, 'Los nombres son obligatorios');
      return false;
    }
    if (apellidos.isEmpty) {
      SnackBarHelper.showError(context, 'Los apellidos son obligatorios');
      return false;
    }
    if (telefono.isEmpty || !RegExp(r'^\d{9}$').hasMatch(telefono)) {
      SnackBarHelper.showError(context, 'El teléfono debe tener 9 dígitos');
      return false;
    }
    return true;
  }

  void _submitRegister() {
    if (!_validateRegisterForm()) return;
    _formCubit.registrarCliente(
      empresaId: widget.empresaId,
      dni: _dniController.text.trim(),
      nombres: _nombresController.text.trim(),
      apellidos: _apellidosController.text.trim(),
      telefono: _telefonoController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      direccion: _direccionController.text.trim().isEmpty
          ? null
          : _direccionController.text.trim(),
    );
  }

  ClienteUnificadoResult _resultFromCliente(Cliente cliente) {
    return ClienteUnificadoResult.persona(
      clienteId: cliente.id,
      nombreCompleto: cliente.nombreCompleto,
      dni: cliente.dni,
      telefono: cliente.telefono,
      email: cliente.email,
    );
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _listCubit),
        BlocProvider.value(value: _formCubit),
      ],
      child: BlocListener<ClienteFormCubit, ClienteFormState>(
        listener: (context, state) {
          if (state is ClienteFormSuccess) {
            final cliente = state.response.cliente;
            Navigator.pop(context, _resultFromCliente(cliente));
          } else if (state is ClienteFormError) {
            if (!mounted) return;
            SnackBarHelper.showError(context, state.message);
          }
        },
        child: _mode == _PersonaMode.search
            ? _buildSearchMode()
            : _buildRegisterMode(),
      ),
    );
  }

  // ─── Search Mode ───

  Widget _buildSearchMode() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: CustomSearchField(
            controller: _searchController,
            hintText: 'Buscar por nombre, DNI o teléfono...',
            onChanged: (query) {
              _debounceTimer?.cancel();
              _debounceTimer = Timer(const Duration(milliseconds: 400), () {
                if (!mounted) return;
                if (query.isEmpty) {
                  _listCubit.loadClientes(empresaId: widget.empresaId);
                } else {
                  _listCubit.search(query);
                }
              });
            },
          ),
        ),
        Flexible(
          child: BlocBuilder<ClienteListCubit, ClienteListState>(
            builder: (context, state) {
              if (state is ClienteListLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (state is ClienteListError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      state.message,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (state is ClienteListLoaded) {
                if (state.clientes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_off_outlined,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'No se encontraron clientes',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Puedes registrar uno nuevo',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.clientes.length,
                  itemBuilder: (context, index) {
                    final cliente = state.clientes[index];
                    return _buildClienteTile(cliente);
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _mode = _PersonaMode.register),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Registrar nuevo cliente'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blue1,
                side: const BorderSide(color: AppColors.blue1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClienteTile(Cliente cliente) {
    return InkWell(
      onTap: () => Navigator.pop(context, _resultFromCliente(cliente)),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.blueborder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.bluechip,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  cliente.iniciales,
                  style: const TextStyle(
                    color: AppColors.blue1,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cliente.nombreCompleto,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'DNI: ${cliente.dni ?? '-'}  ·  ${cliente.telefono ?? '-'}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ─── Register Mode ───

  Widget _buildRegisterMode() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _mode = _PersonaMode.search),
              ),
              const SizedBox(width: 8),
              AppSubtitle('REGISTRAR PERSONA', fontSize: 12),
            ],
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DNI lookup
                Text(
                  'Ingresa el DNI para autocompletar los datos.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomText(
                        controller: _dniController,
                        label: 'DNI',
                        hintText: '12345678',
                        fieldType: FieldType.number,
                        maxLength: 8,
                        prefixIcon: const Icon(Icons.badge_outlined),
                        borderColor: AppColors.blue1,
                        enabled: !_isLookingUpDni,
                        externalError: _dniError,
                        onChanged: _onDniChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _isLookingUpDni
                          ? const SizedBox(
                              width: 35,
                              height: 35,
                              child: Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1,
                                    color: AppColors.blue2,
                                  ),
                                ),
                              ),
                            )
                          : FloatingButtonIcon(
                              size: 35,
                              icon: Icons.search,
                              backgroundColor: AppColors.blue2,
                              onPressed: _dniController.text.length != 8
                                  ? () {}
                                  : _lookupDni,
                            ),
                    ),
                  ],
                ),
                if (_dniFieldsFilled) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            size: 14, color: Colors.green),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _origenDatos == 'INTERNO'
                                ? 'Persona encontrada en el sistema'
                                : 'Datos autocompletados desde RENIEC',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                CustomText(
                  controller: _nombresController,
                  label: 'Nombres *',
                  hintText: 'Juan Carlos',
                  prefixIcon: const Icon(Icons.person_outline),
                  borderColor: AppColors.blue1,
                  enabled: !_dniFieldsFilled,
                ),
                const SizedBox(height: 14),
                CustomText(
                  controller: _apellidosController,
                  label: 'Apellidos *',
                  hintText: 'Pérez García',
                  prefixIcon: const Icon(Icons.person_outline),
                  borderColor: AppColors.blue1,
                  enabled: !_dniFieldsFilled,
                ),
                const SizedBox(height: 14),
                CustomText(
                  controller: _telefonoController,
                  label: 'Teléfono *',
                  hintText: '987654321',
                  fieldType: FieldType.number,
                  maxLength: 9,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  borderColor: AppColors.blue1,
                ),
                const SizedBox(height: 14),
                CustomText(
                  controller: _emailController,
                  label: 'Email (opcional)',
                  hintText: 'cliente@example.com',
                  fieldType: FieldType.email,
                  prefixIcon: const Icon(Icons.email_outlined),
                  borderColor: AppColors.blue1,
                ),
                const SizedBox(height: 14),
                CustomText(
                  controller: _direccionController,
                  label: 'Dirección (opcional)',
                  hintText: 'Av. Principal 123',
                  prefixIcon: const Icon(Icons.home_outlined),
                  borderColor: AppColors.blue1,
                ),
                const SizedBox(height: 20),
                BlocBuilder<ClienteFormCubit, ClienteFormState>(
                  builder: (context, state) {
                    final isLoading = state is ClienteFormLoading;
                    return CustomButton(
                      text: 'Registrar Cliente',
                      isLoading: isLoading,
                      icon: const Icon(Icons.person_add,
                          color: Colors.white, size: 18),
                      onPressed: isLoading ? null : _submitRegister,
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ─── Empresa Tab (inline search + register) ───
// ═══════════════════════════════════════════════════════════════════

enum _EmpresaMode { search, register }

class _EmpresaTab extends StatefulWidget {
  final String empresaId;

  const _EmpresaTab({required this.empresaId});

  @override
  State<_EmpresaTab> createState() => _EmpresaTabState();
}

class _EmpresaTabState extends State<_EmpresaTab>
    with AutomaticKeepAliveClientMixin {
  _EmpresaMode _mode = _EmpresaMode.search;

  // Search
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounceTimer;
  List<ClienteEmpresa> _empresas = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;

  // Register
  final _rucController = TextEditingController();
  final _razonSocialController = TextEditingController();
  final _nombreComercialController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _contactoNombreController = TextEditingController();
  final _contactoCargoController = TextEditingController();
  final _contactoDniController = TextEditingController();
  final _contactoTelefonoController = TextEditingController();

  bool _isLookingUpRuc = false;
  bool _rucFieldsFilled = false;
  String? _rucError;
  bool _isRegistering = false;

  // SUNAT snapshot fields
  String? _estadoContribuyente;
  String? _condicionContribuyente;
  String? _ubigeo;
  String? _departamento;
  String? _provincia;
  String? _distrito;

  late final ClienteEmpresaRepository _repo;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _repo = locator<ClienteEmpresaRepository>();
    _scrollController.addListener(_onScroll);
    _loadEmpresas();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore &&
        _currentPage < _totalPages) {
      _loadMoreEmpresas();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _rucController.dispose();
    _razonSocialController.dispose();
    _nombreComercialController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _contactoNombreController.dispose();
    _contactoCargoController.dispose();
    _contactoDniController.dispose();
    _contactoTelefonoController.dispose();
    super.dispose();
  }

  Future<void> _loadEmpresas({String? search}) async {
    setState(() {
      _isSearching = true;
      _currentPage = 1;
    });
    final result = await _repo.getClientesEmpresa(
      empresaId: widget.empresaId,
      search: search,
      page: 1,
    );
    if (!mounted) return;
    setState(() {
      _isSearching = false;
      _hasSearched = true;
      if (result is Success<ClientesEmpresaPaginados>) {
        _empresas = result.data.data;
        _totalPages = (result.data.total / 20).ceil().clamp(1, 9999);
      }
    });
  }

  Future<void> _loadMoreEmpresas() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    final nextPage = _currentPage + 1;
    final result = await _repo.getClientesEmpresa(
      empresaId: widget.empresaId,
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      page: nextPage,
    );
    if (!mounted) return;
    setState(() {
      _isLoadingMore = false;
      if (result is Success<ClientesEmpresaPaginados>) {
        _empresas.addAll(result.data.data);
        _currentPage = nextPage;
      }
    });
  }

  // ─── RUC Lookup ───

  Future<void> _lookupRuc() async {
    final ruc = _rucController.text.trim();
    if (ruc.length != 11 || !RegExp(r'^\d{11}$').hasMatch(ruc)) {
      setState(() => _rucError = 'Ingresa un RUC válido de 11 dígitos');
      return;
    }

    setState(() {
      _isLookingUpRuc = true;
      _rucError = null;
    });

    try {
      final useCase = locator<ConsultarRucUseCase>();
      final result = await useCase(ruc);
      if (!mounted) return;

      if (result is Success<ConsultaRuc>) {
        final data = result.data;
        setState(() {
          _razonSocialController.text = data.razonSocial;
          _direccionController.text = data.direccionCompleta;
          _estadoContribuyente = data.estado;
          _condicionContribuyente = data.condicion;
          _ubigeo = data.ubigeo;
          _departamento = data.departamento;
          _provincia = data.provincia;
          _distrito = data.distrito;
          _rucFieldsFilled = true;
          _isLookingUpRuc = false;
        });
      } else if (result is Error<ConsultaRuc>) {
        setState(() {
          _rucError = result.message;
          _isLookingUpRuc = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rucError = 'Error al consultar SUNAT';
        _isLookingUpRuc = false;
      });
    }
  }

  void _onRucChanged(String value) {
    if (_rucError != null) setState(() => _rucError = null);
    if (_rucFieldsFilled) {
      setState(() {
        _razonSocialController.clear();
        _direccionController.clear();
        _rucFieldsFilled = false;
        _estadoContribuyente = null;
        _condicionContribuyente = null;
        _ubigeo = null;
        _departamento = null;
        _provincia = null;
        _distrito = null;
      });
    }
    if (value.length == 11 && RegExp(r'^\d{11}$').hasMatch(value)) {
      _lookupRuc();
    }
  }

  // ─── Select empresa + contact ───

  void _selectEmpresa(ClienteEmpresa empresa) {
    if (empresa.contactos != null && empresa.contactos!.isNotEmpty) {
      _showContactoSelector(empresa);
    } else {
      Navigator.pop(
        context,
        ClienteUnificadoResult.empresa(
          clienteEmpresaId: empresa.id,
          razonSocial: empresa.razonSocial,
          nombreComercial: empresa.nombreComercial,
          ruc: empresa.numeroDocumento,
          telefono: empresa.telefono,
          email: empresa.email,
        ),
      );
    }
  }

  void _showContactoSelector(ClienteEmpresa empresa) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.contacts, color: AppColors.blue1, size: 20),
                  const SizedBox(width: 8),
                  AppSubtitle('SELECCIONAR CONTACTO', fontSize: 12),
                ],
              ),
            ),
            const Divider(height: 1),
            // Nuevo contacto option
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.orange),
              title: const Text('Ingresar nuevo contacto',
                  style: TextStyle(fontSize: 13)),
              subtitle: const Text('Completarás los datos en el formulario',
                  style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pop(
                  context,
                  ClienteUnificadoResult.empresa(
                    clienteEmpresaId: empresa.id,
                    razonSocial: empresa.razonSocial,
                    nombreComercial: empresa.nombreComercial,
                    ruc: empresa.numeroDocumento,
                    telefono: empresa.telefono,
                    email: empresa.email,
                  ),
                );
              },
            ),
            ...empresa.contactos!.map((contacto) => ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: contacto.esPrincipal
                        ? AppColors.blue1
                        : AppColors.bluechip,
                    child: Text(
                      contacto.nombre.isNotEmpty
                          ? contacto.nombre[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: contacto.esPrincipal
                            ? Colors.white
                            : AppColors.blue1,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  title: Text(contacto.nombre,
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                    [
                      if (contacto.cargo != null) contacto.cargo!,
                      if (contacto.dni != null) 'DNI: ${contacto.dni}',
                    ].join('  ·  '),
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: contacto.esPrincipal
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.blue1.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Principal',
                              style: TextStyle(
                                  fontSize: 9, color: AppColors.blue1)),
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pop(
                      context,
                      ClienteUnificadoResult.empresa(
                        clienteEmpresaId: empresa.id,
                        razonSocial: empresa.razonSocial,
                        nombreComercial: empresa.nombreComercial,
                        ruc: empresa.numeroDocumento,
                        contactoId: contacto.id,
                        contactoNombre: contacto.nombre,
                        contactoCargo: contacto.cargo,
                        telefono: contacto.telefono ?? empresa.telefono,
                        email: contacto.email ?? empresa.email,
                      ),
                    );
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── Register ───

  Future<void> _submitRegister() async {
    final ruc = _rucController.text.trim();
    final razonSocial = _razonSocialController.text.trim();

    if (ruc.length != 11 || !RegExp(r'^\d{11}$').hasMatch(ruc)) {
      SnackBarHelper.showError(context, 'El RUC debe tener 11 dígitos');
      return;
    }
    if (razonSocial.isEmpty) {
      SnackBarHelper.showError(context, 'La razón social es obligatoria');
      return;
    }

    setState(() => _isRegistering = true);

    final contactoNombre = _contactoNombreController.text.trim();
    List<Map<String, dynamic>>? contactos;
    if (contactoNombre.isNotEmpty) {
      contactos = [
        {
          'nombre': contactoNombre,
          if (_contactoCargoController.text.trim().isNotEmpty)
            'cargo': _contactoCargoController.text.trim(),
          if (_contactoDniController.text.trim().isNotEmpty)
            'dni': _contactoDniController.text.trim(),
          if (_contactoTelefonoController.text.trim().isNotEmpty)
            'telefono': _contactoTelefonoController.text.trim(),
          'esPrincipal': true,
        },
      ];
    }

    final result = await _repo.crearClienteEmpresa(
      empresaId: widget.empresaId,
      razonSocial: razonSocial,
      numeroDocumento: ruc,
      nombreComercial: _nombreComercialController.text.trim().isEmpty
          ? null
          : _nombreComercialController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      telefono: _telefonoController.text.trim().isEmpty
          ? null
          : _telefonoController.text.trim(),
      direccion: _direccionController.text.trim().isEmpty
          ? null
          : _direccionController.text.trim(),
      estadoContribuyente: _estadoContribuyente,
      condicionContribuyente: _condicionContribuyente,
      ubigeo: _ubigeo,
      departamento: _departamento,
      provincia: _provincia,
      distrito: _distrito,
      contactos: contactos,
    );

    if (!mounted) return;
    setState(() => _isRegistering = false);

    if (result is Success<ClienteEmpresa>) {
      final empresa = result.data;
      final contacto = empresa.contactoPrincipal;
      Navigator.pop(
        context,
        ClienteUnificadoResult.empresa(
          clienteEmpresaId: empresa.id,
          razonSocial: empresa.razonSocial,
          nombreComercial: empresa.nombreComercial,
          ruc: empresa.numeroDocumento,
          contactoId: contacto?.id,
          contactoNombre: contacto?.nombre,
          contactoCargo: contacto?.cargo,
          telefono: empresa.telefono,
          email: empresa.email,
        ),
      );
    } else if (result is Error<ClienteEmpresa>) {
      if (!mounted) return;
      SnackBarHelper.showError(context, result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _mode == _EmpresaMode.search
        ? _buildSearchMode()
        : _buildRegisterMode();
  }

  // ─── Search Mode ───

  Widget _buildSearchMode() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: CustomSearchField(
            controller: _searchController,
            hintText: 'Buscar por razón social, RUC...',
            onChanged: (query) {
              _debounceTimer?.cancel();
              _debounceTimer = Timer(const Duration(milliseconds: 400), () {
                if (!mounted) return;
                if (query.isEmpty) {
                  _loadEmpresas();
                } else {
                  _loadEmpresas(search: query);
                }
              });
            },
          ),
        ),
        Flexible(
          child: _isSearching
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _empresas.isEmpty && _hasSearched
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.business_outlined,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'No se encontraron empresas',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Puedes registrar una nueva',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _empresas.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _empresas.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }
                        final empresa = _empresas[index];
                        return _buildEmpresaTile(empresa);
                      },
                    ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _mode = _EmpresaMode.register),
              icon: const Icon(Icons.add_business, size: 18),
              label: const Text('Registrar nueva empresa'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blue1,
                side: const BorderSide(color: AppColors.blue1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpresaTile(ClienteEmpresa empresa) {
    return InkWell(
      onTap: () => _selectEmpresa(empresa),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.blueborder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.bluechip,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  empresa.iniciales,
                  style: const TextStyle(
                    color: AppColors.blue1,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    empresa.nombreDisplay,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'RUC: ${empresa.numeroDocumento}${empresa.contactos != null && empresa.contactos!.isNotEmpty ? "  ·  ${empresa.contactos!.length} contacto(s)" : ""}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ─── Register Mode ───

  Widget _buildRegisterMode() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _mode = _EmpresaMode.search),
              ),
              const SizedBox(width: 8),
              AppSubtitle('REGISTRAR EMPRESA', fontSize: 12),
            ],
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // RUC lookup
                Text(
                  'Ingresa el RUC para autocompletar desde SUNAT.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomText(
                        controller: _rucController,
                        label: 'RUC',
                        hintText: '20123456789',
                        fieldType: FieldType.number,
                        maxLength: 11,
                        prefixIcon: const Icon(Icons.badge_outlined),
                        borderColor: AppColors.blue1,
                        enabled: !_isLookingUpRuc,
                        externalError: _rucError,
                        onChanged: _onRucChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _isLookingUpRuc
                          ? const SizedBox(
                              width: 35,
                              height: 35,
                              child: Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1,
                                    color: AppColors.blue2,
                                  ),
                                ),
                              ),
                            )
                          : FloatingButtonIcon(
                              size: 35,
                              icon: Icons.search,
                              backgroundColor: AppColors.blue2,
                              onPressed: _rucController.text.length != 11
                                  ? () {}
                                  : _lookupRuc,
                            ),
                    ),
                  ],
                ),
                if (_rucFieldsFilled) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            size: 14, color: Colors.green),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Datos autocompletados desde SUNAT'
                            '${_estadoContribuyente != null ? "  ·  $_estadoContribuyente" : ""}'
                            '${_condicionContribuyente != null ? " / $_condicionContribuyente" : ""}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                CustomText(
                  controller: _razonSocialController,
                  label: 'Razón Social *',
                  hintText: 'Empresa S.A.C.',
                  prefixIcon: const Icon(Icons.business),
                  borderColor: AppColors.blue1,
                  enabled: !_rucFieldsFilled,
                ),
                const SizedBox(height: 14),
                CustomText(
                  controller: _nombreComercialController,
                  label: 'Nombre Comercial (opcional)',
                  hintText: 'Nombre comercial',
                  prefixIcon: const Icon(Icons.storefront),
                  borderColor: AppColors.blue1,
                ),
                const SizedBox(height: 14),
                CustomText(
                  controller: _emailController,
                  label: 'Email (opcional)',
                  hintText: 'empresa@example.com',
                  fieldType: FieldType.email,
                  prefixIcon: const Icon(Icons.email_outlined),
                  borderColor: AppColors.blue1,
                ),
                const SizedBox(height: 14),
                CustomText(
                  controller: _telefonoController,
                  label: 'Teléfono (opcional)',
                  hintText: '01-1234567',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  borderColor: AppColors.blue1,
                ),
                const SizedBox(height: 14),
                CustomText(
                  controller: _direccionController,
                  label: 'Dirección',
                  hintText: 'Av. Principal 123',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  borderColor: AppColors.blue1,
                  enabled: !_rucFieldsFilled,
                ),

                // Contacto principal section
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.contacts_outlined,
                        size: 16, color: AppColors.blue1),
                    const SizedBox(width: 8),
                    AppSubtitle('CONTACTO PRINCIPAL (opcional)', fontSize: 11),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Persona de contacto dentro de la empresa.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 10),
                CustomText(
                  controller: _contactoNombreController,
                  label: 'Nombre del contacto',
                  hintText: 'Juan Pérez',
                  prefixIcon: const Icon(Icons.person_outline),
                  borderColor: AppColors.blue1,
                ),
                const SizedBox(height: 14),
                CustomText(
                  controller: _contactoCargoController,
                  label: 'Cargo (opcional)',
                  hintText: 'Gerente de TI',
                  prefixIcon: const Icon(Icons.work_outline),
                  borderColor: AppColors.blue1,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        controller: _contactoDniController,
                        label: 'DNI contacto',
                        hintText: '12345678',
                        fieldType: FieldType.number,
                        maxLength: 8,
                        prefixIcon: const Icon(Icons.badge_outlined),
                        borderColor: AppColors.blue1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomText(
                        controller: _contactoTelefonoController,
                        label: 'Teléfono contacto',
                        hintText: '987654321',
                        fieldType: FieldType.number,
                        maxLength: 9,
                        prefixIcon: const Icon(Icons.phone_outlined),
                        borderColor: AppColors.blue1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                CustomButton(
                  text: 'Registrar Empresa',
                  isLoading: _isRegistering,
                  icon: const Icon(Icons.add_business,
                      color: Colors.white, size: 18),
                  onPressed: _isRegistering ? null : _submitRegister,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
