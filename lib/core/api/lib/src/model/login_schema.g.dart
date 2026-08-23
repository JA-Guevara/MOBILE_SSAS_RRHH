// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_schema.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LoginSchema extends LoginSchema {
  @override
  final String email;
  @override
  final String password;

  factory _$LoginSchema([void Function(LoginSchemaBuilder)? updates]) =>
      (LoginSchemaBuilder()..update(updates))._build();

  _$LoginSchema._({required this.email, required this.password}) : super._();
  @override
  LoginSchema rebuild(void Function(LoginSchemaBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LoginSchemaBuilder toBuilder() => LoginSchemaBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LoginSchema &&
        email == other.email &&
        password == other.password;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, password.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'LoginSchema')
          ..add('email', email)
          ..add('password', password))
        .toString();
  }
}

class LoginSchemaBuilder implements Builder<LoginSchema, LoginSchemaBuilder> {
  _$LoginSchema? _$v;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _password;
  String? get password => _$this._password;
  set password(String? password) => _$this._password = password;

  LoginSchemaBuilder() {
    LoginSchema._defaults(this);
  }

  LoginSchemaBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _email = $v.email;
      _password = $v.password;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LoginSchema other) {
    _$v = other as _$LoginSchema;
  }

  @override
  void update(void Function(LoginSchemaBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  LoginSchema build() => _build();

  _$LoginSchema _build() {
    final _$result = _$v ??
        _$LoginSchema._(
          email: BuiltValueNullFieldError.checkNotNull(
              email, r'LoginSchema', 'email'),
          password: BuiltValueNullFieldError.checkNotNull(
              password, r'LoginSchema', 'password'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
