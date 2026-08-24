// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role_schema.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RoleSchema extends RoleSchema {
  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  @override
  final bool isActive;
  @override
  final BuiltList<PermissionSchema>? permissions;

  factory _$RoleSchema([void Function(RoleSchemaBuilder)? updates]) =>
      (RoleSchemaBuilder()..update(updates))._build();

  _$RoleSchema._({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    this.permissions,
  }) : super._();
  @override
  RoleSchema rebuild(void Function(RoleSchemaBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RoleSchemaBuilder toBuilder() => RoleSchemaBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RoleSchema &&
        id == other.id &&
        name == other.name &&
        description == other.description &&
        isActive == other.isActive &&
        permissions == other.permissions;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, permissions.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RoleSchema')
          ..add('id', id)
          ..add('name', name)
          ..add('description', description)
          ..add('isActive', isActive)
          ..add('permissions', permissions))
        .toString();
  }
}

class RoleSchemaBuilder implements Builder<RoleSchema, RoleSchemaBuilder> {
  _$RoleSchema? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  ListBuilder<PermissionSchema>? _permissions;
  ListBuilder<PermissionSchema> get permissions =>
      _$this._permissions ??= ListBuilder<PermissionSchema>();
  set permissions(ListBuilder<PermissionSchema>? permissions) =>
      _$this._permissions = permissions;

  RoleSchemaBuilder() {
    RoleSchema._defaults(this);
  }

  RoleSchemaBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _description = $v.description;
      _isActive = $v.isActive;
      _permissions = $v.permissions?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RoleSchema other) {
    _$v = other as _$RoleSchema;
  }

  @override
  void update(void Function(RoleSchemaBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RoleSchema build() => _build();

  _$RoleSchema _build() {
    _$RoleSchema _$result;
    try {
      _$result =
          _$v ??
          _$RoleSchema._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'RoleSchema', 'id'),
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'RoleSchema',
              'name',
            ),
            description: description,
            isActive: BuiltValueNullFieldError.checkNotNull(
              isActive,
              r'RoleSchema',
              'isActive',
            ),
            permissions: _permissions?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'permissions';
        _permissions?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'RoleSchema',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
