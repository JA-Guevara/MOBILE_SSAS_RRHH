// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_schema.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MessageSchema extends MessageSchema {
  @override
  final String message;

  factory _$MessageSchema([void Function(MessageSchemaBuilder)? updates]) =>
      (MessageSchemaBuilder()..update(updates))._build();

  _$MessageSchema._({required this.message}) : super._();
  @override
  MessageSchema rebuild(void Function(MessageSchemaBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MessageSchemaBuilder toBuilder() => MessageSchemaBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MessageSchema && message == other.message;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MessageSchema')
          ..add('message', message))
        .toString();
  }
}

class MessageSchemaBuilder
    implements Builder<MessageSchema, MessageSchemaBuilder> {
  _$MessageSchema? _$v;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  MessageSchemaBuilder() {
    MessageSchema._defaults(this);
  }

  MessageSchemaBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _message = $v.message;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MessageSchema other) {
    _$v = other as _$MessageSchema;
  }

  @override
  void update(void Function(MessageSchemaBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MessageSchema build() => _build();

  _$MessageSchema _build() {
    final _$result = _$v ??
        _$MessageSchema._(
          message: BuiltValueNullFieldError.checkNotNull(
              message, r'MessageSchema', 'message'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
