// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assign_permissions_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AssignPermissionsRequest extends AssignPermissionsRequest {
  @override
  final BuiltList<String> permissionIds;

  factory _$AssignPermissionsRequest(
          [void Function(AssignPermissionsRequestBuilder)? updates]) =>
      (AssignPermissionsRequestBuilder()..update(updates))._build();

  _$AssignPermissionsRequest._({required this.permissionIds}) : super._();
  @override
  AssignPermissionsRequest rebuild(
          void Function(AssignPermissionsRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AssignPermissionsRequestBuilder toBuilder() =>
      AssignPermissionsRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AssignPermissionsRequest &&
        permissionIds == other.permissionIds;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, permissionIds.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AssignPermissionsRequest')
          ..add('permissionIds', permissionIds))
        .toString();
  }
}

class AssignPermissionsRequestBuilder
    implements
        Builder<AssignPermissionsRequest, AssignPermissionsRequestBuilder> {
  _$AssignPermissionsRequest? _$v;

  ListBuilder<String>? _permissionIds;
  ListBuilder<String> get permissionIds =>
      _$this._permissionIds ??= ListBuilder<String>();
  set permissionIds(ListBuilder<String>? permissionIds) =>
      _$this._permissionIds = permissionIds;

  AssignPermissionsRequestBuilder() {
    AssignPermissionsRequest._defaults(this);
  }

  AssignPermissionsRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _permissionIds = $v.permissionIds.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AssignPermissionsRequest other) {
    _$v = other as _$AssignPermissionsRequest;
  }

  @override
  void update(void Function(AssignPermissionsRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AssignPermissionsRequest build() => _build();

  _$AssignPermissionsRequest _build() {
    _$AssignPermissionsRequest _$result;
    try {
      _$result = _$v ??
          _$AssignPermissionsRequest._(
            permissionIds: permissionIds.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'permissionIds';
        permissionIds.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'AssignPermissionsRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
