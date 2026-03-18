import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text.dart' show CustomText, FieldType;
import '../../../../core/widgets/custom_switch_tile.dart';
import '../../../../core/widgets/info_chip.dart';
import '../../data/datasources/empresa_remote_datasource.dart';
import '../../domain/entities/empresa_info.dart';
import '../bloc/empresa_context/empresa_context_cubit.dart';
import '../bloc/empresa_context/empresa_context_state.dart';

class EmpresaProfilePage extends StatefulWidget {
  const EmpresaProfilePage({super.key});

  @override
  State<EmpresaProfilePage> createState() => _EmpresaProfilePageState();
}

class _EmpresaProfilePageState extends State<EmpresaProfilePage> {
  final _subdominioController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _webController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _descripcionTercerizacionController = TextEditingController();
  final _datasource = locator<EmpresaRemoteDataSource>();
  final _localStorage = locator<LocalStorageService>();

  bool _isSaving = false;
  bool _initialized = false;
  bool _aceptaTercerizacion = false;
  List<String> _tiposServicioTercerizacion = [];

  @override
  void dispose() {
    _subdominioController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _webController.dispose();
    _descripcionController.dispose();
    _descripcionTercerizacionController.dispose();
    super.dispose();
  }

  void _initControllers(EmpresaInfo empresa) {
    if (_initialized) return;
    _subdominioController.text = empresa.subdominio ?? '';
    _telefonoController.text = empresa.telefono ?? '';
    _emailController.text = empresa.email ?? '';
    _webController.text = empresa.web ?? '';
    _descripcionController.text = empresa.descripcion ?? '';
    _aceptaTercerizacion = empresa.aceptaTercerizacion;
    _descripcionTercerizacionController.text = empresa.descripcionTercerizacion ?? '';
    _tiposServicioTercerizacion = List.from(empresa.tiposServicioTercerizacion);
    _initialized = true;
  }

  Future<void> _saveChanges() async {
    final empresaId = _localStorage.getString(StorageConstants.tenantId);
    if (empresaId == null) return;

    setState(() => _isSaving = true);

    try {
      await _datasource.updateEmpresa(
        empresaId: empresaId,
        data: {
          if (_subdominioController.text.isNotEmpty)
            'subdominio': _subdominioController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), ''),
          'telefono': _telefonoController.text.isEmpty
              ? null
              : _telefonoController.text,
          'email':
              _emailController.text.isEmpty ? null : _emailController.text,
          'web': _webController.text.isEmpty ? null : _webController.text,
          'descripcion': _descripcionController.text.isEmpty
              ? null
              : _descripcionController.text,
          'aceptaTercerizacion': _aceptaTercerizacion,
          'descripcionTercerizacion':
              _descripcionTercerizacionController.text.isEmpty
                  ? null
                  : _descripcionTercerizacionController.text,
          'tiposServicioTercerizacion': _tiposServicioTercerizacion,
        },
      );

      if (!mounted) return;

      await context.read<EmpresaContextCubit>().reloadContext();

      if (!mounted) return;

