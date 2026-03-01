part of 'consulta_ruc_cubit.dart';

enum ConsultaRucStatus {
  initial,
  loading,
  success,
  error,
  condicionInvalida,
}

class ConsultaRucState extends Equatable {
  final ConsultaRucStatus status;
  final ConsultaRuc? data;
  final String? errorMessage;

  const ConsultaRucState({
    this.status = ConsultaRucStatus.initial,
    this.data,
    this.errorMessage,
  });

  bool get isLoading => status == ConsultaRucStatus.loading;
  bool get isSuccess => status == ConsultaRucStatus.success;
  bool get isError => status == ConsultaRucStatus.error;
  bool get isCondicionInvalida => status == ConsultaRucStatus.condicionInvalida;
  bool get hasData => data != null;

  ConsultaRucState copyWith({
    ConsultaRucStatus? status,
    ConsultaRuc? data,
    String? errorMessage,
    bool clearData = false,
    bool clearError = false,
  }) {
    return ConsultaRucState(
      status: status ?? this.status,
      data: clearData ? null : (data ?? this.data),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}
