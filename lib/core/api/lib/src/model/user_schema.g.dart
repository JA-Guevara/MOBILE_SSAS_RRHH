// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_schema.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UserSchema extends UserSchema {
  @override
  final String id;
  @override
  final String name;
  @override
  final String email;
  @override
  final bool isActive;
  @override
  final bool emailVerified;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  factory _$UserSchema([void Function(UserSchemaBuilder)? updates]) =>
      (UserSchemaBuilder()..update(updates))._build();

  _$UserSchema._({
    required this.id,
    required this.name,
    required this.email,
    required this.isActive,
    required this.emailVerified,
    this.createdAt,
    this.updatedAt,
  }) : super._();
  @override
  UserSchema rebuild(void Function(UserSchemaBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserSchemaBuilder toBuilder() => UserSchemaBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserSchema &&
        id == other.id &&
        name == other.name &&
        email == other.email &&
        isActive == other.isActive &&
        emailVerified == other.emailVerified &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, emailVerified.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UserSchema')
          ..add('id', id)
          ..add('name', name)
          ..add('email', email)
          ..add('isActive', isActive)
          ..add('emailVerified', emailVerified)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class UserSchemaBuilder implements Builder<UserSchema, UserSchemaBuilder> {
  _$UserSchema? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  bool? _emailVerified;
  bool? get emailVerified => _$this._emailVerified;
  set emailVerified(bool? emailVerified) =>
      _$this._emailVerified = emailVerified;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  UserSchemaBuilder() {
    UserSchema._defaults(this);
  }

  UserSchemaBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _email = $v.email;
      _isActive = $v.isActive;
      _emailVerified = $v.emailVerified;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserSchema other) {
    _$v = other as _$UserSchema;
  }

  @override
  void update(void Function(UserSchemaBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UserSchema build() => _build();

  _$UserSchema _build() {
    final _$result =
        _$v ??
        _$UserSchema._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'UserSchema', 'id'),
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'UserSchema',
            'name',
          ),
          email: BuiltValueNullFieldError.checkNotNull(
            email,
            r'UserSchema',
            'email',
          ),
          isActive: BuiltValueNullFieldError.checkNotNull(
            isActive,
            r'UserSchema',
            'isActive',
          ),
          emailVerified: BuiltValueNullFieldError.checkNotNull(
            emailVerified,
            r'UserSchema',
            'emailVerified',
          ),
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
