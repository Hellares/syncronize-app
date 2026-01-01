part of 'verify_email_cubit.dart';

/// Estados del VerifyEmailCubit
class VerifyEmailState extends Equatable {
  final Resource? response;

  const VerifyEmailState({this.response});

  VerifyEmailState copyWith({Resource? response}) {
    return VerifyEmailState(response: response);
  }

  @override
  List<Object?> get props => [response];
}
