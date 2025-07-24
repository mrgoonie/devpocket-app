// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cluster.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Cluster _$ClusterFromJson(Map<String, dynamic> json) => Cluster(
      id: json['id'] as String,
      name: json['name'] as String,
      region: json['region'] as String,
      active: json['active'] as bool,
      maxEnvironments: (json['max_environments'] as num).toInt(),
      currentEnvironments: (json['current_environments'] as num).toInt(),
      availableResources: ClusterResources.fromJson(
          json['available_resources'] as Map<String, dynamic>),
      usedResources: ClusterResources.fromJson(
          json['used_resources'] as Map<String, dynamic>),
      healthStatus: json['health_status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ClusterToJson(Cluster instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'region': instance.region,
      'active': instance.active,
      'max_environments': instance.maxEnvironments,
      'current_environments': instance.currentEnvironments,
      'available_resources': instance.availableResources.toJson(),
      'used_resources': instance.usedResources.toJson(),
      'health_status': instance.healthStatus,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

ClusterResources _$ClusterResourcesFromJson(Map<String, dynamic> json) =>
    ClusterResources(
      cpu: (json['cpu'] as num).toDouble(),
      memory: (json['memory'] as num).toDouble(),
      storage: (json['storage'] as num).toDouble(),
    );

Map<String, dynamic> _$ClusterResourcesToJson(ClusterResources instance) =>
    <String, dynamic>{
      'cpu': instance.cpu,
      'memory': instance.memory,
      'storage': instance.storage,
    };

ClusterHealth _$ClusterHealthFromJson(Map<String, dynamic> json) =>
    ClusterHealth(
      status: json['status'] as String,
      message: json['message'] as String,
      lastChecked: DateTime.parse(json['last_checked'] as String),
      details: json['details'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ClusterHealthToJson(ClusterHealth instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'last_checked': instance.lastChecked.toIso8601String(),
      'details': instance.details,
    };
