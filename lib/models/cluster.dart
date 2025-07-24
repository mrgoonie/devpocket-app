import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'cluster.g.dart';

@JsonSerializable(explicitToJson: true)
class Cluster extends Equatable {
  final String id;
  final String name;
  final String region;
  final bool active;

  @JsonKey(name: 'max_environments')
  final int maxEnvironments;

  @JsonKey(name: 'current_environments')
  final int currentEnvironments;

  @JsonKey(name: 'available_resources')
  final ClusterResources availableResources;

  @JsonKey(name: 'used_resources')
  final ClusterResources usedResources;

  @JsonKey(name: 'health_status')
  final String healthStatus;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const Cluster({
    required this.id,
    required this.name,
    required this.region,
    required this.active,
    required this.maxEnvironments,
    required this.currentEnvironments,
    required this.availableResources,
    required this.usedResources,
    required this.healthStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Cluster.fromJson(Map<String, dynamic> json) =>
      _$ClusterFromJson(json);
  Map<String, dynamic> toJson() => _$ClusterToJson(this);

  @override
  List<Object?> get props => [
        id,
        name,
        region,
        active,
        maxEnvironments,
        currentEnvironments,
        availableResources,
        usedResources,
        healthStatus,
        createdAt,
        updatedAt,
      ];
}

@JsonSerializable(explicitToJson: true)
class ClusterResources extends Equatable {
  final double cpu;
  final double memory;
  final double storage;

  const ClusterResources({
    required this.cpu,
    required this.memory,
    required this.storage,
  });

  factory ClusterResources.fromJson(Map<String, dynamic> json) =>
      _$ClusterResourcesFromJson(json);
  Map<String, dynamic> toJson() => _$ClusterResourcesToJson(this);

  @override
  List<Object?> get props => [cpu, memory, storage];
}

@JsonSerializable(explicitToJson: true)
class ClusterHealth extends Equatable {
  final String status;
  final String message;

  @JsonKey(name: 'last_checked')
  final DateTime lastChecked;

  final Map<String, dynamic>? details;

  const ClusterHealth({
    required this.status,
    required this.message,
    required this.lastChecked,
    this.details,
  });

  factory ClusterHealth.fromJson(Map<String, dynamic> json) =>
      _$ClusterHealthFromJson(json);
  Map<String, dynamic> toJson() => _$ClusterHealthToJson(this);

  @override
  List<Object?> get props => [status, message, lastChecked, details];
}