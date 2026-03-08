import 'package:equatable/equatable.dart';
import '../../../domain/entities/tercerizacion.dart';

abstract class TercerizacionListState extends Equatable {
  const TercerizacionListState();
  @override
  List<Object?> get props => [];
}

class TercerizacionListInitial extends TercerizacionListState {
  const TercerizacionListInitial();
}

class TercerizacionListLoading extends TercerizacionListState {
  const TercerizacionListLoading();
}

class TercerizacionListLoaded extends TercerizacionListState {
  final List<TercerizacionServicio> items;
  final int total;
  final int page;
  final int totalPages;
  final String? tipo; // 'enviadas' | 'recibidas' | null (todas)
  final String? estado;

  const TercerizacionListLoaded({
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

class TercerizacionListError extends TercerizacionListState {
  final String message;
  const TercerizacionListError(this.message);
  @override
  List<Object?> get props => [message];
}
