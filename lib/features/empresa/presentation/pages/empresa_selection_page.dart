import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../auth/domain/usecases/refresh_token_usecase.dart';
import '../../../../core/utils/role_navigation_helper.dart';
import '../../domain/entities/empresa_list_item.dart';
import '../../domain/usecases/get_user_empresas_usecase.dart';
import '../../domain/usecases/switch_empresa_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Página inteligente de selección de empresa
/// Maneja automáticamente los casos:
/// - 0 empresas: Redirige a crear empresa
/// - 1 empresa: Selecciona automáticamente y va al dashboard
/// - 2+ empresas: Muestra selector
class EmpresaSelectionPage extends StatefulWidget {
  const EmpresaSelectionPage({super.key});

  @override
  State<EmpresaSelectionPage> createState() => _EmpresaSelectionPageState();
}

class _EmpresaSelectionPageState extends State<EmpresaSelectionPage> {
  final _getUserEmpresasUseCase = locator<GetUserEmpresasUseCase>();
  final _switchEmpresaUseCase = locator<SwitchEmpresaUseCase>();
  final _refreshTokenUseCase = locator<RefreshTokenUseCase>();
  final _localStorage = locator<LocalStorageService>();
  final _secureStorage = locator<SecureStorageService>();

  bool _isLoading = true;
  List<EmpresaListItem> _empresas = [];
  bool _isSelecting = false;
  String? _selectingId;

  @override
  void initState() {
    super.initState();
    _loadEmpresas();
  }

