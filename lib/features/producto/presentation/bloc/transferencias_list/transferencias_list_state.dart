import 'package:equatable/equatable.dart';
import '../../../domain/entities/transferencia_stock.dart';

abstract class TransferenciasListState extends Equatable {
  const TransferenciasListState();

  @override
  List<Object?> get props => [];
}

class TransferenciasListInitial extends TransferenciasListState {
  const TransferenciasListInitial();
}

class TransferenciasListLoading extends TransferenciasListState {
  const TransferenciasListLoading();
}

class TransferenciasListLoadingMore extends TransferenciasListState {
  final List<TransferenciaStock> currentTransferencias;

  const TransferenciasListLoadingMore(this.currentTransferencias);

  @override
  List<Object?> get props => [currentTransferencias];
}

class TransferenciasListLoaded extends TransferenciasListState {
  final List<TransferenciaStock> transferencias;
  final int total;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final EstadoTransferencia? filtroEstado;
  final String? filtroSedeId;

  const TransferenciasListLoaded({
    required this.transferencias,
    required this.total,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
    this.filtroEstado,
    this.filtroSedeId,
  });

  @override
  List<Object?> get props => [
        transferencias,
        total,
        currentPage,
        totalPages,
        hasMore,
        filtroEstado,
        filtroSedeId,
      ];
}

class TransferenciasListEmpty extends TransferenciasListState {
  const TransferenciasListEmpty();
}

class TransferenciasListError extends TransferenciasListState {
  final String message;
  final String? errorCode;

  const TransferenciasListError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}
