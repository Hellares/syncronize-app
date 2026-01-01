import 'dart:io';
import 'package:equatable/equatable.dart';

/// Estados del gestor de imágenes de producto
abstract class ProductoImagesState extends Equatable {
  const ProductoImagesState();

  @override
  List<Object?> get props => [];
}

class ProductoImagesInitial extends ProductoImagesState {
  const ProductoImagesInitial();
}

class ProductoImagesLoaded extends ProductoImagesState {
  final List<ProductoImage> images;

  const ProductoImagesLoaded({required this.images});

  bool get hasImages => images.isNotEmpty;
  bool get isUploading => images.any((img) => img.isUploading);
  bool get hasErrors => images.any((img) => img.hasError);
  bool get hasPendingImages => images.any((img) => img.isLocal);
  int get pendingImagesCount => images.where((img) => img.isLocal).length;

  ProductoImage? get mainImage =>
      images.firstWhere((img) => img.isMain, orElse: () => images.first);

  @override
  List<Object?> get props => [images];
}

/// Modelo de imagen de producto
class ProductoImage extends Equatable {
  final String id;
  final String? url;
  final String? urlThumbnail;
  final File? file;
  final bool isLocal; // true = solo local, false = subido al servidor
  final bool isUploading;
  final double uploadProgress;
  final bool hasError;
  final String? errorMessage;
  final bool isMain;
  final int order;

  const ProductoImage({
    required this.id,
    this.url,
    this.urlThumbnail,
    this.file,
    this.isLocal = false,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.hasError = false,
    this.errorMessage,
    this.isMain = false,
    this.order = 0,
  });

  ProductoImage copyWith({
    String? id,
    String? url,
    String? urlThumbnail,
    File? file,
    bool? isLocal,
    bool? isUploading,
    double? uploadProgress,
    bool? hasError,
    String? errorMessage,
    bool? isMain,
    int? order,
  }) {
    return ProductoImage(
      id: id ?? this.id,
      url: url ?? this.url,
      urlThumbnail: urlThumbnail ?? this.urlThumbnail,
      file: file ?? this.file,
      isLocal: isLocal ?? this.isLocal,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      isMain: isMain ?? this.isMain,
      order: order ?? this.order,
    );
  }

  @override
  List<Object?> get props => [
        id,
        url,
        urlThumbnail,
        file,
        isLocal,
        isUploading,
        uploadProgress,
        hasError,
        errorMessage,
        isMain,
        order,
      ];
}
