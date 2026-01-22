import '../../domain/entities/stock_por_sede_info.dart';

class StockPorSedeInfoModel extends StockPorSedeInfo {
  const StockPorSedeInfoModel({
    required super.sedeId,
    required super.sedeNombre,
    required super.sedeCodigo,
    required super.cantidad,
  });

  factory StockPorSedeInfoModel.fromJson(Map<String, dynamic> json) {
    return StockPorSedeInfoModel(
      sedeId: json['sedeId'] as String,
      sedeNombre: json['sedeNombre'] as String,
      sedeCodigo: json['sedeCodigo'] as String,
      cantidad: json['cantidad'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sedeId': sedeId,
      'sedeNombre': sedeNombre,
      'sedeCodigo': sedeCodigo,
      'cantidad': cantidad,
    };
  }

  factory StockPorSedeInfoModel.fromEntity(StockPorSedeInfo entity) {
    return StockPorSedeInfoModel(
      sedeId: entity.sedeId,
      sedeNombre: entity.sedeNombre,
      sedeCodigo: entity.sedeCodigo,
      cantidad: entity.cantidad,
    );
  }

  StockPorSedeInfo toEntity() => this;
}
