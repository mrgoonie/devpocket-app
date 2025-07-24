import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'resource_limits.g.dart';

@JsonSerializable(explicitToJson: true)
class ResourceLimits extends Equatable {
  final String? cpu;
  final String? memory;
  final String? storage;
  
  @JsonKey(name: 'max_instances')
  final int? maxInstances;

  const ResourceLimits({
    this.cpu,
    this.memory,
    this.storage,
    this.maxInstances,
  });

  factory ResourceLimits.fromJson(Map<String, dynamic> json) => 
      _$ResourceLimitsFromJson(json);
  Map<String, dynamic> toJson() => _$ResourceLimitsToJson(this);

  ResourceLimits copyWith({
    String? cpu,
    String? memory,
    String? storage,
    int? maxInstances,
  }) {
    return ResourceLimits(
      cpu: cpu ?? this.cpu,
      memory: memory ?? this.memory,
      storage: storage ?? this.storage,
      maxInstances: maxInstances ?? this.maxInstances,
    );
  }

  @override
  List<Object?> get props => [
    cpu,
    memory,
    storage,
    maxInstances,
  ];
}