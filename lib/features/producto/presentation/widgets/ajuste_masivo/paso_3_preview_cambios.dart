import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';

class Paso3PreviewCambios extends StatelessWidget {
  final Map<String, dynamic>? previewData;
  final bool isLoading;
  final VoidCallback onAplicarCambios;

  const Paso3PreviewCambios({
    super.key,
    required this.previewData,
    required this.isLoading,
    required this.onAplicarCambios,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Calculando cambios...'),
          ],
        ),
      );
    }

    if (previewData == null) {
      return const Center(
        child: Text('No hay datos de preview'),
      );
    }

    final resumen = previewData!['resumen'] as Map<String, dynamic>?;
    final cambios = previewData!['cambios'] as List<dynamic>? ?? [];
    final advertencias = previewData!['advertencias'] as List<dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          AppSubtitle(
            'Preview de cambios', fontSize: 14,
          ),
          Text(
            'Revisa los cambios antes de aplicarlos. Los precios se actualizarán de forma permanente.',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
            ),
          ),

          const SizedBox(height: 18),

          // Resumen de estadísticas
          _buildResumenCard(resumen),

          const SizedBox(height: 20),

          // Advertencias (si existen)
          if (advertencias != null && advertencias.isNotEmpty)
            ...[
              _buildAdvertenciasCard(advertencias),
              const SizedBox(height: 20),
            ],

          // Lista de cambios
          _buildCambiosCard(cambios),

          const SizedBox(height: 24),

          // Botón de aplicar cambios
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAplicarCambios, // Siempre habilitado
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Confirmar y Aplicar Cambios',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCard(Map<String, dynamic>? resumen) {
    if (resumen == null) return const SizedBox();

    final totalProductos = resumen['totalProductosAfectados'] ?? 0;
    final totalVariantes = resumen['totalVariantesAfectadas'] ?? 0;
    final ajuste = resumen['ajustePromedio'] ?? 0;
    final operacion = resumen['operacion'] ?? 'INCREMENTO';

    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.blue1,
            AppColors.blue1.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue1.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.insights,
            color: Colors.white,
            size: 25,
          ),
          // const SizedBox(height: 5),
          Text(
            'Resumen del Ajuste',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildResumenItem(
                'Productos',
                totalProductos.toString(),
                Icons.inventory_2,
              ),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildResumenItem(
                'Variantes',
                totalVariantes.toString(),
                Icons.category,
              ),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildResumenItem(
                'Ajuste',
                '${operacion == 'INCREMENTO' ? '+' : '-'}$ajuste%',
                operacion == 'INCREMENTO' ? Icons.trending_up : Icons.trending_down,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvertenciasCard(List<dynamic> advertencias) {
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange[700], size: 16),
              const SizedBox(width: 8),
              Text(
                'Advertencias',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[900],
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...advertencias.map((advertencia) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, color: Colors.orange[700], size: 8),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        advertencia.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCambiosCard(List<dynamic> cambios) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.list_alt, color: AppColors.blue1, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Cambios Detallados',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${cambios.length} cambios',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blue1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lista de cambios
          if (cambios.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No hay cambios para mostrar'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cambios.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final cambio = cambios[index] as Map<String, dynamic>;
                return _buildCambioItem(cambio);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCambioItem(Map<String, dynamic> cambio) {
    final nombre = cambio['nombre'] ?? '';
    final varianteNombre = cambio['varianteNombre'];
    final precioAnterior = cambio['precioAnterior'] ?? 0.0;
    final precioNuevo = cambio['precioNuevo'] ?? 0.0;
    final diferencia = cambio['diferencia'] ?? 0.0;
    final diferenciaPercentual = cambio['diferenciaPercentual'] ?? 0.0;

    final isIncremento = diferencia > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre del producto
          Text(
            nombre,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
            ),
          ),

          // Nombre de variante (si existe)
          if (varianteNombre != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Variante: $varianteNombre',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Precios
          Row(
            children: [
              // Precio anterior
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Precio actual',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'S/ ${precioAnterior.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              ),

              // Flecha
              Icon(
                Icons.arrow_forward,
                color: isIncremento ? Colors.green : Colors.orange,
                size: 20,
              ),

              const SizedBox(width: 8),

              // Precio nuevo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Precio nuevo',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'S/ ${precioNuevo.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isIncremento ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),

              // Badge de diferencia
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isIncremento
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${isIncremento ? '+' : ''}${diferenciaPercentual.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isIncremento ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
