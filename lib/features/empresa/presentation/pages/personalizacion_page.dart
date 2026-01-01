import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/personalizacion_empresa.dart';
import '../../domain/usecases/get_personalizacion_usecase.dart';
import '../../domain/usecases/update_personalizacion_usecase.dart';

class PersonalizacionPage extends StatefulWidget {
  const PersonalizacionPage({super.key});

  @override
  State<PersonalizacionPage> createState() => _PersonalizacionPageState();
}

class _PersonalizacionPageState extends State<PersonalizacionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _getPersonalizacionUseCase = locator<GetPersonalizacionUseCase>();
  final _updatePersonalizacionUseCase = locator<UpdatePersonalizacionUseCase>();
  final _localStorage = locator<LocalStorageService>();

  bool _isLoading = true;
  bool _isSaving = false;
  PersonalizacionEmpresa? _personalizacion;
  String? _errorMessage;

  // Controllers para formularios
  final _bannerUrlController = TextEditingController();
  final _bannerTextoController = TextEditingController();
  final _splashUrlController = TextEditingController();
  final _dominioController = TextEditingController();

  // Valores de colores
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
    _tabController = TabController(length: 3, vsync: this);
    _loadPersonalizacion();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    // Extract RGB components using the new color space API
    final r = ((color.r * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
    final g = ((color.g * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
    final b = ((color.b * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

  Future<void> _savePersonalizacion() async {
    if (_personalizacion == null) return;

    setState(() {
      _isSaving = true;
    });

    final empresaId = _localStorage.getString(StorageConstants.tenantId)!;

    final updatedPersonalizacion = _personalizacion!.copyWith(
      bannerPrincipalUrl: _bannerUrlController.text.isEmpty
          ? null
          : _bannerUrlController.text,
      bannerPrincipalTexto: _bannerTextoController.text.isEmpty
          ? null
          : _bannerTextoController.text,
      bannerColor: _colorToHex(_bannerColor),
      colorPrimario: _colorToHex(_colorPrimario),
      colorSecundario: _colorToHex(_colorSecundario),
      colorAcento: _colorToHex(_colorAcento),
      mostrarPrecios: _mostrarPrecios,
      mostrarContacto: _mostrarContacto,
      mostrarRedesSociales: _mostrarRedesSociales,
      permitirRegistro: _permitirRegistro,
      appSplashScreenUrl:
          _splashUrlController.text.isEmpty ? null : _splashUrlController.text,
      appColorTema: _colorToHex(_appColorTema),
      dominioPersonalizado:
          _dominioController.text.isEmpty ? null : _dominioController.text,
    );

    final result = await _updatePersonalizacionUseCase(
      empresaId: empresaId,
      personalizacion: updatedPersonalizacion,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (result is Success<PersonalizacionEmpresa>) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Personalización guardada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _personalizacion = result.data;
      });
    } else if (result is Error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result as Error).message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalización de Marketplace'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.palette), text: 'Colores y Tema'),
            Tab(icon: Icon(Icons.image), text: 'Multimedia'),
            Tab(icon: Icon(Icons.settings), text: 'Configuración'),
          ],
        ),
        actions: [
          if (!_isLoading && _personalizacion != null)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              onPressed: _isSaving ? null : _savePersonalizacion,
              tooltip: 'Guardar cambios',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildColoresTab(),
                    _buildMultimediaTab(),
                    _buildConfiguracionTab(),
                  ],
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
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPersonalizacion,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColoresTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Personaliza los colores de tu perfil en el marketplace',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        _buildColorPicker(
          'Color Primario',
          'Color principal de tu marca',
          _colorPrimario,
          (color) => setState(() => _colorPrimario = color),
        ),
        const SizedBox(height: 16),
        _buildColorPicker(
          'Color Secundario',
          'Color secundario complementario',
          _colorSecundario,
          (color) => setState(() => _colorSecundario = color),
        ),
        const SizedBox(height: 16),
        _buildColorPicker(
          'Color de Acento',
          'Color para resaltar elementos importantes',
          _colorAcento,
          (color) => setState(() => _colorAcento = color),
        ),
        const SizedBox(height: 16),
        _buildColorPicker(
          'Color del Banner',
          'Color de fondo del banner principal',
          _bannerColor,
          (color) => setState(() => _bannerColor = color),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Color de la App Móvil',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildColorPicker(
          'Color del Tema App',
          'Color principal en la app móvil',
          _appColorTema,
          (color) => setState(() => _appColorTema = color),
        ),
      ],
    );
  }

  Widget _buildMultimediaTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Imágenes y multimedia para tu perfil',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _bannerUrlController,
          decoration: const InputDecoration(
            labelText: 'URL del Banner Principal',
            hintText: 'https://ejemplo.com/banner.jpg',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.image),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _bannerTextoController,
          decoration: const InputDecoration(
            labelText: 'Texto del Banner',
            hintText: '¡Bienvenidos a nuestra empresa!',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.text_fields),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'App Móvil',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _splashUrlController,
          decoration: const InputDecoration(
            labelText: 'URL del Splash Screen',
            hintText: 'https://ejemplo.com/splash.jpg',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone_android),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Dominio Personalizado',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Solo disponible en planes premium',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _dominioController,
          decoration: const InputDecoration(
            labelText: 'Dominio Personalizado',
            hintText: 'www.miempresa.com',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.language),
          ),
        ),
      ],
    );
  }

  Widget _buildConfiguracionTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Configura qué elementos mostrar en tu perfil público',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        SwitchListTile(
          title: const Text('Mostrar Precios'),
          subtitle: const Text('Mostrar precios de productos públicamente'),
          value: _mostrarPrecios,
          onChanged: (value) => setState(() => _mostrarPrecios = value),
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('Mostrar Información de Contacto'),
          subtitle: const Text('Teléfono, email y dirección visibles'),
          value: _mostrarContacto,
          onChanged: (value) => setState(() => _mostrarContacto = value),
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('Mostrar Redes Sociales'),
          subtitle: const Text('Mostrar links a redes sociales'),
          value: _mostrarRedesSociales,
          onChanged: (value) => setState(() => _mostrarRedesSociales = value),
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('Permitir Registro de Usuarios'),
          subtitle: const Text('Los clientes pueden crear cuentas'),
          value: _permitirRegistro,
          onChanged: (value) => setState(() => _permitirRegistro = value),
        ),
        const SizedBox(height: 32),
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    const Text(
                      'Información',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Estos cambios afectarán cómo se ve tu empresa en el marketplace web y en la app móvil. Los cambios se aplicarán inmediatamente después de guardar.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorPicker(
    String title,
    String subtitle,
    Color currentColor,
    Function(Color) onColorChanged,
  ) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: currentColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
        ),
        onTap: () => _showColorPickerDialog(title, currentColor, onColorChanged),
      ),
    );
  }

  Future<void> _showColorPickerDialog(
    String title,
    Color currentColor,
    Function(Color) onColorChanged,
  ) async {
    Color pickerColor = currentColor;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Selecciona $title'),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              onColorChanged(pickerColor);
              Navigator.pop(context);
            },
            child: const Text('Seleccionar'),
          ),
        ],
      ),
    );
  }
}
