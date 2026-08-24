// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forgot_password_schema.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ForgotPasswordSchema extends ForgotPasswordSchema {
  @override
  final String email;

  factory _$ForgotPasswordSchema([
    void Function(ForgotPasswordSchemaBuilder)? updates,
  ]) => (ForgotPasswordSchemaBuilder()..update(updates))._build();

  _$ForgotPasswordSchema._({required this.email}) : super._();
  @override
  ForgotPasswordSchema rebuild(
    void Function(ForgotPasswordSchemaBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ForgotPasswordSchemaBuilder toBuilder() =>
      ForgotPasswordSchemaBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ForgotPasswordSchema && email == other.email;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'ForgotPasswordSchema',
    )..add('email', email)).toString();
  }
}

class ForgotPasswordSchemaBuilder
    implements Builder<ForgotPasswordSchema, ForgotPasswordSchemaBuilder> {
  _$ForgotPasswordSchema? _$v;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  ForgotPasswordSchemaBuilder() {
    ForgotPasswordSchema._defaults(this);
  }

  ForgotPasswordSchemaBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _email = $v.email;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ForgotPasswordSchema other) {
    _$v = other as _$ForgotPasswordSchema;
  }

  @override
  void update(void Function(ForgotPasswordSchemaBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ForgotPasswordSchema build() => _build();

  _$ForgotPasswordSchema _build() {
    final _$result =
        _$v ??
        _$ForgotPasswordSchema._(
          email: BuiltValueNullFieldError.checkNotNull(
            email,
            r'ForgotPasswordSchema',
            'email',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
