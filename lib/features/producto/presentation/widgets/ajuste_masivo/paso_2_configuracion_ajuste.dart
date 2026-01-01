import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/custom_switch_tile.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';

class Paso2ConfiguracionAjuste extends StatelessWidget {
  final String operacion;
  final double porcentaje;
  final bool incluirVariantes;
  final String razon;
  final ValueChanged<String> onOperacionChanged;
  final ValueChanged<double> onPorcentajeChanged;
  final ValueChanged<bool> onIncluirVariantesChanged;
  final ValueChanged<String> onRazonChanged;

  const Paso2ConfiguracionAjuste({
    super.key,
    required this.operacion,
    required this.porcentaje,
    required this.incluirVariantes,
    required this.razon,
    required this.onOperacionChanged,
    required this.onPorcentajeChanged,
    required this.onIncluirVariantesChanged,
    required this.onRazonChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            'Configura el ajuste',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Define cómo deseas ajustar los precios de los productos seleccionados.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
            ),
          ),

          const SizedBox(height: 28),

          // Card de operación
          _buildCard(
            title: 'Tipo de operación',
            icon: Icons.swap_vert,
            child: Column(
              children: [
                _buildOperacionOption('INCREMENTO', 'Aumentar precios', Icons.trending_up, Colors.green),
                const SizedBox(height: 12),
                _buildOperacionOption('DECREMENTO', 'Reducir precios', Icons.trending_down, Colors.orange),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Card de porcentaje
          _buildCard(
            title: 'Porcentaje de ajuste',
            icon: Icons.percent,
            child: Column(
              children: [
                // Valor actual
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        operacion == 'INCREMENTO' ? '+' : '-',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: operacion == 'INCREMENTO' ? Colors.green : Colors.orange,
                        ),
                      ),
                      Text(
                        '${porcentaje.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blue1,
                          fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Slider
                Row(
                  children: [
                    Text(
                      '0%',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Expanded(
                      child: Slider(
                        value: porcentaje,
                        min: 0,
                        max: 100,
                        divisions: 200,
                        activeColor: AppColors.blue1,
                        onChanged: onPorcentajeChanged,
                      ),
                    ),
                    Text(
                      '100%',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Botones de valores rápidos
                Wrap(
                  spacing: 4,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [5.0, 10.0, 15.0, 20.0, 25.0, 30.0]
                      .map((valor) => _buildQuickValueButton(valor))
                      .toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Card de opciones adicionales
          _buildCard(
            title: 'Opciones adicionales',
            icon: Icons.settings,
            child: Column(
              children: [
                // Incluir variantes
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomSwitchTile(title: 'Incluir variantes', value: incluirVariantes, onChanged: onIncluirVariantesChanged, subtitle: 'Aplicar el ajuste también a las variantes de productos',),
                ),

                const SizedBox(height: 16),

                // Razón del ajuste
                CustomText(
                  label: 'Razón del ajuste (opcional)',
                  borderColor: AppColors.grey,
                  labelStyle: TextStyle(
                    color: AppColors.blue1,
                    fontSize: 10,
                  ),
                  hintText: 'Ej: Ajuste trimestral por inflación',
                  maxLines: 2,
                  onChanged: onRazonChanged,
                  prefixIcon: Icon(Icons.notes),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Preview de cálculo
          _buildCalculoPreview(),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
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
            children: [
              Icon(icon, color: AppColors.blue1, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildOperacionOption(String value, String label, IconData icon, Color color) {
    final isSelected = operacion == value;

    return InkWell(
      onTap: () => onOperacionChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 1 : 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey[800],
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickValueButton(double valor) {
    final isSelected = (porcentaje - valor).abs() < 0.1;

    return InkWell(
      onTap: () => onPorcentajeChanged(valor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue1 : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.blue1 : Colors.grey[400]!,
            width: 1,
          ),
        ),
        child: Text(
          '${valor.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey[800],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculoPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.blue1.withValues(alpha: 0.1),
            AppColors.blue1.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue1.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate, color: AppColors.blue1, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ejemplo de cálculo',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue1,
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildCalculoRow('Precio actual:', 'S/ 100.00'),
          const SizedBox(height: 8),
          _buildCalculoRow(
            'Ajuste:',
            '${operacion == 'INCREMENTO' ? '+' : '-'}${porcentaje.toStringAsFixed(1)}%',
            color: operacion == 'INCREMENTO' ? Colors.green : Colors.orange,
          ),
          const Divider(),
          _buildCalculoRow(
            'Precio nuevo:',
            'S/ ${_calcularPrecioEjemplo().toStringAsFixed(2)}',
            isBold: true,
            color: AppColors.blue1,
          ),
        ],
      ),
    );
  }

  Widget _buildCalculoRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[700],
            fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.grey[800],
            fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
          ),
        ),
      ],
    );
  }

  double _calcularPrecioEjemplo() {
    const precioBase = 100.0;
    final factor = porcentaje / 100;
    if (operacion == 'INCREMENTO') {
      return precioBase * (1 + factor);
    } else {
      return precioBase * (1 - factor);
    }
  }
}
