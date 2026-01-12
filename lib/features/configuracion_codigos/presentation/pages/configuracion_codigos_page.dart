import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/smart_appbar.dart';
import 'configuracion_codigos_body.dart';

/// Página principal de configuración de códigos/nomenclaturas
/// Ahora delegada a un widget separado (ConfiguracionCodigosBody) para mejorar la separación de responsabilidades.
class ConfiguracionCodigosPage extends StatefulWidget {
  const ConfiguracionCodigosPage({super.key});

  @override
  State<ConfiguracionCodigosPage> createState() =>
      _ConfiguracionCodigosPageState();
}

class _ConfiguracionCodigosPageState extends State<ConfiguracionCodigosPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        showLogo: false,
        foregroundColor: AppColors.white,
        backgroundColor: AppColors.blue1,
        title: 'Configuración de Códigos',
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(37),
          child: _buildTabBar(),
        ),
      ),
      body: ConfiguracionCodigosBody(tabController: _tabController),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
      dividerHeight: 0,
      labelColor: AppColors.white,
      unselectedLabelColor: Colors.grey,
      labelPadding: const EdgeInsets.symmetric(horizontal: 10),
      indicatorPadding: const EdgeInsets.only(bottom: 13),
      indicatorSize: TabBarIndicatorSize.label,
      indicatorWeight: 2,
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(width: 2, color: AppColors.white),
      ),
      tabs: const [
        Tab(text: 'PRODUCTOS'),
        Tab(text: 'VARIANTES'),
        Tab(text: 'SERVICIOS'),
        Tab(text: 'VENTAS'),
        Tab(text: 'DOCUMENTOS'),
      ],
    );
  }
}
