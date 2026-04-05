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
import 'package:go_router/go_router.dart';
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

  // Banner upload state
  String? _currentBannerUrl;
  File? _selectedBannerFile;
  bool _isUploadingBanner = false;
  double _logoUploadProgress = 0.0;

  // Banners múltiples
  List<Map<String, dynamic>> _banners = [];
  bool _isUploadingMultiBanner = false;

  // Videos para la web
  List<Map<String, String>> _webVideos = [];

  // Controllers
  final _bannerUrlController = TextEditingController();
  final _bannerTextoController = TextEditingController();
  final _splashUrlController = TextEditingController();
  final _dominioController = TextEditingController();

  // Colores por defecto (matching web original design)
  static const _defaultPrimario = Color(0xFF437EFF);
  static const _defaultSecundario = Color(0xFF06b6d4);
  static const _defaultAcento = Color(0xFF437EFF);
  static const _defaultBannerColor = Color(0xFF000000);
  static const _defaultAppColorTema = Color(0xFF007bff);
  static const _defaultFondo1 = Color(0xFF06b6d4);
  static const _defaultFondo2 = Color(0xFF5b8fd4);

  // Colores
  Color _bannerColor = _defaultBannerColor;
  Color _colorPrimario = _defaultPrimario;
  Color _colorSecundario = _defaultSecundario;
  Color _colorAcento = _defaultAcento;
  Color _appColorTema = _defaultAppColorTema;
  Color _colorFondo1 = _defaultFondo1;
  Color _colorFondo2 = _defaultFondo2;

  // Storage info
  int _storageUsadoMB = 0;
  int? _storageLimiteMB;

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
        _currentBannerUrl = p.bannerPrincipalUrl;
        _bannerUrlController.text = p.bannerPrincipalUrl ?? '';
        _bannerTextoController.text = p.bannerPrincipalTexto ?? '';
        _banners = (p.banners)
            ?.where((b) => b is Map)
            .map((b) => Map<String, dynamic>.from(b as Map))
            .toList() ?? [];
        _splashUrlController.text = p.appSplashScreenUrl ?? '';
        _dominioController.text = p.dominioPersonalizado ?? '';
        _bannerColor = _parseColor(p.bannerColor);
        _colorPrimario = _parseColor(p.colorPrimario);
        _colorSecundario = _parseColor(p.colorSecundario);
        _colorAcento = _parseColor(p.colorAcento);
        _appColorTema = _parseColor(p.appColorTema);
        // Colores de fondo y videos desde webConfig
        final wc = p.webConfig;
        if (wc != null) {
          _colorFondo1 = _parseColor(wc['colorFondo1'] as String? ?? '#06b6d4');
          _colorFondo2 = _parseColor(wc['colorFondo2'] as String? ?? '#5b8fd4');
          final vids = wc['videos'] as List?;
          if (vids != null) {
            _webVideos = vids
                .where((v) => v is Map)
                .map((v) => Map<String, String>.from({
                      'url': (v as Map)['url']?.toString() ?? '',
                      'titulo': v['titulo']?.toString() ?? '',
                    }))
                .where((v) => v['url']!.isNotEmpty)
                .toList();
          }
        }
        _mostrarPrecios = p.mostrarPrecios;
        _mostrarContacto = p.mostrarContacto;
        _mostrarRedesSociales = p.mostrarRedesSociales;
        _permitirRegistro = p.permitirRegistro;
        _isLoading = false;
      });
      // Cargar storage info en paralelo
      _loadStorageInfo();
    } else if (result is Error) {
      setState(() {
        _errorMessage = (result as Error).message;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStorageInfo() async {
    final empresaId = _localStorage.getString(StorageConstants.tenantId);
    if (empresaId == null) return;
    try {
      final response = await locator<EmpresaRemoteDataSource>().getPlanLimitsInfo(empresaId);
      if (!mounted) return;
      final almacenamiento = response?['limites']?['almacenamiento'];
      if (almacenamiento != null) {
        setState(() {
          _storageUsadoMB = almacenamiento['actualMB'] as int? ?? 0;
          _storageLimiteMB = almacenamiento['limiteMB'] as int?;
        });
      }
    } catch (_) {
      // No es crítico
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

  void _resetColoresWeb() {
    setState(() {
      _colorPrimario = _defaultPrimario;
      _colorSecundario = _defaultSecundario;
      _colorAcento = _defaultAcento;
      _bannerColor = _defaultBannerColor;
      _colorFondo1 = _defaultFondo1;
      _colorFondo2 = _defaultFondo2;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Colores restaurados. Presiona Guardar para aplicar.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickLogo(ImageSource source) async {
    try {
      final XFile? picked = source == ImageSource.camera
          ? await _imagePicker.pickImage(source: source, maxWidth: 512, maxHeight: 512)
          : await _imagePicker.pickImage(source: source);
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

  Future<void> _pickBanner(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked == null) return;

      // Validar dimensiones
      final bytes = await picked.readAsBytes();
      final decoded = await decodeImageFromList(bytes);
      final width = decoded.width;
      final height = decoded.height;

      if (width < 800) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El banner debe tener al menos 800px de ancho. Recomendado: 1080x360px'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final ratio = width / height;
      if (ratio < 2.0 || ratio > 4.0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Proporción no válida (${ratio.toStringAsFixed(1)}:1). Use entre 2:1 y 4:1. Recomendado: 1080x360px'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() => _selectedBannerFile = File(picked.path));
      await _uploadBanner();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _uploadBanner() async {
    if (_selectedBannerFile == null) return;
    final empresaId = _localStorage.getString(StorageConstants.tenantId);
    if (empresaId == null) return;

    setState(() => _isUploadingBanner = true);

    try {
      final archivoResponse = await _storageService.uploadFile(
        file: _selectedBannerFile!,
        empresaId: empresaId,
        entidadTipo: 'EMPRESA',
        entidadId: empresaId,
        categoria: 'BANNER',
      );

      setState(() {
        _currentBannerUrl = archivoResponse.url;
        _bannerUrlController.text = archivoResponse.url;
        _selectedBannerFile = null;
        _isUploadingBanner = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banner subido. Guarda para aplicar cambios.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingBanner = false;
        _selectedBannerFile = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir banner: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _addBanner() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final empresaId = _localStorage.getString(StorageConstants.tenantId);
    if (empresaId == null) return;

    try {
      final XFile? picked = await _imagePicker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;

      setState(() => _isUploadingMultiBanner = true);

      final archivoResponse = await _storageService.uploadFile(
        file: File(picked.path),
        empresaId: empresaId,
        entidadTipo: 'EMPRESA',
        entidadId: empresaId,
        categoria: 'BANNER',
      );

      setState(() {
        _banners.add({
          'url': archivoResponse.url,
          'texto': '',
          'link': '',
          'orden': _banners.length,
        });
        _isUploadingMultiBanner = false;
      });
    } catch (e) {
      setState(() => _isUploadingMultiBanner = false);
    }
  }

  void _showBannerSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Subir Banner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () { Navigator.pop(ctx); _pickBanner(ImageSource.gallery); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () { Navigator.pop(ctx); _pickBanner(ImageSource.camera); },
            ),
          ],
        ),
      ),
    );
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
      webConfig: {
        ...?_personalizacion!.webConfig,
        'colorFondo1': _colorToHex(_colorFondo1),
        'colorFondo2': _colorToHex(_colorFondo2),
        'videos': _webVideos,
      },
      bannerPrincipalUrl: _bannerUrlController.text.isEmpty ? null : _bannerUrlController.text,
      bannerPrincipalTexto: _bannerTextoController.text.isEmpty ? null : _bannerTextoController.text,
      banners: _banners.isNotEmpty ? _banners : null,
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

        // ─── Videos Web ───
        _buildVideosWebCard(),
        const SizedBox(height: 12),

        // ─── Configuración ───
        _buildConfiguracionCard(),
        const SizedBox(height: 12),

        // ─── Almacenamiento ───
        _buildStorageCard(),
        const SizedBox(height: 12),

        // ─── Notificaciones ───
        _buildNotificacionesCard(),
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
                        color: Colors.white,
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
      return Image.file(_selectedLogoFile!, width: 100, height: 100, fit: BoxFit.contain);
    }
    if (_currentLogoUrl != null && _currentLogoUrl!.isNotEmpty) {
      return Image.network(
        _currentLogoUrl!,
        width: 100, height: 100, fit: BoxFit.contain,
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
              'Personaliza los colores de tu pagina web y app',
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 14),

            // Página Web
            Row(
              children: [
                Icon(Icons.language, size: 13, color: AppColors.blue1),
                const SizedBox(width: 6),
                Text(
                  'Pagina web',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            AppLabelText(
              'Estos colores se aplican a la cabecera y fondo de tu tienda online',
              fontSize: 9,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 10),
            _buildColorRow('Color cabecera', _colorPrimario, (c) => setState(() => _colorPrimario = c)),
            _buildColorRow('Color degradado', _colorSecundario, (c) => setState(() => _colorSecundario = c)),
            _buildColorRow('Color de navegacion', _colorAcento, (c) => setState(() => _colorAcento = c)),
            _buildColorRow('Color de banner', _bannerColor, (c) => setState(() => _bannerColor = c)),

            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.wallpaper, size: 13, color: AppColors.blue1),
                const SizedBox(width: 6),
                Text(
                  'Fondo de pagina',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            AppLabelText(
              'Degradado del fondo de tu tienda web',
              fontSize: 9,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            _buildColorRow('Color fondo 1', _colorFondo1, (c) => setState(() => _colorFondo1 = c)),
            _buildColorRow('Color fondo 2', _colorFondo2, (c) => setState(() => _colorFondo2 = c)),

            // Preview completo
            const SizedBox(height: 10),
            AppLabelText(
              'Vista previa',
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: Column(
                  children: [
                    // Cabecera
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _colorPrimario,
                            Color.lerp(_colorPrimario, _colorSecundario, 0.5)!,
                            _colorSecundario,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Icon(Icons.store, size: 12, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 6),
                                  Text('Buscar productos...', style: TextStyle(fontSize: 7, color: Colors.grey.shade400)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ),
                    // Navegación
                    Container(
                      height: 22,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            HSLColor.fromColor(_colorAcento).withLightness(
                              (HSLColor.fromColor(_colorAcento).lightness - 0.05).clamp(0.0, 1.0),
                            ).toColor(),
                            _colorAcento,
                            HSLColor.fromColor(_colorAcento).withLightness(
                              (HSLColor.fromColor(_colorAcento).lightness + 0.05).clamp(0.0, 1.0),
                            ).toColor(),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          ...[
                            'Inicio',
                            'Categorias',
                            'Productos',
                            'Servicios',
                          ].map((t) => Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Text(
                              t,
                              style: TextStyle(
                                fontSize: 6.5,
                                color: Colors.white.withValues(alpha: 0.85),
                                fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                    // Fondo con contenido simulado
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(_colorFondo1, Colors.white, 0.75)!,
                            Color.lerp(_colorFondo2, Colors.white, 0.80)!,
                            Color.lerp(_colorFondo1, Colors.white, 0.85)!,
                            Color.lerp(_colorFondo2, Colors.white, 0.75)!,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: List.generate(4, (i) => Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Icon(Icons.image_outlined, size: 10, color: Colors.grey.shade300),
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    width: 30,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botón resetear colores web
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _resetColoresWeb,
                icon: Icon(Icons.restart_alt, size: 14, color: Colors.grey.shade600),
                label: Text(
                  'Restaurar colores originales',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),

            _sectionDivider(),

            // App Móvil
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
            const Text('Banner principal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _isUploadingBanner ? null : _showBannerSourceDialog,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.blueborder),
                ),
                clipBehavior: Clip.antiAlias,
                child: _isUploadingBanner
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : _currentBannerUrl != null && _currentBannerUrl!.isNotEmpty
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(_currentBannerUrl!, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _bannerPlaceholder()),
                              Positioned(
                                bottom: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('Cambiar', style: TextStyle(color: Colors.white, fontSize: 10)),
                                ),
                              ),
                            ],
                          )
                        : _bannerPlaceholder(),
              ),
            ),
            const SizedBox(height: 10),
            CustomText(
              controller: _bannerTextoController,
              label: 'Texto del banner',
              hintText: 'Bienvenidos a nuestra empresa',
              prefixIcon: const Icon(Icons.text_fields, size: 16),
              borderColor: AppColors.blueborder,
            ),

            const SizedBox(height: 16),

            // Banners múltiples (carousel web)
            Row(
              children: [
                Icon(Icons.view_carousel, size: 13, color: AppColors.blue1),
                const SizedBox(width: 6),
                const Text('Banners del carousel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _isUploadingMultiBanner ? null : _addBanner,
                  icon: const Icon(Icons.add_photo_alternate, size: 14),
                  label: const Text('Agregar', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            if (_isUploadingMultiBanner)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
            if (_banners.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Sin banners adicionales', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              )
            else
              SizedBox(
                height: 80,
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _banners.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _banners.removeAt(oldIndex);
                      _banners.insert(newIndex, item);
                      for (int i = 0; i < _banners.length; i++) {
                        _banners[i]['orden'] = i;
                      }
                    });
                  },
                  itemBuilder: (_, i) {
                    final b = _banners[i];
                    return Container(
                      key: ValueKey(b['url']),
                      width: 130,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.blueborder),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(b['url'], fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.image))),
                          Positioned(
                            top: 2, right: 2,
                            child: GestureDetector(
                              onTap: () => setState(() => _banners.removeAt(i)),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 2, left: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(3)),
                              child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 9)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
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

  // ─── Videos Web Card ───

  bool _isUploadingWebVideo = false;
  double _webVideoUploadProgress = 0.0;

  Widget _buildVideosWebCard() {
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
            _sectionHeader('Videos de tu pagina web', Icons.video_library_outlined),
            const SizedBox(height: 4),
            AppLabelText(
              'Agrega videos promocionales, tutoriales o testimonios que se mostraran en tu tienda online',
              fontSize: 9,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),

            // Lista de videos
            ..._webVideos.asMap().entries.map((entry) {
              final i = entry.key;
              final video = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    // Thumbnail
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.play_circle_outline, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 10),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titulo editable
                          GestureDetector(
                            onTap: () => _editVideoTitle(i),
                            child: Text(
                              video['titulo']?.isNotEmpty == true ? video['titulo']! : 'Video ${i + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            video['url'] ?? '',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.grey.shade500,
                              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => _editVideoTitle(i),
                            child: Text(
                              'Editar titulo',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.blue1,
                                fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Eliminar
                    IconButton(
                      onPressed: () {
                        setState(() => _webVideos.removeAt(i));
                      },
                      icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade300),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              );
            }),

            // Progreso de subida
            if (_isUploadingWebVideo) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _webVideoUploadProgress,
                  backgroundColor: Colors.grey.shade200,
                  color: AppColors.blue1,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: AppLabelText(
                  'Subiendo video... ${(_webVideoUploadProgress * 100).toInt()}%',
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Botones agregar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploadingWebVideo ? null : _pickWebVideo,
                    icon: Icon(Icons.video_camera_back_outlined, size: 16, color: _isUploadingWebVideo ? Colors.grey : AppColors.blue1),
                    label: Text(
                      'Subir video',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isUploadingWebVideo ? Colors.grey : AppColors.blue1,
                        fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: (_isUploadingWebVideo ? Colors.grey : AppColors.blue1).withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploadingWebVideo ? null : _showAddVideoUrlDialog,
                    icon: Icon(Icons.link, size: 16, color: _isUploadingWebVideo ? Colors.grey : Colors.orange.shade700),
                    label: Text(
                      'Pegar URL',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isUploadingWebVideo ? Colors.grey : Colors.orange.shade700,
                        fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: (_isUploadingWebVideo ? Colors.grey : Colors.orange.shade700).withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),

            if (_webVideos.isNotEmpty) ...[
              const SizedBox(height: 8),
              AppLabelText(
                'Recuerda presionar Guardar para aplicar los cambios',
                fontSize: 9,
                color: Colors.orange.shade400,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickWebVideo() async {
    try {
      final picked = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (picked == null) return;

      final file = File(picked.path);
      final sizeInMB = await file.length() / (1024 * 1024);
      if (sizeInMB > 80) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('El video es demasiado grande (${sizeInMB.toStringAsFixed(1)}MB). Maximo 80MB.'), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() {
        _isUploadingWebVideo = true;
        _webVideoUploadProgress = 0.0;
      });

      final empresaId = _localStorage.getString(StorageConstants.tenantId)!;

      final response = await _storageService.uploadFile(
        file: file,
        empresaId: empresaId,
        entidadTipo: 'EMPRESA',
        entidadId: empresaId,
        categoria: 'GALERIA',
        onProgress: (progress) {
          if (mounted) setState(() => _webVideoUploadProgress = progress);
        },
      );

      if (!mounted) return;

      setState(() {
        _webVideos.add({'url': response.url, 'titulo': ''});
        _isUploadingWebVideo = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video subido. Edita el titulo y presiona Guardar.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingWebVideo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir video: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddVideoUrlDialog() {
    final urlController = TextEditingController();
    final tituloController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.link, size: 20, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Pegar URL de video', style: TextStyle(fontSize: 15)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: 'URL del video',
                hintText: 'https://www.youtube.com/watch?v=...',
                hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                labelStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                prefixIcon: const Icon(Icons.link, size: 18),
              ),
              style: const TextStyle(fontSize: 12),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tituloController,
              decoration: InputDecoration(
                labelText: 'Titulo (opcional)',
                hintText: 'Ej: Video promocional',
                hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                labelStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                prefixIcon: const Icon(Icons.title, size: 18),
              ),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            AppLabelText(
              'YouTube, Vimeo o enlace directo MP4',
              fontSize: 9,
              color: Colors.grey.shade500,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isEmpty) return;
              setState(() {
                _webVideos.add({'url': url, 'titulo': tituloController.text.trim()});
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: const Text('Agregar', style: TextStyle(fontSize: 12, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editVideoTitle(int index) {
    final controller = TextEditingController(text: _webVideos[index]['titulo']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar titulo', style: TextStyle(fontSize: 15)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Ej: Video promocional',
            hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          style: const TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _webVideos[index] = {
                  ..._webVideos[index],
                  'titulo': controller.text.trim(),
                };
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: const Text('Guardar', style: TextStyle(fontSize: 12, color: Colors.white)),
          ),
        ],
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

  // ─── Notificaciones Card ───

  Widget _buildStorageCard() {
    final limiteLabel = _storageLimiteMB != null
        ? (_storageLimiteMB! >= 1024
            ? '${(_storageLimiteMB! / 1024).toStringAsFixed(0)} GB'
            : '$_storageLimiteMB MB')
        : 'Ilimitado';
    final usadoLabel = _storageUsadoMB >= 1024
        ? '${(_storageUsadoMB / 1024).toStringAsFixed(1)} GB'
        : '$_storageUsadoMB MB';
    final porcentaje = _storageLimiteMB != null && _storageLimiteMB! > 0
        ? (_storageUsadoMB / _storageLimiteMB!).clamp(0.0, 1.0)
        : 0.0;
    final esCritico = porcentaje > 0.85;

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
            _sectionHeader('Almacenamiento', Icons.cloud_outlined),
            const SizedBox(height: 12),
            // Barra de progreso
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: porcentaje,
                          backgroundColor: Colors.grey.shade200,
                          color: esCritico ? Colors.red : AppColors.blue1,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$usadoLabel usado',
                            style: TextStyle(
                              fontSize: 11,
                              color: esCritico ? Colors.red : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                            ),
                          ),
                          Text(
                            'de $limiteLabel',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (esCritico) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red.shade400),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Almacenamiento casi lleno. Actualiza tu plan para mas espacio.',
                        style: TextStyle(fontSize: 10, color: Colors.red.shade600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificacionesCard() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.blueborder,
      borderWidth: 0.6,
      child: InkWell(
        onTap: () => context.push('/empresa/notificaciones/preferencias'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: AppColors.blue1, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppTitle(
                      'Preferencias de notificaciones',
                      fontSize: 13,
                      color: AppColors.blue2,
                    ),
                    const SizedBox(height: 2),
                    AppLabelText(
                      'Elige qué notificaciones push quieres recibir',
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
            ],
          ),
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

  Widget _bannerPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.panorama, size: 32, color: Colors.grey.shade400),
          const SizedBox(height: 4),
          Text('Toca para subir banner', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
