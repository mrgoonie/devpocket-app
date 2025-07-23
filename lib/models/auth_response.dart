import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'user.dart';

part 'auth_response.g.dart';

@JsonSerializable(explicitToJson: true)
class AuthResponse extends Equatable {
  @JsonKey(name: 'access_token')
  final String accessToken;
  
  @JsonKey(name: 'refresh_token')
  final String refreshToken;
  
  @JsonKey(name: 'token_type')
  final String tokenType;
  
  @JsonKey(name: 'expires_in')
  final int expiresIn;
  
  final User user;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => 
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);

  @override
  List<Object?> get props => [
    accessToken,
    refreshToken,
    tokenType,
    expiresIn,
    user,
  ];
}