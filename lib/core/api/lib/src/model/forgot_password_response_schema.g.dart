// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forgot_password_response_schema.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ForgotPasswordResponseSchema extends ForgotPasswordResponseSchema {
  @override
  final String message;
  @override
  final String? resetToken;

  factory _$ForgotPasswordResponseSchema([
    void Function(ForgotPasswordResponseSchemaBuilder)? updates,
  ]) => (ForgotPasswordResponseSchemaBuilder()..update(updates))._build();

  _$ForgotPasswordResponseSchema._({required this.message, this.resetToken})
    : super._();
  @override
  ForgotPasswordResponseSchema rebuild(
    void Function(ForgotPasswordResponseSchemaBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ForgotPasswordResponseSchemaBuilder toBuilder() =>
      ForgotPasswordResponseSchemaBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ForgotPasswordResponseSchema &&
        message == other.message &&
        resetToken == other.resetToken;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jc(_$hash, resetToken.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ForgotPasswordResponseSchema')
          ..add('message', message)
          ..add('resetToken', resetToken))
        .toString();
  }
}

class ForgotPasswordResponseSchemaBuilder
    implements
        Builder<
          ForgotPasswordResponseSchema,
          ForgotPasswordResponseSchemaBuilder
        > {
  _$ForgotPasswordResponseSchema? _$v;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  String? _resetToken;
  String? get resetToken => _$this._resetToken;
  set resetToken(String? resetToken) => _$this._resetToken = resetToken;

  ForgotPasswordResponseSchemaBuilder() {
    ForgotPasswordResponseSchema._defaults(this);
  }

  ForgotPasswordResponseSchemaBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _message = $v.message;
      _resetToken = $v.resetToken;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ForgotPasswordResponseSchema other) {
    _$v = other as _$ForgotPasswordResponseSchema;
  }

  @override
  void update(void Function(ForgotPasswordResponseSchemaBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ForgotPasswordResponseSchema build() => _build();

  _$ForgotPasswordResponseSchema _build() {
    final _$result =
        _$v ??
        _$ForgotPasswordResponseSchema._(
          message: BuiltValueNullFieldError.checkNotNull(
            message,
            r'ForgotPasswordResponseSchema',
            'message',
          ),
          resetToken: resetToken,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
