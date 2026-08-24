// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reset_password_schema.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ResetPasswordSchema extends ResetPasswordSchema {
  @override
  final String token;
  @override
  final String newPassword;

  factory _$ResetPasswordSchema([
    void Function(ResetPasswordSchemaBuilder)? updates,
  ]) => (ResetPasswordSchemaBuilder()..update(updates))._build();

  _$ResetPasswordSchema._({required this.token, required this.newPassword})
    : super._();
  @override
  ResetPasswordSchema rebuild(
    void Function(ResetPasswordSchemaBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ResetPasswordSchemaBuilder toBuilder() =>
      ResetPasswordSchemaBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ResetPasswordSchema &&
        token == other.token &&
        newPassword == other.newPassword;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, token.hashCode);
    _$hash = $jc(_$hash, newPassword.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ResetPasswordSchema')
          ..add('token', token)
          ..add('newPassword', newPassword))
        .toString();
  }
}

class ResetPasswordSchemaBuilder
    implements Builder<ResetPasswordSchema, ResetPasswordSchemaBuilder> {
  _$ResetPasswordSchema? _$v;

  String? _token;
  String? get token => _$this._token;
  set token(String? token) => _$this._token = token;

  String? _newPassword;
  String? get newPassword => _$this._newPassword;
  set newPassword(String? newPassword) => _$this._newPassword = newPassword;

  ResetPasswordSchemaBuilder() {
    ResetPasswordSchema._defaults(this);
  }

  ResetPasswordSchemaBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _token = $v.token;
      _newPassword = $v.newPassword;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ResetPasswordSchema other) {
    _$v = other as _$ResetPasswordSchema;
  }

  @override
  void update(void Function(ResetPasswordSchemaBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ResetPasswordSchema build() => _build();

  _$ResetPasswordSchema _build() {
    final _$result =
        _$v ??
        _$ResetPasswordSchema._(
          token: BuiltValueNullFieldError.checkNotNull(
            token,
            r'ResetPasswordSchema',
            'token',
          ),
          newPassword: BuiltValueNullFieldError.checkNotNull(
            newPassword,
            r'ResetPasswordSchema',
            'newPassword',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
