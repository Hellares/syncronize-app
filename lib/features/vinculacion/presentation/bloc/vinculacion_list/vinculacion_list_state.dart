import 'package:equatable/equatable.dart';
import '../../../domain/entities/vinculacion.dart';

abstract class VinculacionListState extends Equatable {
  const VinculacionListState();
  @override
  List<Object?> get props => [];
}

class VinculacionListInitial extends VinculacionListState {
  const VinculacionListInitial();
}

class VinculacionListLoading extends VinculacionListState {
  const VinculacionListLoading();
}

class VinculacionListLoaded extends VinculacionListState {
  final List<VinculacionEmpresa> items;
  final int total;
  final int page;
  final int totalPages;
  final String? tipo;
  final String? estado;

  const VinculacionListLoaded({
    required this.items,
    required this.total,
    required this.page,
    required this.totalPages,
    this.tipo,
    this.estado,
  });

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [items, total, page, tipo, estado];
}

class VinculacionListError extends VinculacionListState {
  final String message;
  const VinculacionListError(this.message);
  @override
  List<Object?> get props => [message];
}
