// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_pair_schema.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TokenPairSchema extends TokenPairSchema {
  @override
  final String accessToken;
  @override
  final String refreshToken;
  @override
  final String? tokenType;

  factory _$TokenPairSchema([void Function(TokenPairSchemaBuilder)? updates]) =>
      (TokenPairSchemaBuilder()..update(updates))._build();

  _$TokenPairSchema._(
      {required this.accessToken, required this.refreshToken, this.tokenType})
      : super._();
  @override
  TokenPairSchema rebuild(void Function(TokenPairSchemaBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TokenPairSchemaBuilder toBuilder() => TokenPairSchemaBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TokenPairSchema &&
        accessToken == other.accessToken &&
        refreshToken == other.refreshToken &&
        tokenType == other.tokenType;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, accessToken.hashCode);
    _$hash = $jc(_$hash, refreshToken.hashCode);
    _$hash = $jc(_$hash, tokenType.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TokenPairSchema')
          ..add('accessToken', accessToken)
          ..add('refreshToken', refreshToken)
          ..add('tokenType', tokenType))
        .toString();
  }
}

class TokenPairSchemaBuilder
    implements Builder<TokenPairSchema, TokenPairSchemaBuilder> {
  _$TokenPairSchema? _$v;

  String? _accessToken;
  String? get accessToken => _$this._accessToken;
  set accessToken(String? accessToken) => _$this._accessToken = accessToken;

  String? _refreshToken;
  String? get refreshToken => _$this._refreshToken;
  set refreshToken(String? refreshToken) => _$this._refreshToken = refreshToken;

  String? _tokenType;
  String? get tokenType => _$this._tokenType;
  set tokenType(String? tokenType) => _$this._tokenType = tokenType;

  TokenPairSchemaBuilder() {
    TokenPairSchema._defaults(this);
  }

  TokenPairSchemaBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _accessToken = $v.accessToken;
      _refreshToken = $v.refreshToken;
      _tokenType = $v.tokenType;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TokenPairSchema other) {
    _$v = other as _$TokenPairSchema;
  }

  @override
  void update(void Function(TokenPairSchemaBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TokenPairSchema build() => _build();

  _$TokenPairSchema _build() {
    final _$result = _$v ??
        _$TokenPairSchema._(
          accessToken: BuiltValueNullFieldError.checkNotNull(
              accessToken, r'TokenPairSchema', 'accessToken'),
          refreshToken: BuiltValueNullFieldError.checkNotNull(
              refreshToken, r'TokenPairSchema', 'refreshToken'),
          tokenType: tokenType,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
