// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      isActive: json['is_active'] as bool,
      isVerified: json['is_verified'] as bool,
      subscriptionPlan: json['subscription_plan'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLogin: json['last_login'] == null
          ? null
          : DateTime.parse(json['last_login'] as String),
      preferredRegion: json['preferred_region'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'full_name': instance.fullName,
      'is_active': instance.isActive,
      'is_verified': instance.isVerified,
      'subscription_plan': instance.subscriptionPlan,
      'created_at': instance.createdAt.toIso8601String(),
      'last_login': instance.lastLogin?.toIso8601String(),
      'preferred_region': instance.preferredRegion,
      'avatar_url': instance.avatarUrl,
    };
