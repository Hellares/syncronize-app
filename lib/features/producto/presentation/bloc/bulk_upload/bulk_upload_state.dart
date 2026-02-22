import 'package:equatable/equatable.dart';
import '../../../domain/entities/bulk_upload_result.dart';

abstract class BulkUploadState extends Equatable {
  const BulkUploadState();

  @override
  List<Object?> get props => [];
}

class BulkUploadInitial extends BulkUploadState {
  const BulkUploadInitial();
}

class BulkUploadDownloadingTemplate extends BulkUploadState {
  const BulkUploadDownloadingTemplate();
}

class BulkUploadTemplateDownloaded extends BulkUploadState {
  final String filePath;

  const BulkUploadTemplateDownloaded(this.filePath);

  @override
  List<Object?> get props => [filePath];
}

class BulkUploadUploading extends BulkUploadState {
  const BulkUploadUploading();
}

class BulkUploadSuccess extends BulkUploadState {
  final BulkUploadResult result;

  const BulkUploadSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class BulkUploadError extends BulkUploadState {
  final String message;
  final String? errorCode;

  const BulkUploadError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}