      SnackBarHelper.showSuccess(context, 'Datos actualizados correctamente');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
      builder: (context, state) {
        if (state is! EmpresaContextLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final empresa = state.context.empresa;
        _initControllers(empresa);

        return GradientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: SmartAppBar(title: 'Perfil de Empresa'),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  _buildHeader(context, empresa),
                  const SizedBox(height: 12),
                  _buildSunatSection(context, empresa),
                  const SizedBox(height: 12),
                  _buildUbicacionSection(context, empresa),
                  const SizedBox(height: 12),
                  _buildContactSection(context),
                  const SizedBox(height: 12),
                  _buildTercerizacionSection(context),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Guardar Cambios',
                    isLoading: _isSaving,
                    icon: const Icon(Icons.save_outlined,
                        color: Colors.white, size: 18),
                    onPressed: _isSaving ? null : _saveChanges,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, EmpresaInfo empresa) {
    return GradientContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => context.push('/empresa/personalizacion'),
              child: Stack(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: Colors.grey.shade300, width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.5),
                      child: empresa.logo != null && empresa.logo!.isNotEmpty
                          ? Image.network(
                              empresa.logo!,
                              width: 84,
                              height: 84,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildInitial(empresa.nombre),
                            )
                          : _buildInitial(empresa.nombre),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.blue2,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              empresa.nombre,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                if (empresa.rubro != null && empresa.rubro!.isNotEmpty)
                  _buildBadge(
                    empresa.rubro!,
                    Colors.blue,
                    Icons.storefront,
                  ),
                _buildBadge(
                  empresa.estadoSuscripcion,
                  empresa.isSubscriptionActive ? Colors.green : Colors.orange,
                  empresa.isSubscriptionActive
                      ? Icons.check_circle
                      : Icons.warning_amber_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitial(String nombre) {
    final initial = (nombre.isNotEmpty ? nombre[0] : '?').toUpperCase();
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.blue2),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSunatSection(BuildContext context, EmpresaInfo empresa) {
    return GradientContainer(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Datos SUNAT', Icons.assured_workload),
            const SizedBox(height: 14),
            if (empresa.razonSocial != null) ...[
              _InfoRow(
                  icon: Icons.business,
                  label: 'Razón Social',
                  value: empresa.razonSocial!),
              const Divider(height: 16),
            ],
            if (empresa.ruc != null) ...[
              _InfoRow(
                  icon: Icons.numbers,
                  label: 'RUC',
                  value: empresa.ruc!),
              const Divider(height: 16),
            ],
            if (empresa.tipoContribuyente != null) ...[
              _InfoRow(
                  icon: Icons.account_balance,
                  label: 'Tipo Contribuyente',
                  value: empresa.tipoContribuyente!),
              const Divider(height: 16),
            ],
            if (empresa.estadoContribuyente != null) ...[
              _InfoRow(
                  icon: Icons.verified_user,
                  label: 'Estado Contribuyente',
                  value: empresa.estadoContribuyente!),
              const Divider(height: 16),
            ],
            if (empresa.condicionContribuyente != null)
              _InfoRow(
                  icon: Icons.fact_check,
                  label: 'Condición Contribuyente',
                  value: empresa.condicionContribuyente!),
            if (_allSunatNull(empresa))
              _InfoRow(
                  icon: Icons.info_outline,
                  label: 'Sin datos',
                  value: 'No se encontraron datos SUNAT'),
          ],
        ),
      ),
    );
  }

  bool _allSunatNull(EmpresaInfo e) =>
      e.razonSocial == null &&
      e.ruc == null &&
      e.tipoContribuyente == null &&
      e.estadoContribuyente == null &&
      e.condicionContribuyente == null;

