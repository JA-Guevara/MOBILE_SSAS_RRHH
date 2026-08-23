//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'forgot_password_schema.g.dart';

/// ForgotPasswordSchema
///
/// Properties:
/// * [email] 
@BuiltValue()
abstract class ForgotPasswordSchema implements Built<ForgotPasswordSchema, ForgotPasswordSchemaBuilder> {
  @BuiltValueField(wireName: r'email')
  String get email;

  ForgotPasswordSchema._();

  factory ForgotPasswordSchema([void updates(ForgotPasswordSchemaBuilder b)]) = _$ForgotPasswordSchema;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ForgotPasswordSchemaBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ForgotPasswordSchema> get serializer => _$ForgotPasswordSchemaSerializer();
}

class _$ForgotPasswordSchemaSerializer implements PrimitiveSerializer<ForgotPasswordSchema> {
  @override
  final Iterable<Type> types = const [ForgotPasswordSchema, _$ForgotPasswordSchema];

  @override
  final String wireName = r'ForgotPasswordSchema';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ForgotPasswordSchema object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'email';
    yield serializers.serialize(
      object.email,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ForgotPasswordSchema object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ForgotPasswordSchemaBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.email = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ForgotPasswordSchema deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ForgotPasswordSchemaBuilder();
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

