// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refresh_token_schema.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RefreshTokenSchema extends RefreshTokenSchema {
  @override
  final String refreshToken;

  factory _$RefreshTokenSchema([
    void Function(RefreshTokenSchemaBuilder)? updates,
  ]) => (RefreshTokenSchemaBuilder()..update(updates))._build();

  _$RefreshTokenSchema._({required this.refreshToken}) : super._();
  @override
  RefreshTokenSchema rebuild(
    void Function(RefreshTokenSchemaBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  RefreshTokenSchemaBuilder toBuilder() =>
      RefreshTokenSchemaBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RefreshTokenSchema && refreshToken == other.refreshToken;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, refreshToken.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'RefreshTokenSchema',
    )..add('refreshToken', refreshToken)).toString();
  }
}

class RefreshTokenSchemaBuilder
    implements Builder<RefreshTokenSchema, RefreshTokenSchemaBuilder> {
  _$RefreshTokenSchema? _$v;

  String? _refreshToken;
  String? get refreshToken => _$this._refreshToken;
  set refreshToken(String? refreshToken) => _$this._refreshToken = refreshToken;

  RefreshTokenSchemaBuilder() {
    RefreshTokenSchema._defaults(this);
  }

  RefreshTokenSchemaBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _refreshToken = $v.refreshToken;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RefreshTokenSchema other) {
    _$v = other as _$RefreshTokenSchema;
  }

  @override
  void update(void Function(RefreshTokenSchemaBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RefreshTokenSchema build() => _build();

  _$RefreshTokenSchema _build() {
    final _$result =
        _$v ??
        _$RefreshTokenSchema._(
          refreshToken: BuiltValueNullFieldError.checkNotNull(
            refreshToken,
            r'RefreshTokenSchema',
            'refreshToken',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
