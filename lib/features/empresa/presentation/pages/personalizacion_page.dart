import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_fonts.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../../../core/widgets/custom_switch_tile.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../data/datasources/empresa_remote_datasource.dart';
import '../../domain/entities/personalizacion_empresa.dart';
import '../../domain/usecases/get_personalizacion_usecase.dart';
import '../../domain/usecases/update_personalizacion_usecase.dart';
import '../bloc/empresa_context/empresa_context_cubit.dart';
import '../bloc/empresa_context/empresa_context_state.dart';

class PersonalizacionPage extends StatefulWidget {
  const PersonalizacionPage({super.key});

  @override
  State<PersonalizacionPage> createState() => _PersonalizacionPageState();
}

class _PersonalizacionPageState extends State<PersonalizacionPage> {
  final _getPersonalizacionUseCase = locator<GetPersonalizacionUseCase>();
  final _updatePersonalizacionUseCase = locator<UpdatePersonalizacionUseCase>();
  final _storageService = locator<StorageService>();
  final _empresaRemoteDataSource = locator<EmpresaRemoteDataSource>();
  final _localStorage = locator<LocalStorageService>();
  final _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  PersonalizacionEmpresa? _personalizacion;
  String? _errorMessage;

  // Logo upload state
  String? _currentLogoUrl;
  File? _selectedLogoFile;
  bool _isUploadingLogo = false;
  double _logoUploadProgress = 0.0;

  // Controllers
  final _bannerUrlController = TextEditingController();
  final _bannerTextoController = TextEditingController();
  final _splashUrlController = TextEditingController();
  final _dominioController = TextEditingController();

  // Colores
  Color _bannerColor = const Color(0xFF000000);
  Color _colorPrimario = const Color(0xFF007bff);
  Color _colorSecundario = const Color(0xFF6c757d);
  Color _colorAcento = const Color(0xFF28a745);
  Color _appColorTema = const Color(0xFF007bff);

  // Switches
  bool _mostrarPrecios = true;
  bool _mostrarContacto = true;
  bool _mostrarRedesSociales = false;
  bool _permitirRegistro = true;

  @override
  void initState() {
    super.initState();
    _loadPersonalizacion();
  }

  @override
  void dispose() {
    _bannerUrlController.dispose();
    _bannerTextoController.dispose();
    _splashUrlController.dispose();
    _dominioController.dispose();
    super.dispose();
  }

