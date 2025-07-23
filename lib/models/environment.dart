import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'environment.g.dart';

@JsonSerializable(explicitToJson: true)
class Environment extends Equatable {
  final String id;
  final String name;
  final String template;
  final String status;
  final Resources resources;
  @JsonKey(name: 'external_url')
  final String? externalUrl;
  @JsonKey(name: 'web_port')
  final int? webPort;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'last_accessed')
  final DateTime? lastAccessed;
  @JsonKey(name: 'cpu_usage')
  final double? cpuUsage;
  @JsonKey(name: 'memory_usage')
  final double? memoryUsage;
  @JsonKey(name: 'storage_usage')
  final double? storageUsage;

  const Environment({
    required this.id,
    required this.name,
    required this.template,
    required this.status,
    required this.resources,
    this.externalUrl,
    this.webPort,
    required this.createdAt,
    this.lastAccessed,
    this.cpuUsage,
    this.memoryUsage,
    this.storageUsage,
  });

  factory Environment.fromJson(Map<String, dynamic> json) => 
      _$EnvironmentFromJson(json);
  Map<String, dynamic> toJson() => _$EnvironmentToJson(this);

  Environment copyWith({
    String? id,
    String? name,
    String? template,
    String? status,
    Resources? resources,
    String? externalUrl,
    int? webPort,
    DateTime? createdAt,
    DateTime? lastAccessed,
    double? cpuUsage,
    double? memoryUsage,
    double? storageUsage,
  }) {
    return Environment(
      id: id ?? this.id,
      name: name ?? this.name,
      template: template ?? this.template,
      status: status ?? this.status,
      resources: resources ?? this.resources,
      externalUrl: externalUrl ?? this.externalUrl,
      webPort: webPort ?? this.webPort,
      createdAt: createdAt ?? this.createdAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      memoryUsage: memoryUsage ?? this.memoryUsage,
      storageUsage: storageUsage ?? this.storageUsage,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    template,
    status,
    resources,
    externalUrl,
    webPort,
    createdAt,
    lastAccessed,
    cpuUsage,
    memoryUsage,
    storageUsage,
  ];
}

@JsonSerializable(explicitToJson: true)
class Resources extends Equatable {
  final String cpu;
  final String memory;
  final String storage;

  const Resources({
    required this.cpu,
    required this.memory,
    required this.storage,
  });

  factory Resources.fromJson(Map<String, dynamic> json) => 
      _$ResourcesFromJson(json);
  Map<String, dynamic> toJson() => _$ResourcesToJson(this);

  @override
  List<Object?> get props => [cpu, memory, storage];
}

@JsonSerializable(explicitToJson: true)
class CreateEnvironmentRequest extends Equatable {
  final String name;
  final String template;
  final Resources? resources;
  @JsonKey(name: 'environment_variables')
  final Map<String, String>? environmentVariables;

  const CreateEnvironmentRequest({
    required this.name,
    required this.template,
    this.resources,
    this.environmentVariables,
  });

  factory CreateEnvironmentRequest.fromJson(Map<String, dynamic> json) => 
      _$CreateEnvironmentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateEnvironmentRequestToJson(this);

  @override
  List<Object?> get props => [name, template, resources, environmentVariables];
}