  Future<void> _loadEmpresas() async {
    setState(() => _isLoading = true);

    final result = await _getUserEmpresasUseCase();

    if (!mounted) return;

    if (result is Success<List<EmpresaListItem>>) {
      final empresas = (result).data;

      setState(() {
        _empresas = empresas;
        _isLoading = false;
      });

      // Manejar casos automáticamente
      if (empresas.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.pushReplacement('/create-empresa');
          }
        });
      } else if (empresas.length == 1) {
        _selectEmpresa(empresas.first);
      }
    } else {
      setState(() => _isLoading = false);
      SnackBarHelper.showError(context, 'Error al cargar empresas');
    }
  }

  Future<void> _selectEmpresa(EmpresaListItem empresa) async {
    if (_isSelecting) return;

    setState(() {
      _isSelecting = true;
      _selectingId = empresa.id;
    });

    final result = await _switchEmpresaUseCase(
      empresaId: empresa.id,
      subdominio: empresa.subdominio,
      empresaNombre: empresa.nombre,
      empresaRole: empresa.primaryRole,
    );

    if (!mounted) return;

    if (result is Success) {
      // Refrescar JWT para obtener tokens con los roles de la nueva empresa
      final currentRefreshToken = await _secureStorage.read(
        key: StorageConstants.refreshToken,
      );
      if (currentRefreshToken != null) {
        final refreshResult = await _refreshTokenUseCase(
          RefreshTokenParams(refreshToken: currentRefreshToken),
        );
        if (refreshResult is Success) {
          final tokens = (refreshResult as Success).data;
          await _secureStorage.write(
            key: StorageConstants.accessToken,
            value: tokens.accessToken,
          );
          await _secureStorage.write(
            key: StorageConstants.refreshToken,
            value: tokens.refreshToken,
          );
        }
      }

      // tenantId y tenantName ya fueron guardados por el repository
      if (empresa.primaryRole != null) {
        await _localStorage.setString(StorageConstants.tenantRole, empresa.primaryRole!);
      }
      await _localStorage.setString(StorageConstants.loginMode, 'management');

      if (!mounted) return;
      context.go(RoleNavigationHelper.getEmpresaRoute());
    } else if (result is Error) {
      setState(() {
        _isSelecting = false;
        _selectingId = null;
      });
      SnackBarHelper.showError(context, (result).message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(title: 'Mis Empresas'),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.blue2))
            : RefreshIndicator(
                onRefresh: _loadEmpresas,
                color: AppColors.blue2,
                child: Column(
                  children: [
                    // Header informativo
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: GradientContainer(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.blue2.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.business_center,
                                  color: AppColors.blue2,
                                  size: 25,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppTitle(
                                      'Tus Empresas',
                                      font: AppFont.pirulentBold,
                                      fontSize: 10,
                                    ),
                                    const SizedBox(height: 4),
                                    AppSubtitle(
                                      'Selecciona la empresa que deseas gestionar',
                                      fontSize: 10,
                                      color: AppColors.blueGrey,
                                    ),
                                  ],
                                ),
                              ),
                              // Badge con cantidad
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.blue2.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: AppSubtitle(
                                  '${_empresas.length}',
                                  fontSize: 12,
                                  color: AppColors.blue2,
                                  font: AppFont.pirulentBold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Lista de empresas agrupadas por tipo
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final misEmpresas = _empresas.where((e) => !e.isOnlyCliente).toList();
                          final clienteEn = _empresas.where((e) => e.isOnlyCliente).toList();

                          return ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            children: [
                              // Sección: Mis empresas (admin, empleado)
                              if (misEmpresas.isNotEmpty) ...[
                                _SectionHeader(
                                  icon: Icons.business,
                                  title: 'Mis Empresas',
                                  count: misEmpresas.length,
                                ),
                                ...misEmpresas.map((empresa) {
                                  final isThisSelecting = _selectingId == empresa.id;
                                  return _EmpresaCard(
                                    empresa: empresa,
                                    isSelecting: isThisSelecting,
                                    isDisabled: _isSelecting && !isThisSelecting,
                                    onTap: () => _selectEmpresa(empresa),
                                  );
                                }),
                              ],

                              // Separador
                              if (misEmpresas.isNotEmpty && clienteEn.isNotEmpty)
                                const SizedBox(height: 8),

                              // Sección: Soy cliente en
                              if (clienteEn.isNotEmpty) ...[
                                _SectionHeader(
                                  icon: Icons.person_outline,
                                  title: 'Soy cliente en',
                                  count: clienteEn.length,
                                ),
                                ...clienteEn.map((empresa) {
                                  final isThisSelecting = _selectingId == empresa.id;
                                  return _EmpresaCard(
                                    empresa: empresa,
                                    isSelecting: isThisSelecting,
                                    isDisabled: _isSelecting && !isThisSelecting,
                                    onTap: () => _selectEmpresa(empresa),
                                  );
                                }),
                              ],
                            ],
                          );
                        },
                      ),
                    ),

                    // Botón crear empresa
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          return CustomButton(
                            text: 'Crear Nueva Empresa',
                            icon: const Icon(Icons.add_business, color: Colors.white, size: 20),
                            onPressed: () {
                              if (state is Authenticated && !state.user.perfilCompleto) {
                                context.push('/complete-profile');
                              } else {
                                context.push('/create-empresa');
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.blue2),
          const SizedBox(width: 8),
          AppSubtitle(
            title,
            fontSize: 11,
            color: AppColors.blue2,
            font: AppFont.oxygenBold,
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.blue2.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                color: AppColors.blue2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: AppColors.blue2.withValues(alpha: 0.2),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmpresaCard extends StatelessWidget {
  final EmpresaListItem empresa;
  final bool isSelecting;
  final bool isDisabled;
  final VoidCallback onTap;

  const _EmpresaCard({
    required this.empresa,
    required this.isSelecting,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GradientContainer(
        borderColor: isSelecting ? AppColors.blue2 : AppColors.white,
        borderWidth: isSelecting ? 1.5 : 0.5,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: isDisabled ? null : onTap,
            child: Opacity(
              opacity: isDisabled ? 0.5 : 1.0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Logo o inicial
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.blue2.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: empresa.logo != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                empresa.logo!,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildInitial(),
                              ),
                            )
                          : _buildInitial(),
                    ),
                    const SizedBox(width: 14),

                    // Info de la empresa
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTitle(
                            empresa.nombre,
                            font: AppFont.oxygenBold,
                            fontSize: 11,
                          ),
                          if (empresa.ruc != null) ...[
                            const SizedBox(height: 2),
                            AppSubtitle(
                              'RUC: ${empresa.ruc}',
                              fontSize: 10,
                              color: AppColors.blueGrey,
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // Chip de suscripción
                              _StatusChip(
                                label: empresa.estadoSuscripcion,
                                isActive: empresa.isSubscriptionActive,
                              ),
                              if (empresa.planNombre != null) ...[
                                const SizedBox(width: 8),
                                _PlanChip(planNombre: empresa.planNombre!),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Indicador de selección
                    if (isSelecting)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.blue2,
                        ),
                      )
                    else
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.blueGrey,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitial() {
    final initial = empresa.nombre.isNotEmpty
        ? empresa.nombre[0].toUpperCase()
        : '?';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: AppFonts.getFontFamily(AppFont.pirulentBold),
          color: AppColors.blue2,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isActive;

  const _StatusChip({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.greenContainer
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.greenBorder
              : AppColors.warning.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.warning_amber_rounded,
            size: 12,
            color: isActive ? AppColors.greendark : AppColors.amberText,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
              color: isActive ? AppColors.greendark : AppColors.amberText,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  final String planNombre;

  const _PlanChip({required this.planNombre});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.bluechip,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        planNombre,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
          color: AppColors.blue2,
        ),
      ),
    );
  }
}
