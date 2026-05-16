import 'package:equatable/equatable.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../domain/entities/impresora_config.dart';

abstract class ImpresoraFormState extends Equatable {
  const ImpresoraFormState();
  @override
  List<Object?> get props => [];
}

class ImpresoraFormInitial extends ImpresoraFormState {
  const ImpresoraFormInitial();
}

class ImpresoraFormLoading extends ImpresoraFormState {
  const ImpresoraFormLoading();
}

class ImpresoraFormEditing extends ImpresoraFormState {
  final ImpresoraConfig original;
  const ImpresoraFormEditing(this.original);
  @override
  List<Object?> get props => [original];
}

class ImpresoraFormSaving extends ImpresoraFormState {
  const ImpresoraFormSaving();
}

class ImpresoraFormSaved extends ImpresoraFormState {
  final ImpresoraConfig impresora;
  const ImpresoraFormSaved(this.impresora);
  @override
  List<Object?> get props => [impresora];
}

class ImpresoraFormScanning extends ImpresoraFormState {
  const ImpresoraFormScanning();
}

class ImpresoraFormDevicesFound extends ImpresoraFormState {
  final List<BluetoothInfo> devices;
  const ImpresoraFormDevicesFound(this.devices);
  @override
  List<Object?> get props => [devices];
}

class ImpresoraFormPrinting extends ImpresoraFormState {
  const ImpresoraFormPrinting();
}

class ImpresoraFormPrintResult extends ImpresoraFormState {
  final bool ok;
  final String message;
  const ImpresoraFormPrintResult({required this.ok, required this.message});
  @override
  List<Object?> get props => [ok, message];
}

class ImpresoraFormError extends ImpresoraFormState {
  final String message;
  const ImpresoraFormError(this.message);
  @override
  List<Object?> get props => [message];
}
