//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'reset_password_schema.g.dart';

/// ResetPasswordSchema
///
/// Properties:
/// * [token] 
/// * [newPassword] 
@BuiltValue()
abstract class ResetPasswordSchema implements Built<ResetPasswordSchema, ResetPasswordSchemaBuilder> {
  @BuiltValueField(wireName: r'token')
  String get token;

  @BuiltValueField(wireName: r'new_password')
  String get newPassword;

  ResetPasswordSchema._();

  factory ResetPasswordSchema([void updates(ResetPasswordSchemaBuilder b)]) = _$ResetPasswordSchema;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ResetPasswordSchemaBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ResetPasswordSchema> get serializer => _$ResetPasswordSchemaSerializer();
}

class _$ResetPasswordSchemaSerializer implements PrimitiveSerializer<ResetPasswordSchema> {
  @override
  final Iterable<Type> types = const [ResetPasswordSchema, _$ResetPasswordSchema];

  @override
  final String wireName = r'ResetPasswordSchema';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ResetPasswordSchema object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'token';
    yield serializers.serialize(
      object.token,
      specifiedType: const FullType(String),
    );
    yield r'new_password';
    yield serializers.serialize(
      object.newPassword,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ResetPasswordSchema object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ResetPasswordSchemaBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.token = valueDes;
          break;
        case r'new_password':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.newPassword = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ResetPasswordSchema deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ResetPasswordSchemaBuilder();
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

