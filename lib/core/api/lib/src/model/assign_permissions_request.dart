//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'assign_permissions_request.g.dart';

/// AssignPermissionsRequest
///
/// Properties:
/// * [permissionIds] 
@BuiltValue()
abstract class AssignPermissionsRequest implements Built<AssignPermissionsRequest, AssignPermissionsRequestBuilder> {
  @BuiltValueField(wireName: r'permission_ids')
  BuiltList<String> get permissionIds;

  AssignPermissionsRequest._();

  factory AssignPermissionsRequest([void updates(AssignPermissionsRequestBuilder b)]) = _$AssignPermissionsRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AssignPermissionsRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AssignPermissionsRequest> get serializer => _$AssignPermissionsRequestSerializer();
}

class _$AssignPermissionsRequestSerializer implements PrimitiveSerializer<AssignPermissionsRequest> {
  @override
  final Iterable<Type> types = const [AssignPermissionsRequest, _$AssignPermissionsRequest];

  @override
  final String wireName = r'AssignPermissionsRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AssignPermissionsRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'permission_ids';
    yield serializers.serialize(
      object.permissionIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AssignPermissionsRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AssignPermissionsRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'permission_ids':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.permissionIds.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AssignPermissionsRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AssignPermissionsRequestBuilder();
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

