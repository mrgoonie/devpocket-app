import 'package:json_annotation/json_annotation.dart';

part 'metrics_response.g.dart';

@JsonSerializable()
class MetricsResponse {
  @JsonKey(name: 'cpu_usage')
  final double? cpuUsage;

  @JsonKey(name: 'memory_usage')
  final double? memoryUsage;

  @JsonKey(name: 'disk_usage')
  final double? diskUsage;

  @JsonKey(name: 'network_in')
  final double? networkIn;

  @JsonKey(name: 'network_out')
  final double? networkOut;

  @JsonKey(name: 'timestamp')
  final DateTime? timestamp;

  MetricsResponse({
    this.cpuUsage,
    this.memoryUsage,
    this.diskUsage,
    this.networkIn,
    this.networkOut,
    this.timestamp,
  });

  factory MetricsResponse.fromJson(Map<String, dynamic> json) =>
      _$MetricsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MetricsResponseToJson(this);
}

@JsonSerializable()
class LogsResponse {
  final List<String> logs;
  final int total;

  @JsonKey(name: 'has_more')
  final bool hasMore;

  LogsResponse({
    required this.logs,
    required this.total,
    required this.hasMore,
  });

  factory LogsResponse.fromJson(Map<String, dynamic> json) =>
      _$LogsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LogsResponseToJson(this);
}

@JsonSerializable()
class TemplateResponse {
  final String id;
  final String name;
  final String description;
  final String image;
  final Map<String, dynamic>? config;

  @JsonKey(name: 'default_resources')
  final Map<String, dynamic>? defaultResources;

  TemplateResponse({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    this.config,
    this.defaultResources,
  });

  factory TemplateResponse.fromJson(Map<String, dynamic> json) =>
      _$TemplateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TemplateResponseToJson(this);
}
