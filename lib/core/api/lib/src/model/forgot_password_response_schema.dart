//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'forgot_password_response_schema.g.dart';

/// ForgotPasswordResponseSchema
///
/// Properties:
/// * [message] 
/// * [resetToken] 
@BuiltValue()
abstract class ForgotPasswordResponseSchema implements Built<ForgotPasswordResponseSchema, ForgotPasswordResponseSchemaBuilder> {
  @BuiltValueField(wireName: r'message')
  String get message;

  @BuiltValueField(wireName: r'reset_token')
  String? get resetToken;

  ForgotPasswordResponseSchema._();

  factory ForgotPasswordResponseSchema([void updates(ForgotPasswordResponseSchemaBuilder b)]) = _$ForgotPasswordResponseSchema;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ForgotPasswordResponseSchemaBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ForgotPasswordResponseSchema> get serializer => _$ForgotPasswordResponseSchemaSerializer();
}

class _$ForgotPasswordResponseSchemaSerializer implements PrimitiveSerializer<ForgotPasswordResponseSchema> {
  @override
  final Iterable<Type> types = const [ForgotPasswordResponseSchema, _$ForgotPasswordResponseSchema];

  @override
  final String wireName = r'ForgotPasswordResponseSchema';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ForgotPasswordResponseSchema object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(String),
    );
    if (object.resetToken != null) {
      yield r'reset_token';
      yield serializers.serialize(
        object.resetToken,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ForgotPasswordResponseSchema object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ForgotPasswordResponseSchemaBuilder result,
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
        case r'reset_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.resetToken = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ForgotPasswordResponseSchema deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ForgotPasswordResponseSchemaBuilder();
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

