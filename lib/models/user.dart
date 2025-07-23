import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'user.g.dart';

@JsonSerializable(explicitToJson: true)
class User extends Equatable {
  final String id;
  final String username;
  final String email;
  final String? fullName;
  final bool isActive;
  final bool isVerified;
  final String subscriptionPlan;
  final DateTime createdAt;
  final DateTime? lastLogin;

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
  ];
}