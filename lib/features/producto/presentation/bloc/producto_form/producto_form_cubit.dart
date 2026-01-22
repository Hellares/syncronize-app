import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/utils/resource.dart';
import '../../../../../core/widgets/currency/currency_formatter.dart';
import '../../../domain/entities/producto.dart';
import '../../../domain/usecases/crear_producto_usecase.dart';
import '../../../domain/usecases/actualizar_producto_usecase.dart';
import '../../../data/datasources/producto_remote_datasource.dart';
import '../../../data/models/producto_atributo_valor_dto.dart';
import '../../controllers/producto_form_controller.dart';
import 'producto_form_state.dart';

/// Cubit que maneja la lógica de negocio del formulario de producto
class ProductoFormCubit extends Cubit<ProductoFormState> {
  final CrearProductoUseCase _crearProductoUseCase;
  final ActualizarProductoUseCase _actualizarProductoUseCase;
  final ProductoRemoteDataSource _productoRemoteDataSource;

  ProductoFormCubit({
    CrearProductoUseCase? crearProductoUseCase,
    ActualizarProductoUseCase? actualizarProductoUseCase,
    ProductoRemoteDataSource? productoRemoteDataSource,
  })  : _crearProductoUseCase = crearProductoUseCase ?? locator<CrearProductoUseCase>(),
        _actualizarProductoUseCase = actualizarProductoUseCase ?? locator<ActualizarProductoUseCase>(),
        _productoRemoteDataSource = productoRemoteDataSource ?? locator<ProductoRemoteDataSource>(),
        super(const ProductoFormInitial());

  /// Resetea el estado a inicial
  void reset() {
    emit(const ProductoFormInitial());
  }

  /// Valida los atributos requeridos de la plantilla
  /// Retorna el nombre del atributo faltante o null si todo está válido
  String? validarAtributosRequeridos(ProductoFormController controller) {
    if (controller.selectedPlantilla == null) return null;

    for (final plantillaAtributo in controller.selectedPlantilla!.atributos) {
      if (plantillaAtributo.esRequerido) {
        final valor = controller.plantillaAtributosValues[plantillaAtributo.atributo.id];
        if (valor == null || valor.trim().isEmpty) {
          return plantillaAtributo.atributo.nombre;
        }
      }
    }

    return null;
  }

