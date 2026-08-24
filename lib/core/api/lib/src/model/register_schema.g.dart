// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_schema.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RegisterSchema extends RegisterSchema {
  @override
  final String name;
  @override
  final String email;
  @override
  final String password;

  factory _$RegisterSchema([void Function(RegisterSchemaBuilder)? updates]) =>
      (RegisterSchemaBuilder()..update(updates))._build();

  _$RegisterSchema._({
    required this.name,
    required this.email,
    required this.password,
  }) : super._();
  @override
  RegisterSchema rebuild(void Function(RegisterSchemaBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RegisterSchemaBuilder toBuilder() => RegisterSchemaBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RegisterSchema &&
        name == other.name &&
        email == other.email &&
        password == other.password;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, password.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RegisterSchema')
          ..add('name', name)
          ..add('email', email)
          ..add('password', password))
        .toString();
  }
}

class RegisterSchemaBuilder
    implements Builder<RegisterSchema, RegisterSchemaBuilder> {
  _$RegisterSchema? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _password;
  String? get password => _$this._password;
  set password(String? password) => _$this._password = password;

  RegisterSchemaBuilder() {
    RegisterSchema._defaults(this);
  }

  RegisterSchemaBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _email = $v.email;
      _password = $v.password;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RegisterSchema other) {
    _$v = other as _$RegisterSchema;
  }

  @override
  void update(void Function(RegisterSchemaBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RegisterSchema build() => _build();

  _$RegisterSchema _build() {
    final _$result =
        _$v ??
        _$RegisterSchema._(
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'RegisterSchema',
            'name',
          ),
          email: BuiltValueNullFieldError.checkNotNull(
            email,
            r'RegisterSchema',
            'email',
          ),
          password: BuiltValueNullFieldError.checkNotNull(
            password,
            r'RegisterSchema',
            'password',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
