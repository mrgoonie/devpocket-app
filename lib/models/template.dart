import 'package:json_annotation/json_annotation.dart';

part 'template.g.dart';

@JsonSerializable()
class Template {
  final String id;
  final String name;
  final String description;
  final String category;
  final String image;
  final String icon;
  final List<String> tags;
  
  @JsonKey(name: 'default_resources')
  final Map<String, dynamic>? defaultResources;
  
  final Map<String, dynamic>? config;
  final bool featured;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Template({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.image,
    required this.icon,
    required this.tags,
    this.defaultResources,
    this.config,
    required this.featured,
    required this.createdAt,
  });

  factory Template.fromJson(Map<String, dynamic> json) =>
      _$TemplateFromJson(json);

  Map<String, dynamic> toJson() => _$TemplateToJson(this);
}