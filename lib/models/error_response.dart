import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'error_response.g.dart';

@JsonSerializable(explicitToJson: true)
class ErrorResponse extends Equatable {
  final String detail;
  final String? code;
  final Map<String, dynamic>? context;
  final List<FieldError>? errors;
  final String? timestamp;
  final String? path;

  const ErrorResponse({
    required this.detail,
    this.code,
    this.context,
    this.errors,
    this.timestamp,
    this.path,
  });

  factory ErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ErrorResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ErrorResponseToJson(this);

  @override
  List<Object?> get props => [detail, code, context, errors, timestamp, path];
}

@JsonSerializable(explicitToJson: true)
class FieldError extends Equatable {
  final String field;
  final String message;
  final String? code;

  const FieldError({
    required this.field,
    required this.message,
    this.code,
  });

  factory FieldError.fromJson(Map<String, dynamic> json) =>
      _$FieldErrorFromJson(json);
  Map<String, dynamic> toJson() => _$FieldErrorToJson(this);

  @override
  List<Object?> get props => [field, message, code];
}
