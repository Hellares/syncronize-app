import 'package:flutter/material.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../consultas_externas/domain/usecases/consultar_licencia_usecase.dart';
import '../../../consultas_externas/domain/usecases/consultar_placa_usecase.dart';
import '../../../consultas_externas/domain/usecases/consultar_ruc_usecase.dart';
import '../../data/datasources/guia_remision_remote_datasource.dart';
import '../../domain/entities/guia_remision.dart';
import '../../domain/repositories/guia_remision_repository.dart';

class CatalogosGrePage extends StatefulWidget {
  const CatalogosGrePage({super.key});

  @override
  State<CatalogosGrePage> createState() => _CatalogosGrePageState();
}

class _CatalogosGrePageState extends State<CatalogosGrePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repository = locator<GuiaRemisionRepository>();
  final _datasource = locator<GuiaRemisionRemoteDatasource>();

  List<VehiculoEmpresa> _vehiculos = [];
  List<ConductorEmpresa> _conductores = [];
  List<TransportistaEmpresa> _transportistas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _repository.listarVehiculos(),
      _repository.listarConductores(),
      _repository.listarTransportistas(),
    ]);
    if (mounted) {
      setState(() {
        if (results[0] is Success) {
          _vehiculos = (results[0] as Success<List<VehiculoEmpresa>>).data;
        }
        if (results[1] is Success) {
          _conductores = (results[1] as Success<List<ConductorEmpresa>>).data;
        }
        if (results[2] is Success) {
          _transportistas =
              (results[2] as Success<List<TransportistaEmpresa>>).data;
        }
        _loading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Catalogos GRE',
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.blue1,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.blue1,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            tabs: const [
              Tab(icon: Icon(Icons.local_shipping, size: 18), text: 'Vehiculos'),
              Tab(icon: Icon(Icons.person, size: 18), text: 'Conductores'),
              Tab(icon: Icon(Icons.business, size: 18), text: 'Transportistas'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildVehiculosTab(),
                  _buildConductoresTab(),
                  _buildTransportistasTab(),
                ],
              ),
        floatingActionButton: _buildFab(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FAB
  // ---------------------------------------------------------------------------

  Widget _buildFab() {
    final labels = ['+ Vehiculo', '+ Conductor', '+ Transportista'];
    final icons = [Icons.local_shipping, Icons.person, Icons.business];
    final idx = _tabController.index;

    return FloatingActionButton.extended(
      onPressed: () {
        switch (idx) {
          case 0:
            _mostrarDialogVehiculo();
            break;
          case 1:
            _mostrarDialogConductor();
            break;
          case 2:
            _mostrarDialogTransportista();
            break;
        }
      },
      backgroundColor: AppColors.blue1,
      icon: Icon(icons[idx], color: Colors.white, size: 18),
      label: Text(labels[idx],
          style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }

  // ===========================================================================
  // TAB 1 - VEHICULOS
  // ===========================================================================

  Widget _buildVehiculosTab() {
    if (_vehiculos.isEmpty) {
      return _buildEmptyState(
        icon: Icons.local_shipping,
        mensaje: 'No hay vehiculos registrados',
        onTap: _mostrarDialogVehiculo,
      );
    }
    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
        itemCount: _vehiculos.length,
        itemBuilder: (_, i) => _buildVehiculoCard(_vehiculos[i]),
      ),
    );
  }

  Widget _buildVehiculoCard(VehiculoEmpresa v) {
    return GradientContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppSubtitle(v.placaNumero, fontSize: 13),
                    const SizedBox(width: 8),
                    _buildBadgeActivo(v.isActive),
                  ],
                ),
                if (v.marca != null || v.modelo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${v.marca ?? ''} - ${v.modelo ?? ''}'.trim(),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                if (v.tuc != null && v.tuc!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'TUC: ${v.tuc}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: AppColors.blue1),
            onPressed: () => _mostrarDialogVehiculo(vehiculo: v),
            tooltip: 'Editar',
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2 - CONDUCTORES
  // ===========================================================================

  Widget _buildConductoresTab() {
    if (_conductores.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person,
        mensaje: 'No hay conductores registrados',
        onTap: _mostrarDialogConductor,
      );
    }
    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
        itemCount: _conductores.length,
        itemBuilder: (_, i) => _buildConductorCard(_conductores[i]),
      ),
    );
  }

  Widget _buildConductorCard(ConductorEmpresa c) {
    return GradientContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: AppSubtitle(c.nombreCompleto, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    _buildBadgeActivo(c.isActive),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'DNI: ${c.numeroDocumento}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Licencia: ${c.numeroLicencia}${c.categoriaLicencia != null ? ' - ${c.categoriaLicencia}' : ''}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: AppColors.blue1),
            onPressed: () => _mostrarDialogConductor(conductor: c),
            tooltip: 'Editar',
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3 - TRANSPORTISTAS
  // ===========================================================================

  Widget _buildTransportistasTab() {
    if (_transportistas.isEmpty) {
      return _buildEmptyState(
        icon: Icons.business,
        mensaje: 'No hay transportistas registrados',
        onTap: _mostrarDialogTransportista,
      );
    }
    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
        itemCount: _transportistas.length,
        itemBuilder: (_, i) => _buildTransportistaCard(_transportistas[i]),
      ),
    );
  }

  Widget _buildTransportistaCard(TransportistaEmpresa t) {
    return GradientContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: AppSubtitle(t.razonSocial, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    _buildBadgeActivo(t.isActive),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'RUC: ${t.ruc}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
                if (t.registroMtc != null && t.registroMtc!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Registro MTC: ${t.registroMtc}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: AppColors.blue1),
            onPressed: () => _mostrarDialogTransportista(transportista: t),
            tooltip: 'Editar',
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // COMMON WIDGETS
  // ===========================================================================

  Widget _buildBadgeActivo(bool activo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: activo
            ? AppColors.green.withValues(alpha: 0.15)
            : Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: activo ? AppColors.greendark : Colors.red.shade700,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String mensaje,
    required VoidCallback onTap,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            mensaje,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Agregar primero',
            onPressed: onTap,
            borderColor: AppColors.blue1,
            textColor: AppColors.blue1,
            isOutlined: true,
            height: 34,
            fontSize: 11,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DIALOG - VEHICULO
  // ===========================================================================

  void _mostrarDialogVehiculo({VehiculoEmpresa? vehiculo}) {
    final isEdit = vehiculo != null;
    final placaCtrl = TextEditingController(text: vehiculo?.placaNumero ?? '');
    final marcaCtrl = TextEditingController(text: vehiculo?.marca ?? '');
    final modeloCtrl = TextEditingController(text: vehiculo?.modelo ?? '');
    final tucCtrl = TextEditingController(text: vehiculo?.tuc ?? '');
    bool saving = false;
    bool searching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Icon(Icons.local_shipping,
                            color: AppColors.blue1, size: 20),
                        const SizedBox(width: 8),
                        AppSubtitle(
                          isEdit ? 'Editar Vehiculo' : 'Nuevo Vehiculo',
                          fontSize: 14,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Placa + Search
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: CustomText(
                            label: 'Placa',
                            controller: placaCtrl,
                            borderColor: AppColors.blue1,
                            textCase: TextCase.upper,
                            required: true,
                            hintText: 'Ej: ABC-123',
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 33,
                          width: 40,
                          child: IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.blue1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: searching
                                ? null
                                : () async {
                                    final placa = placaCtrl.text.trim();
                                    if (placa.isEmpty) return;
                                    setDialogState(() => searching = true);
                                    try {
                                      final useCase =
                                          locator<ConsultarPlacaUseCase>();
                                      final result = await useCase(placa);
                                      if (result is Success) {
                                        final data = (result as Success).data;
                                        marcaCtrl.text = data.marca;
                                        modeloCtrl.text = data.modelo;
                                      } else if (result is Error) {
                                        if (ctx.mounted) {
                                          ScaffoldMessenger.of(ctx).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  (result as Error).message),
                                            ),
                                          );
                                        }
                                      }
                                    } catch (_) {}
                                    setDialogState(() => searching = false);
                                  },
                            icon: searching
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5, color: Colors.white),
                                  )
                                : const Icon(Icons.search,
                                    color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Marca
                    CustomText(
                      label: 'Marca',
                      controller: marcaCtrl,
                      borderColor: AppColors.blue1,
                    ),
                    const SizedBox(height: 10),

                    // Modelo
                    CustomText(
                      label: 'Modelo',
                      controller: modeloCtrl,
                      borderColor: AppColors.blue1,
                    ),
                    const SizedBox(height: 10),

                    // TUC
                    CustomText(
                      label: 'TUC (Tarjeta Unica Circulacion)',
                      controller: tucCtrl,
                      borderColor: AppColors.blue1,
                    ),
                    const SizedBox(height: 16),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Cancelar',
                            onPressed: () => Navigator.pop(ctx),
                            isOutlined: true,
                            borderColor: Colors.grey,
                            textColor: Colors.grey,
                            height: 36,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: 'Guardar',
                            isLoading: saving,
                            onPressed: saving
                                ? null
                                : () async {
                                    final placa = placaCtrl.text.trim();
                                    if (placa.isEmpty) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('La placa es obligatoria')),
                                      );
                                      return;
                                    }
                                    setDialogState(() => saving = true);
                                    try {
                                      final data = {
                                        'placaNumero': placa.toUpperCase(),
                                        if (marcaCtrl.text.trim().isNotEmpty)
                                          'marca': marcaCtrl.text.trim(),
                                        if (modeloCtrl.text.trim().isNotEmpty)
                                          'modelo': modeloCtrl.text.trim(),
                                        if (tucCtrl.text.trim().isNotEmpty)
                                          'tuc': tucCtrl.text.trim(),
                                      };
                                      if (isEdit) {
                                        // TODO: actualizarVehiculo via datasource PUT when available
                                        data['id'] = vehiculo.id;
                                        await _datasource.crearVehiculo(data);
                                      } else {
                                        await _datasource.crearVehiculo(data);
                                      }
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      _cargarDatos();
                                    } catch (e) {
                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Error: ${e.toString()}')),
                                        );
                                      }
                                    }
                                    setDialogState(() => saving = false);
                                  },
                            borderColor: AppColors.blue1,
                            backgroundColor: AppColors.blue1,
                            textColor: Colors.white,
                            height: 36,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // DIALOG - CONDUCTOR
  // ===========================================================================

  void _mostrarDialogConductor({ConductorEmpresa? conductor}) {
    final isEdit = conductor != null;
    final dniCtrl =
        TextEditingController(text: conductor?.numeroDocumento ?? '');
    final nombreCtrl = TextEditingController(text: conductor?.nombre ?? '');
    final apellidosCtrl =
        TextEditingController(text: conductor?.apellidos ?? '');
    final licenciaCtrl =
        TextEditingController(text: conductor?.numeroLicencia ?? '');
    final categoriaCtrl =
        TextEditingController(text: conductor?.categoriaLicencia ?? '');
    bool saving = false;
    bool searching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Icon(Icons.person,
                            color: AppColors.blue1, size: 20),
                        const SizedBox(width: 8),
                        AppSubtitle(
                          isEdit ? 'Editar Conductor' : 'Nuevo Conductor',
                          fontSize: 14,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // DNI + Search
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: CustomText(
                            label: 'DNI',
                            controller: dniCtrl,
                            borderColor: AppColors.blue1,
                            required: true,
                            keyboardType: TextInputType.number,
                            maxLength: 8,
                            hintText: '8 digitos',
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 33,
                          width: 40,
                          child: IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.blue1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: searching
                                ? null
                                : () async {
                                    final dni = dniCtrl.text.trim();
                                    if (dni.length != 8) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'DNI debe tener 8 digitos')),
                                      );
                                      return;
                                    }
                                    setDialogState(() => searching = true);
                                    try {
                                      final useCase =
                                          locator<ConsultarLicenciaUseCase>();
                                      final result = await useCase(dni);
                                      if (result is Success) {
                                        final data = (result as Success).data;
                                        nombreCtrl.text = data.nombres;
                                        apellidosCtrl.text = data.apellidos;
                                        licenciaCtrl.text =
                                            data.licenciaNumero;
                                        categoriaCtrl.text =
                                            data.licenciaCategoria;
                                      } else if (result is Error) {
                                        if (ctx.mounted) {
                                          ScaffoldMessenger.of(ctx).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  (result as Error).message),
                                            ),
                                          );
                                        }
                                      }
                                    } catch (_) {}
                                    setDialogState(() => searching = false);
                                  },
                            icon: searching
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5, color: Colors.white),
                                  )
                                : const Icon(Icons.search,
                                    color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Nombre
                    CustomText(
                      label: 'Nombre',
                      controller: nombreCtrl,
                      borderColor: AppColors.blue1,
                      required: true,
                    ),
                    const SizedBox(height: 10),

                    // Apellidos
                    CustomText(
                      label: 'Apellidos',
                      controller: apellidosCtrl,
                      borderColor: AppColors.blue1,
                      required: true,
                    ),
                    const SizedBox(height: 10),

                    // Numero Licencia
                    CustomText(
                      label: 'Numero Licencia',
                      controller: licenciaCtrl,
                      borderColor: AppColors.blue1,
                      required: true,
                      textCase: TextCase.upper,
                    ),
                    const SizedBox(height: 10),

                    // Categoria Licencia
                    CustomText(
                      label: 'Categoria Licencia',
                      controller: categoriaCtrl,
                      borderColor: AppColors.blue1,
                      textCase: TextCase.upper,
                    ),
                    const SizedBox(height: 16),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Cancelar',
                            onPressed: () => Navigator.pop(ctx),
                            isOutlined: true,
                            borderColor: Colors.grey,
                            textColor: Colors.grey,
                            height: 36,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: 'Guardar',
                            isLoading: saving,
                            onPressed: saving
                                ? null
                                : () async {
                                    final dni = dniCtrl.text.trim();
                                    final nombre = nombreCtrl.text.trim();
                                    final apellidos = apellidosCtrl.text.trim();
                                    final licencia = licenciaCtrl.text.trim();
                                    if (dni.isEmpty ||
                                        nombre.isEmpty ||
                                        apellidos.isEmpty ||
                                        licencia.isEmpty) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Complete los campos obligatorios')),
                                      );
                                      return;
                                    }
                                    setDialogState(() => saving = true);
                                    try {
                                      final data = {
                                        'tipoDocumento': '1',
                                        'numeroDocumento': dni,
                                        'nombre': nombre,
                                        'apellidos': apellidos,
                                        'numeroLicencia':
                                            licencia.toUpperCase(),
                                        if (categoriaCtrl.text
                                            .trim()
                                            .isNotEmpty)
                                          'categoriaLicencia': categoriaCtrl
                                              .text
                                              .trim()
                                              .toUpperCase(),
                                      };
                                      if (isEdit) {
                                        // TODO: actualizarConductor via datasource PUT when available
                                        data['id'] = conductor.id;
                                        await _datasource
                                            .crearConductor(data);
                                      } else {
                                        await _datasource
                                            .crearConductor(data);
                                      }
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      _cargarDatos();
                                    } catch (e) {
                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Error: ${e.toString()}')),
                                        );
                                      }
                                    }
                                    setDialogState(() => saving = false);
                                  },
                            borderColor: AppColors.blue1,
                            backgroundColor: AppColors.blue1,
                            textColor: Colors.white,
                            height: 36,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // DIALOG - TRANSPORTISTA
  // ===========================================================================

  void _mostrarDialogTransportista({TransportistaEmpresa? transportista}) {
    final isEdit = transportista != null;
    final rucCtrl = TextEditingController(text: transportista?.ruc ?? '');
    final razonSocialCtrl =
        TextEditingController(text: transportista?.razonSocial ?? '');
    final direccionCtrl =
        TextEditingController(text: transportista?.direccion ?? '');
    final telefonoCtrl =
        TextEditingController(text: transportista?.telefono ?? '');
    final emailCtrl = TextEditingController(text: transportista?.email ?? '');
    final mtcCtrl =
        TextEditingController(text: transportista?.registroMtc ?? '');
    bool saving = false;
    bool searching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Icon(Icons.business,
                            color: AppColors.blue1, size: 20),
                        const SizedBox(width: 8),
                        AppSubtitle(
                          isEdit
                              ? 'Editar Transportista'
                              : 'Nuevo Transportista',
                          fontSize: 14,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // RUC + Search
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: CustomText(
                            label: 'RUC',
                            controller: rucCtrl,
                            borderColor: AppColors.blue1,
                            required: true,
                            keyboardType: TextInputType.number,
                            maxLength: 11,
                            hintText: '11 digitos',
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 33,
                          width: 40,
                          child: IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.blue1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: searching
                                ? null
                                : () async {
                                    final ruc = rucCtrl.text.trim();
                                    if (ruc.length != 11) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'RUC debe tener 11 digitos')),
                                      );
                                      return;
                                    }
                                    setDialogState(() => searching = true);
                                    try {
                                      final useCase =
                                          locator<ConsultarRucUseCase>();
                                      final result = await useCase(ruc);
                                      if (result is Success) {
                                        final data = (result as Success).data;
                                        razonSocialCtrl.text =
                                            data.razonSocial;
                                        direccionCtrl.text =
                                            data.direccionCompleta;
                                      } else if (result is Error) {
                                        if (ctx.mounted) {
                                          ScaffoldMessenger.of(ctx).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  (result as Error).message),
                                            ),
                                          );
                                        }
                                      }
                                    } catch (_) {}
                                    setDialogState(() => searching = false);
                                  },
                            icon: searching
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5, color: Colors.white),
                                  )
                                : const Icon(Icons.search,
                                    color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Razon Social
                    CustomText(
                      label: 'Razon Social',
                      controller: razonSocialCtrl,
                      borderColor: AppColors.blue1,
                      required: true,
                    ),
                    const SizedBox(height: 10),

                    // Direccion
                    CustomText(
                      label: 'Direccion',
                      controller: direccionCtrl,
                      borderColor: AppColors.blue1,
                    ),
                    const SizedBox(height: 10),

                    // Telefono
                    CustomText(
                      label: 'Telefono',
                      controller: telefonoCtrl,
                      borderColor: AppColors.blue1,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),

                    // Email
                    CustomText(
                      label: 'Email',
                      controller: emailCtrl,
                      borderColor: AppColors.blue1,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 10),

                    // Registro MTC
                    CustomText(
                      label: 'Registro MTC',
                      controller: mtcCtrl,
                      borderColor: AppColors.blue1,
                    ),
                    const SizedBox(height: 16),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Cancelar',
                            onPressed: () => Navigator.pop(ctx),
                            isOutlined: true,
                            borderColor: Colors.grey,
                            textColor: Colors.grey,
                            height: 36,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: 'Guardar',
                            isLoading: saving,
                            onPressed: saving
                                ? null
                                : () async {
                                    final ruc = rucCtrl.text.trim();
                                    final razon = razonSocialCtrl.text.trim();
                                    if (ruc.isEmpty || razon.isEmpty) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'RUC y Razon Social son obligatorios')),
                                      );
                                      return;
                                    }
                                    setDialogState(() => saving = true);
                                    try {
                                      final data = {
                                        'ruc': ruc,
                                        'razonSocial': razon,
                                        if (direccionCtrl.text
                                            .trim()
                                            .isNotEmpty)
                                          'direccion':
                                              direccionCtrl.text.trim(),
                                        if (telefonoCtrl.text
                                            .trim()
                                            .isNotEmpty)
                                          'telefono':
                                              telefonoCtrl.text.trim(),
                                        if (emailCtrl.text.trim().isNotEmpty)
                                          'email': emailCtrl.text.trim(),
                                        if (mtcCtrl.text.trim().isNotEmpty)
                                          'registroMtc':
                                              mtcCtrl.text.trim(),
                                      };
                                      if (isEdit) {
                                        // TODO: actualizarTransportista via datasource PUT when available
                                        data['id'] = transportista.id;
                                        await _datasource
                                            .crearTransportista(data);
                                      } else {
                                        await _datasource
                                            .crearTransportista(data);
                                      }
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      _cargarDatos();
                                    } catch (e) {
                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Error: ${e.toString()}')),
                                        );
                                      }
                                    }
                                    setDialogState(() => saving = false);
                                  },
                            borderColor: AppColors.blue1,
                            backgroundColor: AppColors.blue1,
                            textColor: Colors.white,
                            height: 36,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
