//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'refresh_token_schema.g.dart';

/// RefreshTokenSchema
///
/// Properties:
/// * [refreshToken] 
@BuiltValue()
abstract class RefreshTokenSchema implements Built<RefreshTokenSchema, RefreshTokenSchemaBuilder> {
  @BuiltValueField(wireName: r'refresh_token')
  String get refreshToken;

  RefreshTokenSchema._();

  factory RefreshTokenSchema([void updates(RefreshTokenSchemaBuilder b)]) = _$RefreshTokenSchema;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RefreshTokenSchemaBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RefreshTokenSchema> get serializer => _$RefreshTokenSchemaSerializer();
}

class _$RefreshTokenSchemaSerializer implements PrimitiveSerializer<RefreshTokenSchema> {
  @override
  final Iterable<Type> types = const [RefreshTokenSchema, _$RefreshTokenSchema];

  @override
  final String wireName = r'RefreshTokenSchema';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RefreshTokenSchema object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'refresh_token';
    yield serializers.serialize(
      object.refreshToken,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RefreshTokenSchema object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RefreshTokenSchemaBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'refresh_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.refreshToken = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RefreshTokenSchema deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RefreshTokenSchemaBuilder();
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

