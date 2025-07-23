import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'error_response.g.dart';

@JsonSerializable(explicitToJson: true)
class ErrorResponse extends Equatable {
  final String detail;
  final String? code;
  final Map<String, dynamic>? context;

  const ErrorResponse({
    required this.detail,
    this.code,
    this.context,
  });

  factory ErrorResponse.fromJson(Map<String, dynamic> json) => 
      _$ErrorResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ErrorResponseToJson(this);

  @override
  List<Object?> get props => [detail, code, context];
}