// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String?,
      isActive: json['isActive'] as bool,
      isVerified: json['isVerified'] as bool,
      subscriptionPlan: json['subscriptionPlan'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLogin: json['lastLogin'] == null
          ? null
          : DateTime.parse(json['lastLogin'] as String),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'fullName': instance.fullName,
      'isActive': instance.isActive,
      'isVerified': instance.isVerified,
      'subscriptionPlan': instance.subscriptionPlan,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastLogin': instance.lastLogin?.toIso8601String(),
    };