  Widget _buildUbicacionSection(BuildContext context, EmpresaInfo empresa) {
    final hasData = empresa.direccionFiscal != null ||
        empresa.departamento != null ||
        empresa.provincia != null ||
        empresa.distrito != null;

    return GradientContainer(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Ubicación Fiscal', Icons.location_on_outlined),
            const SizedBox(height: 14),
            if (empresa.direccionFiscal != null) ...[
              _InfoRow(
                  icon: Icons.location_on,
                  label: 'Dirección Fiscal',
                  value: empresa.direccionFiscal!),
              const Divider(height: 16),
            ],
            if (empresa.departamento != null) ...[
              _InfoRow(
                  icon: Icons.map,
                  label: 'Departamento',
                  value: empresa.departamento!),
              const Divider(height: 16),
            ],
            if (empresa.provincia != null) ...[
              _InfoRow(
                  icon: Icons.location_city,
                  label: 'Provincia',
                  value: empresa.provincia!),
              const Divider(height: 16),
            ],
            if (empresa.distrito != null)
              _InfoRow(
                  icon: Icons.place,
                  label: 'Distrito',
                  value: empresa.distrito!),
            if (!hasData)
              _InfoRow(
                  icon: Icons.info_outline,
                  label: 'Sin datos',
                  value: 'No se encontró ubicación fiscal'),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return GradientContainer(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Información de Contacto', Icons.contact_mail_outlined),
            const SizedBox(height: 6),
            Text(
              'Estos datos son editables y se muestran públicamente.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),
            CustomText(
              controller: _subdominioController,
              borderColor: AppColors.blue1,
              label: 'Subdominio (URL de tu tienda web)',
              hintText: 'Ej: mi-tienda',
              prefixIcon: const Icon(Icons.link),
            ),
            if (_subdominioController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  'tienda.syncronize.net.pe/${_subdominioController.text}',
                  style: TextStyle(fontSize: 11, color: AppColors.blue1),
                ),
              ),
            const SizedBox(height: 14),
            CustomText(
              controller: _telefonoController,
              borderColor: AppColors.blue1,
              label: 'Teléfono',
              hintText: 'Ej: +51 999 888 777',
              fieldType: FieldType.number,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            const SizedBox(height: 14),
            CustomText(
              controller: _emailController,
              borderColor: AppColors.blue1,
              label: 'Email',
              hintText: 'contacto@miempresa.com',
              fieldType: FieldType.email,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            const SizedBox(height: 14),
            CustomText(
              controller: _webController,
              borderColor: AppColors.blue1,
              label: 'Sitio Web',
              hintText: 'https://miempresa.com',
              prefixIcon: const Icon(Icons.language),
            ),
            const SizedBox(height: 14),
            CustomText(
              controller: _descripcionController,
              borderColor: AppColors.blue1,
              label: 'Descripción',
              hintText: 'Describe tu empresa...',
              prefixIcon: const Icon(Icons.description_outlined),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildTercerizacionSection(BuildContext context) {
    const tiposDisponibles = [
      'REPARACION',
      'MANTENIMIENTO',
      'INSTALACION',
      'DIAGNOSTICO',
      'ACTUALIZACION',
      'LIMPIEZA',
      'RECUPERACION_DATOS',
      'CONFIGURACION',
      'CONSULTORIA',
      'FORMACION',
      'SOPORTE',
    ];

    const tipoLabels = {
      'REPARACION': 'Reparación',
      'MANTENIMIENTO': 'Mantenimiento',
      'INSTALACION': 'Instalación',
      'DIAGNOSTICO': 'Diagnóstico',
      'ACTUALIZACION': 'Actualización',
      'LIMPIEZA': 'Limpieza',
      'RECUPERACION_DATOS': 'Recuperación datos',
      'CONFIGURACION': 'Configuración',
      'CONSULTORIA': 'Consultoría',
      'FORMACION': 'Formación',
      'SOPORTE': 'Soporte',
    };

    return GradientContainer(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
                context, 'Tercerización B2B', Icons.swap_horiz),
            const SizedBox(height: 6),
            Text(
              'Permite que otras empresas te envíen servicios para tercerizar.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 12),
            CustomSwitchTile(
              title: 'Acepto tercerización',
              value: _aceptaTercerizacion,
              onChanged: (v) => setState(() => _aceptaTercerizacion = v),
              activeColor: AppColors.blue2,
            ),
            if (_aceptaTercerizacion) ...[
              const SizedBox(height: 14),
              CustomText(
                controller: _descripcionTercerizacionController,
                label: 'Descripción del servicio B2B',
                hintText: 'Ej: Reparamos laptops, PCs y equipos de red',
                prefixIcon: const Icon(Icons.description_outlined),
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Tipos de servicio que aceptas',
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.grey.shade300, width: 0.5),
                    borderRadius:
                        const BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: AppColors.blue2, width: 0.5),
                    borderRadius:
                        const BorderRadius.all(Radius.circular(8)),
                  ),
                  border: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.grey.shade300, width: 0.5),
                    borderRadius:
                        const BorderRadius.all(Radius.circular(8)),
                  ),
                  helperText: 'Selecciona los servicios que tu empresa puede atender',
                ),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tiposDisponibles.map((tipo) {
                    final selected =
                        _tiposServicioTercerizacion.contains(tipo);
                    return InfoChip(
                      borderRadius: 6,
                      text: tipoLabels[tipo] ?? tipo,
                      selected: selected,
                      showCheckmark: true,
                      borderColor: AppColors.blue2,
                      borderWidth: 0.5,
                      selectedBackgroundColor: AppColors.blue2,
                      selectedTextColor: Colors.white,
                      selectedBorderColor: AppColors.blue2,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _tiposServicioTercerizacion.add(tipo);
                          } else {
                            _tiposServicioTercerizacion.remove(tipo);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: AppColors.blue2.withValues(alpha: 0.7)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 1),
              AppSubtitle(value),
            ],
          ),
        ),
      ],
    );
  }
}

extension on Color {
  Color get shade700 {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
  }
}