  Future<void> _loadPersonalizacion() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final empresaId = _localStorage.getString(StorageConstants.tenantId);
    if (empresaId == null) {
      setState(() {
        _errorMessage = 'No hay empresa seleccionada';
        _isLoading = false;
      });
      return;
    }

    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _currentLogoUrl = empresaState.context.empresa.logo;
    }

    final result = await _getPersonalizacionUseCase(empresaId);

    if (!mounted) return;

    if (result is Success<PersonalizacionEmpresa>) {
      final p = result.data;
      setState(() {
        _personalizacion = p;
        _bannerUrlController.text = p.bannerPrincipalUrl ?? '';
        _bannerTextoController.text = p.bannerPrincipalTexto ?? '';
        _splashUrlController.text = p.appSplashScreenUrl ?? '';
        _dominioController.text = p.dominioPersonalizado ?? '';
        _bannerColor = _parseColor(p.bannerColor);
        _colorPrimario = _parseColor(p.colorPrimario);
        _colorSecundario = _parseColor(p.colorSecundario);
        _colorAcento = _parseColor(p.colorAcento);
        _appColorTema = _parseColor(p.appColorTema);
        _mostrarPrecios = p.mostrarPrecios;
        _mostrarContacto = p.mostrarContacto;
        _mostrarRedesSociales = p.mostrarRedesSociales;
        _permitirRegistro = p.permitirRegistro;
        _isLoading = false;
      });
    } else if (result is Error) {
      setState(() {
        _errorMessage = (result as Error).message;
        _isLoading = false;
      });
    }
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  String _colorToHex(Color color) {
    final r = ((color.r * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
    final g = ((color.g * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
    final b = ((color.b * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

  Future<void> _pickLogo(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _selectedLogoFile = File(picked.path));
      await _uploadLogo();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _uploadLogo() async {
    if (_selectedLogoFile == null) return;
    final empresaId = _localStorage.getString(StorageConstants.tenantId);
    if (empresaId == null) return;

    setState(() {
      _isUploadingLogo = true;
      _logoUploadProgress = 0.0;
    });

    try {
      final archivoResponse = await _storageService.uploadFile(
        file: _selectedLogoFile!,
        empresaId: empresaId,
        entidadTipo: 'EMPRESA',
        entidadId: empresaId,
        categoria: 'LOGO',
        onProgress: (progress) {
          if (mounted) setState(() => _logoUploadProgress = progress);
        },
      );

      await _empresaRemoteDataSource.updateEmpresaLogo(
        empresaId: empresaId,
        logoUrl: archivoResponse.url,
      );

      if (!mounted) return;
      await context.read<EmpresaContextCubit>().reloadContext();
      if (!mounted) return;

      setState(() {
        _currentLogoUrl = archivoResponse.url;
        _selectedLogoFile = null;
        _isUploadingLogo = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo actualizado'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingLogo = false;
        _selectedLogoFile = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir logo: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showLogoSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () { Navigator.pop(ctx); _pickLogo(ImageSource.gallery); },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.blue1.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.photo_library_outlined, color: AppColors.blue1, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const AppSubtitle('Seleccionar de galeria', fontSize: 12),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: () { Navigator.pop(ctx); _pickLogo(ImageSource.camera); },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.blue1.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.camera_alt_outlined, color: AppColors.blue1, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const AppSubtitle('Tomar foto', fontSize: 12),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _savePersonalizacion() async {
    if (_personalizacion == null) return;

    setState(() => _isSaving = true);

    final empresaId = _localStorage.getString(StorageConstants.tenantId)!;

    final updatedPersonalizacion = _personalizacion!.copyWith(
      bannerPrincipalUrl: _bannerUrlController.text.isEmpty ? null : _bannerUrlController.text,
      bannerPrincipalTexto: _bannerTextoController.text.isEmpty ? null : _bannerTextoController.text,
      bannerColor: _colorToHex(_bannerColor),
      colorPrimario: _colorToHex(_colorPrimario),
      colorSecundario: _colorToHex(_colorSecundario),
      colorAcento: _colorToHex(_colorAcento),
      mostrarPrecios: _mostrarPrecios,
      mostrarContacto: _mostrarContacto,
      mostrarRedesSociales: _mostrarRedesSociales,
      permitirRegistro: _permitirRegistro,
      appSplashScreenUrl: _splashUrlController.text.isEmpty ? null : _splashUrlController.text,
      appColorTema: _colorToHex(_appColorTema),
      dominioPersonalizado: _dominioController.text.isEmpty ? null : _dominioController.text,
    );

    final result = await _updatePersonalizacionUseCase(
      empresaId: empresaId,
      personalizacion: updatedPersonalizacion,
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (result is Success<PersonalizacionEmpresa>) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Personalización guardada'), backgroundColor: Colors.green),
      );
      setState(() => _personalizacion = result.data);
    } else if (result is Error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as Error).message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Personalización',
          backgroundColor: AppColors.blue1,
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CustomLoading())
            : _errorMessage != null
                ? _buildErrorView()
                : _buildContent(),
        bottomNavigationBar: (!_isLoading && _personalizacion != null)
            ? _buildBottomBar()
            : null,
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: CustomButton(
        text: 'Guardar cambios',
        icon: const Icon(Icons.save_outlined, size: 16, color: Colors.white),
        backgroundColor: AppColors.blue1,
        height: 40,
        borderRadius: 8,
        isLoading: _isSaving,
        loadingText: 'Guardando...',
        onPressed: _isSaving ? null : _savePersonalizacion,
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Reintentar',
              icon: const Icon(Icons.refresh, size: 14, color: Colors.white),
              backgroundColor: AppColors.blue1,
              height: 36,
              borderRadius: 8,
              onPressed: _loadPersonalizacion,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // ─── Logo ───
        _buildLogoCard(),
        const SizedBox(height: 12),

        // ─── Colores + Banner (card unificada) ───
        _buildColoresCard(),
        const SizedBox(height: 12),

        // ─── Multimedia ───
        _buildMultimediaCard(),
        const SizedBox(height: 12),

        // ─── Configuración ───
        _buildConfiguracionCard(),
        const SizedBox(height: 80),
      ],
    );
  }

  // ─── Logo Card ───

  Widget _buildLogoCard() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.blueborder,
      borderWidth: 0.6,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Logo de la empresa', Icons.business_outlined),
            const SizedBox(height: 4),
            AppLabelText(
              'Se muestra en el marketplace, drawer y listados',
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 14),

            // Logo preview
            Center(
              child: GestureDetector(
                onTap: _isUploadingLogo ? null : _showLogoSourceDialog,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.blueborder, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: _buildLogoPreview(),
                      ),
                    ),
                    if (!_isUploadingLogo)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.blue1,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (_isUploadingLogo) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _logoUploadProgress,
                  backgroundColor: Colors.grey.shade200,
                  color: AppColors.blue1,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: AppLabelText(
                  'Subiendo... ${(_logoUploadProgress * 100).toInt()}%',
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogoPreview() {
    if (_selectedLogoFile != null) {
      return Image.file(_selectedLogoFile!, width: 100, height: 100, fit: BoxFit.cover);
    }
    if (_currentLogoUrl != null && _currentLogoUrl!.isNotEmpty) {
      return Image.network(
        _currentLogoUrl!,
        width: 100, height: 100, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildLogoPlaceholder(),
      );
    }
    return _buildLogoPlaceholder();
  }

  Widget _buildLogoPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business, size: 32, color: Colors.grey.shade300),
          const SizedBox(height: 4),
          Text(
            'Sin logo',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade400,
              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Colores Card ───

  Widget _buildColoresCard() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.blueborder,
      borderWidth: 0.6,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Colores y tema', Icons.palette_outlined),
            const SizedBox(height: 4),
            AppLabelText(
              'Personaliza los colores de tu perfil en el marketplace',
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 14),

            // Color grid
            _buildColorRow('Primario', _colorPrimario, (c) => setState(() => _colorPrimario = c)),
            _buildColorRow('Secundario', _colorSecundario, (c) => setState(() => _colorSecundario = c)),
            _buildColorRow('Acento', _colorAcento, (c) => setState(() => _colorAcento = c)),
            _buildColorRow('Banner', _bannerColor, (c) => setState(() => _bannerColor = c)),

            _sectionDivider(),

            Row(
              children: [
                Icon(Icons.phone_android, size: 13, color: AppColors.blue1),
                const SizedBox(width: 6),
                Text(
                  'Color tema app movil',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildColorRow('Tema App', _appColorTema, (c) => setState(() => _appColorTema = c)),
          ],
        ),
      ),
    );
  }

  Widget _buildColorRow(String label, Color color, Function(Color) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showColorPickerDialog(label, color, onChanged),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                ),
              ),
            ),
            Text(
              _colorToHex(color),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.edit_outlined, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // ─── Multimedia Card ───

  Widget _buildMultimediaCard() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.blueborder,
      borderWidth: 0.6,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Multimedia', Icons.image_outlined),
            const SizedBox(height: 12),

            // Banner
            CustomText(
              controller: _bannerUrlController,
              label: 'URL del banner principal',
              hintText: 'https://ejemplo.com/banner.jpg',
              prefixIcon: const Icon(Icons.image_outlined, size: 16),
              borderColor: AppColors.blueborder,
            ),
            const SizedBox(height: 10),
            CustomText(
              controller: _bannerTextoController,
              label: 'Texto del banner',
              hintText: 'Bienvenidos a nuestra empresa',
              prefixIcon: const Icon(Icons.text_fields, size: 16),
              borderColor: AppColors.blueborder,
            ),

            _sectionDivider(),

            // App
            Row(
              children: [
                Icon(Icons.phone_android, size: 13, color: AppColors.blue1),
                const SizedBox(width: 6),
                Text(
                  'App movil',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CustomText(
              controller: _splashUrlController,
              label: 'URL del splash screen',
              hintText: 'https://ejemplo.com/splash.jpg',
              prefixIcon: const Icon(Icons.screenshot_outlined, size: 16),
              borderColor: AppColors.blueborder,
            ),

            _sectionDivider(),

            // Dominio
            Row(
              children: [
                Icon(Icons.language, size: 13, color: AppColors.blue1),
                const SizedBox(width: 6),
                Text(
                  'Dominio personalizado',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PREMIUM',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade700,
                      fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CustomText(
              controller: _dominioController,
              label: 'Dominio',
              hintText: 'www.miempresa.com',
              prefixIcon: const Icon(Icons.link, size: 16),
              borderColor: AppColors.blueborder,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Configuración Card ───

  Widget _buildConfiguracionCard() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.blueborder,
      borderWidth: 0.6,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Configuracion', Icons.tune_outlined),
            const SizedBox(height: 4),
            AppLabelText(
              'Configura que elementos mostrar en tu perfil publico',
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 12),

            CustomSwitchTile(
              title: 'Mostrar precios',
              subtitle: 'Mostrar precios de productos publicamente',
              value: _mostrarPrecios,
              onChanged: (v) => setState(() => _mostrarPrecios = v),
            ),
            const SizedBox(height: 6),
            CustomSwitchTile(
              title: 'Mostrar contacto',
              subtitle: 'Telefono, email y direccion visibles',
              value: _mostrarContacto,
              onChanged: (v) => setState(() => _mostrarContacto = v),
            ),
            const SizedBox(height: 6),
            CustomSwitchTile(
              title: 'Mostrar redes sociales',
              subtitle: 'Mostrar links a redes sociales',
              value: _mostrarRedesSociales,
              onChanged: (v) => setState(() => _mostrarRedesSociales = v),
            ),
            const SizedBox(height: 6),
            CustomSwitchTile(
              title: 'Permitir registro',
              subtitle: 'Los clientes pueden crear cuentas',
              value: _permitirRegistro,
              onChanged: (v) => setState(() => _permitirRegistro = v),
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.blue1.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.blueborder, width: 0.6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 14, color: AppColors.blue1),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Los cambios se aplicaran en el marketplace web y la app movil despues de guardar.',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        height: 1.4,
                        fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ───

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.blue1.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: AppColors.blue1, size: 16),
        ),
        const SizedBox(width: 10),
        AppTitle(title, fontSize: 13, color: AppColors.blue2),
      ],
    );
  }

  Widget _sectionDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: Colors.grey.shade200),
    );
  }

  // ─── Color Picker Dialog ───

  Future<void> _showColorPickerDialog(
    String title,
    Color currentColor,
    Function(Color) onColorChanged,
  ) async {
    Color pickerColor = currentColor;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.blue1.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.palette, color: AppColors.blue1, size: 18),
            ),
            const SizedBox(width: 10),
            AppTitle(title, fontSize: 14, color: AppColors.blue2),
          ],
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) => pickerColor = color,
            labelTypes: const [],
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600)),
          ),
          CustomButton(
            text: 'Aplicar',
            backgroundColor: AppColors.blue1,
            height: 34,
            borderRadius: 8,
            onPressed: () {
              onColorChanged(pickerColor);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
