// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_schema.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PermissionSchema extends PermissionSchema {
  @override
  final String id;
  @override
  final String name;
  @override
  final String resource;
  @override
  final String action;
  @override
  final String? description;

  factory _$PermissionSchema([
    void Function(PermissionSchemaBuilder)? updates,
  ]) => (PermissionSchemaBuilder()..update(updates))._build();

  _$PermissionSchema._({
    required this.id,
    required this.name,
    required this.resource,
    required this.action,
    this.description,
  }) : super._();
  @override
  PermissionSchema rebuild(void Function(PermissionSchemaBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PermissionSchemaBuilder toBuilder() =>
      PermissionSchemaBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PermissionSchema &&
        id == other.id &&
        name == other.name &&
        resource == other.resource &&
        action == other.action &&
        description == other.description;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, resource.hashCode);
    _$hash = $jc(_$hash, action.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PermissionSchema')
          ..add('id', id)
          ..add('name', name)
          ..add('resource', resource)
          ..add('action', action)
          ..add('description', description))
        .toString();
  }
}

class PermissionSchemaBuilder
    implements Builder<PermissionSchema, PermissionSchemaBuilder> {
  _$PermissionSchema? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _resource;
  String? get resource => _$this._resource;
  set resource(String? resource) => _$this._resource = resource;

  String? _action;
  String? get action => _$this._action;
  set action(String? action) => _$this._action = action;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  PermissionSchemaBuilder() {
    PermissionSchema._defaults(this);
  }

  PermissionSchemaBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _resource = $v.resource;
      _action = $v.action;
      _description = $v.description;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PermissionSchema other) {
    _$v = other as _$PermissionSchema;
  }

  @override
  void update(void Function(PermissionSchemaBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PermissionSchema build() => _build();

  _$PermissionSchema _build() {
    final _$result =
        _$v ??
        _$PermissionSchema._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'PermissionSchema',
            'id',
          ),
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'PermissionSchema',
            'name',
          ),
          resource: BuiltValueNullFieldError.checkNotNull(
            resource,
            r'PermissionSchema',
            'resource',
          ),
          action: BuiltValueNullFieldError.checkNotNull(
            action,
            r'PermissionSchema',
            'action',
          ),
          description: description,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
