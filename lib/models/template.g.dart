// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Template _$TemplateFromJson(Map<String, dynamic> json) => Template(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      image: json['image'] as String,
      icon: json['icon'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      defaultResources: json['default_resources'] as Map<String, dynamic>?,
      config: json['config'] as Map<String, dynamic>?,
      featured: json['featured'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$TemplateToJson(Template instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'image': instance.image,
      'icon': instance.icon,
      'tags': instance.tags,
      'default_resources': instance.defaultResources,
      'config': instance.config,
      'featured': instance.featured,
      'created_at': instance.createdAt.toIso8601String(),
    };
