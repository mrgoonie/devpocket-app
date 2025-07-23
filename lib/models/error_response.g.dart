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
    );

Map<String, dynamic> _$ErrorResponseToJson(ErrorResponse instance) =>
    <String, dynamic>{
      'detail': instance.detail,
      'code': instance.code,
      'context': instance.context,
    };
