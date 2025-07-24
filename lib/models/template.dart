import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'enums.dart';

part 'template.g.dart';

@JsonSerializable(explicitToJson: true)
class Template extends Equatable {
  final String id;
  final String name;
  
  @JsonKey(name: 'display_name')
  final String displayName;
  
  final String description;
  final TemplateCategory category;
  final List<String> tags;
  
  @JsonKey(name: 'docker_image')
  final String dockerImage;
  
  @JsonKey(name: 'default_port')
  final int? defaultPort;
  
  @JsonKey(name: 'default_resources')
  final Map<String, String> defaultResources;
  
  @JsonKey(name: 'environment_variables')
  final Map<String, String> environmentVariables;
  
  @JsonKey(name: 'startup_commands')
  final List<String> startupCommands;
  
  @JsonKey(name: 'documentation_url')
  final String? documentationUrl;
  
  @JsonKey(name: 'icon_url')
  final String? iconUrl;
  
  final TemplateStatus status;
  final String version;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  
  @JsonKey(name: 'usage_count')
  final int usageCount;

  const Template({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.category,
    required this.tags,
    required this.dockerImage,
    this.defaultPort,
    required this.defaultResources,
    required this.environmentVariables,
    required this.startupCommands,
    this.documentationUrl,
    this.iconUrl,
    required this.status,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    required this.usageCount,
  });

  factory Template.fromJson(Map<String, dynamic> json) =>
      _$TemplateFromJson(json);

  Map<String, dynamic> toJson() => _$TemplateToJson(this);

  @override
  List<Object?> get props => [
    id,
    name,
    displayName,
    description,
    category,
    tags,
    dockerImage,
    defaultPort,
    defaultResources,
    environmentVariables,
    startupCommands,
    documentationUrl,
    iconUrl,
    status,
    version,
    createdAt,
    updatedAt,
    usageCount,
  ];
}