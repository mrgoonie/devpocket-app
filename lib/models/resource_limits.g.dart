// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_limits.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResourceLimits _$ResourceLimitsFromJson(Map<String, dynamic> json) =>
    ResourceLimits(
      cpu: json['cpu'] as String?,
      memory: json['memory'] as String?,
      storage: json['storage'] as String?,
      maxInstances: (json['max_instances'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ResourceLimitsToJson(ResourceLimits instance) =>
    <String, dynamic>{
      'cpu': instance.cpu,
      'memory': instance.memory,
      'storage': instance.storage,
      'max_instances': instance.maxInstances,
    };
