import 'package:json_annotation/json_annotation.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum EnvironmentStatus {
  creating,
  running,
  stopped,
  terminated,
  error,
}

@JsonEnum(fieldRename: FieldRename.snake)
enum TemplateCategory {
  @JsonValue('programming_language')
  programmingLanguage,
  framework,
  database,
  devops,
  @JsonValue('operating_system')
  operatingSystem,
}

@JsonEnum(fieldRename: FieldRename.snake)
enum TemplateStatus {
  active,
  deprecated,
  beta,
}

@JsonEnum(fieldRename: FieldRename.snake)
enum EnvironmentTemplate {
  python,
  nodejs,
  golang,
  rust,
  ubuntu,
  custom,
}