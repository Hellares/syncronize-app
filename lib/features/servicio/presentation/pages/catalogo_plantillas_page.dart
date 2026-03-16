import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../data/catalogo_plantillas_servicio.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../domain/repositories/plantilla_servicio_repository.dart';

class CatalogoPlantillasPage extends StatefulWidget {
  const CatalogoPlantillasPage({super.key});

  @override
  State<CatalogoPlantillasPage> createState() => _CatalogoPlantillasPageState();
}

class _CatalogoPlantillasPageState extends State<CatalogoPlantillasPage> {
  bool _isCreating = false;
  int? _creatingIndex;

  Future<void> _usarPlantilla(CatalogoPlantilla plantilla, int index) async {
    setState(() {
      _isCreating = true;
      _creatingIndex = index;
    });

    final repo = locator<PlantillaServicioRepository>();
    final result = await repo.crear(
      nombre: plantilla.nombre,
      descripcion: plantilla.descripcion,
      campos: plantilla.campos,
    );

    if (!mounted) return;

    setState(() {
      _isCreating = false;
      _creatingIndex = null;
    });

    if (result is Success) {
      SnackBarHelper.showSuccess(
        context,
        'Plantilla "${plantilla.nombre}" creada exitosamente',
      );
      context.pop(true);
    } else if (result is Error) {
      SnackBarHelper.showError(
        context,
        (result as Error).message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          title: 'Catálogo de Plantillas',
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: catalogoPlantillas.length,
          itemBuilder: (context, index) {
            final plantilla = catalogoPlantillas[index];
            return _CatalogoPlantillaCard(
              plantilla: plantilla,
              isCreating: _isCreating && _creatingIndex == index,
              isDisabled: _isCreating && _creatingIndex != index,
              onUsar: () => _usarPlantilla(plantilla, index),
            );
          },
        ),
      ),
    );
  }
}

class _CatalogoPlantillaCard extends StatefulWidget {
  final CatalogoPlantilla plantilla;
  final bool isCreating;
  final bool isDisabled;
  final VoidCallback onUsar;

  const _CatalogoPlantillaCard({
    required this.plantilla,
    required this.isCreating,
    required this.isDisabled,
    required this.onUsar,
  });

  @override
  State<_CatalogoPlantillaCard> createState() => _CatalogoPlantillaCardState();
}

class _CatalogoPlantillaCardState extends State<_CatalogoPlantillaCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.plantilla;

    return Opacity(
      opacity: widget.isDisabled ? 0.5 : 1.0,
      child: GradientContainer(
        borderColor: widget.isCreating ? Colors.green.shade300 : AppColors.blueborder,
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: p.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(p.icono, size: 22, color: p.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.nombre,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue1,
                            fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${p.camposCount} campos',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey.shade600,
                            fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Descripción
              Text(
                p.descripcion,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  height: 1.4,
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                ),
              ),
              const SizedBox(height: 10),

              // Chips de categorías
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: p.categorias.map((cat) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: p.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: p.color.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      _categoriaNombre(cat),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: p.color,
                        fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // Expand/collapse campos
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: AppColors.blue2,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _expanded ? 'Ocultar campos' : 'Ver campos incluidos',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blue2,
                          fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Campos expandidos
              if (_expanded) ...[
                const SizedBox(height: 8),
                _buildCamposPreview(p),
              ],

              const SizedBox(height: 12),

              // Botón usar
              CustomButton(
                text: widget.isCreating ? 'Creando...' : 'Usar esta plantilla',
                isLoading: widget.isCreating,
                backgroundColor: p.color,
                height: 36,
                fontSize: 11.5,
                borderRadius: 8,
                icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
                onPressed: widget.isCreating || widget.isDisabled ? null : widget.onUsar,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCamposPreview(CatalogoPlantilla plantilla) {
    // Agrupar por categoría
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final campo in plantilla.campos) {
      final cat = campo['categoria'] as String? ?? 'GENERAL';
      grouped.putIfAbsent(cat, () => []).add(campo);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categoría header
            Padding(
              padding: const EdgeInsets.only(bottom: 4, top: 6),
              child: AppSubtitle(
                _categoriaNombre(entry.key),
                fontSize: 10,
                font: AppFont.pirulentBold,
                color: AppColors.blue2,
              ),
            ),
            // Campos de la categoría
            ...entry.value.map((campo) {
              final tipo = campo['tipoCampo'] as String;
              final nombre = campo['nombre'] as String;
              final requerido = campo['esRequerido'] as bool? ?? false;

              return Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 3),
                child: Row(
                  children: [
                    Icon(
                      _iconForTipo(tipo),
                      size: 13,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        nombre,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.blue1,
                          fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                        ),
                      ),
                    ),
                    if (requerido)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Req.',
                          style: TextStyle(fontSize: 8.5, color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      _tipoLabel(tipo),
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade500,
                        fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }

  String _categoriaNombre(String categoria) {
    const labels = {
      'DIAGNOSTICO': 'Diagnóstico',
      'CLIENTE': 'Cliente',
      'TECNICO': 'Técnico',
      'COMPONENTE': 'Componente',
      'COSTOS': 'Costos',
      'TIEMPOS': 'Tiempos',
      'EQUIPO_CLIENTE': 'Equipo del Cliente',
      'GENERAL': 'General',
    };
    return labels[categoria] ?? categoria;
  }

  IconData _iconForTipo(String tipo) {
    const icons = {
      'TEXTO': Icons.text_fields,
      'NUMERO': Icons.pin,
      'EMAIL': Icons.email,
      'TELEFONO': Icons.phone,
      'URL': Icons.link,
      'TEXTO_AREA': Icons.notes,
      'OPCION_SIMPLES': Icons.radio_button_checked,
      'OPCION_MULTIPLE': Icons.checklist,
      'CHECKBOX': Icons.check_box,
      'CHECKBOX_MULTIPLE': Icons.playlist_add_check,
      'FECHA': Icons.calendar_today,
      'HORA': Icons.access_time,
      'ARCHIVO': Icons.attach_file,
      'OBJETO': Icons.account_tree_outlined,
      'PATRON_DESBLOQUEO': Icons.pattern,
      'INSPECCION_VISUAL': Icons.car_crash_outlined,
    };
    return icons[tipo] ?? Icons.help_outline;
  }

  String _tipoLabel(String tipo) {
    const labels = {
      'TEXTO': 'Texto',
      'NUMERO': 'Número',
      'EMAIL': 'Email',
      'TELEFONO': 'Teléfono',
      'URL': 'URL',
      'TEXTO_AREA': 'Texto largo',
      'OPCION_SIMPLES': 'Selección',
      'OPCION_MULTIPLE': 'Multi-selección',
      'CHECKBOX': 'Si/No',
      'CHECKBOX_MULTIPLE': 'Checks múltiple',
      'FECHA': 'Fecha',
      'HORA': 'Hora',
      'ARCHIVO': 'Archivo',
      'OBJETO': 'Objeto',
      'PATRON_DESBLOQUEO': 'Patrón',
      'INSPECCION_VISUAL': 'Inspección',
    };
    return labels[tipo] ?? tipo;
  }
}
