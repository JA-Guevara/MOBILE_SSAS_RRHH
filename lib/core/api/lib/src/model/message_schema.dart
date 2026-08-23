//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'message_schema.g.dart';

/// MessageSchema
///
/// Properties:
/// * [message] 
@BuiltValue()
abstract class MessageSchema implements Built<MessageSchema, MessageSchemaBuilder> {
  @BuiltValueField(wireName: r'message')
  String get message;

  MessageSchema._();

  factory MessageSchema([void updates(MessageSchemaBuilder b)]) = _$MessageSchema;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MessageSchemaBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MessageSchema> get serializer => _$MessageSchemaSerializer();
}

class _$MessageSchemaSerializer implements PrimitiveSerializer<MessageSchema> {
  @override
  final Iterable<Type> types = const [MessageSchema, _$MessageSchema];

  @override
  final String wireName = r'MessageSchema';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MessageSchema object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MessageSchema object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MessageSchemaBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.message = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MessageSchema deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MessageSchemaBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

