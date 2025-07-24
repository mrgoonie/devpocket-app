// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ErrorResponse _$ErrorResponseFromJson(Map<String, dynamic> json) =>
    ErrorResponse(
      detail: json['detail'] as String,
      code: json['code'] as String?,
      context: json['context'] as Map<String, dynamic>?,
      errors: (json['errors'] as List<dynamic>?)
          ?.map((e) => FieldError.fromJson(e as Map<String, dynamic>))
          .toList(),
      timestamp: json['timestamp'] as String?,
      path: json['path'] as String?,
    );

Map<String, dynamic> _$ErrorResponseToJson(ErrorResponse instance) =>
    <String, dynamic>{
      'detail': instance.detail,
      'code': instance.code,
      'context': instance.context,
      'errors': instance.errors?.map((e) => e.toJson()).toList(),
      'timestamp': instance.timestamp,
      'path': instance.path,
    };

FieldError _$FieldErrorFromJson(Map<String, dynamic> json) => FieldError(
      field: json['field'] as String,
      message: json['message'] as String,
      code: json['code'] as String?,
    );

Map<String, dynamic> _$FieldErrorToJson(FieldError instance) =>
    <String, dynamic>{
      'field': instance.field,
      'message': instance.message,
      'code': instance.code,
    };
