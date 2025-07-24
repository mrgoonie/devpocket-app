// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'environment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Environment _$EnvironmentFromJson(Map<String, dynamic> json) => Environment(
      id: json['id'] as String,
      name: json['name'] as String,
      templateId: json['template_id'] as String,
      status: $enumDecode(_$EnvironmentStatusEnumMap, json['status']),
      resourceLimits: ResourceLimits.fromJson(
          json['resource_limits'] as Map<String, dynamic>),
      environmentVariables:
          Map<String, String>.from(json['environment_variables'] as Map),
      externalUrl: json['external_url'] as String?,
      webPort: (json['web_port'] as num?)?.toInt(),
      sshPort: (json['ssh_port'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastAccessed: json['last_accessed'] == null
          ? null
          : DateTime.parse(json['last_accessed'] as String),
      cpuUsage: (json['cpu_usage'] as num?)?.toDouble(),
      memoryUsage: (json['memory_usage'] as num?)?.toDouble(),
      storageUsage: (json['storage_usage'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$EnvironmentToJson(Environment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'template_id': instance.templateId,
      'status': _$EnvironmentStatusEnumMap[instance.status]!,
      'resource_limits': instance.resourceLimits.toJson(),
      'environment_variables': instance.environmentVariables,
      'external_url': instance.externalUrl,
      'web_port': instance.webPort,
      'ssh_port': instance.sshPort,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'last_accessed': instance.lastAccessed?.toIso8601String(),
      'cpu_usage': instance.cpuUsage,
      'memory_usage': instance.memoryUsage,
      'storage_usage': instance.storageUsage,
    };

const _$EnvironmentStatusEnumMap = {
  EnvironmentStatus.creating: 'creating',
  EnvironmentStatus.running: 'running',
  EnvironmentStatus.stopped: 'stopped',
  EnvironmentStatus.terminated: 'terminated',
  EnvironmentStatus.error: 'error',
};

Resources _$ResourcesFromJson(Map<String, dynamic> json) => Resources(
      cpu: json['cpu'] as String,
      memory: json['memory'] as String,
      storage: json['storage'] as String,
    );

Map<String, dynamic> _$ResourcesToJson(Resources instance) => <String, dynamic>{
      'cpu': instance.cpu,
      'memory': instance.memory,
      'storage': instance.storage,
    };

CreateEnvironmentRequest _$CreateEnvironmentRequestFromJson(
        Map<String, dynamic> json) =>
    CreateEnvironmentRequest(
      name: json['name'] as String,
      templateId: json['template_id'] as String,
      resourceLimits: json['resource_limits'] == null
          ? null
          : ResourceLimits.fromJson(
              json['resource_limits'] as Map<String, dynamic>),
      environmentVariables:
          (json['environment_variables'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$CreateEnvironmentRequestToJson(
        CreateEnvironmentRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'template_id': instance.templateId,
      'resource_limits': instance.resourceLimits?.toJson(),
      'environment_variables': instance.environmentVariables,
    };