  /// Guarda un producto (crear o actualizar)
  Future<void> submit({
    required ProductoFormController controller,
    required String empresaId,
    required bool isEditing,
    String? productoId,
    required List<String> imagenesIds,
    required Future<List<String>> Function() uploadPendingImages,
  }) async {
    // Validar formulario
    if (!controller.formKey.currentState!.validate()) {
      emit(const ProductoFormValidationError(
        message: 'Por favor corrige los errores del formulario',
      ));
      emit(const ProductoFormInitial());
      return;
    }

    // Validar atributos requeridos (solo para productos simples)
    if (!controller.tieneVariantes && !controller.esCombo) {
      final atributoFaltante = validarAtributosRequeridos(controller);
      if (atributoFaltante != null) {
        emit(ProductoFormValidationError(
          message: 'El atributo "$atributoFaltante" es requerido',
          fieldName: atributoFaltante,
        ));
        emit(const ProductoFormInitial());
        return;
      }
    }

    emit(const ProductoFormLoading(message: 'Guardando producto...'));

    try {
      // Subir imágenes pendientes
      List<String> finalImagenesIds = List.from(imagenesIds);
      try {
        emit(const ProductoFormLoading(message: 'Subiendo imágenes...'));
        final newIds = await uploadPendingImages();
        finalImagenesIds.addAll(newIds);
      } catch (e) {
        emit(ProductoFormError(
          message: 'Error al subir imágenes: $e',
          type: ProductoFormErrorType.imageUpload,
        ));
        return;
      }

      emit(const ProductoFormLoading(message: 'Guardando...'));

      // Extraer datos del controller
      final nombre = controller.nombreController.text.trim();
      final descripcion = controller.descripcionController.text.trim();

      // Calcular precio
      final double precio;
      if (controller.esCombo &&
          (controller.tipoPrecioCombo == 'CALCULADO' || controller.tipoPrecioCombo == 'CALCULADO_CON_DESCUENTO')) {
        precio = 0.0;
      } else {
        precio = controller.precioController.currencyValue;
      }

      // Preparar dimensiones
      Map<String, dynamic>? dimensiones;
      if (controller.dimensionLargoController.text.isNotEmpty ||
          controller.dimensionAnchoController.text.isNotEmpty ||
          controller.dimensionAltoController.text.isNotEmpty) {
        dimensiones = {
          if (controller.dimensionLargoController.text.isNotEmpty)
            'largo': double.tryParse(controller.dimensionLargoController.text) ?? 0.0,
          if (controller.dimensionAnchoController.text.isNotEmpty)
            'ancho': double.tryParse(controller.dimensionAnchoController.text) ?? 0.0,
          if (controller.dimensionAltoController.text.isNotEmpty)
            'alto': double.tryParse(controller.dimensionAltoController.text) ?? 0.0,
        };
      }

      final Resource<Producto> result;
      if (isEditing && productoId != null) {
        result = await _actualizarProductoUseCase(
          productoId: productoId,
          empresaId: empresaId,
          // NO enviar sedeId - la sede no se puede cambiar al actualizar
          unidadMedidaId: controller.selectedUnidadMedidaId,
          nombre: nombre,
          descripcion: descripcion.isEmpty ? null : descripcion,
          precio: precio,
          empresaCategoriaId: controller.selectedCategoriaId,
          empresaMarcaId: controller.selectedMarcaId,
          sku: controller.skuController.text.trim().isEmpty ? null : controller.skuController.text.trim(),
          codigoBarras: controller.codigoBarrasController.text.trim().isEmpty ? null : controller.codigoBarrasController.text.trim(),
          precioCosto: controller.precioCostoController.currencyValue > 0 ? controller.precioCostoController.currencyValue : null,
          // DEPRECATED: Stock ahora se maneja mediante ProductoStock por sede
          // stock: controller.stockController.text.isEmpty ? null : int.tryParse(controller.stockController.text),
          // stockMinimo: controller.stockMinimoController.text.isEmpty ? null : int.tryParse(controller.stockMinimoController.text),
          peso: controller.pesoController.text.isEmpty ? null : double.tryParse(controller.pesoController.text),
          dimensiones: dimensiones,
          videoUrl: controller.videoUrlController.text.trim(),
          impuestoPorcentaje: controller.impuestoPorcentajeController.text.isEmpty
              ? null
              : double.tryParse(controller.impuestoPorcentajeController.text),
          descuentoMaximo: controller.descuentoMaximoController.text.isEmpty
              ? null
              : double.tryParse(controller.descuentoMaximoController.text),
          visibleMarketplace: controller.visibleMarketplace,
          destacado: controller.destacado,
          enOferta: controller.enOferta,
          tieneVariantes: controller.tieneVariantes,
          esCombo: controller.esCombo,
          tipoPrecioCombo: controller.esCombo ? controller.tipoPrecioCombo : null,
          precioOferta: controller.enOferta ? controller.precioOfertaController.currencyValue : null,
          fechaInicioOferta: controller.enOferta ? controller.fechaInicioOferta : null,
          fechaFinOferta: controller.enOferta ? controller.fechaFinOferta : null,
          imagenesIds: finalImagenesIds.isNotEmpty ? finalImagenesIds : null,
          configuracionPrecioId: controller.selectedConfiguracionPrecioId,
        );
      } else {
        result = await _crearProductoUseCase(
          empresaId: empresaId,
          sedesIds: controller.selectedSedesIds,
          unidadMedidaId: controller.selectedUnidadMedidaId,
          nombre: nombre,
          descripcion: descripcion.isEmpty ? null : descripcion,
          precio: precio,
          empresaCategoriaId: controller.selectedCategoriaId,
          empresaMarcaId: controller.selectedMarcaId,
          sku: controller.skuController.text.trim().isEmpty ? null : controller.skuController.text.trim(),
          codigoBarras: controller.codigoBarrasController.text.trim().isEmpty ? null : controller.codigoBarrasController.text.trim(),
          precioCosto: controller.precioCostoController.currencyValue > 0 ? controller.precioCostoController.currencyValue : null,
          // Stock ya no se envía en creación, se agrega después mediante ProductoStock
          // stock: 0,
          // stockMinimo: null,
          peso: controller.pesoController.text.isEmpty ? null : double.tryParse(controller.pesoController.text),
          dimensiones: dimensiones,
          videoUrl: controller.videoUrlController.text.trim(),
          impuestoPorcentaje: controller.impuestoPorcentajeController.text.isEmpty
              ? null
              : double.tryParse(controller.impuestoPorcentajeController.text),
          descuentoMaximo: controller.descuentoMaximoController.text.isEmpty
              ? null
              : double.tryParse(controller.descuentoMaximoController.text),
          visibleMarketplace: controller.visibleMarketplace,
          destacado: controller.destacado,
          enOferta: controller.enOferta,
          tieneVariantes: controller.tieneVariantes,
          esCombo: controller.esCombo,
          tipoPrecioCombo: controller.esCombo ? controller.tipoPrecioCombo : null,
          precioOferta: controller.enOferta ? controller.precioOfertaController.currencyValue : null,
          fechaInicioOferta: controller.enOferta ? controller.fechaInicioOferta : null,
          fechaFinOferta: controller.enOferta ? controller.fechaFinOferta : null,
          imagenesIds: finalImagenesIds.isNotEmpty ? finalImagenesIds : null,
          configuracionPrecioId: controller.selectedConfiguracionPrecioId,
        );
      }

      if (result is Success<Producto>) {
        final producto = result.data;

        // Guardar atributos de plantilla si hay (solo para productos simples)
        if (!controller.tieneVariantes && !controller.esCombo && controller.selectedPlantillaId != null) {
          await _guardarAtributos(
            productoId: producto.id,
            empresaId: empresaId,
            valores: controller.plantillaAtributosValues,
          );
        }

        controller.clearChanges();
        emit(ProductoFormSuccess(
          producto: producto,
          isEditing: isEditing,
          message: isEditing ? 'Producto actualizado' : 'Producto creado',
        ));
      } else if (result is Error) {
        emit(ProductoFormError(
          message: (result as Error).message,
          type: ProductoFormErrorType.general,
        ));
      }
    } catch (e) {
      emit(ProductoFormError(
        message: 'Error: $e',
        type: ProductoFormErrorType.general,
      ));
    }
  }

  /// Guarda los atributos de un producto
  Future<void> _guardarAtributos({
    required String productoId,
    required String empresaId,
    required Map<String, String> valores,
  }) async {
    if (valores.isEmpty) return;

    try {
      final atributos = valores.entries
          .map((e) => VarianteAtributoDto(
                atributoId: e.key,
                valor: e.value,
              ))
          .toList();

      await _productoRemoteDataSource.setProductoAtributos(
        productoId: productoId,
        empresaId: empresaId,
        data: {'atributos': atributos.map((a) => a.toJson()).toList()},
      );
    } catch (e) {
      // No emitir error, solo loggear - los atributos son secundarios
      // El producto ya fue guardado exitosamente
    }
  }
}
