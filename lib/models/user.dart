import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'user.g.dart';

@JsonSerializable(explicitToJson: true)
class User extends Equatable {
  final String id;
  final String username;
  final String email;
  
  @JsonKey(name: 'full_name')
  final String? fullName;
  
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  
  @JsonKey(name: 'subscription_plan')
  final String subscriptionPlan;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'last_login')
  final DateTime? lastLogin;
  
  @JsonKey(name: 'preferred_region')
  final String? preferredRegion;
  
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  const User({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    required this.isActive,
    required this.isVerified,
    required this.subscriptionPlan,
    required this.createdAt,
    this.lastLogin,
    this.preferredRegion,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    bool? isActive,
    bool? isVerified,
    String? subscriptionPlan,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? preferredRegion,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      preferredRegion: preferredRegion ?? this.preferredRegion,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    username,
    email,
    fullName,
    isActive,
    isVerified,
    subscriptionPlan,
    createdAt,
    lastLogin,
    preferredRegion,
    avatarUrl,
  ];
}