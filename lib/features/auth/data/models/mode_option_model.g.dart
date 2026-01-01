// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mode_option_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModeOptionModel _$ModeOptionModelFromJson(Map<String, dynamic> json) =>
    ModeOptionModel(
      type: json['type'] as String,
      label: json['label'] as String,
      description: json['description'] as String,
      availableCompanies: (json['availableCompanies'] as List<dynamic>?)
          ?.map(
            (e) => AvailableCompanyModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$ModeOptionModelToJson(ModeOptionModel instance) =>
    <String, dynamic>{
      'type': instance.type,
      'label': instance.label,
      'description': instance.description,
      'availableCompanies': instance.availableCompanies
          ?.map((e) => e.toJson())
          .toList(),
    };
