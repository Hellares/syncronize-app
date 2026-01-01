import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/usecases/verify_email_usecase.dart';
import '../../../../../core/utils/resource.dart';

part 'verify_email_state.dart';

/// Cubit para manejar la verificación de email
@injectable
class VerifyEmailCubit extends Cubit<VerifyEmailState> {
  final VerifyEmailUseCase verifyEmailUseCase;

  VerifyEmailCubit({required this.verifyEmailUseCase}) : super(const VerifyEmailState());

  /// Verificar email con token
  Future<void> verifyEmail(String token) async {
    emit(state.copyWith(response: Loading()));

    final params = VerifyEmailParams(token: token);
    final result = await verifyEmailUseCase(params);

    emit(state.copyWith(response: result));
  }

  /// Resetear estado
  void reset() {
    emit(const VerifyEmailState());
  }
}
