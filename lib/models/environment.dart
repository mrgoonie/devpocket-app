import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'enums.dart';
import 'resource_limits.dart';

part 'environment.g.dart';

@JsonSerializable(explicitToJson: true)
class Environment extends Equatable {
  final String id;
  final String name;
  
  @JsonKey(name: 'template_id')
  final String templateId;
  
  final EnvironmentStatus status;
  
  @JsonKey(name: 'resource_limits')
  final ResourceLimits resourceLimits;
  
  @JsonKey(name: 'environment_variables')
  final Map<String, String> environmentVariables;
  
  @JsonKey(name: 'external_url')
  final String? externalUrl;
  
  @JsonKey(name: 'web_port')
  final int? webPort;
  
  @JsonKey(name: 'ssh_port')
  final int? sshPort;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  
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
    required this.templateId,
    required this.status,
    required this.resourceLimits,
    required this.environmentVariables,
    this.externalUrl,
    this.webPort,
    this.sshPort,
    required this.createdAt,
    required this.updatedAt,
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
    String? templateId,
    EnvironmentStatus? status,
    ResourceLimits? resourceLimits,
    Map<String, String>? environmentVariables,
    String? externalUrl,
    int? webPort,
    int? sshPort,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastAccessed,
    double? cpuUsage,
    double? memoryUsage,
    double? storageUsage,
  }) {
    return Environment(
      id: id ?? this.id,
      name: name ?? this.name,
      templateId: templateId ?? this.templateId,
      status: status ?? this.status,
      resourceLimits: resourceLimits ?? this.resourceLimits,
      environmentVariables: environmentVariables ?? this.environmentVariables,
      externalUrl: externalUrl ?? this.externalUrl,
      webPort: webPort ?? this.webPort,
      sshPort: sshPort ?? this.sshPort,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    templateId,
    status,
    resourceLimits,
    environmentVariables,
    externalUrl,
    webPort,
    sshPort,
    createdAt,
    updatedAt,
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
  
  @JsonKey(name: 'template_id')
  final String templateId;
  
  @JsonKey(name: 'resource_limits')
  final ResourceLimits? resourceLimits;
  
  @JsonKey(name: 'environment_variables')
  final Map<String, String>? environmentVariables;

  const CreateEnvironmentRequest({
    required this.name,
    required this.templateId,
    this.resourceLimits,
    this.environmentVariables,
  });

  factory CreateEnvironmentRequest.fromJson(Map<String, dynamic> json) => 
      _$CreateEnvironmentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateEnvironmentRequestToJson(this);

  @override
  List<Object?> get props => [name, templateId, resourceLimits, environmentVariables];
}