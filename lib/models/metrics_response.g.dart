// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metrics_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MetricsResponse _$MetricsResponseFromJson(Map<String, dynamic> json) =>
    MetricsResponse(
      cpuUsage: (json['cpu_usage'] as num?)?.toDouble(),
      memoryUsage: (json['memory_usage'] as num?)?.toDouble(),
      diskUsage: (json['disk_usage'] as num?)?.toDouble(),
      networkIn: (json['network_in'] as num?)?.toDouble(),
      networkOut: (json['network_out'] as num?)?.toDouble(),
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$MetricsResponseToJson(MetricsResponse instance) =>
    <String, dynamic>{
      'cpu_usage': instance.cpuUsage,
      'memory_usage': instance.memoryUsage,
      'disk_usage': instance.diskUsage,
      'network_in': instance.networkIn,
      'network_out': instance.networkOut,
      'timestamp': instance.timestamp?.toIso8601String(),
    };

LogsResponse _$LogsResponseFromJson(Map<String, dynamic> json) => LogsResponse(
      logs: (json['logs'] as List<dynamic>).map((e) => e as String).toList(),
      total: (json['total'] as num).toInt(),
      hasMore: json['has_more'] as bool,
    );

Map<String, dynamic> _$LogsResponseToJson(LogsResponse instance) =>
    <String, dynamic>{
      'logs': instance.logs,
      'total': instance.total,
      'has_more': instance.hasMore,
    };

TemplateResponse _$TemplateResponseFromJson(Map<String, dynamic> json) =>
    TemplateResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      image: json['image'] as String,
      config: json['config'] as Map<String, dynamic>?,
      defaultResources: json['default_resources'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$TemplateResponseToJson(TemplateResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'image': instance.image,
      'config': instance.config,
      'default_resources': instance.defaultResources,
    };
