// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Template _$TemplateFromJson(Map<String, dynamic> json) => Template(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['display_name'] as String,
      description: json['description'] as String,
      category: $enumDecode(_$TemplateCategoryEnumMap, json['category']),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      dockerImage: json['docker_image'] as String,
      defaultPort: (json['default_port'] as num?)?.toInt(),
      defaultResources:
          Map<String, String>.from(json['default_resources'] as Map),
      environmentVariables:
          Map<String, String>.from(json['environment_variables'] as Map),
      startupCommands: (json['startup_commands'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      documentationUrl: json['documentation_url'] as String?,
      iconUrl: json['icon_url'] as String?,
      status: $enumDecode(_$TemplateStatusEnumMap, json['status']),
      version: json['version'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      usageCount: (json['usage_count'] as num).toInt(),
    );

Map<String, dynamic> _$TemplateToJson(Template instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'display_name': instance.displayName,
      'description': instance.description,
      'category': _$TemplateCategoryEnumMap[instance.category]!,
      'tags': instance.tags,
      'docker_image': instance.dockerImage,
      'default_port': instance.defaultPort,
      'default_resources': instance.defaultResources,
      'environment_variables': instance.environmentVariables,
      'startup_commands': instance.startupCommands,
      'documentation_url': instance.documentationUrl,
      'icon_url': instance.iconUrl,
      'status': _$TemplateStatusEnumMap[instance.status]!,
      'version': instance.version,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'usage_count': instance.usageCount,
    };

const _$TemplateCategoryEnumMap = {
  TemplateCategory.programmingLanguage: 'programming_language',
  TemplateCategory.framework: 'framework',
  TemplateCategory.database: 'database',
  TemplateCategory.devops: 'devops',
  TemplateCategory.operatingSystem: 'operating_system',
};

const _$TemplateStatusEnumMap = {
  TemplateStatus.active: 'active',
  TemplateStatus.deprecated: 'deprecated',
  TemplateStatus.beta: 'beta',
};
